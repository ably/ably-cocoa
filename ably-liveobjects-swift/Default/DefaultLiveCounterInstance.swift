import Ably

internal final class DefaultLiveCounterInstance: DefaultInstance, LiveCounterInstance, @unchecked Sendable {
    var id: String {
        notImplemented()
    }

    func value() throws(ARTErrorInfo) -> Double? {
        notImplemented()
    }

    func increment(amount: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }

    func decrement(amount: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }

    @discardableResult
    func subscribe(listener: @escaping InstanceSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        notImplemented()
    }
}
