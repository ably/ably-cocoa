import Foundation

/// Handles subscription bookkeeping, providing methods for subscribing and emitting events.
internal struct SubscriptionStorage<Update: Sendable> {
    /// Internal bookkeeping for subscriptions.
    private var subscriptionsByID: [Subscription.ID: Subscription] = [:]

    // MARK: - Subscriptions

    private struct Subscription: Identifiable {
        var id = UUID()
        var listener: LiveObjectUpdateCallback<Update>
        var updateSubscriptionStorage: UpdateSubscriptionStorage
    }

    /// A function that allows a `SubscriptionStorage` to later perform mutations to an externally-held copy of itself. This is used to allow a `SubscribeResponse` to unsubscribe.
    ///
    /// Accepts an action, which, if called, should be called with an `inout` reference to the externally-held copy. The function is not required to call this action (for example, if the function holds a weak reference which is now `nil`).
    ///
    /// Note that the `SubscriptionStorage` will store a copy of this function and thus this function should be careful not to introduce a strong reference cycle.
    internal typealias UpdateSubscriptionStorage = @Sendable (_ action: (inout Self) -> Void) -> Void

    private struct SubscribeResponse: AblyLiveObjects.SubscribeResponse {
        var subscriptionID: Subscription.ID
        var updateSubscriptionStorage: UpdateSubscriptionStorage

        func unsubscribe() {
            updateSubscriptionStorage { subscriptionStorage in
                subscriptionStorage.unsubscribe(subscriptionID: subscriptionID)
            }
        }
    }

    @discardableResult
    internal mutating func subscribe(listener: @escaping LiveObjectUpdateCallback<Update>, updateSelfLater: @escaping UpdateSubscriptionStorage) -> any AblyLiveObjects.SubscribeResponse {
        let subscription = Subscription(listener: listener, updateSubscriptionStorage: updateSelfLater)
        subscriptionsByID[subscription.id] = subscription
        return SubscribeResponse(subscriptionID: subscription.id, updateSubscriptionStorage: updateSelfLater)
    }

    internal mutating func unsubscribeAll() {
        subscriptionsByID.removeAll()
    }

    private mutating func unsubscribe(subscriptionID: Subscription.ID) {
        subscriptionsByID.removeValue(forKey: subscriptionID)
    }

    internal func emit(_ update: Update, on queue: DispatchQueue) {
        for subscription in subscriptionsByID.values {
            queue.async {
                let response = SubscribeResponse(subscriptionID: subscription.id, updateSubscriptionStorage: subscription.updateSubscriptionStorage)
                subscription.listener(update, response)
            }
        }
    }
}
