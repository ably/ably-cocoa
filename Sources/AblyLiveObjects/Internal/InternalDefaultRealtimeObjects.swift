import Ably
internal import AblyPlugin

/// This provides the implementation behind ``PublicDefaultRealtimeObjects``, via internal versions of the ``RealtimeObjects`` API.
internal final class InternalDefaultRealtimeObjects: Sendable, LiveMapObjectPoolDelegate {
    // Used for synchronizing access to all of this instance's mutable state. This is a temporary solution just to allow us to implement `Sendable`, and we'll revisit it in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3.
    private let mutex = NSLock()

    private nonisolated(unsafe) var mutableState: MutableState!

    private let logger: AblyPlugin.Logger
    private let userCallbackQueue: DispatchQueue
    private let clock: SimpleClock

    // These drive the testsOnly_* properties that expose the received ProtocolMessages to the test suite.
    private let receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation
    private let receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation

    /// The RTO10a interval at which we will perform garbage collection.
    private let garbageCollectionInterval: TimeInterval
    /// The RTO10b grace period for which we will retain tombstoned objects and map entries.
    private nonisolated(unsafe) var garbageCollectionGracePeriod: TimeInterval
    // The task that runs the periodic garbage collection described in RTO10.
    private nonisolated(unsafe) var garbageCollectionTask: Task<Void, Never>!

    /// Parameters used to control the garbage collection of tombstoned objects and map entries, as described in RTO10.
    internal struct GarbageCollectionOptions {
        /// The RTO10a interval at which we will perform garbage collection.
        ///
        /// The default value comes from the suggestion in RTO10a.
        internal var interval: TimeInterval = 5 * 60

        /// The initial RTO10b grace period for which we will retain tombstoned objects and map entries. This value may later get overridden by the `gcGracePeriod` of a `CONNECTED` `ProtocolMessage` from Realtime.
        ///
        /// This default value comes from RTO10b3; can be overridden for testing.
        internal var gracePeriod: TimeInterval = 24 * 60 * 60
    }

    internal var testsOnly_objectsPool: ObjectsPool {
        mutex.withLock {
            mutableState.objectsPool
        }
    }

    /// If this returns false, it means that there is currently no stored sync sequence ID, SyncObjectsPool, or BufferedObjectOperations.
    internal var testsOnly_hasSyncSequence: Bool {
        mutex.withLock {
            mutableState.syncSequence != nil
        }
    }

    // These drive the testsOnly_waitingForSyncEvents property that informs the test suite when `getRoot()` is waiting for the object sync sequence to complete per RTO1c.
    private let waitingForSyncEvents: AsyncStream<Void>
    private let waitingForSyncEventsContinuation: AsyncStream<Void>.Continuation
    /// Emits an element whenever `getRoot()` starts waiting for the object sync sequence to complete per RTO1c.
    internal var testsOnly_waitingForSyncEvents: AsyncStream<Void> {
        waitingForSyncEvents
    }

    /// Contains the data gathered during an `OBJECT_SYNC` sequence.
    private struct SyncSequence {
        /// The sync sequence ID, per RTO5a1.
        internal var id: String

        /// The `ObjectMessage`s gathered during this sync sequence.
        internal var syncObjectsPool: [SyncObjectsPoolEntry]

        /// `OBJECT` ProtocolMessages that were received during this sync sequence, to be applied once the sync sequence is complete, per RTO7a.
        internal var bufferedObjectOperations: [InboundObjectMessage]
    }

    /// Tracks whether an object sync sequence has happened yet. This allows us to wait for a sync before returning from `getRoot()`, per RTO1c.
    private struct SyncStatus {
        private(set) var isSyncComplete = false
        private let syncCompletionEvents: AsyncStream<Void>
        private let syncCompletionContinuation: AsyncStream<Void>.Continuation

        internal init() {
            (syncCompletionEvents, syncCompletionContinuation) = AsyncStream.makeStream()
        }

        internal mutating func signalSyncComplete() {
            isSyncComplete = true
            syncCompletionContinuation.yield()
        }

        internal func waitForSyncCompletion() async {
            await syncCompletionEvents.first { _ in true }
        }
    }

