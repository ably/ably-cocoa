import Ably

/// A callback used in ``LiveObject`` to listen for updates to the object.
///
/// - Parameters:
///   - update: The update object describing the changes made to the object.
///   - subscription: A ``SubscribeResponse`` object that allows the provided listener to deregister itself from future updates.
public typealias LiveObjectUpdateCallback<T> = @Sendable (_ update: sending T, _ subscription: SubscribeResponse) -> Void

/// The callback used for the events emitted by ``RealtimeObjects``.
///
/// - Parameter subscription: An ``OnObjectsEventResponse`` object that allows the provided listener to deregister itself from future updates.
public typealias ObjectsEventCallback = @Sendable (_ subscription: OnObjectsEventResponse) -> Void

/// The callback used for the lifecycle events emitted by ``LiveObject``.
/// - Parameter subscription: A ``OnLiveObjectLifecycleEventResponse`` object that allows the provided listener to deregister itself from future updates.
public typealias LiveObjectLifecycleEventCallback = @Sendable (_ subscription: OnLiveObjectLifecycleEventResponse) -> Void

/// Describes the events emitted by an ``RealtimeObjects`` object.
public enum ObjectsEvent: Sendable {
    /// The local copy of Objects on a channel is currently being synchronized with the Ably service.
    case syncing
    /// The local copy of Objects on a channel has been synchronized with the Ably service.
    case synced
}

/// Describes the events emitted by a ``LiveObject`` object.
public enum LiveObjectLifecycleEvent: Sendable {
    /// Indicates that the object has been deleted from the Objects pool and should no longer be interacted with.
    case deleted
}

/// Enables the Objects to be read, modified and subscribed to for a channel.
public protocol RealtimeObjects: Sendable {
    /// Retrieves the root ``LiveMap`` object for Objects on a channel.
    func getRoot() async throws(ARTErrorInfo) -> any LiveMap

    /// Creates a new ``LiveMap`` object instance with the provided entries.
    ///
    /// - Parameter entries: The initial entries for the new ``LiveMap`` object.
    func createMap(entries: [String: LiveMapValue]) async throws(ARTErrorInfo) -> any LiveMap

    /// Creates a new empty ``LiveMap`` object instance.
    func createMap() async throws(ARTErrorInfo) -> any LiveMap

    /// Creates a new ``LiveCounter`` object instance with the provided `count` value.
    ///
    /// - Parameter count: The initial value for the new ``LiveCounter`` object.
    func createCounter(count: Double) async throws(ARTErrorInfo) -> any LiveCounter

    /// Creates a new ``LiveCounter`` object instance with a value of zero.
    func createCounter() async throws(ARTErrorInfo) -> any LiveCounter

    /// Registers the provided listener for the specified event. If `on()` is called more than once with the same listener and event, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `on()`, and an event is emitted once, the listener would be invoked twice.
    ///
    /// - Parameters:
    ///   - event: The named event to listen for.
    ///   - callback: The event listener.
    /// - Returns: An ``OnObjectsEventResponse`` object that allows the provided listener to be deregistered from future updates.
    @discardableResult
    func on(event: ObjectsEvent, callback: @escaping ObjectsEventCallback) -> OnObjectsEventResponse

    /// Deregisters all registrations, for all events and listeners.
    func offAll()
}

