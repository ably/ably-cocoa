import Ably
internal import AblyPlugin
import Foundation

/// This provides the implementation behind ``PublicDefaultLiveCounter``, via internal versions of the ``LiveCounter`` API.
internal final class InternalDefaultLiveCounter: Sendable {
    // Used for synchronizing access to all of this instance's mutable state. This is a temporary solution just to allow us to implement `Sendable`, and we'll revisit it in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3.
    private let mutex = NSLock()

    private nonisolated(unsafe) var mutableState: MutableState

    internal var testsOnly_siteTimeserials: [String: String] {
        mutex.withLock {
            mutableState.liveObjectMutableState.siteTimeserials
        }
    }

    internal var testsOnly_createOperationIsMerged: Bool {
        mutex.withLock {
            mutableState.liveObjectMutableState.createOperationIsMerged
        }
    }

    private let logger: AblyPlugin.Logger
    private let userCallbackQueue: DispatchQueue
    private let clock: SimpleClock

    // MARK: - Initialization

    internal convenience init(
        testsOnly_data data: Double,
        objectID: String,
        logger: AblyPlugin.Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock
    ) {
        self.init(data: data, objectID: objectID, logger: logger, userCallbackQueue: userCallbackQueue, clock: clock)
    }

    private init(
        data: Double,
        objectID: String,
        logger: AblyPlugin.Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock
    ) {
        mutableState = .init(liveObjectMutableState: .init(objectID: objectID), data: data)
        self.logger = logger
        self.userCallbackQueue = userCallbackQueue
        self.clock = clock
    }

    /// Creates a "zero-value LiveCounter", per RTLC4.
    ///
    /// - Parameters:
    ///   - objectID: The value for the "private objectId field" of RTO5c1b1a.
    internal static func createZeroValued(
        objectID: String,
        logger: AblyPlugin.Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
    ) -> Self {
        .init(
            data: 0,
            objectID: objectID,
            logger: logger,
            userCallbackQueue: userCallbackQueue,
            clock: clock,
        )
    }

    // MARK: - Data access

    internal var objectID: String {
        mutex.withLock {
            mutableState.liveObjectMutableState.objectID
        }
    }

    // MARK: - Internal methods that back LiveCounter conformance

    internal func value(coreSDK: CoreSDK) throws(ARTErrorInfo) -> Double {
        // RTLC5b: If the channel is in the DETACHED or FAILED state, the library should indicate an error with code 90001
        let currentChannelState = coreSDK.channelState
        if currentChannelState == .detached || currentChannelState == .failed {
            throw LiveObjectsError.objectsOperationFailedInvalidChannelState(
                operationDescription: "LiveCounter.value",
                channelState: currentChannelState,
            )
            .toARTErrorInfo()
        }

        return mutex.withLock {
            // RTLC5c
            mutableState.data
        }
    }

    internal func increment(amount _: Double) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    internal func decrement(amount _: Double) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    @discardableResult
    internal func subscribe(listener: @escaping LiveObjectUpdateCallback<DefaultLiveCounterUpdate>, coreSDK: CoreSDK) throws(ARTErrorInfo) -> any SubscribeResponse {
        try mutex.ablyLiveObjects_withLockWithTypedThrow { () throws(ARTErrorInfo) in
            // swiftlint:disable:next trailing_closure
            try mutableState.liveObjectMutableState.subscribe(listener: listener, coreSDK: coreSDK, updateSelfLater: { [weak self] action in
                guard let self else {
                    return
                }

                mutex.withLock {
                    action(&mutableState.liveObjectMutableState)
                }
            })
        }
    }

    internal func unsubscribeAll() {
        mutex.withLock {
            mutableState.liveObjectMutableState.unsubscribeAll()
        }
    }

    @discardableResult
    internal func on(event _: LiveObjectLifecycleEvent, callback _: @escaping LiveObjectLifecycleEventCallback) -> any OnLiveObjectLifecycleEventResponse {
        notYetImplemented()
    }

    internal func offAll() {
        notYetImplemented()
    }

    // MARK: - Emitting update from external sources

    /// Emit an event from this `LiveCounter`.
    ///
    /// This is used to instruct this counter to emit updates during an `OBJECT_SYNC`.
    internal func emit(_ update: LiveObjectUpdate<DefaultLiveCounterUpdate>) {
        mutex.withLock {
            mutableState.liveObjectMutableState.emit(update, on: userCallbackQueue)
        }
    }

    // MARK: - Data manipulation

