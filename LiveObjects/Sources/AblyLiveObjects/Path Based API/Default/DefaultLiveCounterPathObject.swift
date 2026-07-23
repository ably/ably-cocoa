import Ably

/// Skeleton implementation of ``LiveCounterPathObject``. Every member currently traps via
/// `notImplemented()`; this is a standalone `final class` (no shared base) so that we don't commit to
/// a particular implementation shape before the path-based API is actually built. `Sendable` is a
/// checked conformance: the class holds no state.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultLiveCounterPathObject: LiveCounterPathObject, Sendable {
    // MARK: - PathObject

    internal var path: String {
        notImplemented()
    }

    internal func instance() throws(ARTErrorInfo) -> Instance? {
        notImplemented()
    }

    internal func compactJson() throws(ARTErrorInfo) -> JSONValue? {
        notImplemented()
    }

    @discardableResult
    internal func subscribe(options _: PathObjectSubscriptionOptions?, listener _: @escaping PathObjectSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        notImplemented()
    }

    internal func exists() throws(ARTErrorInfo) -> Bool {
        notImplemented()
    }

    internal func type() throws(ARTErrorInfo) -> ValueType? {
        notImplemented()
    }

    internal func asLiveMap() -> any LiveMapPathObject {
        notImplemented()
    }

    internal func asLiveCounter() -> any LiveCounterPathObject {
        notImplemented()
    }

    internal func asPrimitive() -> any PrimitivePathObject {
        notImplemented()
    }

    // MARK: - LiveCounterPathObject

    internal func value() throws(ARTErrorInfo) -> Double? {
        notImplemented()
    }

    internal func increment(amount _: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }

    internal func decrement(amount _: Double) async throws(ARTErrorInfo) {
        notImplemented()
    }
}
