import Ably

internal final class DefaultPrimitiveInstance: DefaultInstance, PrimitiveInstance, @unchecked Sendable {
    func value() throws(ARTErrorInfo) -> Primitive? {
        notImplemented()
    }
}
