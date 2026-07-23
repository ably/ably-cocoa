import Ably

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultSubscription: Subscription, Sendable {
    internal func unsubscribe() {
        notImplemented()
    }
}