    /// Replaces the internal data of this counter with the provided ObjectState, per RTLC6.
    ///
    /// - Parameters:
    ///   - objectMessageSerialTimestamp: The `serialTimestamp` of the containing `ObjectMessage`. Used if we need to tombstone this counter.
    internal func replaceData(
        using state: ObjectState,
        objectMessageSerialTimestamp: Date?,
    ) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
        mutex.withLock {
            mutableState.replaceData(using: state, objectMessageSerialTimestamp: objectMessageSerialTimestamp)
        }
    }

    /// Merges the initial value from an ObjectOperation into this LiveCounter, per RTLC10.
    internal func mergeInitialValue(from operation: ObjectOperation) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
        mutex.withLock {
            mutableState.mergeInitialValue(from: operation)
        }
    }

    /// Test-only method to apply a COUNTER_CREATE operation, per RTLC8.
    internal func testsOnly_applyCounterCreateOperation(_ operation: ObjectOperation) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
        mutex.withLock {
            mutableState.applyCounterCreateOperation(operation, logger: logger)
        }
    }

    /// Test-only method to apply a COUNTER_INC operation, per RTLC9.
    internal func testsOnly_applyCounterIncOperation(_ operation: WireObjectsCounterOp?) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
        mutex.withLock {
            mutableState.applyCounterIncOperation(operation)
        }
    }

    /// Attempts to apply an operation from an inbound `ObjectMessage`, per RTLC7.
    internal func apply(
        _ operation: ObjectOperation,
        objectMessageSerial: String?,
        objectMessageSiteCode: String?,
        objectMessageSerialTimestamp: Date?,
        objectsPool: inout ObjectsPool,
    ) {
        mutex.withLock {
            mutableState.apply(
                operation,
                objectMessageSerial: objectMessageSerial,
                objectMessageSiteCode: objectMessageSiteCode,
                objectMessageSerialTimestamp: objectMessageSerialTimestamp,
                objectsPool: &objectsPool,
                logger: logger,
                userCallbackQueue: userCallbackQueue,
            )
        }
    }

    // MARK: - Mutable state and the operations that affect it

    private struct MutableState: InternalLiveObject {
        /// The mutable state common to all LiveObjects.
        internal var liveObjectMutableState: LiveObjectMutableState<DefaultLiveCounterUpdate>

        /// The internal data that this map holds, per RTLC3.
        internal var data: Double

        /// Replaces the internal data of this counter with the provided ObjectState, per RTLC6.
        ///
        /// - Parameters:
        ///   - objectMessageSerialTimestamp: The `serialTimestamp` of the containing `ObjectMessage`. Used if we need to tombstone this counter.
        internal mutating func replaceData(
            using state: ObjectState,
            objectMessageSerialTimestamp: Date?,
        ) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
            // RTLC6a: Replace the private siteTimeserials with the value from ObjectState.siteTimeserials
            liveObjectMutableState.siteTimeserials = state.siteTimeserials

            // RTLC6b: Set the private flag createOperationIsMerged to false
            liveObjectMutableState.createOperationIsMerged = false

            // RTLC6c: Set data to the value of ObjectState.counter.count, or to 0 if it does not exist
            data = state.counter?.count?.doubleValue ?? 0

            // RTLC6d: If ObjectState.createOp is present, merge the initial value into the LiveCounter as described in RTLC10
            return if let createOp = state.createOp {
                mergeInitialValue(from: createOp)
            } else {
                // TODO: I assume this is what to do, clarify in https://github.com/ably/specification/pull/346/files#r2201363446
                .noop
            }
        }

        /// Merges the initial value from an ObjectOperation into this LiveCounter, per RTLC10.
        internal mutating func mergeInitialValue(from operation: ObjectOperation) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
            let update: LiveObjectUpdate<DefaultLiveCounterUpdate>

            // RTLC10a: Add ObjectOperation.counter.count to data, if it exists
            if let operationCount = operation.counter?.count?.doubleValue {
                data += operationCount
                // RTLC10c
                update = .update(DefaultLiveCounterUpdate(amount: operationCount))
            } else {
                // RTLC10d
                update = .noop
            }

            // RTLC10b: Set the private flag createOperationIsMerged to true
            liveObjectMutableState.createOperationIsMerged = true

            return update
        }

        /// Attempts to apply an operation from an inbound `ObjectMessage`, per RTLC7.
        internal mutating func apply(
            _ operation: ObjectOperation,
            objectMessageSerial: String?,
            objectMessageSiteCode: String?,
            objectMessageSerialTimestamp: Date?,
            objectsPool: inout ObjectsPool,
            logger: Logger,
            userCallbackQueue: DispatchQueue,
        ) {
            guard let applicableOperation = liveObjectMutableState.canApplyOperation(objectMessageSerial: objectMessageSerial, objectMessageSiteCode: objectMessageSiteCode, logger: logger) else {
                // RTLC7b
                logger.log("Operation \(operation) (serial: \(String(describing: objectMessageSerial)), siteCode: \(String(describing: objectMessageSiteCode))) should not be applied; discarding", level: .debug)
                return
            }

            // RTLC7c
            liveObjectMutableState.siteTimeserials[applicableOperation.objectMessageSiteCode] = applicableOperation.objectMessageSerial

            switch operation.action {
            case .known(.counterCreate):
                // RTLC7d1
                let update = applyCounterCreateOperation(
                    operation,
                    logger: logger,
                )
                // RTLC7d1a
                liveObjectMutableState.emit(update, on: userCallbackQueue)
            case .known(.counterInc):
                // RTLC7d2
                let update = applyCounterIncOperation(operation.counterOp)
                // RTLC7d2a
                liveObjectMutableState.emit(update, on: userCallbackQueue)
            default:
                // RTLC7d3
                logger.log("Operation \(operation) has unsupported action for LiveCounter; discarding", level: .warn)
            }
        }

        /// Applies a `COUNTER_CREATE` operation, per RTLC8.
        internal mutating func applyCounterCreateOperation(
            _ operation: ObjectOperation,
            logger: Logger,
        ) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
            if liveObjectMutableState.createOperationIsMerged {
                // RTLC8b
                logger.log("Not applying COUNTER_CREATE because a COUNTER_CREATE has already been applied", level: .warn)
                return .noop
            }

            // RTLC8c, RTLC8e
            return mergeInitialValue(from: operation)
        }

        /// Applies a `COUNTER_INC` operation, per RTLC9.
        internal mutating func applyCounterIncOperation(_ operation: WireObjectsCounterOp?) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
            guard let operation else {
                // RTL9e
                return .noop
            }

            // RTLC9b, RTLC9d
            let amount = operation.amount.doubleValue
            data += amount
            return .update(DefaultLiveCounterUpdate(amount: amount))
        }
    }
}
