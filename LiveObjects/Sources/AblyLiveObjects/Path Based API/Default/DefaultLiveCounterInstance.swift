import Ably

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultLiveCounterInstance: LiveCounterInstance {
    internal var id: String {
        notImplemented()
    }

    internal var value: Double {
        get throws(ARTErrorInfo) {
            notImplemented()
        }
    }

    internal func increment(amount _: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }

    internal func decrement(amount _: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }

    @discardableResult
    internal func subscribe(listener _: @escaping InstanceSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        notImplemented()
    }

    internal func compactJson() throws(ARTErrorInfo) -> JSONValue {
        notImplemented()
    }
}
