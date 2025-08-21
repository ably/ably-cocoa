import Foundation

/// Same as the public ``LiveMapValue`` type but with associated values of internal type.
internal enum InternalLiveMapValue: Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case data(Data)
    case jsonArray([JSONValue])
    case jsonObject([String: JSONValue])
    case liveMap(InternalDefaultLiveMap)
    case liveCounter(InternalDefaultLiveCounter)

    // MARK: - Creating from a public LiveMapValue

    /// Converts a public ``LiveMapValue`` into an ``InternalLiveMapValue``.
    ///
    /// Needed in order to access the internals of user-provided LiveObject-valued LiveMap entries to extract their object ID.
    internal init(liveMapValue: LiveMapValue) {
        switch liveMapValue {
        case let .string(value):
            self = .string(value)
        case let .number(value):
            self = .number(value)
        case let .bool(value):
            self = .bool(value)
        case let .data(value):
            self = .data(value)
        case let .jsonArray(value):
            self = .jsonArray(value)
        case let .jsonObject(value):
            self = .jsonObject(value)
        case let .liveMap(publicLiveMap):
            guard let publicDefaultLiveMap = publicLiveMap as? PublicDefaultLiveMap else {
                // TODO: Try and remove this runtime check and know this type statically, see https://github.com/ably/ably-liveobjects-swift-plugin/issues/37
                preconditionFailure("Expected PublicDefaultLiveMap, got \(publicLiveMap)")
            }
            self = .liveMap(publicDefaultLiveMap.proxied)
        case let .liveCounter(publicLiveCounter):
            guard let publicDefaultLiveCounter = publicLiveCounter as? PublicDefaultLiveCounter else {
                // TODO: Try and remove this runtime check and know this type statically, see https://github.com/ably/ably-liveobjects-swift-plugin/issues/37
                preconditionFailure("Expected PublicDefaultLiveCounter, got \(publicLiveCounter)")
            }
            self = .liveCounter(publicDefaultLiveCounter.proxied)
        }
    }

    // MARK: - Representation in the Realtime protocol

    /// Converts an `InternalLiveMapValue` to the value that should be used when creating or updating a map entry in the Realtime protocol, per the rules of RTO11f4 and RTLM20e4.
    internal var toObjectData: ObjectData {
        // RTO11f4c1: Create an ObjectsMapEntry for the current value
        switch self {
        case let .bool(value):
            .init(boolean: value)
        case let .data(value):
            .init(bytes: value)
        case let .number(value):
            .init(number: NSNumber(value: value))
        case let .string(value):
            .init(string: value)
        case let .jsonArray(value):
            .init(json: .array(value))
        case let .jsonObject(value):
            .init(json: .object(value))
        case let .liveMap(liveMap):
            // RTO11f4c1a: If the value is of type LiveMap, set ObjectsMapEntry.data.objectId to the objectId of that object
            .init(objectId: liveMap.objectID)
        case let .liveCounter(liveCounter):
            // RTO11f4c1a: If the value is of type LiveCounter, set ObjectsMapEntry.data.objectId to the objectId of that object
            .init(objectId: liveCounter.objectID)
        }
    }

    // MARK: - Convenience getters for associated values

    /// If this `InternalLiveMapValue` has case `liveMap`, this returns the associated value. Else, it returns `nil`.
    internal var liveMapValue: InternalDefaultLiveMap? {
        if case let .liveMap(value) = self {
            return value
        }
        return nil
    }

    /// If this `InternalLiveMapValue` has case `liveCounter`, this returns the associated value. Else, it returns `nil`.
    internal var liveCounterValue: InternalDefaultLiveCounter? {
        if case let .liveCounter(value) = self {
            return value
        }
        return nil
    }

    /// If this `InternalLiveMapValue` has case `string`, this returns that value. Else, it returns `nil`.
    internal var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }

    /// If this `InternalLiveMapValue` has case `number`, this returns that value. Else, it returns `nil`.
    internal var numberValue: Double? {
        if case let .number(value) = self {
            return value
        }
        return nil
    }

    /// If this `InternalLiveMapValue` has case `bool`, this returns that value. Else, it returns `nil`.
    internal var boolValue: Bool? {
        if case let .bool(value) = self {
            return value
        }
        return nil
    }

    /// If this `InternalLiveMapValue` has case `data`, this returns that value. Else, it returns `nil`.
    internal var dataValue: Data? {
        if case let .data(value) = self {
            return value
        }
        return nil
    }

    /// If this `InternalLiveMapValue` has case `jsonArray`, this returns that value. Else, it returns `nil`.
    internal var jsonArrayValue: [JSONValue]? {
        if case let .jsonArray(value) = self {
            return value
        }
        return nil
    }

    /// If this `InternalLiveMapValue` has case `jsonObject`, this returns that value. Else, it returns `nil`.
    internal var jsonObjectValue: [String: JSONValue]? {
        if case let .jsonObject(value) = self {
            return value
        }
        return nil
    }

    // MARK: - Equatable Implementation

    internal static func == (lhs: InternalLiveMapValue, rhs: InternalLiveMapValue) -> Bool {
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
