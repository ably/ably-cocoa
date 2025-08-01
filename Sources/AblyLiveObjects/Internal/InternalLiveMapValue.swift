import Foundation

/// Same as the public ``LiveMapValue`` type but with associated values of internal type.
internal enum InternalLiveMapValue: Sendable, Equatable {
    case primitive(PrimitiveObjectValue)
    case liveMap(InternalDefaultLiveMap)
    case liveCounter(InternalDefaultLiveCounter)

    // MARK: - Convenience getters for associated values

    /// If this `InternalLiveMapValue` has case `primitive`, this returns the associated value. Else, it returns `nil`.
    internal var primitiveValue: PrimitiveObjectValue? {
        if case let .primitive(value) = self {
            return value
        }
        return nil
    }

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

    /// If this `InternalLiveMapValue` has case `primitive` with a string value, this returns that value. Else, it returns `nil`.
    internal var stringValue: String? {
        primitiveValue?.stringValue
    }

    /// If this `InternalLiveMapValue` has case `primitive` with a number value, this returns that value. Else, it returns `nil`.
    internal var numberValue: Double? {
        primitiveValue?.numberValue
    }

    /// If this `InternalLiveMapValue` has case `primitive` with a boolean value, this returns that value. Else, it returns `nil`.
    internal var boolValue: Bool? {
        primitiveValue?.boolValue
    }

    /// If this `InternalLiveMapValue` has case `primitive` with a data value, this returns that value. Else, it returns `nil`.
    internal var dataValue: Data? {
        primitiveValue?.dataValue
    }

    /// If this `InternalLiveMapValue` has case `primitive` with a JSON array value, this returns that value. Else, it returns `nil`.
    internal var jsonArrayValue: [JSONValue]? {
        primitiveValue?.jsonArrayValue
    }

    /// If this `InternalLiveMapValue` has case `primitive` with a JSON object value, this returns that value. Else, it returns `nil`.
    internal var jsonObjectValue: [String: JSONValue]? {
        primitiveValue?.jsonObjectValue
    }

    // MARK: - Equatable Implementation

    internal static func == (lhs: InternalLiveMapValue, rhs: InternalLiveMapValue) -> Bool {
        switch lhs {
        case let .primitive(lhsValue):
            if case let .primitive(rhsValue) = rhs, lhsValue == rhsValue {
                return true
            }
        case let .liveMap(lhsMap):
            if case let .liveMap(rhsMap) = rhs, lhsMap === rhsMap {
                return true
            }
        case let .liveCounter(lhsCounter):
            if case let .liveCounter(rhsCounter) = rhs, lhsCounter === rhsCounter {
                return true
            }
        }

        return false
    }
}
