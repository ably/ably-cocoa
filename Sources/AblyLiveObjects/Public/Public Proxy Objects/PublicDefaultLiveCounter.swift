import Ably
internal import AblyPlugin

/// Our default implementation of ``LiveCounter``.
///
/// This is largely a wrapper around ``InternalDefaultLiveCounter``.
internal final class PublicDefaultLiveCounter: LiveCounter {
    internal let proxied: InternalDefaultLiveCounter

    // MARK: - Dependencies that hold a strong reference to `proxied`

    private let coreSDK: CoreSDK
    private let logger: AblyPlugin.Logger

    internal init(proxied: InternalDefaultLiveCounter, coreSDK: CoreSDK, logger: AblyPlugin.Logger) {
        self.proxied = proxied
        self.coreSDK = coreSDK
        self.logger = logger
    }

    // MARK: - `LiveCounter` protocol

    internal var value: Double {
        get throws(ARTErrorInfo) {
            try proxied.value(coreSDK: coreSDK)
        }
    }

    internal func increment(amount: Double) async throws(ARTErrorInfo) {
        try await proxied.increment(amount: amount, coreSDK: coreSDK)
    }

    internal func decrement(amount: Double) async throws(ARTErrorInfo) {
        try await proxied.decrement(amount: amount, coreSDK: coreSDK)
    }

    internal func subscribe(listener: @escaping LiveObjectUpdateCallback<LiveCounterUpdate>) throws(ARTErrorInfo) -> any SubscribeResponse {
        try proxied.subscribe(listener: listener, coreSDK: coreSDK)
    }

    internal func unsubscribeAll() {
        proxied.unsubscribeAll()
    }

    internal func on(event: LiveObjectLifecycleEvent, callback: @escaping LiveObjectLifecycleEventCallback) -> any OnLiveObjectLifecycleEventResponse {
        proxied.on(event: event, callback: callback)
    }

    internal func offAll() {
        proxied.offAll()
    }
}
