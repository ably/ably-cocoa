import Ably

/// Base class for the path-object skeletons. Conforms to ``PathObject`` and provides the members
/// common to every path-object view (and, via the ``PathObject`` extension, the `as*` helpers). The
/// typed subclasses (``DefaultLiveMapPathObject`` etc.) inherit these and add their type-specific
/// methods.
///
/// Non-`final` so it can be subclassed; `@unchecked Sendable` because a subclassable class cannot
/// receive a checked `Sendable` conformance. The skeletons hold no state, so this is safe.
internal class DefaultPathObject: PathObject, @unchecked Sendable {
    func path() -> String {
        notImplemented()
    }

    func instance() throws(ARTErrorInfo) -> (any Instance)? {
        notImplemented()
    }

    func compactJson() throws(ARTErrorInfo) -> JSONValue? {
        notImplemented()
    }

    @discardableResult
    func subscribe(options: PathObjectSubscriptionOptions?, listener: @escaping PathObjectSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        notImplemented()
    }
}
