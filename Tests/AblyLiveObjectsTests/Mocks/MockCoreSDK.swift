import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects

final class MockCoreSDK: CoreSDK {
    /// Synchronizes access to `_publishHandler`.
    private let mutex = NSLock()
    private nonisolated(unsafe) var _publishHandler: (([OutboundObjectMessage]) async throws(ARTErrorInfo) -> Void)?

    private let channelStateMutex: DispatchQueueMutex<_AblyPluginSupportPrivate.RealtimeChannelState>
    private let serverTime: Date

    init(channelState: _AblyPluginSupportPrivate.RealtimeChannelState, serverTime: Date = .init(), internalQueue: DispatchQueue) {
        channelStateMutex = DispatchQueueMutex(dispatchQueue: internalQueue, initialValue: channelState)
        self.serverTime = serverTime
    }

    func publish(objectMessages: [OutboundObjectMessage]) async throws(ARTErrorInfo) {
        if let handler = _publishHandler {
            try await handler(objectMessages)
        } else {
            protocolRequirementNotImplemented()
        }
    }

    func testsOnly_overridePublish(with _: @escaping ([OutboundObjectMessage]) async throws(ARTErrorInfo) -> Void) {
        protocolRequirementNotImplemented()
    }

    var nosync_channelState: _AblyPluginSupportPrivate.RealtimeChannelState {
        channelStateMutex.withoutSync { $0 }
    }

    /// Sets a custom publish handler for testing
    func setPublishHandler(_ handler: @escaping ([OutboundObjectMessage]) async throws(ARTErrorInfo) -> Void) {
        mutex.withLock {
            _publishHandler = handler
        }
    }

    func fetchServerTime() async throws(ARTErrorInfo) -> Date {
        serverTime
    }
}
