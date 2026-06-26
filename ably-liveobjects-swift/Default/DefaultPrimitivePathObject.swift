import Ably

internal final class DefaultPrimitivePathObject: DefaultPathObject, PrimitivePathObject, @unchecked Sendable {
    func value() throws(ARTErrorInfo) -> Primitive? {
        notImplemented()
    }
}
