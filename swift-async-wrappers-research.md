# A Swift `async`/`await` layer for ably-cocoa

Swift doesn't turn ably-cocoa's callback methods into `async` functions by itself. This note looks at the alternative: a Swift layer of `async throws` wrappers over the Objective-C API.

## Where the layer would live

SwiftPM doesn't allow Objective-C and Swift in the same target, so the wrappers need a target of their own. There are two ways to arrange that.

**A. Add a Swift product next to the existing one.** A new target (for example `AblyPubSubDeviceAsync`) depends on `AblyPubSubDevice` and adds extensions to its classes. This breaks nothing and Objective-C users don't notice it. The cost is that Swift users need two imports.

**B. Put a Swift module in front of the Objective-C one.** The Objective-C target gets an internal name, and a new Swift target takes the name `AblyPubSubDevice` and re-exports it with `@_exported import`. Swift users keep one import. The costs:

- `@_exported` is an underscored, unofficial attribute.
- Objective-C users would have to import the internal module by name.
- It changes the rule in `CLAUDE.md` that the SDK is "one target and one module".

A is the cheap, reversible choice. B is what you'd pick if `async` is meant to be the main Swift API.

## What the wrappers look like

There's already a pattern to follow. LiveObjects exposes `async throws(ErrorInfo)` from Swift (`PublicDefaultRealtimeObject.swift:26`) and targets the same iOS 15 floor. `ARTErrorInfo` already conforms to Swift's `Error`, so no error-mapping layer is needed.

**One-shot operations.** About 59 declarations in the public headers have this shape. Many of them are duplicated between a protocol and its class, so there are fewer distinct methods.

```swift
extension RealtimeChannel {
    public func attach() async throws(ErrorInfo) {
        let error: ErrorInfo? = await withCheckedContinuation { c in
            attach { c.resume(returning: $0) }
        }
        if let error { throw error }
    }
}
```

**Methods that return `BOOL` and fill an error pointer.** There are 7 of these, including `history` and `presence.get`. They report a validation error straight away, then deliver the result later. The wrapper throws the first error before it starts waiting:

```swift
public func history(_ query: RealtimeHistoryQuery? = nil) async throws(ErrorInfo) -> PaginatedResult<Message> {
    var validationError: ErrorInfo?
    let result: Result<PaginatedResult<Message>, ErrorInfo> = await withCheckedContinuation { c in
        do {
            try history(query) { page, error in
                c.resume(returning: page.map { .success($0) } ?? .failure(error!))
            }
        } catch {
            validationError = ErrorInfo.wrap(error)   // helper; the thrown value is NSError
            c.resume(returning: .failure(validationError!))
        }
    }
    return try result.get()
}
```

`PaginatedResult.next`, `first` and friends would need their own wrappers. Optionally, you could add an `AsyncSequence` over pages.

**Subscriptions.** About 22 methods return an `ARTEventListener`. These map to `AsyncStream`, with unsubscribing hooked to the stream's termination:

```swift
public func messages(named name: String? = nil) -> AsyncStream<Message> {
    AsyncStream { continuation in
        let listener = name.map { subscribe($0) { continuation.yield($0) } }
                         ?? subscribe { continuation.yield($0) }
        continuation.onTermination = { [weak self] _ in
            if let listener { self?.unsubscribe(listener) }
        }
    }
}
```

The attach callback these methods take (`onAttach`) doesn't fit a stream. You'd leave it out and tell users to call `try await attach()` first.

## The hard parts

1. **Each callback must run exactly once.** A checked continuation crashes if it's resumed twice and leaks if it's never resumed. The Objective-C layer doesn't promise either. For example, it's unclear whether every failure path of `attach` calls back exactly once when a channel is released or the client is closed. Each wrapped method needs checking and a test that covers this.

2. **Swift 6 concurrency checking.** None of the public headers mark anything `Sendable`. `ARTMessage`, `ARTPaginatedResult` and the channel classes are mutable reference types. Once an `async` function returns them, a Swift 6 caller that moves them between actors gets compiler errors. There are three ways out:
   - Audit the classes and add `NS_SWIFT_SENDABLE` where they really are safe to share.
   - Declare `@unchecked Sendable` conformances in the Swift layer. That's quick, but it's a promise the code may not keep.
   - Leave users to write `@preconcurrency import`.

   This is probably the biggest single piece of work.

3. **Cancellation.** Ably operations can't be aborted once started. Cancelling a task that is awaiting `attach()` can't stop the attach. Either the wrapper ignores cancellation, or it throws `CancellationError` while the operation keeps running. Whichever you pick needs documenting.

