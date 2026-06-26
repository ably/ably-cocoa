import Ably

internal final class DefaultLiveCounterPathObject: DefaultPathObject, LiveCounterPathObject, @unchecked Sendable {
    func value() throws(ARTErrorInfo) -> Double? {
        notImplemented()
    }

    func increment(amount: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }

    func decrement(amount: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }
}
