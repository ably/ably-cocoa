import Ably
internal import AblyPlugin

/// The class that provides the public API for interacting with LiveObjects, via the ``ARTRealtimeChannel/objects`` property.
internal final class DefaultRealtimeObjects: RealtimeObjects, LiveMapObjectPoolDelegate {
    // Used for synchronizing access to all of this instance's mutable state. This is a temporary solution just to allow us to implement `Sendable`, and we'll revisit it in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3.
    private let mutex = NSLock()

    private nonisolated(unsafe) var mutableState: MutableState!

    private let coreSDK: CoreSDK
    private let logger: AblyPlugin.Logger

    // These drive the testsOnly_* properties that expose the received ProtocolMessages to the test suite.
    private let receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation
    private let receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation

    internal var testsOnly_objectsPool: ObjectsPool {
        mutex.withLock {
            mutableState.objectsPool
        }
    }

    /// If this returns false, it means that there is currently no stored sync sequence ID or SyncObjectsPool
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
        internal var syncObjectsPool: [ObjectState]
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

    internal init(coreSDK: CoreSDK, logger: AblyPlugin.Logger) {
        self.coreSDK = coreSDK
        self.logger = logger
        (receivedObjectProtocolMessages, receivedObjectProtocolMessagesContinuation) = AsyncStream.makeStream()
        (receivedObjectSyncProtocolMessages, receivedObjectSyncProtocolMessagesContinuation) = AsyncStream.makeStream()
        (waitingForSyncEvents, waitingForSyncEventsContinuation) = AsyncStream.makeStream()
        mutableState = .init(objectsPool: .init(rootDelegate: self, rootCoreSDK: coreSDK))
    }

    // MARK: - LiveMapObjectPoolDelegate

    internal func getObjectFromPool(id: String) -> ObjectsPool.Entry? {
        mutex.withLock {
            mutableState.objectsPool.entries[id]
        }
    }

    // MARK: `RealtimeObjects` protocol

