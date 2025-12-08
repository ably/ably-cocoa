import Foundation

/// A class for testing LiveObjects subscriptions.
///
/// Create a listener function using ``createListener``, and pass it to the `subscribe(listener:)` method of a LiveObject. Fetch details of the invocations of this listener function using ``getInvocations``.
@available(iOS 17.0.0, tvOS 17.0.0, *) // "Parameter packs in generic types are only available in tvOS 17.0.0 or newer". I wrote this class using this language feature and only after a while realised that this issue exists. So I've gone and marked all of the tests that use this as having the same availability. Might revisit this class at some point if this turns out to be a big nuisance (it's annoying that you can't mark whole suites as @available).
final class Subscriber<each CallbackArg: Sendable>: Sendable {
    private let callbackQueue: DispatchQueue
    // Used to synchronize access to the nonisolated(unsafe) mutable state.
    private let mutex = NSLock()
    private nonisolated(unsafe) var invocations: [(repeat each CallbackArg)] = []
    private nonisolated(unsafe) var listeners: [CallbackWrapper] = []

    /// Creates a `Subscriber`.
    ///
    /// - Parameters:
    ///   - callbackQueue: The queue on which this subscriber expects its listeners to be called.
    init(callbackQueue: DispatchQueue) {
        self.callbackQueue = callbackQueue
    }

    /// Waits for the `callbackQueue` to perform all of its pending work, and then returns all of the invocations of a ``createListener`` listener that this subscriber has so far received.
    func getInvocations() async -> [(repeat each CallbackArg)] {
        await withCheckedContinuation { continuation in
            callbackQueue.async {
                continuation.resume()
            }
        }

        return mutex.withLock {
            invocations
        }
    }

    /// Creates a listener function which, when invoked, records an invocation. The details of this invocation can subsequently be fetched using ``getInvocations``.
    func createListener(_ action: (@Sendable (repeat each CallbackArg) -> Void)? = nil) -> (@Sendable (repeat each CallbackArg) -> Void) {
        { [callbackQueue, weak self](arg: repeat each CallbackArg) in
            dispatchPrecondition(condition: .onQueue(callbackQueue))

            guard let self else {
                return
            }
            let callListeners = mutex.withLock {
                let invocation = (repeat each arg)
                invocations.append(invocation)

                return { [listeners] in
                    for listener in listeners {
                        listener.callAsFunction(repeat each invocation)
                    }
                }
            }
            if let action {
                action(repeat each arg)
            }
            callListeners()
        }
    }

    /// A wrapper that allows us to store a callback that takes variadic args.
    ///
    /// This allows us to avoid the error "Cannot fully abstract a value of variadic function type '@Sendable (repeat each CallbackArg) -> ()' because different contexts will not be able to reliably agree on a calling convention; try wrapping it in a struct" that we get if we try to directly store the callback in an array. Claude suggested this solution.
    private struct CallbackWrapper {
        let callback: @Sendable (repeat each CallbackArg) -> Void

        func callAsFunction(_ args: repeat each CallbackArg) {
            callback(repeat each args)
        }
    }

    /// Adds a listener which replays all previously buffered and future invocations of any function previously created by ``createListener(_:)``.
    ///
    /// This is useful for the scenario where you want to set up a subscription synchronously (so as not to miss any events) but then in an `async` context perform actions as a result of the invocation of the listener. (You could equally use the SDK's `AsyncSequence` interface but the approach here is a closer mapping of the ported JS integration tests that call `subscribe`.)
    func addListener(_ listener: @escaping (@Sendable (repeat each CallbackArg) -> Void)) {
        let performInvocations = mutex.withLock {
            listeners.append(.init(callback: listener))

            return { [invocations, callbackQueue] in
                for invocation in invocations {
                    callbackQueue.async {
                        listener(repeat each invocation)
                    }
                }
            }
        }

        performInvocations()
    }
}
