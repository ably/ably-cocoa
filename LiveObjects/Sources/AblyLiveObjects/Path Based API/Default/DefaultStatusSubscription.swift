import Ably

/// Default implementation of the public ``StatusSubscription`` (RTO18f). It wraps the internal
/// engine's ``OnObjectsEventResponse`` handle so that `off()` deregisters the status listener
/// registered by ``RealtimeObject/on(event:callback:)``. Spec: `RTO18f`, `RTO18f1`.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultStatusSubscription: StatusSubscription, Sendable {
    private let response: any OnObjectsEventResponse

    internal init(response: any OnObjectsEventResponse) {
        self.response = response
    }

    internal func off() {
        response.off()
    }
}