    internal func getRoot() async throws(ARTErrorInfo) -> any LiveMap {
        // RTO1b: If the channel is in the DETACHED or FAILED state, the library should indicate an error with code 90001
        let currentChannelState = coreSDK.channelState
        if currentChannelState == .detached || currentChannelState == .failed {
            throw ARTErrorInfo.create(withCode: Int(ARTErrorCode.channelOperationFailedInvalidState.rawValue), message: "getRoot operation failed (invalid channel state: \(currentChannelState))")
        }

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

    internal func createMap(entries _: [String: LiveMapValue]) async throws(ARTErrorInfo) -> any LiveMap {
        notYetImplemented()
    }

    internal func createMap() async throws(ARTErrorInfo) -> any LiveMap {
        notYetImplemented()
    }

    internal func createCounter(count _: Double) async throws(ARTErrorInfo) -> any LiveCounter {
        notYetImplemented()
    }

    internal func createCounter() async throws(ARTErrorInfo) -> any LiveCounter {
        notYetImplemented()
    }

    internal func batch(callback _: sending (sending any BatchContext) -> Void) async throws {
        notYetImplemented()
    }

    internal func on(event _: ObjectsEvent, callback _: () -> Void) -> any OnObjectsEventResponse {
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
                mapDelegate: self,
                coreSDK: coreSDK,
            )
        }
    }

    internal var testsOnly_receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        receivedObjectProtocolMessages
    }

    internal func handleObjectProtocolMessage(objectMessages: [InboundObjectMessage]) {
        receivedObjectProtocolMessagesContinuation.yield(objectMessages)
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
                receivedObjectSyncProtocolMessagesContinuation: receivedObjectSyncProtocolMessagesContinuation,
                mapDelegate: self,
                coreSDK: coreSDK,
            )
        }
    }

    /// Creates a zero-value LiveObject in the object pool for this object ID.
    ///
    /// Intended as a way for tests to populate the object pool.
    internal func testsOnly_createZeroValueLiveObject(forObjectID objectID: String, coreSDK: CoreSDK) -> ObjectsPool.Entry? {
        mutex.withLock {
            mutableState.objectsPool.createZeroValueObject(forObjectID: objectID, mapDelegate: self, coreSDK: coreSDK)
        }
    }

    // MARK: - Sending `OBJECT` ProtocolMessage

    // This is currently exposed so that we can try calling it from the tests in the early days of the SDK to check that we can send an OBJECT ProtocolMessage. We'll probably make it private later on.
    internal func testsOnly_sendObject(objectMessages: [OutboundObjectMessage]) async throws(InternalError) {
        try await coreSDK.sendObject(objectMessages: objectMessages)
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
        internal var syncSequence: SyncSequence?
        internal var syncStatus = SyncStatus()
        internal var onChannelAttachedHasObjects: Bool?

        internal mutating func onChannelAttached(
            hasObjects: Bool,
            logger: Logger,
            mapDelegate: LiveMapObjectPoolDelegate,
            coreSDK: CoreSDK,
        ) {
            logger.log("onChannelAttached(hasObjects: \(hasObjects)", level: .debug)

            onChannelAttachedHasObjects = hasObjects

            // We only care about the case where HAS_OBJECTS is not set (RTO4b); if it is set then we're going to shortly receive an OBJECT_SYNC instead (RTO4a)
            guard !hasObjects else {
                return
            }

            // RTO4b1, RTO4b2: Reset the ObjectsPool to have a single empty root object
            // TODO: this one is unclear (are we meant to replace the root or just clear its data?) https://github.com/ably/specification/pull/333/files#r2183493458
            objectsPool = .init(rootDelegate: mapDelegate, rootCoreSDK: coreSDK)

            // I have, for now, not directly implemented the "perform the actions for object sync completion" of RTO4b4 since my implementation doesn't quite match the model given there; here you only have a SyncObjectsPool if you have an OBJECT_SYNC in progress, which you might not have upon receiving an ATTACHED. Instead I've just implemented what seem like the relevant side effects. Can revisit this if "the actions for object sync completion" get more complex.

            // RTO4b3, RTO4b4, RTO5c3, RTO5c4
            syncSequence = nil
            syncStatus.signalSyncComplete()
        }

        /// Implements the `OBJECT_SYNC` handling of RTO5.
        internal mutating func handleObjectSyncProtocolMessage(
            objectMessages: [InboundObjectMessage],
            protocolMessageChannelSerial: String?,
            logger: Logger,
            receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation,
            mapDelegate: LiveMapObjectPoolDelegate,
            coreSDK: CoreSDK,
        ) {
            logger.log("handleObjectSyncProtocolMessage(objectMessages: \(objectMessages), protocolMessageChannelSerial: \(String(describing: protocolMessageChannelSerial)))", level: .debug)

            receivedObjectSyncProtocolMessagesContinuation.yield(objectMessages)

            // If populated, this contains a full set of sync data for the channel, and should be applied to the ObjectsPool.
            let completedSyncObjectsPool: [ObjectState]?

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
                        // RTO5a2: new sequence started, discard previous
                        .init(id: syncCursor.sequenceID, syncObjectsPool: [])
                    }
                } else {
                    // There's no current sync sequence; start one
                    .init(id: syncCursor.sequenceID, syncObjectsPool: [])
                }

                // RTO5b
                updatedSyncSequence.syncObjectsPool.append(contentsOf: objectMessages.compactMap(\.object))

                syncSequence = updatedSyncSequence

                completedSyncObjectsPool = if syncCursor.isEndOfSequence {
                    updatedSyncSequence.syncObjectsPool
                } else {
                    nil
                }
            } else {
                // RTO5a5: The sync data is contained entirely within this single OBJECT_SYNC
                completedSyncObjectsPool = objectMessages.compactMap(\.object)
            }

            if let completedSyncObjectsPool {
                // RTO5c
                objectsPool.applySyncObjectsPool(
                    completedSyncObjectsPool,
                    mapDelegate: mapDelegate,
                    coreSDK: coreSDK,
                    logger: logger,
                )
                // RTO5c3, RTO5c4
                syncSequence = nil

                syncStatus.signalSyncComplete()
            }
        }
    }
}
