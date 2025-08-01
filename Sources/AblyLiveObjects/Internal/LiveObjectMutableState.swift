internal import AblyPlugin

/// This is the equivalent of the `LiveObject` abstract class described in RTLO.
///
/// ``InternalDefaultLiveCounter`` and ``InternalDefaultLiveMap`` include it by composition.
internal struct LiveObjectMutableState<Update: Sendable> {
    // RTLO3a
    internal var objectID: String
    // RTLO3b
    internal var siteTimeserials: [String: String] = [:]
    // RTLO3c
    internal var createOperationIsMerged = false

    /// Internal bookkeeping for subscriptions.
    private var subscriptionsByID: [Subscription.ID: Subscription] = [:]

    internal init(
        objectID: String,
        testsOnly_siteTimeserials siteTimeserials: [String: String]? = nil,
    ) {
        self.objectID = objectID
        self.siteTimeserials = siteTimeserials ?? [:]
    }

    /// Represents parameters of an operation that `canApplyOperation` has decided can be applied to a `LiveObject`.
    ///
    /// The key thing is that it offers a non-nil `serial` and `siteCode`, which will be needed when subsequently performing the operation.
    internal struct ApplicableOperation: Equatable {
        internal let objectMessageSerial: String
        internal let objectMessageSiteCode: String
    }

    /// Indicates whether an operation described by an `ObjectMessage` should be applied or discarded, per RTLO4a.
    ///
    /// Instead of returning a `Bool`, in the case where the operation can be applied it returns a non-nil `ApplicableOperation` (whose non-nil `serial` and `siteCode` will be needed as part of subsequently performing this operation).
    internal func canApplyOperation(objectMessageSerial: String?, objectMessageSiteCode: String?, logger: Logger) -> ApplicableOperation? {
        // RTLO4a3: Both ObjectMessage.serial and ObjectMessage.siteCode must be non-empty strings
        guard let serial = objectMessageSerial, !serial.isEmpty,
              let siteCode = objectMessageSiteCode, !siteCode.isEmpty
        else {
            // RTLO4a3: Otherwise, log a warning that the object operation message has invalid serial values
            logger.log("Object operation message has invalid serial values: serial=\(objectMessageSerial ?? "nil"), siteCode=\(objectMessageSiteCode ?? "nil")", level: .warn)
            return nil
        }

        // RTLO4a4: Get the siteSerial value stored for this LiveObject in the siteTimeserials map using the key ObjectMessage.siteCode
        let siteSerial = siteTimeserials[siteCode]

        // RTLO4a5: If the siteSerial for this LiveObject is null or an empty string, return true
        guard let siteSerial, !siteSerial.isEmpty else {
            return ApplicableOperation(objectMessageSerial: serial, objectMessageSiteCode: siteCode)
        }

        // RTLO4a6: If the siteSerial for this LiveObject is not an empty string, return true if ObjectMessage.serial is greater than siteSerial when compared lexicographically
        if serial > siteSerial {
            return ApplicableOperation(objectMessageSerial: serial, objectMessageSiteCode: siteCode)
        }

        return nil
    }

    // MARK: - Subscriptions

    private struct Subscription: Identifiable {
        var id = UUID()
        var listener: LiveObjectUpdateCallback<Update>
        var updateLiveObject: UpdateLiveObject
    }

    /// A function that allows a `LiveObjectMutableState` to later perform mutations to an externally-held copy of itself. This is used to allow a `SubscribeResponse` to unsubscribe.
    ///
    /// Accepts an action, which, if called, should be called with an `inout` reference to the externally-held copy. The function is not required to call this action (for example, if the function holds a weak reference which is now `nil`).
    ///
    /// Note that the `LiveObjectMutableState` will store a copy of this function and thus this function should be careful not to introduce a strong reference cycle.
    internal typealias UpdateLiveObject = @Sendable (_ action: (inout LiveObjectMutableState<Update>) -> Void) -> Void

    private struct SubscribeResponse: AblyLiveObjects.SubscribeResponse {
        var subscriptionID: Subscription.ID
        var updateLiveObject: UpdateLiveObject

        func unsubscribe() {
            updateLiveObject { liveObject in
                liveObject.unsubscribe(subscriptionID: subscriptionID)
            }
        }
    }

    @discardableResult
    internal mutating func subscribe(listener: @escaping LiveObjectUpdateCallback<Update>, coreSDK: CoreSDK, updateSelfLater: @escaping UpdateLiveObject) throws(ARTErrorInfo) -> any AblyLiveObjects.SubscribeResponse {
        // RTLO4b2
        try coreSDK.validateChannelState(notIn: [.detached, .failed], operationDescription: "subscribe")

        let subscription = Subscription(listener: listener, updateLiveObject: updateSelfLater)
        subscriptionsByID[subscription.id] = subscription
        return SubscribeResponse(subscriptionID: subscription.id, updateLiveObject: updateSelfLater)
    }

    internal mutating func unsubscribeAll() {
        subscriptionsByID.removeAll()
    }

    private mutating func unsubscribe(subscriptionID: Subscription.ID) {
        // RTLO4d
        subscriptionsByID.removeValue(forKey: subscriptionID)
    }

    internal func emit(_ update: LiveObjectUpdate<Update>, on queue: DispatchQueue) {
        switch update {
        case .noop:
            // RTLO4b4c1
            return
        case let .update(update):
            // RTLO4b4c2
            for subscription in subscriptionsByID.values {
                queue.async {
                    let response = SubscribeResponse(subscriptionID: subscription.id, updateLiveObject: subscription.updateLiveObject)
                    subscription.listener(update, response)
                }
            }
        }
    }
}
