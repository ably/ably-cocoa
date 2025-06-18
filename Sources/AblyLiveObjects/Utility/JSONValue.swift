import Ably
import Foundation

/// A JSON value (where "value" has the meaning defined by the [JSON specification](https://www.json.org)).
///
/// `JSONValue` provides a type-safe API for working with JSON values. It implements Swift's `ExpressibleBy*Literal` protocols. This allows you to write type-safe JSON values using familiar syntax. For example:
///
/// ```swift
/// let jsonValue: JSONValue = [
///     "someArray": [
///         [
///             "someStringKey": "someString",
///             "someIntegerKey": 123,
///             "someFloatKey": 123.456,
///             "someTrueKey": true,
///             "someFalseKey": false,
///             "someNullKey": .null,
///         ],
///         "someOtherArrayElement",
///     ],
///     "someNestedObject": [
///         "someOtherKey": "someOtherValue",
///     ],
/// ]
///  ```
///
/// > Note: To write a `JSONValue` that corresponds to the `null` JSON value, you must explicitly write `.null`. `JSONValue` deliberately does not implement the `ExpressibleByNilLiteral` protocol in order to avoid confusion between a value of type `JSONValue?` and a `JSONValue` with case `.null`.
internal indirect enum JSONValue: Sendable, Equatable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null

    // MARK: - Convenience getters for associated values

    /// If this `JSONValue` has case `object`, this returns the associated value. Else, it returns `nil`.
    internal var objectValue: [String: JSONValue]? {
        if case let .object(objectValue) = self {
            objectValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `array`, this returns the associated value. Else, it returns `nil`.
    internal var arrayValue: [JSONValue]? {
        if case let .array(arrayValue) = self {
            arrayValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `string`, this returns the associated value. Else, it returns `nil`.
    internal var stringValue: String? {
        if case let .string(stringValue) = self {
            stringValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `number`, this returns the associated value. Else, it returns `nil`.
    internal var numberValue: NSNumber? {
        if case let .number(numberValue) = self {
            numberValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `bool`, this returns the associated value. Else, it returns `nil`.
    internal var boolValue: Bool? {
        if case let .bool(boolValue) = self {
            boolValue
        } else {
            nil
        }
    }

    /// Returns true if and only if this `JSONValue` has case `null`.
    internal var isNull: Bool {
        if case .null = self {
            true
        } else {
            false
        }
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    internal init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(.init(uniqueKeysWithValues: elements))
    }
}

extension JSONValue: ExpressibleByArrayLiteral {
    internal init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByStringLiteral {
    internal init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    internal init(integerLiteral value: Int) {
        self = .number(value as NSNumber)
    }
}

extension JSONValue: ExpressibleByFloatLiteral {
    internal init(floatLiteral value: Double) {
        self = .number(value as NSNumber)
    }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    internal init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: - Bridging with JSONSerialization

internal extension JSONValue {
    /// Creates a `JSONValue` from the output of Foundation's `JSONSerialization`.
    ///
    /// This means that it accepts either:
    ///
    /// - The result of serializing an array or dictionary using `JSONSerialization`
    /// - Some nested element of the result of serializing such an array or dictionary
    init(jsonSerializationOutput: Any) {
        // swiftlint:disable:next trailing_closure
        let extended = ExtendedJSONValue<Never>(deserialized: jsonSerializationOutput, createExtraValue: { deserializedExtraValue in
            // JSONSerialization is not conforming to our assumptions; our assumptions are probably wrong. Either way, bring this loudly to our attention instead of trying to carry on
            preconditionFailure("JSONValue(jsonSerializationOutput:) was given unsupported value \(deserializedExtraValue)")
        })

        self.init(extendedJSONValue: extended)
    }

    /// Converts a `JSONValue` to an input for Foundation's `JSONSerialization`.
    ///
    /// This means that it returns:
    ///
    /// - All cases: An object which we can put inside an array or dictionary that we ask `JSONSerialization` to serialize
    /// - Additionally, if case `object` or `array`: An object which we can ask `JSONSerialization` to serialize
    var toJSONSerializationInputElement: Any {
        toExtendedJSONValue.serialized
    }
}

internal extension [String: JSONValue] {
    /// Converts a dictionary that has string keys and `JSONValue` values into an input for Foundation's `JSONSerialization`.
    var toJSONSerializationInput: [String: Any] {
        mapValues(\.toJSONSerializationInputElement)
    }
}

internal extension [JSONValue] {
    /// Converts an array that has `JSONValue` values into an input for Foundation's `JSONSerialization`.
    var toJSONSerializationInput: [Any] {
        map(\.toJSONSerializationInputElement)
    }
}

// MARK: - Conversion to/from ExtendedJSONValue

internal extension JSONValue {
    init(extendedJSONValue: ExtendedJSONValue<Never>) {
        switch extendedJSONValue {
        case let .object(underlying):
            self = .object(underlying.mapValues { .init(extendedJSONValue: $0) })
        case let .array(underlying):
            self = .array(underlying.map { .init(extendedJSONValue: $0) })
        case let .string(underlying):
            self = .string(underlying)
        case let .number(underlying):
            self = .number(underlying)
        case let .bool(underlying):
            self = .bool(underlying)
        case .null:
            self = .null
        }
    }

    var toExtendedJSONValue: ExtendedJSONValue<Never> {
        switch self {
        case let .object(underlying):
            .object(underlying.mapValues(\.toExtendedJSONValue))
        case let .array(underlying):
            .array(underlying.map(\.toExtendedJSONValue))
        case let .string(underlying):
            .string(underlying)
        case let .number(underlying):
            .number(underlying)
        case let .bool(underlying):
            .bool(underlying)
        case .null:
            .null
        }
    }
}
