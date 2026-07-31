import Ably

/// Default implementation of ``PrimitivePathObject`` (Kotlin's six `Default*PathObject` primitive
/// types, collapsed into one per DEV-2), a terminal primitive view adding a type-narrowed ``value()``
/// on top of ``DefaultPathObject``.
///
/// Spec: `RTTS6c`.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultPrimitivePathObject: DefaultPathObject, PrimitivePathObject, @unchecked Sendable {
    internal func value() throws(ARTErrorInfo) -> Primitive? {
        try ChannelConfigGuards.throwIfInvalidAccessApiConfiguration(coreSDK: coreSDK, internalQueue: internalQueue)
        // Unresolved path -> nil.
        guard let resolved = try resolveValueAtCurrentPath() else {
            return nil
        }
        // DEV-2: unlike ably-java's six type-filtered primitive views, this returns whatever primitive
        // resolved (RTTS6c collapse). A live object (map/counter) is not a primitive -> nil.
        switch resolved {
        case let .string(value):
            return .string(value)
        case let .number(value):
            return .number(value)
        case let .bool(value):
            return .bool(value)
        case let .data(value):
            return .data(value)
        case let .jsonArray(value):
            return .jsonArray(value)
        case let .jsonObject(value):
            return .jsonObject(value)
        case .liveMap, .liveCounter:
            return nil
        }
    }
}