    internal init(logger: AblyPlugin.Logger, userCallbackQueue: DispatchQueue, clock: SimpleClock, garbageCollectionOptions: GarbageCollectionOptions = .init()) {
        self.logger = logger
        self.userCallbackQueue = userCallbackQueue
        self.clock = clock
        (receivedObjectProtocolMessages, receivedObjectProtocolMessagesContinuation) = AsyncStream.makeStream()
        (receivedObjectSyncProtocolMessages, receivedObjectSyncProtocolMessagesContinuation) = AsyncStream.makeStream()
        (waitingForSyncEvents, waitingForSyncEventsContinuation) = AsyncStream.makeStream()
        mutableState = .init(objectsPool: .init(logger: logger, userCallbackQueue: userCallbackQueue, clock: clock))
        garbageCollectionInterval = garbageCollectionOptions.interval
        garbageCollectionGracePeriod = garbageCollectionOptions.gracePeriod

        garbageCollectionTask = Task { [weak self, garbageCollectionInterval] in
            do {
                while true {
                    logger.log("Will perform garbage collection in \(garbageCollectionInterval)s", level: .debug)
                    try await Task.sleep(nanoseconds: UInt64(garbageCollectionInterval) * NSEC_PER_SEC)

                    guard let self else {
                        return
                    }

                    performGarbageCollection()
                }
            } catch {
                precondition(error is CancellationError)
                logger.log("Garbage collection task terminated due to cancellation", level: .debug)
            }
        }
    }

    deinit {
        garbageCollectionTask.cancel()
    }

    // MARK: - LiveMapObjectPoolDelegate

    internal func getObjectFromPool(id: String) -> ObjectsPool.Entry? {
        mutex.withLock {
            mutableState.objectsPool.entries[id]
        }
    }

    // MARK: - Internal methods that power RealtimeObjects conformance