/// Represents the type of data stored for a given key in a ``LiveMap``.
/// It may be a primitive value (string, number, boolean, binary data, JSON array, or JSON object), or another ``LiveObject``.
///
/// `LiveMapValue` implements Swift's `ExpressibleBy*Literal` protocols. This, in combination with `JSONValue`'s conformance to these protocols, allows you to write type-safe map values using familiar syntax. For example:
///
/// ```swift
/// let map = try await channel.objects.createMap(entries: [
///     "someStringKey": "someString",
///     "someIntegerKey": 123,
///     "someFloatKey": 123.456,
///     "someTrueKey": true,
///     "someFalseKey": false,
///     "someJSONObjectKey": [
///         "someNestedJSONObjectKey": [
///             "someOtherKey": "someOtherValue",
///         ],
///     ],
///     "someJSONArrayKey": [
///         "foo",
///         42,
///     ],
/// ])
/// ```
public enum LiveMapValue: Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case data(Data)
    case jsonArray([JSONValue])
    case jsonObject([String: JSONValue])
    case liveMap(any LiveMap)
    case liveCounter(any LiveCounter)

    // MARK: - Convenience getters for associated values

    /// If this `LiveMapValue` has case `liveMap`, this returns the associated value. Else, it returns `nil`.
    public var liveMapValue: (any LiveMap)? {
        if case let .liveMap(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `liveCounter`, this returns the associated value. Else, it returns `nil`.
    public var liveCounterValue: (any LiveCounter)? {
        if case let .liveCounter(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `string`, this returns the associated value. Else, it returns `nil`.
    public var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `number`, this returns the associated value. Else, it returns `nil`.
    public var numberValue: Double? {
        if case let .number(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `bool`, this returns the associated value. Else, it returns `nil`.
    public var boolValue: Bool? {
        if case let .bool(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `data`, this returns the associated value. Else, it returns `nil`.
    public var dataValue: Data? {
        if case let .data(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `jsonArray`, this returns the associated value. Else, it returns `nil`.
    public var jsonArrayValue: [JSONValue]? {
        if case let .jsonArray(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `jsonObject`, this returns the associated value. Else, it returns `nil`.
    public var jsonObjectValue: [String: JSONValue]? {
        if case let .jsonObject(value) = self {
            return value
        }
        return nil
    }

    // MARK: - Equatable Implementation

    public static func == (lhs: LiveMapValue, rhs: LiveMapValue) -> Bool {
        switch (lhs, rhs) {
        case let (.string(lhsValue), .string(rhsValue)):
            lhsValue == rhsValue
        case let (.number(lhsValue), .number(rhsValue)):
            lhsValue == rhsValue
        case let (.bool(lhsValue), .bool(rhsValue)):
            lhsValue == rhsValue
        case let (.data(lhsValue), .data(rhsValue)):
            lhsValue == rhsValue
        case let (.jsonArray(lhsValue), .jsonArray(rhsValue)):
            lhsValue == rhsValue
        case let (.jsonObject(lhsValue), .jsonObject(rhsValue)):
            lhsValue == rhsValue
        case let (.liveMap(lhsMap), .liveMap(rhsMap)):
            lhsMap === rhsMap
        case let (.liveCounter(lhsCounter), .liveCounter(rhsCounter)):
            lhsCounter === rhsCounter
        default:
            false
        }
    }
}

// MARK: - ExpressibleBy*Literal conformances

extension LiveMapValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .jsonObject(.init(uniqueKeysWithValues: elements))
    }
}

extension LiveMapValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .jsonArray(elements)
    }
}

extension LiveMapValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension LiveMapValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension LiveMapValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension LiveMapValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

/// Object returned from an `on` call, allowing the listener provided in that call to be deregistered.
public protocol OnObjectsEventResponse: Sendable {
    /// Deregisters the listener passed to the `on` call.
    func off()
}

/// The `LiveMap` class represents a key-value map data structure, similar to a Swift `Dictionary`, where all changes are synchronized across clients in realtime.
/// Conflicts in a LiveMap are automatically resolved with last-write-wins (LWW) semantics,
/// meaning that if two clients update the same key in the map, the update with the most recent timestamp wins.
///
/// Keys must be strings. Values can be another ``LiveObject``, or a primitive type, such as a string, number, boolean, JSON-serializable object or array, or binary data.
public protocol LiveMap: LiveObject where Update == LiveMapUpdate {
    /// Returns the value associated with a given key. Returns `nil` if the key doesn't exist in a map or if the associated ``LiveObject`` has been deleted.
    ///
    /// Always returns `nil` if this map object is deleted.
    ///
    /// - Parameter key: The key to retrieve the value for.
    /// - Returns: A ``LiveObject``, a primitive type (string, number, boolean, JSON-serializable object or array, or binary data) or `nil` if the key doesn't exist in a map or the associated ``LiveObject`` has been deleted. Always `nil` if this map object is deleted.
    func get(key: String) throws(ARTErrorInfo) -> LiveMapValue?

    /// Returns the number of key-value pairs in the map.
    var size: Int { get throws(ARTErrorInfo) }

    /// Returns an array of key-value pairs for every entry in the map.
    var entries: [(key: String, value: LiveMapValue)] { get throws(ARTErrorInfo) }

    /// Returns an array of keys in the map.
    var keys: [String] { get throws(ARTErrorInfo) }

    /// Returns an iterable of values in the map.
    var values: [LiveMapValue] { get throws(ARTErrorInfo) }

    /// Sends an operation to the Ably system to set a key on this `LiveMap` object to a specified value.
    ///
    /// This does not modify the underlying data of this object. Instead, the change is applied when
    /// the published operation is echoed back to the client and applied to the object.
    /// To get notified when object gets updated, use the ``LiveObject/subscribe(listener:)`` method.
    ///
    /// - Parameters:
    ///   - key: The key to set the value for.
    ///   - value: The value to assign to the key.
    func set(key: String, value: LiveMapValue) async throws(ARTErrorInfo)

    /// Sends an operation to the Ably system to remove a key from this `LiveMap` object.
    ///
    /// This does not modify the underlying data of this object. Instead, the change is applied when
    /// the published operation is echoed back to the client and applied to the object.
    /// To get notified when object gets updated, use the ``LiveObject/subscribe(listener:)`` method.
    ///
    /// - Parameter key: The key to remove.
    func remove(key: String) async throws(ARTErrorInfo)
}

/// Describes whether an entry in ``LiveMapUpdate/update`` represents an update or a removal.
public enum LiveMapUpdateAction: Sendable {
    /// The value of a key in the map was updated.
    case updated
    /// The value of a key in the map was removed.
    case removed
}

/// Represents an update to a ``LiveMap`` object, describing the keys that were updated or removed.
public protocol LiveMapUpdate: Sendable {
    /// An object containing keys from a `LiveMap` that have changed, along with their change status:
    /// - ``LiveMapUpdateAction/updated`` - the value of a key in the map was updated.
    /// - ``LiveMapUpdateAction/removed`` - the key was removed from the map.
    var update: [String: LiveMapUpdateAction] { get }
}

/// The `LiveCounter` class represents a counter that can be incremented or decremented and is synchronized across clients in realtime.
public protocol LiveCounter: LiveObject where Update == LiveCounterUpdate {
    /// Returns the current value of the counter.
    var value: Double { get throws(ARTErrorInfo) }

    /// Sends an operation to the Ably system to increment the value of this `LiveCounter` object.
    ///
    /// This does not modify the underlying data of this object. Instead, the change is applied when
    /// the published operation is echoed back to the client and applied to the object.
    /// To get notified when object gets updated, use the ``LiveObject/subscribe(listener:)`` method.
    ///
    /// - Parameter amount: The amount by which to increase the counter value.
    func increment(amount: Double) async throws(ARTErrorInfo)

    /// An alias for calling [`increment(-amount)`](doc:LiveCounter/increment(amount:)).
    ///
    /// - Parameter amount: The amount by which to decrease the counter value.
    func decrement(amount: Double) async throws(ARTErrorInfo)
}

/// Represents an update to a ``LiveCounter`` object.
public protocol LiveCounterUpdate: Sendable {
    /// Holds the numerical change to the counter value.
    var amount: Double { get }
}

/// Describes the common interface for all conflict-free data structures supported by the Objects.
public protocol LiveObject: AnyObject, Sendable {
    /// The type of update event that this object emits.
    associatedtype Update

    /// Registers a listener that is called each time this LiveObject is updated.
    ///
    /// - Parameter listener: An event listener function that is called with an update object whenever this LiveObject is updated.
    /// - Returns: A ``SubscribeResponse`` object that allows the provided listener to be deregistered from future updates.
    @discardableResult
    func subscribe(listener: @escaping LiveObjectUpdateCallback<Update>) throws(ARTErrorInfo) -> SubscribeResponse

    /// Deregisters all listeners from updates for this LiveObject.
    func unsubscribeAll()

    /// Registers the provided listener for the specified event. If `on()` is called more than once with the same listener and event, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `on()`, and an event is emitted once, the listener would be invoked twice.
    ///
    /// - Parameters:
    ///   - event: The named event to listen for.
    ///   - callback: The event listener.
    /// - Returns: A ``OnLiveObjectLifecycleEventResponse`` object that allows the provided listener to be deregistered from future updates.
    @discardableResult
    func on(event: LiveObjectLifecycleEvent, callback: @escaping LiveObjectLifecycleEventCallback) -> OnLiveObjectLifecycleEventResponse

    /// Deregisters all registrations, for all events and listeners.
    func offAll()
}

/// Object returned from a `subscribe` call, allowing the listener provided in that call to be deregistered.
public protocol SubscribeResponse: Sendable {
    /// Deregisters the listener passed to the `subscribe` call.
    func unsubscribe()
}

/// Object returned from an `on` call, allowing the listener provided in that call to be deregistered.
public protocol OnLiveObjectLifecycleEventResponse: Sendable {
    /// Deregisters the listener passed to the `on` call.
    func off()
}

// MARK: - AsyncSequence Extensions

/// Extension to provide AsyncSequence-based subscription for `LiveObject` updates.
public extension LiveObject {
    /// Returns an `AsyncSequence` that emits updates to this `LiveObject`.
    ///
    /// This provides an alternative to the callback-based ``subscribe(listener:)`` method,
    /// allowing you to use Swift's structured concurrency features like `for await` loops.
    ///
    /// - Returns: An AsyncSequence that emits ``Update`` values when the object is updated.
    /// - Throws: An ``ARTErrorInfo`` if the subscription fails.
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
