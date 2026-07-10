import Foundation

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal extension NSLock {
    /// Behaves like `NSLock.withLock`, but the thrown error has the same type as that thrown by the body. (`withLock` uses `rethrows`, which is always an untyped throw.)
    func ablyLiveObjects_withLockWithTypedThrow<R, E>(_ body: () throws(E) -> R) throws(E) -> R {
        lock()
        defer { unlock() }
        return try body()
    }
}