    internal func getRoot(coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveMap {
        // RTO1b: If the channel is in the DETACHED or FAILED state, the library should indicate an error with code 90001
        try coreSDK.validateChannelState(notIn: [.detached, .failed], operationDescription: "getRoot")

        let syncStatus = mutex.withLock {
            mutableState.syncStatus
        }

        if !syncStatus.isSyncComplete {
            // RTO1c
            waitingForSyncEventsContinuation.yield()
            logger.log("getRoot started waiting for sync sequence to complete", level: .debug)
            await syncStatus.waitForSyncCompletion()
            logger.log("getRoot completed waiting for sync sequence to complete", level: .debug)
        }

        return mutex.withLock {
            // RTO1d
            mutableState.objectsPool.root
        }
    }

    internal func createMap(entries: [String: InternalLiveMapValue], coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveMap {
        do throws(InternalError) {
            // RTO11d
            do {
                try coreSDK.validateChannelState(notIn: [.detached, .failed, .suspended], operationDescription: "RealtimeObjects.createMap")
            } catch {
                throw error.toInternalError()
            }

            // RTO11f
            // TODO: This is a stopgap; change to use server time per RTO11f5 (https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/50)
            let timestamp = clock.now
            let creationOperation = ObjectCreationHelpers.creationOperationForLiveMap(
                entries: entries,
                timestamp: timestamp,
            )

            // RTO11g
            try await coreSDK.publish(objectMessages: [creationOperation.objectMessage])

            // RTO11h
            return mutex.withLock {
                mutableState.objectsPool.getOrCreateMap(
                    creationOperation: creationOperation,
                    logger: logger,
                    userCallbackQueue: userCallbackQueue,
                    clock: clock,
                )
            }
        } catch {
            throw error.toARTErrorInfo()
        }
    }

    internal func createMap(coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveMap {
        // RTO11f4b
        try await createMap(entries: [:], coreSDK: coreSDK)
    }

    internal func createCounter(count: Double, coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveCounter {
        do throws(InternalError) {
            // RTO12d
            do {
                try coreSDK.validateChannelState(notIn: [.detached, .failed, .suspended], operationDescription: "RealtimeObjects.createCounter")
            } catch {
                throw error.toInternalError()
            }

            // RTO12f1
            if !count.isFinite {
                throw LiveObjectsError.counterInitialValueInvalid(value: count).toARTErrorInfo().toInternalError()
            }

            // RTO12f

            // TODO: This is a stopgap; change to use server time per RTO12f5 (https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/50)
            let timestamp = clock.now
            let creationOperation = ObjectCreationHelpers.creationOperationForLiveCounter(
                count: count,
                timestamp: timestamp,
            )

            // RTO12g
            try await coreSDK.publish(objectMessages: [creationOperation.objectMessage])

            // RTO12h
            return mutex.withLock {
                mutableState.objectsPool.getOrCreateCounter(
                    creationOperation: creationOperation,
                    logger: logger,
                    userCallbackQueue: userCallbackQueue,
                    clock: clock,
                )
            }
        } catch {
            throw error.toARTErrorInfo()
        }
    }

    internal func createCounter(coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveCounter {
        // RTO12f2a
        try await createCounter(count: 0, coreSDK: coreSDK)
    }

    internal func batch(callback _: sending BatchCallback) async throws {
        notYetImplemented()
    }

    @discardableResult
    internal func on(event _: ObjectsEvent, callback _: ObjectsEventCallback) -> any OnObjectsEventResponse {
        notYetImplemented()
    }

    internal func offAll() {
        notYetImplemented()
    }

    // MARK: Handling channel events

    internal var testsOnly_onChannelAttachedHasObjects: Bool? {
        mutex.withLock {
            mutableState.onChannelAttachedHasObjects
        }
    }

    internal func onChannelAttached(hasObjects: Bool) {
        mutex.withLock {
            mutableState.onChannelAttached(
                hasObjects: hasObjects,
                logger: logger,
            )
        }
    }

    internal var testsOnly_receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        receivedObjectProtocolMessages
    }

    /// Implements the `OBJECT` handling of RTO8.
    internal func handleObjectProtocolMessage(objectMessages: [InboundObjectMessage]) {
        mutex.withLock {
            mutableState.handleObjectProtocolMessage(
                objectMessages: objectMessages,
                logger: logger,
                userCallbackQueue: userCallbackQueue,
                clock: clock,
                receivedObjectProtocolMessagesContinuation: receivedObjectProtocolMessagesContinuation,
            )
        }
    }

    internal var testsOnly_receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        receivedObjectSyncProtocolMessages
    }

    /// Implements the `OBJECT_SYNC` handling of RTO5.
    internal func handleObjectSyncProtocolMessage(objectMessages: [InboundObjectMessage], protocolMessageChannelSerial: String?) {
        mutex.withLock {
            mutableState.handleObjectSyncProtocolMessage(
                objectMessages: objectMessages,
                protocolMessageChannelSerial: protocolMessageChannelSerial,
                logger: logger,
                userCallbackQueue: userCallbackQueue,
                clock: clock,
                receivedObjectSyncProtocolMessagesContinuation: receivedObjectSyncProtocolMessagesContinuation,
            )
        }
    }

    /// Creates a zero-value LiveObject in the object pool for this object ID.
    ///
    /// Intended as a way for tests to populate the object pool.
    internal func testsOnly_createZeroValueLiveObject(forObjectID objectID: String) -> ObjectsPool.Entry? {
        mutex.withLock {
            mutableState.objectsPool.createZeroValueObject(forObjectID: objectID, logger: logger, userCallbackQueue: userCallbackQueue, clock: clock)
        }
    }

    // MARK: - Sending `OBJECT` ProtocolMessage

    // This is currently exposed so that we can try calling it from the tests in the early days of the SDK to check that we can send an OBJECT ProtocolMessage. We'll probably make it private later on.
    internal func testsOnly_publish(objectMessages: [OutboundObjectMessage], coreSDK: CoreSDK) async throws(InternalError) {
        try await coreSDK.publish(objectMessages: objectMessages)
    }

    // MARK: - Garbage collection of deleted objects and map entries

    /// Performs garbage collection of tombstoned objects and map entries, per RTO10c.
    internal func performGarbageCollection() {
        mutex.withLock {
            mutableState.objectsPool.performGarbageCollection(
                gracePeriod: garbageCollectionGracePeriod,
                clock: clock,
                logger: logger,
            )
        }
    }

    // MARK: - Testing

    /// Finishes the following streams, to allow a test to perform assertions about which elements the streams have emitted to this moment:
    ///
    /// - testsOnly_receivedObjectProtocolMessages
    /// - testsOnly_receivedObjectStateProtocolMessages
    /// - testsOnly_waitingForSyncEvents
    internal func testsOnly_finishAllTestHelperStreams() {
        receivedObjectProtocolMessagesContinuation.finish()
        receivedObjectSyncProtocolMessagesContinuation.finish()
        waitingForSyncEventsContinuation.finish()
    }

    // MARK: - Mutable state and the operations that affect it

    private struct MutableState {
        internal var objectsPool: ObjectsPool
        /// Note that we only ever populate this during a multi-`ProtocolMessage` sync sequence. It is not used in the RTO4b or RTO5a5 cases where the sync data is entirely contained within a single ProtocolMessage, because an individual ProtocolMessage is processed atomically and so no other operations that might wish to query this property can occur concurrently with the handling of these cases.
        internal var syncSequence: SyncSequence?
        internal var syncStatus = SyncStatus()
        internal var onChannelAttachedHasObjects: Bool?

        internal mutating func onChannelAttached(
            hasObjects: Bool,
            logger: Logger,
        ) {
            logger.log("onChannelAttached(hasObjects: \(hasObjects)", level: .debug)

            onChannelAttachedHasObjects = hasObjects

            // We only care about the case where HAS_OBJECTS is not set (RTO4b); if it is set then we're going to shortly receive an OBJECT_SYNC instead (RTO4a)
            guard !hasObjects else {
                return
            }

            // RTO4b1, RTO4b2: Reset the ObjectsPool to have a single empty root object
            objectsPool.reset()

            // I have, for now, not directly implemented the "perform the actions for object sync completion" of RTO4b4 since my implementation doesn't quite match the model given there; here you only have a SyncObjectsPool if you have an OBJECT_SYNC in progress, which you might not have upon receiving an ATTACHED. Instead I've just implemented what seem like the relevant side effects. Can revisit this if "the actions for object sync completion" get more complex.

            // RTO4b3, RTO4b4, RTO4b5, RTO5c3, RTO5c4, RTO5c5
            syncSequence = nil
            syncStatus.signalSyncComplete()
        }

        /// Implements the `OBJECT_SYNC` handling of RTO5.
        internal mutating func handleObjectSyncProtocolMessage(
            objectMessages: [InboundObjectMessage],
            protocolMessageChannelSerial: String?,
            logger: Logger,
            userCallbackQueue: DispatchQueue,
            clock: SimpleClock,
            receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation,
        ) {
            logger.log("handleObjectSyncProtocolMessage(objectMessages: \(LoggingUtilities.formatObjectMessagesForLogging(objectMessages)), protocolMessageChannelSerial: \(String(describing: protocolMessageChannelSerial)))", level: .debug)

            receivedObjectSyncProtocolMessagesContinuation.yield(objectMessages)

            // If populated, this contains a full set of sync data for the channel, and should be applied to the ObjectsPool.
            let completedSyncObjectsPool: [SyncObjectsPoolEntry]?
            // If populated, this contains a set of buffered inbound OBJECT messages that should be applied.
            let completedSyncBufferedObjectOperations: [InboundObjectMessage]?

            if let protocolMessageChannelSerial {
                let syncCursor: SyncCursor
                do {
                    // RTO5a
                    syncCursor = try SyncCursor(channelSerial: protocolMessageChannelSerial)
                } catch {
                    logger.log("Failed to parse sync cursor: \(error)", level: .error)
                    return
                }

                // Figure out whether to continue any existing sync sequence or start a new one
                var updatedSyncSequence: SyncSequence = if let syncSequence {
                    if syncCursor.sequenceID == syncSequence.id {
                        // RTO5a3: Continue existing sync sequence
                        syncSequence
                    } else {
                        // RTO5a2a, RTO5a2b: new sequence started, discard previous
                        .init(id: syncCursor.sequenceID, syncObjectsPool: [], bufferedObjectOperations: [])
                    }
                } else {
                    // There's no current sync sequence; start one
                    .init(id: syncCursor.sequenceID, syncObjectsPool: [], bufferedObjectOperations: [])
                }

                // RTO5b
                updatedSyncSequence.syncObjectsPool.append(contentsOf: objectMessages.compactMap { objectMessage in
                    if let object = objectMessage.object {
                        .init(state: object, objectMessageSerialTimestamp: objectMessage.serialTimestamp)
                    } else {
                        nil
                    }
                })

                syncSequence = updatedSyncSequence

                (completedSyncObjectsPool, completedSyncBufferedObjectOperations) = if syncCursor.isEndOfSequence {
                    (updatedSyncSequence.syncObjectsPool, updatedSyncSequence.bufferedObjectOperations)
                } else {
                    (nil, nil)
                }
            } else {
                // RTO5a5: The sync data is contained entirely within this single OBJECT_SYNC
                completedSyncObjectsPool = objectMessages.compactMap { objectMessage in
                    if let object = objectMessage.object {
                        .init(state: object, objectMessageSerialTimestamp: objectMessage.serialTimestamp)
                    } else {
                        nil
                    }
                }
                completedSyncBufferedObjectOperations = nil
            }

            if let completedSyncObjectsPool {
                // RTO5c
                objectsPool.applySyncObjectsPool(
                    completedSyncObjectsPool,
                    logger: logger,
                    userCallbackQueue: userCallbackQueue,
                    clock: clock,
                )

                // RTO5c6
                if let completedSyncBufferedObjectOperations, !completedSyncBufferedObjectOperations.isEmpty {
                    logger.log("Applying \(completedSyncBufferedObjectOperations.count) buffered OBJECT ObjectMessages", level: .debug)
                    for objectMessage in completedSyncBufferedObjectOperations {
                        applyObjectProtocolMessageObjectMessage(
                            objectMessage,
                            logger: logger,
                            userCallbackQueue: userCallbackQueue,
                            clock: clock,
                        )
                    }
                }

                // RTO5c3, RTO5c4, RTO5c5
                syncSequence = nil

                syncStatus.signalSyncComplete()
            }
        }

        /// Implements the `OBJECT` handling of RTO8.
        internal mutating func handleObjectProtocolMessage(
            objectMessages: [InboundObjectMessage],
            logger: Logger,
            userCallbackQueue: DispatchQueue,
            clock: SimpleClock,
            receivedObjectProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation,
        ) {
            receivedObjectProtocolMessagesContinuation.yield(objectMessages)

            logger.log("handleObjectProtocolMessage(objectMessages: \(LoggingUtilities.formatObjectMessagesForLogging(objectMessages)))", level: .debug)

            if let existingSyncSequence = syncSequence {
                // RTO8a: Buffer the OBJECT message, to be handled once the sync completes
                logger.log("Buffering OBJECT message due to in-progress sync", level: .debug)
                var newSyncSequence = existingSyncSequence
                newSyncSequence.bufferedObjectOperations.append(contentsOf: objectMessages)
                syncSequence = newSyncSequence
            } else {
                // RTO8b: Handle the OBJECT message immediately
                for objectMessage in objectMessages {
                    applyObjectProtocolMessageObjectMessage(
                        objectMessage,
                        logger: logger,
                        userCallbackQueue: userCallbackQueue,
                        clock: clock,
                    )
                }
            }
        }

        /// Implements the `OBJECT` application of RTO9.
        private mutating func applyObjectProtocolMessageObjectMessage(
            _ objectMessage: InboundObjectMessage,
            logger: Logger,
            userCallbackQueue: DispatchQueue,
            clock: SimpleClock,
        ) {
            guard let operation = objectMessage.operation else {
                // RTO9a1
                logger.log("Unsupported OBJECT message received (no operation); \(objectMessage)", level: .warn)
                return
            }

            // RTO9a2a1, RTO9a2a2
            let entry: ObjectsPool.Entry
            if let existingEntry = objectsPool.entries[operation.objectId] {
                entry = existingEntry
            } else {
                guard let newEntry = objectsPool.createZeroValueObject(
                    forObjectID: operation.objectId,
                    logger: logger,
                    userCallbackQueue: userCallbackQueue,
                    clock: clock,
                ) else {
                    logger.log("Unable to create zero-value object for \(operation.objectId) when processing OBJECT message; dropping", level: .warn)
                    return
                }

                entry = newEntry
            }

            switch operation.action {
            case let .known(action):
                switch action {
                case .mapCreate, .mapSet, .mapRemove, .counterCreate, .counterInc, .objectDelete:
                    // RTO9a2a3
                    entry.apply(
                        operation,
                        objectMessageSerial: objectMessage.serial,
                        objectMessageSiteCode: objectMessage.siteCode,
                        objectMessageSerialTimestamp: objectMessage.serialTimestamp,
                        objectsPool: &objectsPool,
                    )
                }
            case let .unknown(rawValue):
                // RTO9a2b
                logger.log("Unsupported OBJECT operation action \(rawValue) received", level: .warn)
                return
            }
        }
    }
}
