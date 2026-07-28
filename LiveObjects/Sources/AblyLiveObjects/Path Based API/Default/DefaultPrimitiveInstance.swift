import Ably

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultPrimitiveInstance: PrimitiveInstance {
    internal var value: Primitive {
        get throws(ARTErrorInfo) {
            notImplemented()
        }
    }

    internal var type: ValueType {
        notImplemented()
    }

    internal func compactJson() throws(ARTErrorInfo) -> JSONValue {
        notImplemented()
    }
}
