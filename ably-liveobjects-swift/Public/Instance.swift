import Ably

// MARK: - Instance (RTINS)

/// A direct-reference view of a `LiveObject` or primitive value.
///
/// Unlike ``PathObject``, which is path-addressed and re-resolves on each call, an `Instance` is
/// identity-addressed: it follows the specific object it was created with, regardless of where that
/// object sits in the graph.
///
/// An `Instance` is obtained from ``PathObject/instance()``. `Instance` is loosely typed; use
/// ``asLiveMap()``, ``asLiveCounter()`` or ``asPrimitive()`` to obtain a view with the methods
/// applicable to a particular expected type.
///
/// Spec: `RTINS1`.
public protocol Instance: Sendable {
    /// Returns a JSON-serializable, recursively-compacted representation of the wrapped value.
    /// Spec: `RTINS11`.
    func compactJson() throws(ARTErrorInfo) -> JSONValue?
}

public extension Instance {
    /// Returns a view of this instance typed as a ``LiveMapInstance``. Purely a type refinement.
    /// Spec: `RTINS1a`.
    func asLiveMap() -> any LiveMapInstance {
        notImplemented()
    }

    /// Returns a view of this instance typed as a ``LiveCounterInstance``. Purely a type refinement.
    /// Spec: `RTINS1a`.
    func asLiveCounter() -> any LiveCounterInstance {
        notImplemented()
    }

    /// Returns a view of this instance typed as a ``PrimitiveInstance``. Purely a type refinement.
    /// Spec: `RTINS1a`.
    func asPrimitive() -> any PrimitiveInstance {
        notImplemented()
    }
}

// MARK: - LiveMapInstance (RTINS, map subset)

/// An ``Instance`` view exposing the methods applicable when the wrapped value is a map.
/// Spec: `RTINS1a`.
public protocol LiveMapInstance: Instance {
    /// The `objectId` of the wrapped map. Spec: `RTINS3`.
    var id: String { get }

    /// Looks up `key` and returns an ``Instance`` wrapping the result, or `nil` if absent.
    /// Spec: `RTINS5`.
    func get(key: String) throws(ARTErrorInfo) -> (any Instance)?

    /// Returns an array of `[key, Instance]` pairs for the wrapped map. Spec: `RTINS6`.
    func entries() throws(ARTErrorInfo) -> [(key: String, value: any Instance)]

    /// Returns the keys of the wrapped map. Spec: `RTINS7`.
    func keys() throws(ARTErrorInfo) -> [String]

    /// Returns an ``Instance`` for each value of the wrapped map. Spec: `RTINS8`.
    func values() throws(ARTErrorInfo) -> [any Instance]

    /// Returns the number of entries in the wrapped map. Spec: `RTINS9`.
    func size() throws(ARTErrorInfo) -> Int?

    /// Sends an operation to set `key` to `value` on the wrapped map. Spec: `RTINS12`.
    func set(key: String, value: LiveMapValue) async throws(ARTErrorInfo)

    /// Sends an operation to remove `key` from the wrapped map. Spec: `RTINS13`.
    func remove(key: String) async throws(ARTErrorInfo)

    /// Registers a listener that is called each time the wrapped map is updated. Spec: `RTINS16`.
    @discardableResult
    func subscribe(listener: @escaping InstanceSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription
}

// MARK: - LiveCounterInstance (RTINS, counter subset)

/// An ``Instance`` view exposing the methods applicable when the wrapped value is a counter.
/// Spec: `RTINS1a`.
public protocol LiveCounterInstance: Instance {
    /// The `objectId` of the wrapped counter. Spec: `RTINS3`.
    var id: String { get }

    /// Returns the current value of the wrapped counter, or `nil` if the wrapped value is not a
    /// counter. Spec: `RTINS4`.
    func value() throws(ARTErrorInfo) -> Double?

    /// Sends an operation to increment the wrapped counter. Spec: `RTINS14`.
    func increment(amount: Double) async throws(ARTErrorInfo)

    /// Sends an operation to decrement the wrapped counter. Spec: `RTINS15`.
    func decrement(amount: Double) async throws(ARTErrorInfo)

    /// Registers a listener that is called each time the wrapped counter is updated. Spec: `RTINS16`.
    @discardableResult
    func subscribe(listener: @escaping InstanceSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription
}

public extension LiveCounterInstance {
    /// Sends an operation to increment the wrapped counter by 1. Spec: `RTINS14`.
    func increment() async throws(ARTErrorInfo) {
        try await increment(amount: 1)
    }

    /// Sends an operation to decrement the wrapped counter by 1. Spec: `RTINS15`.
    func decrement() async throws(ARTErrorInfo) {
        try await decrement(amount: 1)
    }
}

// MARK: - PrimitiveInstance (RTINS, primitive subset)

/// An ``Instance`` view exposing the methods applicable when the wrapped value is a primitive.
/// Spec: `RTINS1a`.
public protocol PrimitiveInstance: Instance {
    /// Returns the wrapped primitive value, or `nil` if the wrapped value is not a primitive.
    /// Spec: `RTINS4`.
    func value() throws(ARTErrorInfo) -> Primitive?
}
