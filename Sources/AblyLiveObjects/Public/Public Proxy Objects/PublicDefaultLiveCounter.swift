import Ably

/// Our default implementation of ``LiveCounter``.
///
/// This is largely a wrapper around ``InternalDefaultLiveCounter``.
internal final class PublicDefaultLiveCounter: LiveCounter {
    private let proxied: InternalDefaultLiveCounter
    internal var testsOnly_proxied: InternalDefaultLiveCounter {
        proxied
    }

    // MARK: - Dependencies that hold a strong reference to `proxied`

    private let coreSDK: CoreSDK

    internal init(proxied: InternalDefaultLiveCounter, coreSDK: CoreSDK) {
        self.proxied = proxied
        self.coreSDK = coreSDK
    }

    // MARK: - `LiveCounter` protocol

    internal var value: Double {
        get throws(ARTErrorInfo) {
            try proxied.value(coreSDK: coreSDK)
        }
    }

    internal func increment(amount: Double) async throws(ARTErrorInfo) {
        try await proxied.increment(amount: amount)
    }

    internal func decrement(amount: Double) async throws(ARTErrorInfo) {
        try await proxied.decrement(amount: amount)
    }

    internal func subscribe(listener: sending (sending any LiveCounterUpdate) -> Void) -> any SubscribeResponse {
        proxied.subscribe(listener: listener)
    }

    internal func unsubscribeAll() {
        proxied.unsubscribeAll()
    }

    internal func on(event: LiveObjectLifecycleEvent, callback: sending () -> Void) -> any OnLiveObjectLifecycleEventResponse {
        proxied.on(event: event, callback: callback)
    }

    internal func offAll() {
        proxied.offAll()
    }
}
