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
@available(macOS 11, iOS 14, tvOS 14, *)
public indirect enum JSONValue: Sendable, Equatable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
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
    public var numberValue: Double? {
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

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(.init(uniqueKeysWithValues: elements))
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: - Bridging with JSONSerialization

@available(macOS 11, iOS 14, tvOS 14, *)
internal extension JSONValue {
    /// Creates a `JSONValue` from the output of Foundation's `JSONSerialization`.
    ///
    /// This means that it accepts either:
    ///
    /// - The result of serializing an array or dictionary using `JSONSerialization`
    /// - Some nested element of the result of serializing such an array or dictionary
    init(jsonSerializationOutput: Any) {
        let extended = ExtendedJSONValue<Double, Never>(deserialized: jsonSerializationOutput, createNumberValue: { $0.doubleValue }, createExtraValue: { deserializedExtraValue in
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
        toExtendedJSONValue.serialized(serializeNumberValue: { $0 as NSNumber }, serializeExtraValue: { _ in })
    }
}

// MARK: - JSON objects and arrays

/// A subset of ``JSONValue`` that has only `object` or `array` cases.
@available(macOS 11, iOS 14, tvOS 14, *)
internal enum JSONObjectOrArray: Equatable {
    case object([String: JSONValue])
    case array([JSONValue])

    internal enum ConversionError: Swift.Error {
        case incompatibleJSONValue(JSONValue)
    }

    internal init(jsonValue: JSONValue) throws(ARTErrorInfo) {
        self = switch jsonValue {
        case let .array(array):
            .array(array)
        case let .object(object):
            .object(object)
        case .bool, .number, .string, .null:
            throw ConversionError.incompatibleJSONValue(jsonValue).toARTErrorInfo()
        }
    }

    // MARK: - Convenience getters for associated values

    /// If this `JSONObjectOrArray` has case `object`, this returns the associated value. Else, it returns `nil`.
    internal var objectValue: [String: JSONValue]? {
        if case let .object(value) = self {
            return value
        }
        return nil
    }

    /// If this `JSONObjectOrArray` has case `array`, this returns the associated value. Else, it returns `nil`.
    internal var arrayValue: [JSONValue]? {
        if case let .array(value) = self {
            return value
        }
        return nil
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONObjectOrArray: ExpressibleByDictionaryLiteral {
    internal init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(.init(uniqueKeysWithValues: elements))
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
extension JSONObjectOrArray: ExpressibleByArrayLiteral {
    internal init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
internal extension [String: JSONValue] {
    /// Converts a dictionary that has string keys and `JSONValue` values into an input for Foundation's `JSONSerialization`.
    var toJSONSerializationInput: [String: Any] {
        mapValues(\.toJSONSerializationInputElement)
    }
}

@available(macOS 11, iOS 14, tvOS 14, *)
internal extension [JSONValue] {
    /// Converts an array that has `JSONValue` values into an input for Foundation's `JSONSerialization`.
    var toJSONSerializationInput: [Any] {
        map(\.toJSONSerializationInputElement)
    }
}

// MARK: - Conversion to/from ExtendedJSONValue

@available(macOS 11, iOS 14, tvOS 14, *)
internal extension JSONValue {
    init(extendedJSONValue: ExtendedJSONValue<Double, Never>) {
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

    var toExtendedJSONValue: ExtendedJSONValue<Double, Never> {
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

@available(macOS 11, iOS 14, tvOS 14, *)
internal extension JSONObjectOrArray {
    enum DecodingError: Swift.Error {
        case incompatibleJSONValue(JSONValue)
    }

    /// Deserializes a JSON string into a `JSONObjectOrArray`. Throws an error if not given a valid JSON string.
    init(jsonString: String) throws(ARTErrorInfo) {
        let data = Data(jsonString.utf8)
        let jsonSerializationOutput: Any
        do {
            jsonSerializationOutput = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw LiveObjectsError.other(error).toARTErrorInfo()
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
