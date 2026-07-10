/// An enum extracted from a wire representation that either belongs to one of a set of known values or is a new, unknown value.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum WireEnum<Known> where Known: RawRepresentable {
    case known(Known)
    case unknown(Known.RawValue)

    internal init(rawValue: Known.RawValue) {
        if let known = Known(rawValue: rawValue) {
            self = .known(known)
        } else {
            self = .unknown(rawValue)
        }
    }

    internal var rawValue: Known.RawValue {
        switch self {
        case let .known(known):
            known.rawValue
        case let .unknown(rawValue):
            rawValue
        }
    }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension WireEnum: Sendable where Known: Sendable, Known.RawValue: Sendable {}
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension WireEnum: Equatable where Known: Equatable, Known.RawValue: Equatable {}
