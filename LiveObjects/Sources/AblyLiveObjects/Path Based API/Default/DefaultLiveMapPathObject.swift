import Ably

/// Skeleton implementation of ``LiveMapPathObject``. Every member currently traps via
/// `notImplemented()`; this is a standalone `final class` (no shared base) so that we don't commit to
/// a particular implementation shape before the path-based API is actually built. `Sendable` is a
/// checked conformance: the class holds no state.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultLiveMapPathObject: LiveMapPathObject, Sendable {
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

    // MARK: - LiveMapPathObject

    internal func get(key _: String) -> any PathObject {
        notImplemented()
    }

    internal func at(path _: String) -> any PathObject {
        notImplemented()
    }

    internal func entries() throws(ARTErrorInfo) -> [(key: String, value: any PathObject)] {
        notImplemented()
    }

    internal func keys() throws(ARTErrorInfo) -> [String] {
        notImplemented()
    }

    internal func values() throws(ARTErrorInfo) -> [any PathObject] {
        notImplemented()
    }

    internal func size() throws(ARTErrorInfo) -> Int? {
        notImplemented()
    }

    internal func set(key _: String, value _: LiveMapValue) async throws(ARTErrorInfo) {
        notImplemented()
    }

    internal func remove(key _: String) async throws(ARTErrorInfo) {
        notImplemented()
    }
}
