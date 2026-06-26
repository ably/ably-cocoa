import Ably

internal final class DefaultLiveMapPathObject: DefaultPathObject, LiveMapPathObject, @unchecked Sendable {
    func get(key: String) -> any PathObject {
        notImplemented()
    }

    func at(path: String) -> any PathObject {
        notImplemented()
    }

    func entries() throws(ARTErrorInfo) -> [(key: String, value: any PathObject)] {
        notImplemented()
    }

    func keys() throws(ARTErrorInfo) -> [String] {
        notImplemented()
    }

    func values() throws(ARTErrorInfo) -> [any PathObject] {
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
}
