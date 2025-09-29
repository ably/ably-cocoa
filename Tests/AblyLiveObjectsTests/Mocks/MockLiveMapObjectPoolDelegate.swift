@testable import AblyLiveObjects
import Foundation

/// A mock delegate that can return predefined objects
final class MockLiveMapObjectPoolDelegate: LiveMapObjectPoolDelegate {
    private let objectsMutex: DispatchQueueMutex<[String: ObjectsPool.Entry]>

    init(internalQueue: DispatchQueue) {
        objectsMutex = DispatchQueueMutex(dispatchQueue: internalQueue, initialValue: [:])
    }

    var objects: [String: ObjectsPool.Entry] {
        get {
            objectsMutex.withSync { $0 }
        }
        set {
            objectsMutex.withSync { $0 = newValue }
        }
    }

    func nosync_getObjectFromPool(id: String) -> ObjectsPool.Entry? {
        objectsMutex.withoutSync { $0[id] }
    }
}
