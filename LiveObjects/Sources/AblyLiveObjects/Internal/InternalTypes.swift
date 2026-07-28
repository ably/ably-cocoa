import Ably

// This file contains supporting types for the internal live-object engine (the callbacks, update
// descriptors and subscription-handle protocols used by `InternalDefaultLiveMap` /
// `InternalDefaultLiveCounter` and `InternalDefaultRealtimeObjects`). None of these are exposed to
// users; the public surface is the path-object / instance API (see the `Path Based API` directory).

/// A callback used by an internal live object to listen for updates to the object.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal typealias LiveObjectUpdateCallback<T> = @Sendable (_ update: sending T, _ subscription: SubscribeResponse) -> Void

/// The callback used for the lifecycle events emitted by an internal live object.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal typealias LiveObjectLifecycleEventCallback = @Sendable (_ subscription: OnLiveObjectLifecycleEventResponse) -> Void

/// Describes the lifecycle events emitted by an internal live object.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum LiveObjectLifecycleEvent: Sendable {
    /// Indicates that the object has been deleted from the Objects pool and should no longer be interacted with.
    case deleted
}

// The `ObjectsEvent` enum that these types refer to now lives in `RealtimeObject.swift` as part of
// the new public API; its cases (`.syncing` / `.synced`) are unchanged, so the internal engine
// continues to use it. The following two supporting types were part of the old public API surface
// but are still needed internally by `InternalDefaultRealtimeObjects` (e.g. `getRoot()` waits for a
// sync via `onInternal(event:callback:)`), so they are retained as `internal`.

/// The callback used for the events emitted by ``InternalDefaultRealtimeObjects``.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal typealias ObjectsEventCallback = @Sendable (_ subscription: OnObjectsEventResponse) -> Void

/// Object returned from an `on` call, allowing the listener provided in that call to be deregistered.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal protocol OnObjectsEventResponse: Sendable {
    /// Deregisters the listener passed to the `on` call.
    func off()
}

/// Describes whether an entry in ``LiveMapUpdate/update`` represents an update or a removal.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum LiveMapUpdateAction: Sendable {
    /// The value of a key in the map was updated.
    case updated
    /// The value of a key in the map was removed.
    case removed
}

/// Represents an update to an internal live map (``InternalDefaultLiveMap``).
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal protocol LiveMapUpdate: Sendable {
    /// The keys that have changed, along with their change status.
    var update: [String: LiveMapUpdateAction] { get }
}

/// Represents an update to an internal live counter (``InternalDefaultLiveCounter``).
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal protocol LiveCounterUpdate: Sendable {
    /// Holds the numerical change to the counter value.
    var amount: Double { get }
}

/// Object returned from a `subscribe` call, allowing the listener provided in that call to be deregistered.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal protocol SubscribeResponse: Sendable {
    /// Deregisters the listener passed to the `subscribe` call.
    func unsubscribe()
}

/// Object returned from an `on` call, allowing the listener provided in that call to be deregistered.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal protocol OnLiveObjectLifecycleEventResponse: Sendable {
    /// Deregisters the listener passed to the `on` call.
    func off()
}
