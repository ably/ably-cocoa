import Ably
import Foundation

// MARK: - Primitive

/// Represents a primitive value that can be stored at a path in the LiveObjects graph.
///
/// A ``PrimitivePathObject`` or ``PrimitiveInstance`` resolves to a `Primitive` when its
/// ``PrimitivePathObject/value()`` (resp. ``PrimitiveInstance/value()``) method is called and the
/// underlying value is in fact a primitive.
public enum Primitive: Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case data(Data)
    case jsonArray([JSONValue])
    case jsonObject([String: JSONValue])

    // MARK: - Convenience getters for associated values

    /// If this `Primitive` has case `string`, this returns the associated value. Else, it returns `nil`.
    public var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }

    /// If this `Primitive` has case `number`, this returns the associated value. Else, it returns `nil`.
    public var numberValue: Double? {
        if case let .number(value) = self {
            return value
        }
        return nil
    }

    /// If this `Primitive` has case `bool`, this returns the associated value. Else, it returns `nil`.
    public var boolValue: Bool? {
        if case let .bool(value) = self {
            return value
        }
        return nil
    }

    /// If this `Primitive` has case `data`, this returns the associated value. Else, it returns `nil`.
    public var dataValue: Data? {
        if case let .data(value) = self {
            return value
        }
        return nil
    }

    /// If this `Primitive` has case `jsonArray`, this returns the associated value. Else, it returns `nil`.
    public var jsonArrayValue: [JSONValue]? {
        if case let .jsonArray(value) = self {
            return value
        }
        return nil
    }

    /// If this `Primitive` has case `jsonObject`, this returns the associated value. Else, it returns `nil`.
    public var jsonObjectValue: [String: JSONValue]? {
        if case let .jsonObject(value) = self {
            return value
        }
        return nil
    }
}

// MARK: - LiveCounter (value type, RTLCV)

/// A value type describing a new `LiveCounter` to be created, for use as a value passed to
/// ``LiveMapPathObject/set(key:value:)`` (or the equivalent on ``LiveMapInstance``).
///
/// This is **not** a live, synchronized counter; it is a lightweight, local description of the
/// counter to create. The live counter is created on the Ably system when this value is set into the
/// graph. Spec: `RTLCV`.
public struct LiveCounter: Sendable, Equatable {
    /// The initial count for the counter. Spec: `RTLCV2a`.
    internal let count: Double

    private init(count: Double) {
        self.count = count
    }

    /// Creates a new `LiveCounter` value type with the provided initial count.
    ///
    /// - Parameter initialCount: The initial value for the new counter.
    /// Spec: `RTLCV3`.
    public static func create(initialCount: Double) -> LiveCounter {
        .init(count: initialCount)
    }

    /// Creates a new `LiveCounter` value type with an initial count of zero.
    /// Spec: `RTLCV3`.
    public static func create() -> LiveCounter {
        .init(count: 0)
    }
}

// MARK: - LiveMap (value type, RTLMV)

/// A value type describing a new `LiveMap` to be created, for use as a value passed to
/// ``LiveMapPathObject/set(key:value:)`` (or the equivalent on ``LiveMapInstance``).
///
/// This is **not** a live, synchronized map; it is a lightweight, local description of the map to
/// create. The live map is created on the Ably system when this value is set into the graph.
/// Spec: `RTLMV`.
public struct LiveMap: Sendable, Equatable {
    /// The initial entries for the map. Spec: `RTLMV2a`.
    internal let entries: [String: LiveMapValue]?

    private init(entries: [String: LiveMapValue]?) {
        self.entries = entries
    }

    /// Creates a new `LiveMap` value type with the provided initial entries.
    ///
    /// - Parameter entries: The initial entries for the new map.
    /// Spec: `RTLMV3`.
    public static func create(entries: [String: LiveMapValue]) -> LiveMap {
        .init(entries: entries)
    }

    /// Creates a new empty `LiveMap` value type.
    /// Spec: `RTLMV3`.
    public static func create() -> LiveMap {
        .init(entries: nil)
    }
}

// MARK: - LiveMapValue

/// Represents the type of data that can be stored for a given key in a map, when *writing* to the
/// graph via ``LiveMapPathObject/set(key:value:)`` or ``LiveMapInstance/set(key:value:)``.
///
/// It may be a primitive value (string, number, boolean, binary data, JSON array, or JSON object),
/// or a new ``LiveMap``/``LiveCounter`` value type to be created.
///
/// `LiveMapValue` implements Swift's `ExpressibleBy*Literal` protocols. This, in combination with
/// `JSONValue`'s conformance to these protocols, allows you to write type-safe map values using
/// familiar syntax. For example:
///
/// ```swift
/// try await root.asLiveMap().set(key: "someStringKey", value: "someString")
/// try await root.asLiveMap().set(key: "someJSONObjectKey", value: [
///     "someNestedJSONObjectKey": [
///         "someOtherKey": "someOtherValue",
///     ],
/// ])
/// ```
public enum LiveMapValue: Sendable, Equatable {
    /// A primitive value (string, number, boolean, binary data, JSON array, or JSON object).
    case primitive(Primitive)
    case liveMap(LiveMap)
    case liveCounter(LiveCounter)

    // MARK: - Convenience getters for associated values

    /// If this `LiveMapValue` has case `primitive`, this returns the associated value. Else, it returns `nil`.
    public var primitiveValue: Primitive? {
        if case let .primitive(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `liveMap`, this returns the associated value. Else, it returns `nil`.
    public var liveMapValue: LiveMap? {
        if case let .liveMap(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` has case `liveCounter`, this returns the associated value. Else, it returns `nil`.
    public var liveCounterValue: LiveCounter? {
        if case let .liveCounter(value) = self {
            return value
        }
        return nil
    }

    /// If this `LiveMapValue` wraps a `string` primitive, this returns the associated value. Else, it returns `nil`.
    public var stringValue: String? { primitiveValue?.stringValue }

    /// If this `LiveMapValue` wraps a `number` primitive, this returns the associated value. Else, it returns `nil`.
    public var numberValue: Double? { primitiveValue?.numberValue }

    /// If this `LiveMapValue` wraps a `bool` primitive, this returns the associated value. Else, it returns `nil`.
    public var boolValue: Bool? { primitiveValue?.boolValue }

    /// If this `LiveMapValue` wraps a `data` primitive, this returns the associated value. Else, it returns `nil`.
    public var dataValue: Data? { primitiveValue?.dataValue }

    /// If this `LiveMapValue` wraps a `jsonArray` primitive, this returns the associated value. Else, it returns `nil`.
    public var jsonArrayValue: [JSONValue]? { primitiveValue?.jsonArrayValue }

    /// If this `LiveMapValue` wraps a `jsonObject` primitive, this returns the associated value. Else, it returns `nil`.
    public var jsonObjectValue: [String: JSONValue]? { primitiveValue?.jsonObjectValue }
}

// MARK: - ExpressibleBy*Literal conformances

extension LiveMapValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .primitive(.jsonObject(.init(uniqueKeysWithValues: elements)))
    }
}

extension LiveMapValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .primitive(.jsonArray(elements))
    }
}

extension LiveMapValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .primitive(.string(value))
    }
}

extension LiveMapValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .primitive(.number(Double(value)))
    }
}

extension LiveMapValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .primitive(.number(value))
    }
}

extension LiveMapValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .primitive(.bool(value))
    }
}
