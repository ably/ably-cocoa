import Ably

// MARK: - PathObject (RTPO)

/// A lazy, path-based reference into the LiveObjects graph.
///
/// A `PathObject` stores a path (an ordered list of string segments) from the root map and resolves
/// it at the time each method is called. This means a `PathObject` survives object replacements: if
/// the object at a given path changes, the same `PathObject` will resolve to the new object on
/// subsequent calls.
///
/// A `PathObject` is obtained from ``RealtimeObject/get()``, which returns a ``LiveMapPathObject``
/// rooted at the channel's root map with an empty path. Further path objects are obtained by
/// navigating with ``LiveMapPathObject/get(key:)`` or ``LiveMapPathObject/at(path:)``.
///
/// `PathObject` is loosely typed. To obtain a view with the methods applicable to a particular
/// expected type, use ``asLiveMap()``, ``asLiveCounter()`` or ``asPrimitive()``. These do not
/// guarantee that the value actually at the path has that type; that can only be determined when the
/// value is evaluated (e.g. via `value()`), at which point `nil` is returned if the actual type
/// differs from the one requested.
///
/// Spec: `RTPO1`.
public protocol PathObject: Sendable {
    /// Returns a dot-delimited string representation of the stored path segments. Dot characters
    /// occurring within individual segments are escaped with a backslash. An empty path (the root)
    /// returns an empty string. Spec: `RTPO4`.
    func path() -> String

    /// Resolves the path and, if it resolves to a `LiveObject`, returns an ``Instance`` wrapping it.
    /// Returns `nil` if the resolved value is a primitive or if resolution fails. Spec: `RTPO8`.
    func instance() throws(ARTErrorInfo) -> (any Instance)?

    /// Resolves the path and returns a JSON-serializable, recursively-compacted representation of the
    /// resolved value, or `nil` if resolution fails. Spec: `RTPO14`.
    func compactJson() throws(ARTErrorInfo) -> JSONValue?

    /// Registers a listener that is called when the object at this path is updated.
    ///
    /// - Parameters:
    ///   - options: Subscription options, such as the nesting depth to observe.
    ///   - listener: The listener to call with a ``PathObjectSubscriptionEvent``.
    /// - Returns: A ``Subscription`` that allows the listener to be deregistered.
    /// Spec: `RTPO19`.
    @discardableResult
    func subscribe(options: PathObjectSubscriptionOptions?, listener: @escaping PathObjectSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription
}

public extension PathObject {
    /// Registers a listener that is called when the object at this path is updated, using default
    /// options. Spec: `RTPO19`.
    @discardableResult
    func subscribe(listener: @escaping PathObjectSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        try subscribe(options: nil, listener: listener)
    }

    /// Returns a view of this path object typed as a ``LiveMapPathObject``. Purely a type refinement;
    /// it does not resolve the path. Spec: `RTPO1a`.
    func asLiveMap() -> any LiveMapPathObject {
        notImplemented()
    }

    /// Returns a view of this path object typed as a ``LiveCounterPathObject``. Purely a type
    /// refinement; it does not resolve the path. Spec: `RTPO1a`.
    func asLiveCounter() -> any LiveCounterPathObject {
        notImplemented()
    }

    /// Returns a view of this path object typed as a ``PrimitivePathObject``. Purely a type
    /// refinement; it does not resolve the path. Spec: `RTPO1a`.
    func asPrimitive() -> any PrimitivePathObject {
        notImplemented()
    }
}

// MARK: - LiveMapPathObject (RTPO, map subset)

/// A ``PathObject`` view exposing the methods applicable when the value at the path is expected to be
/// a map. Spec: `RTPO1a`.
public protocol LiveMapPathObject: PathObject {
    /// Returns a new ``PathObject`` with `key` appended to this object's path. Purely navigational;
    /// does not resolve the path. Spec: `RTPO5`.
    func get(key: String) -> any PathObject

    /// Returns a new ``PathObject`` with the parsed segments of the dot-delimited `path` appended to
    /// this object's path. Purely navigational; does not resolve the path. Spec: `RTPO6`.
    func at(path: String) -> any PathObject

    /// Resolves the path and, if it resolves to a map, returns an array of `[key, PathObject]` pairs.
    /// Returns an empty array if the resolved value is not a map or resolution fails. Spec: `RTPO9`.
    func entries() throws(ARTErrorInfo) -> [(key: String, value: any PathObject)]

    /// Resolves the path and, if it resolves to a map, returns its keys. Returns an empty array if
    /// the resolved value is not a map or resolution fails. Spec: `RTPO10`.
    func keys() throws(ARTErrorInfo) -> [String]

    /// Resolves the path and, if it resolves to a map, returns a ``PathObject`` for each value.
    /// Returns an empty array if the resolved value is not a map or resolution fails. Spec: `RTPO11`.
    func values() throws(ARTErrorInfo) -> [any PathObject]

    /// Resolves the path and, if it resolves to a map, returns the number of entries. Returns `nil`
    /// if the resolved value is not a map or resolution fails. Spec: `RTPO12`.
    func size() throws(ARTErrorInfo) -> Int?

    /// Sends an operation to set `key` to `value` on the map at this path. Spec: `RTPO15`.
    func set(key: String, value: LiveMapValue) async throws(ARTErrorInfo)

    /// Sends an operation to remove `key` from the map at this path. Spec: `RTPO16`.
    func remove(key: String) async throws(ARTErrorInfo)
}

// MARK: - LiveCounterPathObject (RTPO, counter subset)

/// A ``PathObject`` view exposing the methods applicable when the value at the path is expected to be
/// a counter. Spec: `RTPO1a`.
public protocol LiveCounterPathObject: PathObject {
    /// Resolves the path and, if it resolves to a counter, returns its current value. Returns `nil`
    /// if the resolved value is not a counter or resolution fails. Spec: `RTPO7`.
    func value() throws(ARTErrorInfo) -> Double?

    /// Sends an operation to increment the counter at this path. Spec: `RTPO17`.
    ///
    /// - Parameter amount: The amount by which to increment.
    func increment(amount: Double) async throws(ARTErrorInfo)

    /// Sends an operation to decrement the counter at this path. Spec: `RTPO18`.
    ///
    /// - Parameter amount: The amount by which to decrement.
    func decrement(amount: Double) async throws(ARTErrorInfo)
}

public extension LiveCounterPathObject {
    /// Sends an operation to increment the counter at this path by 1. Spec: `RTPO17`.
    func increment() async throws(ARTErrorInfo) {
        try await increment(amount: 1)
    }

    /// Sends an operation to decrement the counter at this path by 1. Spec: `RTPO18`.
    func decrement() async throws(ARTErrorInfo) {
        try await decrement(amount: 1)
    }
}

// MARK: - PrimitivePathObject (RTPO, primitive subset)

/// A ``PathObject`` view exposing the methods applicable when the value at the path is expected to be
/// a primitive. Spec: `RTPO1a`.
public protocol PrimitivePathObject: PathObject {
    /// Resolves the path and, if it resolves to a primitive, returns it. Returns `nil` if the
    /// resolved value is not a primitive or resolution fails. Spec: `RTPO7`.
    func value() throws(ARTErrorInfo) -> Primitive?
}
