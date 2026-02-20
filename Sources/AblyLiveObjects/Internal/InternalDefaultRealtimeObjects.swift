internal import _AblyPluginSupportPrivate
import Ably

/// Protocol that abstracts `InternalDefaultRealtimeObjects`, for testability.
internal protocol InternalRealtimeObjectsProtocol: LiveMapObjectsPoolDelegate {
    /// Per RTO20.
    ///
    /// The callback may be invoked while exclusive access to internal state is held, so it must not
    /// call other methods on this object that read or mutate its state.
    /// https://github.com/ably/ably-liveobjects-swift-plugin/issues/120 tracks removing this restriction.
    func nosync_publishAndApply(
        objectMessages: [OutboundObjectMessage],
        coreSDK: CoreSDK,
        callback: @escaping @Sendable (Result<Void, ARTErrorInfo>) -> Void,
    )
}

/// This provides the implementation behind ``PublicDefaultRealtimeObjects``, via internal versions of the ``RealtimeObjects`` API.
internal final class InternalDefaultRealtimeObjects: Sendable, InternalRealtimeObjectsProtocol {
    private let mutableStateMutex: DispatchQueueMutex<MutableState>

    private let logger: Logger
    private let userCallbackQueue: DispatchQueue
    private let clock: SimpleClock

