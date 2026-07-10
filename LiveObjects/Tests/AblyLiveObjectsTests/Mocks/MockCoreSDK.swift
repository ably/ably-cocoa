import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects

final class MockCoreSDK: CoreSDK {
    /// Synchronizes access to `_publishHandler` and `_publishCallbackHandler`.
    private let mutex = NSLock()
    private nonisolated(unsafe) var _publishHandler: (([OutboundObjectMessage]) async throws(ARTErrorInfo) -> PublishResult)?
    private nonisolated(unsafe) var _publishCallbackHandler: (([OutboundObjectMessage], @escaping @Sendable (Result<PublishResult, ARTErrorInfo>) -> Void) -> Void)?

    private let channelStateMutex: DispatchQueueMutex<_AblyPluginSupportPrivate.RealtimeChannelState>
    private let serverTime: Date

    init(channelState: _AblyPluginSupportPrivate.RealtimeChannelState, serverTime: Date = .init(), internalQueue: DispatchQueue) {
        channelStateMutex = DispatchQueueMutex(dispatchQueue: internalQueue, initialValue: channelState)
        self.serverTime = serverTime
    }

    func nosync_publish(objectMessages: [OutboundObjectMessage], callback: @escaping @Sendable (Result<PublishResult, ARTErrorInfo>) -> Void) {
        // We can't return _publishHandler from `mutex.withLock` because we get "error: runtime support for typed throws function types is only available in macOS 15.0.0 or newer"
        var asyncHandler: (([OutboundObjectMessage]) async throws(ARTErrorInfo) -> PublishResult)?
        var callbackHandler: (([OutboundObjectMessage], @escaping @Sendable (Result<PublishResult, ARTErrorInfo>) -> Void) -> Void)?
        mutex.withLock {
            asyncHandler = _publishHandler
            callbackHandler = _publishCallbackHandler
        }

        if let callbackHandler {
            callbackHandler(objectMessages, callback)
        } else if let asyncHandler {
            let queue = channelStateMutex.dispatchQueue
            Task {
                do throws(ARTErrorInfo) {
                    let publishResult = try await asyncHandler(objectMessages)
                    queue.async { callback(.success(publishResult)) }
                } catch {
                    queue.async { callback(.failure(error)) }
                }
            }
        } else {
            protocolRequirementNotImplemented()
        }
    }

    func testsOnly_overridePublish(with _: @escaping ([OutboundObjectMessage]) async throws(ARTErrorInfo) -> PublishResult) {
        protocolRequirementNotImplemented()
    }

    var nosync_channelState: _AblyPluginSupportPrivate.RealtimeChannelState {
        channelStateMutex.withoutSync { $0 }
    }

    /// Sets a custom publish handler for testing.
    ///
    /// - Precondition: ``setPublishCallbackHandler(_:)`` must not have been called.
    func setPublishHandler(_ handler: @escaping ([OutboundObjectMessage]) async throws(ARTErrorInfo) -> PublishResult) {
        mutex.withLock {
            precondition(_publishCallbackHandler == nil, "Cannot set both publishHandler and publishCallbackHandler")
            _publishHandler = handler
        }
    }

    /// Sets a callback-based publish handler for testing.
    ///
    /// Unlike ``setPublishHandler(_:)``, this variant receives the publish callback directly,
    /// avoiding the `Task`-based dispatch used by the async variant. This makes it easier to
    /// control the ordering of side effects relative to the publish callback — the handler can
    /// dispatch the callback and follow-up work as separate blocks on the internal queue, giving
    /// explicit control over their ordering.
    ///
    /// - Precondition: ``setPublishHandler(_:)`` must not have been called.
    func setPublishCallbackHandler(_ handler: @escaping ([OutboundObjectMessage], @escaping @Sendable (Result<PublishResult, ARTErrorInfo>) -> Void) -> Void) {
        mutex.withLock {
            // We use pattern matching instead of `== nil` to avoid "runtime support for typed
            // throws function types is only available in macOS 15.0.0 or newer".
            if case .some = _publishHandler {
                preconditionFailure("Cannot set both publishHandler and publishCallbackHandler")
            }
            _publishCallbackHandler = handler
        }
    }

    func nosync_fetchServerTime(callback: @escaping @Sendable (Result<Date, ARTErrorInfo>) -> Void) {
        callback(.success(serverTime))
    }
}
