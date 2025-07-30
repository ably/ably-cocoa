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
public indirect enum JSONValue: Sendable, Equatable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null

    // MARK: - Convenience getters for associated values

    /// If this `JSONValue` has case `object`, this returns the associated value. Else, it returns `nil`.
    public var objectValue: [String: JSONValue]? {
        if case let .object(objectValue) = self {
            objectValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `array`, this returns the associated value. Else, it returns `nil`.
    public var arrayValue: [JSONValue]? {
        if case let .array(arrayValue) = self {
            arrayValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `string`, this returns the associated value. Else, it returns `nil`.
    public var stringValue: String? {
        if case let .string(stringValue) = self {
            stringValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `number`, this returns the associated value. Else, it returns `nil`.
    public var numberValue: NSNumber? {
        if case let .number(numberValue) = self {
            numberValue
        } else {
            nil
        }
    }

    /// If this `JSONValue` has case `bool`, this returns the associated value. Else, it returns `nil`.
    public var boolValue: Bool? {
        if case let .bool(boolValue) = self {
            boolValue
        } else {
            nil
        }
    }

    /// Returns true if and only if this `JSONValue` has case `null`.
    public var isNull: Bool {
        if case .null = self {
            true
        } else {
            false
        }
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(.init(uniqueKeysWithValues: elements))
    }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(value as NSNumber)
    }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value as NSNumber)
    }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
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

// MARK: - JSON objects and arrays

/// A subset of ``JSONValue`` that has only `object` or `array` cases.
internal enum JSONObjectOrArray: Equatable {
    case object([String: JSONValue])
    case array([JSONValue])

    internal enum ConversionError: Swift.Error {
        case incompatibleJSONValue(JSONValue)
    }

    internal init(jsonValue: JSONValue) throws(InternalError) {
        self = switch jsonValue {
        case let .array(array):
            .array(array)
        case let .object(object):
            .object(object)
        case .bool, .number, .string, .null:
            throw ConversionError.incompatibleJSONValue(jsonValue).toInternalError()
        }
    }
}

extension JSONObjectOrArray: ExpressibleByDictionaryLiteral {
    internal init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(.init(uniqueKeysWithValues: elements))
    }
}

extension JSONObjectOrArray: ExpressibleByArrayLiteral {
    internal init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
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

// MARK: Serializing to and deserializing from a JSON string

internal extension JSONObjectOrArray {
    enum DecodingError: Swift.Error {
        case incompatibleJSONValue(JSONValue)
    }

    /// Deserializes a JSON string into a `JSONObjectOrArray`. Throws an error if not given a valid JSON string.
    init(jsonString: String) throws(InternalError) {
        let data = Data(jsonString.utf8)
        let jsonSerializationOutput: Any
        do {
            jsonSerializationOutput = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw error.toInternalError()
        }

        let jsonValue = JSONValue(jsonSerializationOutput: jsonSerializationOutput)
        try self.init(jsonValue: jsonValue)
    }

    /// Converts a `JSONObjectOrArray` into an input for Foundation's `JSONSerialization`.
    private var toJSONSerializationInput: Any {
        switch self {
        case let .array(array):
            array.toJSONSerializationInput
        case let .object(object):
            object.toJSONSerializationInput
        }
    }

    /// Serializes a `JSONObjectOrArray` to a JSON string.
    var toJSONString: String {
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: toJSONSerializationInput)
        } catch {
            preconditionFailure("Unexpected error encoding to JSON: \(error)")
        }

        guard let string = String(data: data, encoding: .utf8) else {
            preconditionFailure("Unexpected failure to decode output of JSONSerialization as UTF-8")
        }

        return string
    }
}