    // These drive the testsOnly_* properties that expose the received ProtocolMessages to the test suite.
    private let receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation
    private let receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]>
    private let receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation

    /// The RTO10a interval at which we will perform garbage collection.
    private let garbageCollectionInterval: TimeInterval
    // The task that runs the periodic garbage collection described in RTO10.
    private nonisolated(unsafe) var garbageCollectionTask: Task<Void, Never>!

    /// Parameters used to control the garbage collection of tombstoned objects and map entries, as described in RTO10.
    internal struct GarbageCollectionOptions: Encodable, Hashable {
        /// The RTO10a interval at which we will perform garbage collection.
        ///
        /// The default value comes from the suggestion in RTO10a.
        internal var interval: TimeInterval = 5 * 60

        /// The initial RTO10b grace period for which we will retain tombstoned objects and map entries. This value may later get overridden by the `objectsGCGracePeriod` of a `CONNECTED` `ProtocolMessage` from Realtime.
        ///
        /// This default value comes from RTO10b3; can be overridden for testing.
        internal var gracePeriod: GracePeriod = .dynamic(Self.defaultGracePeriod)

        /// The default value from RTO10b3.
        internal static let defaultGracePeriod: TimeInterval = 24 * 60 * 60

        internal enum GracePeriod: Encodable, Hashable {
            /// The client will always use this grace period, and will not update the grace period from the `objectsGCGracePeriod` of a `CONNECTED` `ProtocolMessage`.
            ///
            /// - Important: This should only be used in tests.
            case fixed(TimeInterval)

            /// The client will use this grace period, which may be subsequently updated by the `objectsGCGracePeriod` of a `CONNECTED` `ProtocolMessage`.
            case dynamic(TimeInterval)

            internal var toTimeInterval: TimeInterval {
                switch self {
                case let .fixed(timeInterval), let .dynamic(timeInterval):
                    timeInterval
                }
            }
        }
    }

    internal var testsOnly_objectsPool: ObjectsPool {
        mutableStateMutex.withSync { mutableState in
            mutableState.objectsPool
        }
    }

    /// If this returns false, it means that there is currently no stored sync sequence ID, SyncObjectsPool, or BufferedObjectOperations.
    internal var testsOnly_hasSyncSequence: Bool {
        mutableStateMutex.withSync { mutableState in
            if case let .syncing(syncingData) = mutableState.state, syncingData.syncSequence != nil {
                true
            } else {
                false
            }
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
    }

    internal init(
        logger: Logger,
        internalQueue: DispatchQueue,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
        garbageCollectionOptions: GarbageCollectionOptions = .init()
    ) {
        self.logger = logger
        self.userCallbackQueue = userCallbackQueue
        self.clock = clock
        (receivedObjectProtocolMessages, receivedObjectProtocolMessagesContinuation) = AsyncStream.makeStream()
        (receivedObjectSyncProtocolMessages, receivedObjectSyncProtocolMessagesContinuation) = AsyncStream.makeStream()
        (waitingForSyncEvents, waitingForSyncEventsContinuation) = AsyncStream.makeStream()
        (completedGarbageCollectionEventsWithoutBuffering, completedGarbageCollectionEventsWithoutBufferingContinuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(0))
        mutableStateMutex = .init(
            dispatchQueue: internalQueue,
            initialValue: .init(
                objectsPool: .init(
                    logger: logger,
                    internalQueue: internalQueue,
                    userCallbackQueue: userCallbackQueue,
                    clock: clock,
                ),
                garbageCollectionGracePeriod: garbageCollectionOptions.gracePeriod,
            ),
        )
        garbageCollectionInterval = garbageCollectionOptions.interval

        garbageCollectionTask = Task { [weak self, garbageCollectionInterval] in
            do {
                while true {
                    logger.log("Will perform garbage collection in \(garbageCollectionInterval)s", level: .debug)
                    try await Task.sleep(nanoseconds: UInt64(garbageCollectionInterval * Double(NSEC_PER_SEC)))

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

    // MARK: - LiveMapObjectsPoolDelegate

    internal var nosync_objectsPool: ObjectsPool {
        mutableStateMutex.withoutSync { mutableState in
            mutableState.objectsPool
        }
    }

    // MARK: - Internal methods that power RealtimeObjects conformance

    internal func getRoot(coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveMap {
        let state = try mutableStateMutex.withSync { mutableState throws(ARTErrorInfo) in
            // RTO1b: If the channel is in the DETACHED or FAILED state, the library should indicate an error with code 90001
            try coreSDK.nosync_validateChannelState(notIn: [.detached, .failed], operationDescription: "getRoot")

            return mutableState.state
        }

        if state.toObjectsSyncState != .synced {
            // RTO1c
            waitingForSyncEventsContinuation.yield()
            logger.log("getRoot started waiting for sync sequence to complete", level: .debug)
            await withCheckedContinuation { continuation in
                onInternal(event: .synced) { subscription in
                    subscription.off()
                    continuation.resume()
                }
            }
            logger.log("getRoot completed waiting for sync sequence to complete", level: .debug)
        }

        return mutableStateMutex.withSync { mutableState in
            // RTO1d
            mutableState.objectsPool.root
        }
    }

    internal func createMap(entries: [String: InternalLiveMapValue], coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveMap {
        try await withCheckedContinuation { (continuation: CheckedContinuation<Result<InternalDefaultLiveMap, ARTErrorInfo>, _>) in
            do throws(ARTErrorInfo) {
                try mutableStateMutex.withSync { _ throws(ARTErrorInfo) in
                    // RTO11d
                    try coreSDK.nosync_validateChannelState(notIn: [.detached, .failed, .suspended], operationDescription: "RealtimeObjects.createMap")

                    // RTO11f7
                    coreSDK.nosync_fetchServerTime { [self] result in
                        let timestamp: Date
                        switch result {
                        case let .failure(error):
                            continuation.resume(returning: .failure(error))
                            return
                        case let .success(t):
                            timestamp = t
                        }

                        // RTO11f
                        let creationOperation = ObjectCreationHelpers.nosync_creationOperationForLiveMap(
                            entries: entries,
                            timestamp: timestamp,
                        )

                        // RTO11i
                        nosync_publishAndApply(objectMessages: [creationOperation.objectMessage], coreSDK: coreSDK) { mutableState, result in
                            switch result {
                            case let .failure(error):
                                continuation.resume(returning: .failure(error))
                            case .success:
                                // RTO11h

                                // RTO11h2
                                guard case let .map(existingMap) = mutableState.objectsPool.entries[creationOperation.objectID] else {
                                    // RTO11h3d: Object should have been created by publishAndApply
                                    let error = LiveObjectsError.newlyCreatedObjectNotInPool(objectID: creationOperation.objectID).toARTErrorInfo()
                                    continuation.resume(returning: .failure(error))
                                    return
                                }

                                continuation.resume(returning: .success(existingMap))
                            }
                        }
                    }
                }
            } catch {
                continuation.resume(returning: .failure(error))
            }
        }.get()
    }

    internal func createMap(coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveMap {
        // RTO11f4b
        try await createMap(entries: [:], coreSDK: coreSDK)
    }

    internal func createCounter(count: Double, coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveCounter {
        try await withCheckedContinuation { (continuation: CheckedContinuation<Result<InternalDefaultLiveCounter, ARTErrorInfo>, _>) in
            do throws(ARTErrorInfo) {
                try mutableStateMutex.withSync { _ throws(ARTErrorInfo) in
                    // RTO12d
                    try coreSDK.nosync_validateChannelState(notIn: [.detached, .failed, .suspended], operationDescription: "RealtimeObjects.createCounter")

                    // RTO12f1
                    if !count.isFinite {
                        throw LiveObjectsError.counterInitialValueInvalid(value: count).toARTErrorInfo()
                    }

                    // RTO12f

                    // RTO12f5
                    coreSDK.nosync_fetchServerTime { [self] result in
                        let timestamp: Date
                        switch result {
                        case let .failure(error):
                            continuation.resume(returning: .failure(error))
                            return
                        case let .success(t):
                            timestamp = t
                        }

                        let creationOperation = ObjectCreationHelpers.creationOperationForLiveCounter(
                            count: count,
                            timestamp: timestamp,
                        )

                        // RTO12i
                        nosync_publishAndApply(objectMessages: [creationOperation.objectMessage], coreSDK: coreSDK) { mutableState, result in
                            switch result {
                            case let .failure(error):
                                continuation.resume(returning: .failure(error))
                            case .success:
                                // RTO12h

                                // RTO12h2
                                guard case let .counter(existingCounter) = mutableState.objectsPool.entries[creationOperation.objectID] else {
                                    // RTO12h3d: Object should have been created by publishAndApply
                                    let error = LiveObjectsError.newlyCreatedObjectNotInPool(objectID: creationOperation.objectID).toARTErrorInfo()
                                    continuation.resume(returning: .failure(error))
                                    return
                                }

                                continuation.resume(returning: .success(existingCounter))
                            }
                        }
                    }
                }
            } catch {
                continuation.resume(returning: .failure(error))
            }
        }.get()
    }

    internal func createCounter(coreSDK: CoreSDK) async throws(ARTErrorInfo) -> InternalDefaultLiveCounter {
        // RTO12f2a
        try await createCounter(count: 0, coreSDK: coreSDK)
    }

    // RTO18
    @discardableResult
    internal func on(event: ObjectsEvent, callback: @escaping ObjectsEventCallback) -> any OnObjectsEventResponse {
        mutableStateMutex.withSync { mutableState in
            // swiftlint:disable:next trailing_closure
            mutableState.on(event: event, callback: callback, updateSelfLater: { [weak self] action in
                guard let self else {
                    return
                }

                mutableStateMutex.withSync { mutableState in
                    action(&mutableState)
                }
            })
        }
    }

    /// Adds a subscriber to the ``internalObjectsEventSubscriptionStorage`` (i.e. unaffected by `offAll()`).
    @discardableResult
    internal func onInternal(event: ObjectsEvent, callback: @escaping ObjectsEventCallback) -> any OnObjectsEventResponse {
        // TODO: Looking at this again later the whole process for adding a subscriber is really verbose and boilerplate-y, and I think the unfortunate result of me trying to be clever at some point; revisit in https://github.com/ably/ably-liveobjects-swift-plugin/issues/102
        mutableStateMutex.withSync { mutableState in
            // swiftlint:disable:next trailing_closure
            mutableState.onInternal(event: event, callback: callback, updateSelfLater: { [weak self] action in
                guard let self else {
                    return
                }

                mutableStateMutex.withSync { mutableState in
                    action(&mutableState)
                }
            })
        }
    }

    internal func offAll() {
        mutableStateMutex.withSync { mutableState in
            mutableState.offAll()
        }
    }

    // MARK: Handling channel events

    internal var testsOnly_onChannelAttachedHasObjects: Bool? {
        mutableStateMutex.withSync { mutableState in
            mutableState.onChannelAttachedHasObjects
        }
    }

    internal func nosync_onChannelAttached(hasObjects: Bool) {
        mutableStateMutex.withoutSync { mutableState in
            mutableState.nosync_onChannelAttached(
                hasObjects: hasObjects,
                logger: logger,
                userCallbackQueue: userCallbackQueue,
            )
        }
    }

    internal func nosync_onChannelStateChanged(toState state: _AblyPluginSupportPrivate.RealtimeChannelState, reason: ARTErrorInfo?) {
        mutableStateMutex.withoutSync { mutableState in
            mutableState.nosync_onChannelStateChanged(
                toState: state,
                reason: reason,
                logger: logger,
            )
        }
    }

    internal var testsOnly_receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        receivedObjectProtocolMessages
    }

    /// Implements the `OBJECT` handling of RTO8.
    internal func nosync_handleObjectProtocolMessage(objectMessages: [InboundObjectMessage]) {
        mutableStateMutex.withoutSync { mutableState in
            mutableState.nosync_handleObjectProtocolMessage(
                objectMessages: objectMessages,
                logger: logger,
                internalQueue: mutableStateMutex.dispatchQueue,
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
    internal func nosync_handleObjectSyncProtocolMessage(objectMessages: [InboundObjectMessage], protocolMessageChannelSerial: String?) {
        mutableStateMutex.withoutSync { mutableState in
            mutableState.nosync_handleObjectSyncProtocolMessage(
                objectMessages: objectMessages,
                protocolMessageChannelSerial: protocolMessageChannelSerial,
                logger: logger,
                internalQueue: mutableStateMutex.dispatchQueue,
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
        mutableStateMutex.withSync { mutableState in
            mutableState.objectsPool.createZeroValueObject(
                forObjectID: objectID,
                logger: logger,
                internalQueue: mutableStateMutex.dispatchQueue,
                userCallbackQueue: userCallbackQueue,
                clock: clock,
            )
        }
    }

    // MARK: - Sending `OBJECT` ProtocolMessage

    // This is currently exposed so that we can try calling it from the tests in the early days of the SDK to check that we can send an OBJECT ProtocolMessage. We'll probably make it private later on.
    internal func testsOnly_publish(objectMessages: [OutboundObjectMessage], coreSDK: CoreSDK) async throws(ARTErrorInfo) {
        try await withCheckedContinuation { (continuation: CheckedContinuation<Result<Void, ARTErrorInfo>, _>) in
            mutableStateMutex.withSync { _ in
                coreSDK.nosync_publish(objectMessages: objectMessages) { result in
                    continuation.resume(returning: result.map { _ in })
                }
            }
        }.get()
    }

    /// RTO20: Publishes ObjectMessages and applies them locally upon receiving the ACK from the server.
    ///
    /// Must be called from within `mutableStateMutex.withSync` (i.e. on the internal queue).
    internal func nosync_publishAndApply(
        objectMessages: [OutboundObjectMessage],
        coreSDK: CoreSDK,
        callback: @escaping @Sendable (Result<Void, ARTErrorInfo>) -> Void,
    ) {
        nosync_publishAndApply(objectMessages: objectMessages, coreSDK: coreSDK) { _, result in
            callback(result)
        }
    }

    /// Internal variant of ``nosync_publishAndApply`` whose callback receives `inout MutableState`,
    /// allowing the caller to access mutable state (e.g. to look up a newly-created object) without
    /// re-acquiring the mutex.
    ///
    /// This is a workaround for the fact that behavioural methods currently live on `MutableState`,
    /// meaning callbacks are invoked while the mutex is held. See
    /// https://github.com/ably/ably-liveobjects-swift-plugin/issues/120 for the longer-term fix.
    ///
    /// Must be called from within `mutableStateMutex.withSync` (i.e. on the internal queue).
    private func nosync_publishAndApply(
        objectMessages: [OutboundObjectMessage],
        coreSDK: CoreSDK,
        mutableStateCallback: @escaping @Sendable (inout MutableState, Result<Void, ARTErrorInfo>) -> Void,
    ) {
        // RTO20b: Publish via the core SDK. The callback fires asynchronously on the internal queue.
        coreSDK.nosync_publish(objectMessages: objectMessages) { [self] result in
            let publishResult: PublishResult
            switch result {
            case let .failure(error):
                mutableStateMutex.withoutSync { mutableState in
                    mutableStateCallback(&mutableState, .failure(error))
                }
                return
            case let .success(pr):
                publishResult = pr
            }

            logger.log("nosync_publishAndApply: received ACK for \(objectMessages.count) message(s), applying locally", level: .debug)

            mutableStateMutex.withoutSync { mutableState in
                // RTO20c1: Check siteCode
                guard let siteCode = mutableState.siteCode else {
                    logger.log("nosync_publishAndApply: operations will not be applied locally: siteCode not available from connectionDetails", level: .error)
                    mutableStateCallback(&mutableState, .success(()))
                    return
                }

                // RTO20c2: Check serials length
                guard publishResult.serials.count == objectMessages.count else {
                    logger.log("nosync_publishAndApply: operations will not be applied locally: PublishResult.serials has unexpected length (expected \(objectMessages.count), got \(publishResult.serials.count))", level: .error)
                    mutableStateCallback(&mutableState, .success(()))
                    return
                }

                // RTO20d: Create synthetic inbound ObjectMessages
                let syntheticMessages = objectMessages.enumerated().compactMap { index, outboundMessage -> InboundObjectMessage? in
                    // RTO20d1: Skip null serials (conflated)
                    guard let serial = publishResult.serials[index] else {
                        logger.log("nosync_publishAndApply: operation at index \(index) will not be applied locally: serial is null in PublishResult", level: .debug)
                        return nil
                    }

                    // RTO20d2, RTO20d3: Create synthetic inbound message
                    return .createSynthetic(from: outboundMessage, serial: serial, siteCode: siteCode)
                }

                // RTO20e: Build a waiter closure that owns both the apply-on-success
                // and error-construction-on-failure logic. The waiter receives `inout MutableState`
                // so it can apply synthetic messages and pass the reference through to the callback,
                // avoiding re-entrant mutex acquisition.
                let waiter: (inout MutableState, MutableState.PublishAndApplySyncWaiterOutcome) -> Void = { [self] mutableState, outcome in
                    switch outcome {
                    case .synced:
                        // RTO20f: Apply synthetic messages with source: .local
                        for syntheticMessage in syntheticMessages {
                            mutableState.nosync_applyObjectProtocolMessageObjectMessage(
                                syntheticMessage,
                                source: .local,
                                logger: logger,
                                internalQueue: mutableStateMutex.dispatchQueue,
                                userCallbackQueue: userCallbackQueue,
                                clock: clock,
                            )
                        }
                        mutableStateCallback(&mutableState, .success(()))
                    case let .channelStateFailed(state, reason):
                        // RTO20e1
                        let error = LiveObjectsError.publishAndApplyFailedChannelStateChanged(
                            channelState: state,
                            reason: reason,
                        )
                        mutableStateCallback(&mutableState, .failure(error.toARTErrorInfo()))
                    }
                }

                // Check sync state: if synced, invoke the waiter immediately; otherwise store it.
                if mutableState.state.toObjectsSyncState != .synced {
                    // RTO20e, RTO20e1: Store as a waiter; will be invoked when sync completes
                    // or when the channel enters detached/suspended/failed.
                    logger.log("nosync_publishAndApply: waiting for sync to complete before applying \(syntheticMessages.count) message(s)", level: .debug)
                    mutableState.publishAndApplySyncWaiters.append(waiter)
                } else {
                    waiter(&mutableState, .synced)
                }
            }
        }
    }

    // MARK: - Garbage collection of deleted objects and map entries

    /// Performs garbage collection of tombstoned objects and map entries, per RTO10c.
    internal func performGarbageCollection() {
        mutableStateMutex.withSync { mutableState in
            mutableState.objectsPool.nosync_performGarbageCollection(
                gracePeriod: mutableState.garbageCollectionGracePeriod.toTimeInterval,
                clock: clock,
                logger: logger,
                eventsContinuation: completedGarbageCollectionEventsWithoutBufferingContinuation,
            )
        }
    }

    // These drive the testsOnly_completedGarbageCollectionEventsWithoutBuffering property that informs the test suite when a garbage collection cycle has completed.
    private let completedGarbageCollectionEventsWithoutBuffering: AsyncStream<Void>
    private let completedGarbageCollectionEventsWithoutBufferingContinuation: AsyncStream<Void>.Continuation
    /// Emits an element whenever a garbage collection cycle has completed.
    internal var testsOnly_completedGarbageCollectionEventsWithoutBuffering: AsyncStream<Void> {
        completedGarbageCollectionEventsWithoutBuffering
    }

    /// Sets the `siteCode` from the latest `connectionDetails`.
    ///
    /// Call this upon receiving a `CONNECTED` `ProtocolMessage`.
    internal func nosync_setSiteCode(_ siteCode: String?) {
        mutableStateMutex.withoutSync { mutableState in
            mutableState.siteCode = siteCode
        }
    }

    /// Sets the garbage collection grace period.
    ///
    /// Call this upon receiving a `CONNECTED` `ProtocolMessage`, per RTO10b2.
    ///
    /// - Note: If the `.fixed` grace period option was chosen on instantiation, this is a no-op.
    internal func nosync_setGarbageCollectionGracePeriod(_ gracePeriod: TimeInterval) {
        mutableStateMutex.withoutSync { mutableState in
            switch mutableState.garbageCollectionGracePeriod {
            case .fixed:
                // no-op
                break
            case .dynamic:
                mutableState.garbageCollectionGracePeriod = .dynamic(gracePeriod)
            }
        }
    }

    internal var testsOnly_gcGracePeriod: TimeInterval {
        mutableStateMutex.withSync { mutableState in
            mutableState.garbageCollectionGracePeriod.toTimeInterval
        }
    }

    internal var testsOnly_appliedOnAckSerials: Set<String> {
        mutableStateMutex.withSync { mutableState in
            mutableState.appliedOnAckSerials
        }
    }

    // MARK: - Testing

    /// Finishes the following streams, to allow a test to perform assertions about which elements the streams have emitted to this moment:
    ///
    /// - testsOnly_receivedObjectProtocolMessages
    /// - testsOnly_receivedObjectStateProtocolMessages
    /// - testsOnly_waitingForSyncEvents
    /// - testsOnly_completedGarbageCollectionEventsWithoutBuffering
    internal func testsOnly_finishAllTestHelperStreams() {
        receivedObjectProtocolMessagesContinuation.finish()
        receivedObjectSyncProtocolMessagesContinuation.finish()
        waitingForSyncEventsContinuation.finish()
        completedGarbageCollectionEventsWithoutBufferingContinuation.finish()
    }

    // MARK: - Mutable state and the operations that affect it

    private struct MutableState {
        internal var objectsPool: ObjectsPool
        internal var onChannelAttachedHasObjects: Bool?
        internal var objectsEventSubscriptionStorage = SubscriptionStorage<ObjectsEvent, Void>()

        /// Used when the object wishes to subscribe to its own events (i.e. unaffected by `offAll()`); used e.g. to wait for a sync before returning from `getRoot()`, per RTO1c.
        internal var internalObjectsEventSubscriptionStorage = SubscriptionStorage<ObjectsEvent, Void>()

        /// The RTO10b grace period for which we will retain tombstoned objects and map entries.
        internal var garbageCollectionGracePeriod: GarbageCollectionOptions.GracePeriod

        /// RTO7b: Serials of operations that have been applied locally upon ACK but whose echoed OBJECT message has not yet been received.
        internal var appliedOnAckSerials: Set<String> = [] // RTO7b1

        /// The `siteCode` from the latest `ConnectionDetails`, pushed via ``nosync_setSiteCode``.
        internal var siteCode: String?

        /// The outcome passed to a `nosync_publishAndApply` sync waiter closure.
        enum PublishAndApplySyncWaiterOutcome: Sendable {
            case synced
            case channelStateFailed(
                state: _AblyPluginSupportPrivate.RealtimeChannelState,
                reason: ARTErrorInfo?,
            )
        }

        /// RTO20e/RTO20e1: Pending `nosync_publishAndApply` calls waiting for sync to complete.
        /// Each closure captures the synthetic messages to apply and the user callback.
        /// On sync completion, closures are called with `.synced`.
        /// On channel state change to detached/suspended/failed, closures are called with `.channelStateFailed`.
        ///
        /// Waiters receive `inout MutableState` so they can apply synthetic messages and pass
        /// mutable state access through to their callback, avoiding re-entrant mutex acquisition.
        internal var publishAndApplySyncWaiters: [(inout MutableState, PublishAndApplySyncWaiterOutcome) -> Void] = []

        /// The RTO17 sync state. Also stores the sync sequence data.
        internal var state = State.initialized

        /// Has the same cases as `ObjectsSyncState` but with associated data to store the sync sequence data and represent the constraint that you only have a sync sequence if you're SYNCING.
        internal enum State {
            case initialized
            case syncing(AssociatedData.Syncing)
            case synced

            /// Note: We follow the same pattern as used in the WIP ably-swift: a state's associated data is a class instance and the convention is that to update the associated data for the current state you mutate the existing instance instead of creating a new one.
            enum AssociatedData {
                class Syncing {
                    /// `OBJECT` ProtocolMessages that were received whilst SYNCING, to be applied once the sync sequence is complete, per RTO7a.
                    var bufferedObjectOperations: [InboundObjectMessage]

                    /// Note that we only ever populate this during a multi-`ProtocolMessage` sync sequence. It is not used in the RTO4b or RTO5a5 cases where the sync data is entirely contained within a single ProtocolMessage, because an individual ProtocolMessage is processed atomically and so no other operations that might wish to query this property can occur concurrently with the handling of these cases.
                    ///
                    /// It is optional because there are times that we transition to SYNCING even when the sync data is contained in a single ProtocolMessage.
                    var syncSequence: SyncSequence?

                    init(bufferedObjectOperations: [InboundObjectMessage], syncSequence: SyncSequence?) {
                        self.bufferedObjectOperations = bufferedObjectOperations
                        self.syncSequence = syncSequence
                    }
                }
            }

            var toObjectsSyncState: ObjectsSyncState {
                switch self {
                case .initialized:
                    .initialized
                case .syncing:
                    .syncing
                case .synced:
                    .synced
                }
            }
        }

        mutating func transition(
            to newState: State,
            userCallbackQueue: DispatchQueue,
        ) {
            guard newState.toObjectsSyncState != state.toObjectsSyncState else {
                preconditionFailure("Cannot transition to the current state")
            }
            state = newState
            guard let event = newState.toObjectsSyncState.toEvent else {
                return
            }
            // RTO17b
            emitObjectsEvent(event, on: userCallbackQueue)
        }

        internal mutating func nosync_onChannelAttached(
            hasObjects: Bool,
            logger: Logger,
            userCallbackQueue: DispatchQueue,
        ) {
            logger.log("onChannelAttached(hasObjects: \(hasObjects)", level: .debug)

            onChannelAttachedHasObjects = hasObjects

            // We will subsequently transition to .synced either by the completion of the RTO4a OBJECT_SYNC, or by the RTO4b no-HAS_OBJECTS case below
            if state.toObjectsSyncState != .syncing {
                // RTO4c
                transition(to: .syncing(.init(bufferedObjectOperations: [], syncSequence: nil)), userCallbackQueue: userCallbackQueue)
            }

            // We only care about the case where HAS_OBJECTS is not set (RTO4b); if it is set then we're going to shortly receive an OBJECT_SYNC instead (RTO4a)
            guard !hasObjects else {
                return
            }

            // RTO4b1, RTO4b2: Reset the ObjectsPool to have a single empty root object
            objectsPool.nosync_reset()

            // I have, for now, not directly implemented the "perform the actions for object sync completion" of RTO4b4 since my implementation doesn't quite match the model given there; here you only have a SyncObjectsPool if you have an OBJECT_SYNC in progress, which you might not have upon receiving an ATTACHED. Instead I've just implemented what seem like the relevant side effects. Can revisit this if "the actions for object sync completion" get more complex.

            // RTO4b3, RTO4b4, RTO4b5, RTO5c3, RTO5c4, RTO5c5, RTO5c9, RTO5c8
            appliedOnAckSerials.removeAll()
            transition(to: .synced, userCallbackQueue: userCallbackQueue)

            // Resume any publishAndApply waiters now that sync is complete
            nosync_drainPublishAndApplySyncWaiters(
                outcome: .synced,
            )
        }

        /// Implements the `OBJECT_SYNC` handling of RTO5.
        internal mutating func nosync_handleObjectSyncProtocolMessage(
            objectMessages: [InboundObjectMessage],
            protocolMessageChannelSerial: String?,
            logger: Logger,
            internalQueue: DispatchQueue,
            userCallbackQueue: DispatchQueue,
            clock: SimpleClock,
            receivedObjectSyncProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation,
        ) {
            logger.log("handleObjectSyncProtocolMessage(objectMessages: \(LoggingUtilities.formatObjectMessagesForLogging(objectMessages)), protocolMessageChannelSerial: \(String(describing: protocolMessageChannelSerial)))", level: .debug)

            receivedObjectSyncProtocolMessagesContinuation.yield(objectMessages)

            let syncCursor: SyncCursor?
            if let protocolMessageChannelSerial {
                do {
                    // RTO5a
                    syncCursor = try SyncCursor(channelSerial: protocolMessageChannelSerial)
                } catch {
                    logger.log("Failed to parse sync cursor: \(error)", level: .error)
                    return
                }
            } else {
                syncCursor = nil
            }

            if case let .syncing(syncingData) = state {
                // Figure out whether to continue any existing sync sequence or start a new one
                let isNewSyncSequence = syncCursor == nil || syncingData.syncSequence?.id != syncCursor?.sequenceID
                if isNewSyncSequence {
                    // RTO5a2a, RTO5a2b: new sequence started, discard previous. Else we continue the existing sequence per RTO5a3
                    syncingData.syncSequence = nil
                    syncingData.bufferedObjectOperations = []
                }
            }

            let syncObjectsPoolEntries = objectMessages.compactMap { objectMessage in
                if let object = objectMessage.object {
                    SyncObjectsPoolEntry(state: object, objectMessageSerialTimestamp: objectMessage.serialTimestamp)
                } else {
                    nil
                }
            }

            // If populated, this contains a full set of sync data for the channel, and should be applied to the ObjectsPool.
            let completedSyncObjectsPool: [SyncObjectsPoolEntry]?
            // The SyncSequence, if any, to store in the SYNCING state that results from this OBJECT_SYNC.
            let syncSequenceForSyncingState: SyncSequence?

            if let syncCursor {
                let syncSequenceToContinue: SyncSequence? = if case let .syncing(syncingData) = state {
                    syncingData.syncSequence
                } else {
                    nil
                }
                var updatedSyncSequence = syncSequenceToContinue ?? .init(id: syncCursor.sequenceID, syncObjectsPool: [])
                // RTO5b
                updatedSyncSequence.syncObjectsPool.append(contentsOf: syncObjectsPoolEntries)
                syncSequenceForSyncingState = updatedSyncSequence

                completedSyncObjectsPool = syncCursor.isEndOfSequence ? updatedSyncSequence.syncObjectsPool : nil
            } else {
                // RTO5a5: The sync data is contained entirely within this single OBJECT_SYNC
                completedSyncObjectsPool = syncObjectsPoolEntries
                syncSequenceForSyncingState = nil
            }

            if case let .syncing(syncingData) = state {
                syncingData.syncSequence = syncSequenceForSyncingState
            } else {
                // RTO5e
                transition(to: .syncing(.init(bufferedObjectOperations: [], syncSequence: syncSequenceForSyncingState)), userCallbackQueue: userCallbackQueue)
            }

            if let completedSyncObjectsPool {
                // RTO5c
                objectsPool.nosync_applySyncObjectsPool(
                    completedSyncObjectsPool,
                    logger: logger,
                    internalQueue: internalQueue,
                    userCallbackQueue: userCallbackQueue,
                    clock: clock,
                )

                // RTO5c6
                guard case let .syncing(syncingData) = state else {
                    // We put ourselves into SYNCING above
                    preconditionFailure()
                }
                let bufferedObjectOperations = syncingData.bufferedObjectOperations
                if !bufferedObjectOperations.isEmpty {
                    logger.log("Applying \(bufferedObjectOperations.count) buffered OBJECT ObjectMessages", level: .debug)
                    for objectMessage in bufferedObjectOperations {
                        // RTO5c6
                        nosync_applyObjectProtocolMessageObjectMessage(
                            objectMessage,
                            source: .channel,
                            logger: logger,
                            internalQueue: internalQueue,
                            userCallbackQueue: userCallbackQueue,
                            clock: clock,
                        )
                    }
                }

                // RTO5c9: Clear appliedOnAckSerials after sync
                appliedOnAckSerials.removeAll()

                // RTO5c3, RTO5c4, RTO5c5, RTO5c8
                transition(to: .synced, userCallbackQueue: userCallbackQueue)

                // Resume any publishAndApply waiters now that sync is complete
                nosync_drainPublishAndApplySyncWaiters(
                    outcome: .synced,
                )
            }
        }

        /// Implements the `OBJECT` handling of RTO8.
        internal mutating func nosync_handleObjectProtocolMessage(
            objectMessages: [InboundObjectMessage],
            logger: Logger,
            internalQueue: DispatchQueue,
            userCallbackQueue: DispatchQueue,
            clock: SimpleClock,
            receivedObjectProtocolMessagesContinuation: AsyncStream<[InboundObjectMessage]>.Continuation,
        ) {
            receivedObjectProtocolMessagesContinuation.yield(objectMessages)

            logger.log("handleObjectProtocolMessage(objectMessages: \(LoggingUtilities.formatObjectMessagesForLogging(objectMessages)))", level: .debug)

            if case let .syncing(syncingData) = state {
                // RTO8a: Buffer the OBJECT message, to be handled once the sync completes
                // Note that RTO8a says to buffer if "not SYNCED" (i.e. it includes the INITIALIZED state). But, "if SYNCING" is an equivalent check since we will only receive operations once attached, and we become SYNCING upon receipt of ATTACHED
                logger.log("Buffering OBJECT message due to in-progress sync", level: .debug)
                syncingData.bufferedObjectOperations.append(contentsOf: objectMessages)
            } else {
                // RTO8b: Handle the OBJECT message immediately
                for objectMessage in objectMessages {
                    nosync_applyObjectProtocolMessageObjectMessage(
                        objectMessage,
                        source: .channel,
                        logger: logger,
                        internalQueue: internalQueue,
                        userCallbackQueue: userCallbackQueue,
                        clock: clock,
                    )
                }
            }
        }

        /// Implements the `OBJECT` application of RTO9.
        internal mutating func nosync_applyObjectProtocolMessageObjectMessage(
            _ objectMessage: InboundObjectMessage,
            source: ObjectsOperationSource,
            logger: Logger,
            internalQueue: DispatchQueue,
            userCallbackQueue: DispatchQueue,
            clock: SimpleClock,
        ) {
            guard let operation = objectMessage.operation else {
                // RTO9a1
                logger.log("Unsupported OBJECT message received (no operation); \(objectMessage)", level: .warn)
                return
            }

            // RTO9a3: Skip if already applied on ACK
            if let serial = objectMessage.serial, appliedOnAckSerials.contains(serial) {
                logger.log("Skipping OBJECT message: already applied on ACK; serial=\(serial)", level: .debug)
                appliedOnAckSerials.remove(serial)
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
                    internalQueue: internalQueue,
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
                    let applied = entry.nosync_apply(
                        operation,
                        source: source,
                        objectMessageSerial: objectMessage.serial,
                        objectMessageSiteCode: objectMessage.siteCode,
                        objectMessageSerialTimestamp: objectMessage.serialTimestamp,
                        objectsPool: &objectsPool,
                    )

                    // RTO9a2a4
                    if source == .local, applied, let serial = objectMessage.serial {
                        appliedOnAckSerials.insert(serial)
                    }
                }
            case let .unknown(rawValue):
                // RTO9a2b
                logger.log("Unsupported OBJECT operation action \(rawValue) received", level: .warn)
                return
            }
        }

        /// Drains all `nosync_publishAndApply` sync waiter closures, invoking each with the given outcome.
        ///
        /// Each waiter receives `&self` so it can apply synthetic messages and pass mutable state
        /// access through to its callback without re-acquiring the mutex.
        internal mutating func nosync_drainPublishAndApplySyncWaiters(
            outcome: PublishAndApplySyncWaiterOutcome,
        ) {
            let waiters = publishAndApplySyncWaiters
            publishAndApplySyncWaiters.removeAll()
            for waiter in waiters {
                waiter(&self, outcome)
            }
        }

        /// RTO20e1: Called when the channel enters detached, suspended, or failed state.
        /// Drains all waiting `nosync_publishAndApply` closures with a `.channelStateFailed` outcome.
        internal mutating func nosync_onChannelStateChanged(
            toState state: _AblyPluginSupportPrivate.RealtimeChannelState,
            reason: ARTErrorInfo?,
            logger: Logger,
        ) {
            switch state {
            case .detached, .suspended, .failed:
                guard !publishAndApplySyncWaiters.isEmpty else {
                    return
                }

                logger.log("Channel entered \(state) state; rejecting \(publishAndApplySyncWaiters.count) publishAndApply waiter(s)", level: .debug)

                // RTO20e1
                nosync_drainPublishAndApplySyncWaiters(
                    outcome: .channelStateFailed(state: state, reason: reason),
                )
            default:
                break
            }
        }

        internal typealias UpdateMutableState = @Sendable (_ action: (inout Self) -> Void) -> Void

        @discardableResult
        internal mutating func on(event: ObjectsEvent, callback: @escaping ObjectsEventCallback, updateSelfLater: @escaping UpdateMutableState) -> any OnObjectsEventResponse {
            let updateSubscriptionStorage: SubscriptionStorage<ObjectsEvent, Void>.UpdateSubscriptionStorage = { action in
                updateSelfLater { mutableState in
                    action(&mutableState.objectsEventSubscriptionStorage)
                }
            }

            let subscription = objectsEventSubscriptionStorage.subscribe(
                listener: { _, subscriptionInCallback in
                    let response = ObjectsEventResponse(subscription: subscriptionInCallback)
                    callback(response)
                },
                eventName: event,
                updateSelfLater: updateSubscriptionStorage,
            )

            return ObjectsEventResponse(subscription: subscription)
        }

        /// Adds a subscriber to the ``internalObjectsEventSubscriptionStorage`` (i.e. unaffected by `offAll()`).
        @discardableResult
        internal mutating func onInternal(event: ObjectsEvent, callback: @escaping ObjectsEventCallback, updateSelfLater: @escaping UpdateMutableState) -> any OnObjectsEventResponse {
            // TODO: Looking at this again later the whole process for adding a subscriber is really verbose and boilerplate-y, and I think the unfortunate result of me trying to be clever at some point; revisit in https://github.com/ably/ably-liveobjects-swift-plugin/issues/102. Also as things stand we end up not being able to use this method because we run into Swift exclusivity violations when we try to unsubscribe from within a listener that's invoked when the mutable state mutex is already held (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/120), so e.g. the RTO20 wait-for-synced can't use this mechanism, which it should be able to.
            let updateSubscriptionStorage: SubscriptionStorage<ObjectsEvent, Void>.UpdateSubscriptionStorage = { action in
                updateSelfLater { mutableState in
                    action(&mutableState.internalObjectsEventSubscriptionStorage)
                }
            }

            let subscription = internalObjectsEventSubscriptionStorage.subscribe(
                listener: { _, subscriptionInCallback in
                    let response = ObjectsEventResponse(subscription: subscriptionInCallback)
                    callback(response)
                },
                eventName: event,
                updateSelfLater: updateSubscriptionStorage,
            )

            return ObjectsEventResponse(subscription: subscription)
        }

        // RTO18f
        private struct ObjectsEventResponse: OnObjectsEventResponse {
            let subscription: any SubscribeResponse

            func off() {
                subscription.unsubscribe()
            }
        }

        internal mutating func offAll() {
            objectsEventSubscriptionStorage.unsubscribeAll()
        }

        internal func emitObjectsEvent(_ event: ObjectsEvent, on queue: DispatchQueue) {
            objectsEventSubscriptionStorage.emit(eventName: event, on: queue)
            internalObjectsEventSubscriptionStorage.emit(eventName: event, on: queue)
        }
    }
}
