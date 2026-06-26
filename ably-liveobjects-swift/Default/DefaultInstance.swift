import Ably

/// Base class for the instance skeletons. Conforms to ``Instance`` and provides the common member
/// (and, via the ``Instance`` extension, the `as*` helpers). The typed subclasses
/// (``DefaultLiveMapInstance`` etc.) inherit these and add their type-specific methods.
///
/// Non-`final` so it can be subclassed; `@unchecked Sendable` because a subclassable class cannot
/// receive a checked `Sendable` conformance. The skeletons hold no state, so this is safe.
internal class DefaultInstance: Instance, @unchecked Sendable {
    func compactJson() throws(ARTErrorInfo) -> JSONValue? {
        notImplemented()
    }
}