4. **Which queue callbacks run on.** Callbacks arrive on `ClientOptions.dispatchQueue`, which is the main queue by default. With continuations this mostly stops mattering, because the caller resumes on its own executor. But a `MessageCallback` that used to run on the main thread no longer does once the user moves to `for await`, which can break UI code that relied on it. The next section covers this in detail.

5. **Overloads.** Swift already exposes `attach(_ callback: Callback?)`, and `c.attach()` calls it with no arguments. An `async` `attach()` in an extension still works: inside an `async` function Swift prefers the `async` overload, and elsewhere it uses the callback one. But it's easy to call the wrong one by accident, so some teams give the async versions distinct names.

6. **Keeping it in sync.** Every new callback method in the Objective-C headers needs a matching Swift wrapper. Nothing enforces that today, so you'd want a check in CI or in code review.

## Message delivery: `MessageCallback` versus `AsyncStream`

`MessageCallback` is the closure passed to `subscribe`. Moving from that closure to `for await` changes more than which thread the code runs on.

### How delivery works today

`ClientOptions.dispatchQueue` is documented as "the queue to which all calls to user-provided callbacks will be dispatched" (`ARTClientOptions.h:146`). The same doc says it serves as the target queue of an internal serial queue, so callbacks run one at a time even if you pass a concurrent queue. It defaults to the main queue.

The channel code follows that. Message listeners are registered on an emitter built with `_userQueue` (`ARTRealtimeChannel.m:321`). Completion callbacks are dispatched with `art_dispatch_async(self->_userQueue, …)` (for example at lines 429 and 494). So message callbacks, connection and channel state changes, and completion callbacks all go through one serial queue.

With the default settings, that gives callback code three guarantees:

1. **It runs on the main thread.** A `MessageCallback` can update UIKit or `@Observable` state directly.
2. **All events arrive in one order.** Suppose a channel detaches and then a message arrives. The state-change listener runs before the message listener, and never at the same time.
3. **A slow callback slows delivery.** While your callback runs, the next callback on that queue waits. It's crude, but it's backpressure: the SDK can't hand you events faster than you handle them.

### What changes with an `AsyncStream`

The subscription wrapper above does this:

```swift
subscribe { continuation.yield($0) }
```

The SDK still calls the closure on `dispatchQueue`, but the closure only puts the message into the stream's buffer and returns. Your code runs later, in the task that consumes the stream:

```swift
Task {
    for await message in channel.messages() {
        label.text = message.data as? String   // Which thread is this on?
    }
}
```

That affects each of the three guarantees.

**1. The thread depends on the consuming task.** The loop body runs wherever that task runs:

- Code in a `@MainActor` context, such as a SwiftUI view's `.task { }` or a `Task { }` started from main-actor code, runs on the main actor.
- A `Task.detached`, or a `Task` started from nonisolated code, runs on the global concurrent executor, off the main thread.

So the same UI update that was safe in a callback may run off the main thread. In Swift 6 mode the compiler catches most of these cases. In Swift 5 mode it mostly doesn't.

**2. Order holds within a stream, not across streams.** One `AsyncStream` yields its messages in order. If you expose messages, channel state and connection state as three streams consumed by three tasks, nothing orders them against each other. Code like this can see a message after `.detached` has already been handled:

```swift
Task { for await m in channel.messages() { handle(m) } }
Task { for await s in channel.stateChanges() { handle(s) } }
```

The callback API never allowed that.

**3. Backpressure is gone.** `yield` returns immediately, and `AsyncStream`'s default buffer is `.unbounded`. A slow consumer on a busy channel means buffered messages keep piling up in memory. The alternatives are `.bufferingNewest(n)` and `.bufferingOldest(n)`, which drop messages silently. That's usually worse for a messaging SDK than the callback API's behaviour of simply delivering more slowly.

### How the wrapper layer could handle this

- **Document the thread rule.** For example: "the loop body runs on the consuming task's executor, not on `dispatchQueue`; consume from a `@MainActor` context to update UI."
- **Offer a single ordered stream where order matters.** For example, a stream of `enum ChannelEvent { case message(Message), stateChange(ChannelStateChange) }` fed from one internal queue. That keeps the ordering the callback API gives.
- **Choose the buffer policy on purpose.** Either keep `.unbounded` and document it, or let callers pass a policy. Don't pick a dropping policy by default.
- **Keep the callback API.** Code that depends on "main thread, serial, in order" can still use `subscribe` directly, so the stream API only needs to be the easy default.

## Size

It's roughly 90 wrappers. Most are the same few lines. The cost is in the exactly-once audit and in deciding how to handle `Sendable`, not in the wrappers themselves. A sensible first step is option A with just the one-shot operations. That covers attach, detach, publish, presence enter/leave, history and auth. Subscriptions and the `Sendable` work can follow.
