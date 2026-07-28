import Ably

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultLiveMapInstance: LiveMapInstance {
    internal var id: String {
        notImplemented()
    }

    internal func get(key _: String) throws(ARTErrorInfo) -> Instance? {
        notImplemented()
    }

    internal func entries() throws(ARTErrorInfo) -> [(key: String, value: Instance)] {
        notImplemented()
    }

    internal func keys() throws(ARTErrorInfo) -> [String] {
        notImplemented()
    }

    internal func values() throws(ARTErrorInfo) -> [Instance] {
        notImplemented()
    }

    internal var size: Int {
        get throws(ARTErrorInfo) {
            notImplemented()
        }
    }

    internal func set(key _: String, value _: LiveMapValue) async throws(ARTErrorInfo) {
        notImplemented()
    }

    internal func remove(key _: String) async throws(ARTErrorInfo) {
        notImplemented()
    }

    @discardableResult
    internal func subscribe(listener _: @escaping InstanceSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        notImplemented()
    }

    internal func compactJson() throws(ARTErrorInfo) -> JSONValue {
        notImplemented()
    }
}
