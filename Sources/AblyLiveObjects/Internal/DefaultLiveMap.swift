import Ably

/// Our default implementation of ``LiveMap``.
internal final class DefaultLiveMap: LiveMap {
    internal init() {}

    // MARK: - LiveMap conformance

    internal func get(key _: String) -> LiveMapValue? {
        notYetImplemented()
    }

    internal var size: Int {
        notYetImplemented()
    }

    internal var entries: [(key: String, value: LiveMapValue)] {
        notYetImplemented()
    }

    internal var keys: [String] {
        notYetImplemented()
    }

    internal var values: [LiveMapValue] {
        notYetImplemented()
    }

    internal func set(key _: String, value _: LiveMapValue) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    internal func remove(key _: String) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    internal func subscribe(listener _: (sending any LiveMapUpdate) -> Void) -> any SubscribeResponse {
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
}
