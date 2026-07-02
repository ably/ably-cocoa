import Ably

// This file contains the previous public LiveObjects API surface. With the introduction of the
// path-object / instance API it is no longer exposed to users: everything here is now `internal`.
// The live-object protocols `LiveMap` / `LiveCounter` have been renamed to `InternalLiveMap` /
// `InternalLiveCounter` (per spec PRs ably/specification#485 and #489), freeing the `LiveMap` /
// `LiveCounter` names for the new public value types (see `ValueTypes.swift`).
//
// Note: the old `RealtimeObjects` (plural) entry point was renamed to `RealtimeObject` (singular) by
// the same spec PRs; its replacement is the new public ``RealtimeObject`` (see `RealtimeObject.swift`).

/// A callback used in ``LiveObject`` to listen for updates to the object.
internal typealias LiveObjectUpdateCallback<T> = @Sendable (_ update: sending T, _ subscription: SubscribeResponse) -> Void

/// The callback used for the lifecycle events emitted by ``LiveObject``.
internal typealias LiveObjectLifecycleEventCallback = @Sendable (_ subscription: OnLiveObjectLifecycleEventResponse) -> Void

/// Describes the events emitted by a ``LiveObject`` object.
internal enum LiveObjectLifecycleEvent: Sendable {
    /// Indicates that the object has been deleted from the Objects pool and should no longer be interacted with.
    case deleted
}

/// The internal live key-value map data structure. Spec: `RTLM`.
internal protocol InternalLiveMap: LiveObject where Update == LiveMapUpdate {
    /// Returns the value associated with a given key.
    func get(key: String) throws(ARTErrorInfo) -> LiveMapValue?

    /// Returns the number of key-value pairs in the map.
    var size: Int { get throws(ARTErrorInfo) }

    /// Returns an array of key-value pairs for every entry in the map.
    var entries: [(key: String, value: LiveMapValue)] { get throws(ARTErrorInfo) }

    /// Returns an array of keys in the map.
    var keys: [String] { get throws(ARTErrorInfo) }

    /// Returns an iterable of values in the map.
    var values: [LiveMapValue] { get throws(ARTErrorInfo) }

    /// Sends an operation to set a key on this map to a specified value.
    func set(key: String, value: LiveMapValue) async throws(ARTErrorInfo)

    /// Sends an operation to remove a key from this map.
    func remove(key: String) async throws(ARTErrorInfo)
}

/// Describes whether an entry in ``LiveMapUpdate/update`` represents an update or a removal.
internal enum LiveMapUpdateAction: Sendable {
    /// The value of a key in the map was updated.
    case updated
    /// The value of a key in the map was removed.
    case removed
}

/// Represents an update to an ``InternalLiveMap`` object.
internal protocol LiveMapUpdate: Sendable {
    /// The keys that have changed, along with their change status.
    var update: [String: LiveMapUpdateAction] { get }
}

/// The internal live counter data structure. Spec: `RTLC`.
internal protocol InternalLiveCounter: LiveObject where Update == LiveCounterUpdate {
    /// Returns the current value of the counter.
    var value: Double { get throws(ARTErrorInfo) }

    /// Sends an operation to increment the value of this counter.
    func increment(amount: Double) async throws(ARTErrorInfo)

    /// Sends an operation to decrement the value of this counter.
    func decrement(amount: Double) async throws(ARTErrorInfo)
}

/// Represents an update to an ``InternalLiveCounter`` object.
internal protocol LiveCounterUpdate: Sendable {
    /// Holds the numerical change to the counter value.
    var amount: Double { get }
}

/// Describes the common interface for all conflict-free data structures supported by the Objects.
internal protocol LiveObject: AnyObject, Sendable {
    /// The type of update event that this object emits.
    associatedtype Update

    /// Registers a listener that is called each time this LiveObject is updated.
    @discardableResult
    func subscribe(listener: @escaping LiveObjectUpdateCallback<Update>) throws(ARTErrorInfo) -> SubscribeResponse

    /// Deregisters all listeners from updates for this LiveObject.
    func unsubscribeAll()

    /// Registers the provided listener for the specified event.
    @discardableResult
    func on(event: LiveObjectLifecycleEvent, callback: @escaping LiveObjectLifecycleEventCallback) -> OnLiveObjectLifecycleEventResponse

    /// Deregisters all registrations, for all events and listeners.
    func offAll()
}

/// Object returned from a `subscribe` call, allowing the listener provided in that call to be deregistered.
internal protocol SubscribeResponse: Sendable {
    /// Deregisters the listener passed to the `subscribe` call.
    func unsubscribe()
}

/// Object returned from an `on` call, allowing the listener provided in that call to be deregistered.
internal protocol OnLiveObjectLifecycleEventResponse: Sendable {
    /// Deregisters the listener passed to the `on` call.
    func off()
}

// MARK: - AsyncSequence Extensions

/// Extension to provide AsyncSequence-based subscription for `LiveObject` updates.
///
/// `AsyncStream` requires a newer deployment target than this package's floor (macOS 10.11 / iOS 9 /
/// tvOS 10), so the extension is gated behind `@available`.
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
internal extension LiveObject {
    /// Returns an `AsyncSequence` that emits updates to this `LiveObject`.
    func updates() throws(ARTErrorInfo) -> AsyncStream<Update> {
        let (stream, continuation) = AsyncStream.makeStream(of: Update.self)

        let subscription = try subscribe { update, _ in
            continuation.yield(update)
        }

        continuation.onTermination = { _ in
            subscription.unsubscribe()
        }

        return stream
    }
}
