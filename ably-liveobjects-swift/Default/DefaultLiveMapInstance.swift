import Ably

internal final class DefaultLiveMapInstance: DefaultInstance, LiveMapInstance, @unchecked Sendable {
    var id: String {
        notImplemented()
    }

    func get(key: String) throws(ARTErrorInfo) -> (any Instance)? {
        notImplemented()
    }

    func entries() throws(ARTErrorInfo) -> [(key: String, value: any Instance)] {
        notImplemented()
    }

    func keys() throws(ARTErrorInfo) -> [String] {
        notImplemented()
    }

    func values() throws(ARTErrorInfo) -> [any Instance] {
        notImplemented()
    }

    func size() throws(ARTErrorInfo) -> Int? {
        notImplemented()
    }

    func set(key: String, value: LiveMapValue) async throws(ARTErrorInfo) {
        notImplemented()
    }

    func remove(key: String) async throws(ARTErrorInfo) {
        notImplemented()
    }

    @discardableResult
    func subscribe(listener: @escaping InstanceSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        notImplemented()
    }
}
