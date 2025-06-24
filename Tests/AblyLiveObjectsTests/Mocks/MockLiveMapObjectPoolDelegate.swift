@testable import AblyLiveObjects
import Foundation

/// A mock delegate that can return predefined objects
final class MockLiveMapObjectPoolDelegate: LiveMapObjectPoolDelegate {
    private let mutex = NSLock()
    private nonisolated(unsafe) var _objects: [String: ObjectsPool.Entry] = [:]
    var objects: [String: ObjectsPool.Entry] {
        get {
            mutex.withLock {
                _objects
            }
        }

        set {
            mutex.withLock {
                _objects = newValue
            }
        }
    }

    func getObjectFromPool(id: String) -> ObjectsPool.Entry? {
        objects[id]
    }
}
