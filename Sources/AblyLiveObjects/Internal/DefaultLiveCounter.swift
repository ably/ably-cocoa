import Ably
internal import AblyPlugin
import Foundation

/// Our default implementation of ``LiveCounter``.
internal final class DefaultLiveCounter: LiveCounter {
    // Used for synchronizing access to all of this instance's mutable state. This is a temporary solution just to allow us to implement `Sendable`, and we'll revisit it in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3.
    private let mutex = NSLock()

    private nonisolated(unsafe) var mutableState: MutableState

    internal var testsOnly_siteTimeserials: [String: String] {
        mutex.withLock {
            mutableState.liveObject.siteTimeserials
        }
    }

    internal var testsOnly_createOperationIsMerged: Bool {
        mutex.withLock {
            mutableState.liveObject.createOperationIsMerged
        }
    }

    internal var testsOnly_objectID: String {
        mutex.withLock {
            mutableState.liveObject.objectID
        }
    }

    private let coreSDK: CoreSDK
    private let logger: AblyPlugin.Logger

    // MARK: - Initialization

    internal convenience init(
        testsOnly_data data: Double,
        objectID: String,
        coreSDK: CoreSDK,
        logger: AblyPlugin.Logger
    ) {
        self.init(data: data, objectID: objectID, coreSDK: coreSDK, logger: logger)
    }

    private init(
        data: Double,
        objectID: String,
        coreSDK: CoreSDK,
        logger: AblyPlugin.Logger
    ) {
        mutableState = .init(liveObject: .init(objectID: objectID), data: data)
        self.coreSDK = coreSDK
        self.logger = logger
    }

    /// Creates a "zero-value LiveCounter", per RTLC4.
    ///
    /// - Parameters:
    ///   - objectID: The value for the "private objectId field" of RTO5c1b1a.
    internal static func createZeroValued(
        objectID: String,
        coreSDK: CoreSDK,
        logger: AblyPlugin.Logger,
    ) -> Self {
        .init(
            data: 0,
            objectID: objectID,
            coreSDK: coreSDK,
            logger: logger,
        )
    }

    // MARK: - LiveCounter conformance

    internal var value: Double {
        get throws(ARTErrorInfo) {
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
    }

    internal func increment(amount _: Double) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    internal func decrement(amount _: Double) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    internal func subscribe(listener _: (sending any LiveCounterUpdate) -> Void) -> any SubscribeResponse {
        notYetImplemented()
    }

    internal func unsubscribeAll() {
        notYetImplemented()
    }

    internal func on(event _: LiveObjectLifecycleEvent, callback _: () -> Void) -> any OnLiveObjectLifecycleEventResponse {
        notYetImplemented()
    }

    internal func offAll() {
        notYetImplemented()
    }

    // MARK: - Data manipulation

    /// Replaces the internal data of this counter with the provided ObjectState, per RTLC6.
    internal func replaceData(using state: ObjectState) {
        mutex.withLock {
            mutableState.replaceData(using: state)
        }
    }

    /// Test-only method to merge initial value from an ObjectOperation, per RTLC10.
    internal func testsOnly_mergeInitialValue(from operation: ObjectOperation) {
        mutex.withLock {
            mutableState.mergeInitialValue(from: operation)
        }
    }

    // MARK: - Mutable state and the operations that affect it

    private struct MutableState {
        /// The mutable state common to all LiveObjects.
        internal var liveObject: LiveObjectMutableState

        /// The internal data that this map holds, per RTLC3.
        internal var data: Double

        /// Replaces the internal data of this counter with the provided ObjectState, per RTLC6.
        internal mutating func replaceData(using state: ObjectState) {
            // RTLC6a: Replace the private siteTimeserials with the value from ObjectState.siteTimeserials
            liveObject.siteTimeserials = state.siteTimeserials

            // RTLC6b: Set the private flag createOperationIsMerged to false
            liveObject.createOperationIsMerged = false

            // RTLC6c: Set data to the value of ObjectState.counter.count, or to 0 if it does not exist
            data = state.counter?.count?.doubleValue ?? 0

            // RTLC6d: If ObjectState.createOp is present, merge the initial value into the LiveCounter as described in RTLC10
            if let createOp = state.createOp {
                mergeInitialValue(from: createOp)
            }
        }

        /// Merges the initial value from an ObjectOperation into this LiveCounter, per RTLC10.
        internal mutating func mergeInitialValue(from operation: ObjectOperation) {
            // RTLC10a: Add ObjectOperation.counter.count to data, if it exists
            if let operationCount = operation.counter?.count?.doubleValue {
                data += operationCount
            }
            // RTLC10b: Set the private flag createOperationIsMerged to true
            liveObject.createOperationIsMerged = true
        }
    }
}
