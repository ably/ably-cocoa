import Ably
import Foundation

/// Our default implementation of ``LiveCounter``.
internal final class DefaultLiveCounter: LiveCounter {
    internal init() {}

    // MARK: - LiveCounter conformance

    internal var value: Double {
        notYetImplemented()
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
}
