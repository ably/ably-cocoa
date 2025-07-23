import Foundation

/// Like ``JSONValue``, but provides an additional case named `extra`, which allows you to support additional types of data. It's used as a common base for the implementations of ``JSONValue`` and ``WireValue``, and for converting between them.
internal indirect enum ExtendedJSONValue<Extra> {
    case object([String: Self])
    case array([Self])
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null
    case extra(Extra)
}

// MARK: - Bridging with Foundation

internal extension ExtendedJSONValue {
    /// Creates an `ExtendedJSONValue` from an object.
    ///
    /// The rules for what `deserialized` will accept are the same as those of `JSONValue.init(jsonSerializationOutput)`, with one addition: any nonsupported values are passed to the `createExtraValue` function, and the result of this function will be used to create an `ExtendedJSONValue` of case `.extra`.
    init(deserialized: Any, createExtraValue: (Any) -> Extra) {
        switch deserialized {
        case let dictionary as [String: Any]:
            self = .object(dictionary.mapValues { .init(deserialized: $0, createExtraValue: createExtraValue) })
        case let array as [Any]:
            self = .array(array.map { .init(deserialized: $0, createExtraValue: createExtraValue) })
        case let string as String:
            self = .string(string)
        case let number as NSNumber:
            // We need to be careful to distinguish booleans from numbers of value 0 or 1; technique taken from https://forums.swift.org/t/jsonserialization-turns-bool-value-to-nsnumber/31909/3
            if number === kCFBooleanTrue {
                self = .bool(true)
            } else if number === kCFBooleanFalse {
                self = .bool(false)
            } else {
                self = .number(number)
            }
        case is NSNull:
            self = .null
        default:
            self = .extra(createExtraValue(deserialized))
        }
    }

    /// Converts an `ExtendedJSONValue` to an object.
    ///
    /// The contract for what this will return are the same as those of `JSONValue.toJSONSerializationInputElemtn`, with one addition: any values in the input of case `.extra` will be passed to the `serializeExtraValue` function, and the result of this function call will be inserted into the output object.
    func serialized(serializeExtraValue: (Extra) -> Any) -> Any {
        switch self {
        case let .object(underlying):
            underlying.mapValues { $0.serialized(serializeExtraValue: serializeExtraValue) }
        case let .array(underlying):
            underlying.map { $0.serialized(serializeExtraValue: serializeExtraValue) }
        case let .string(underlying):
            underlying
        case let .number(underlying):
            underlying
        case let .bool(underlying):
            underlying
        case .null:
            NSNull()
        case let .extra(extra):
            serializeExtraValue(extra)
        }
    }
}

internal extension ExtendedJSONValue where Extra == Never {
    var serialized: Any {
        // swiftlint:disable:next trailing_closure
        serialized(serializeExtraValue: { _ in })
    }
}

// MARK: - Transforming the extra data

internal extension ExtendedJSONValue {
    /// Converts this `ExtendedJSONValue<Extra>` to an `ExtendedJSONValue<NewExtra>` using a given transformation.
    func map<NewExtra, Failure>(_ transform: @escaping (Extra) throws(Failure) -> NewExtra) throws(Failure) -> ExtendedJSONValue<NewExtra> {
        switch self {
        case let .object(underlying):
            try .object(underlying.ablyLiveObjects_mapValuesWithTypedThrow { value throws(Failure) in
                try value.map(transform)
            })
        case let .array(underlying):
            try .array(underlying.map { element throws(Failure) in
                try element.map(transform)
            })
        case let .string(underlying):
            .string(underlying)
        case let .number(underlying):
            .number(underlying)
        case let .bool(underlying):
            .bool(underlying)
        case .null:
            .null
        case let .extra(extra):
            try .extra(transform(extra))
        }
    }
}
