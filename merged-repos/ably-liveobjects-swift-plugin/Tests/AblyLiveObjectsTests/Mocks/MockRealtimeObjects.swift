import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects

final class MockRealtimeObjects: InternalRealtimeObjectsProtocol {
    private let objectsPoolDelegate: MockLiveMapObjectsPoolDelegate?

    /// Synchronizes access to `_publishAndApplyHandler`.
    private let mutex = NSLock()
    private nonisolated(unsafe) var _publishAndApplyHandler: (([OutboundObjectMessage]) -> Result<Void, ARTErrorInfo>)?

    init(objectsPoolDelegate: MockLiveMapObjectsPoolDelegate? = nil) {
        self.objectsPoolDelegate = objectsPoolDelegate
    }

    var nosync_objectsPool: ObjectsPool {
        guard let objectsPoolDelegate else {
            preconditionFailure("MockRealtimeObjects was not initialised with an objectsPoolDelegate")
        }
        return objectsPoolDelegate.nosync_objectsPool
    }

    func setPublishAndApplyHandler(_ handler: @escaping ([OutboundObjectMessage]) -> Result<Void, ARTErrorInfo>) {
        mutex.withLock {
            _publishAndApplyHandler = handler
        }
    }

    func nosync_publishAndApply(
        objectMessages: [OutboundObjectMessage],
        coreSDK: CoreSDK,
        callback: @escaping @Sendable (Result<Void, ARTErrorInfo>) -> Void,
    ) {
        var handler: (([OutboundObjectMessage]) -> Result<Void, ARTErrorInfo>)?
        mutex.withLock {
            handler = _publishAndApplyHandler
        }

        if let handler {
            callback(handler(objectMessages))
        } else {
            callback(.success(()))
        }
    }
}
