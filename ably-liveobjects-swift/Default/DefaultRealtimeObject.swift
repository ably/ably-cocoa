import Ably

internal final class DefaultRealtimeObject: RealtimeObject, Sendable {
    /// The process-wide instance. A `static let` is initialized lazily and exactly once per program
    /// execution (the Swift runtime guarantees thread-safe, run-once initialization), backing
    /// ``ARTRealtimeChannel/object``.
    static let shared = DefaultRealtimeObject()

    func get() async throws(ARTErrorInfo) -> any LiveMapPathObject {
        notImplemented()
    }

    @discardableResult
    func on(event: ObjectsEvent, callback: @escaping @Sendable () -> Void) -> any StatusSubscription {
        notImplemented()
    }

    func offAll() {
        notImplemented()
    }
}
