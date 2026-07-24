import Foundation

@available(macOS 10.15, iOS 13, tvOS 13, *)
internal extension DispatchQueue {
    /// Same as `sync(execute:)` but with a runtime precondition that we are not already on this queue.
    func ably_syncNoDeadlock(execute block: () -> Void) {
        dispatchPrecondition(condition: .notOnQueue(self))
        sync(execute: block)
    }

    /// Same as `sync(execute:)` but with a runtime precondition that we are not already on this queue.
    func ably_syncNoDeadlock<T>(execute work: () throws -> T) rethrows -> T {
        dispatchPrecondition(condition: .notOnQueue(self))
        return try sync(execute: work)
    }
}
