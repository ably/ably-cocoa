internal import _AblyPluginSupportPrivate
import Ably

/// The API that the internal components of the SDK (that is, `DefaultLiveObjects` and down) use to interact with our core SDK (i.e. ably-cocoa).
///
/// This provides us with a mockable interface to ably-cocoa, and it also allows internal components and their tests not to need to worry about some of the boring details of how we bridge Swift types to `_AblyPluginSupportPrivate`'s Objective-C API (i.e. boxing).
internal protocol CoreSDK: AnyObject, Sendable {
    /// Implements the internal `#publish` method of RTO15.
    func nosync_publish(objectMessages: [OutboundObjectMessage], callback: @escaping @Sendable (Result<PublishResult, ARTErrorInfo>) -> Void)

    /// Implements the server time fetch of RTO16, including the storing and usage of the local clock offset.
    func nosync_fetchServerTime(callback: @escaping @Sendable (Result<Date, ARTErrorInfo>) -> Void)

    /// Replaces the implementation of ``nosync_publish(objectMessages:callback:)``.
    ///
    /// Used by integration tests, for example to disable `ObjectMessage` publishing so that a test can verify that a behaviour is not a side effect of an `ObjectMessage` sent by the SDK.
    func testsOnly_overridePublish(with newImplementation: @escaping ([OutboundObjectMessage]) async throws(ARTErrorInfo) -> PublishResult)

    /// Returns the current state of the Realtime channel that this wraps.
    var nosync_channelState: _AblyPluginSupportPrivate.RealtimeChannelState { get }
}

internal final class DefaultCoreSDK: CoreSDK {
    /// Used to synchronize access to internal mutable state.
    private let mutex = NSLock()

    private let channel: _AblyPluginSupportPrivate.RealtimeChannel
    private let client: _AblyPluginSupportPrivate.RealtimeClient
    private let pluginAPI: PluginAPIProtocol
    private let logger: Logger

    /// If set, ``publish(objectMessages:)`` delegates to this implementation.
    ///
    /// This enables the `testsOnly_overridePublish(with:)` test hook.
    ///
    /// - Note: This should be `throws(ARTErrorInfo)` but that causes a compilation error of "Runtime support for typed throws function types is only available in macOS 15.0.0 or newer".
    private nonisolated(unsafe) var overriddenPublishImplementation: (([OutboundObjectMessage]) async throws -> PublishResult)?

    internal init(
        channel: _AblyPluginSupportPrivate.RealtimeChannel,
        client: _AblyPluginSupportPrivate.RealtimeClient,
        pluginAPI: PluginAPIProtocol,
        logger: Logger
    ) {
        self.channel = channel
        self.client = client
        self.pluginAPI = pluginAPI
        self.logger = logger
    }

    // MARK: - CoreSDK conformance

    internal func nosync_publish(objectMessages: [OutboundObjectMessage], callback: @escaping @Sendable (Result<PublishResult, ARTErrorInfo>) -> Void) {
        logger.log("nosync_publish(objectMessages: \(LoggingUtilities.formatObjectMessagesForLogging(objectMessages)))", level: .debug)

        // Use the overridden implementation if supplied
        let overriddenImplementation = mutex.withLock {
            overriddenPublishImplementation
        }
        if let overriddenImplementation {
            let queue = pluginAPI.internalQueue(for: client)
            Task {
                do {
                    let publishResult = try await overriddenImplementation(objectMessages)
                    queue.async { callback(.success(publishResult)) }
                } catch {
                    guard let artErrorInfo = error as? ARTErrorInfo else {
                        preconditionFailure("Expected ARTErrorInfo, got \(error)")
                    }
                    queue.async { callback(.failure(artErrorInfo)) }
                }
            }
            return
        }

        // TODO: Implement message size checking (https://github.com/ably/ably-liveobjects-swift-plugin/issues/13)
        DefaultInternalPlugin.nosync_sendObject(
            objectMessages: objectMessages,
            channel: channel,
            client: client,
            pluginAPI: pluginAPI,
            callback: callback,
        )
    }

    internal func testsOnly_overridePublish(with newImplementation: @escaping ([OutboundObjectMessage]) async throws(ARTErrorInfo) -> PublishResult) {
        mutex.withLock {
            overriddenPublishImplementation = newImplementation
        }
    }

    internal func nosync_fetchServerTime(callback: @escaping @Sendable (Result<Date, ARTErrorInfo>) -> Void) {
        let internalQueue = pluginAPI.internalQueue(for: client)

        pluginAPI.nosync_fetchServerTime(for: client) { serverTime, error in
            dispatchPrecondition(condition: .onQueue(internalQueue))

            if let error {
                callback(.failure(ARTErrorInfo.castPluginPublicErrorInfo(error)))
            } else {
                guard let serverTime else {
                    preconditionFailure("nosync_fetchServerTime gave nil serverTime and nil error")
                }
                callback(.success(serverTime))
            }
        }
    }

    internal var nosync_channelState: _AblyPluginSupportPrivate.RealtimeChannelState {
        pluginAPI.nosync_state(for: channel)
    }
}

// MARK: - Channel State Validation

/// Extension on CoreSDK to provide channel state validation utilities.
internal extension CoreSDK {
    /// Validates that the channel is not in any of the specified invalid states.
    ///
    /// - Parameters:
    ///   - invalidStates: Array of channel states that are considered invalid for the operation
    ///   - operationDescription: A description of the operation being performed, used in error messages
    /// - Throws: `ARTErrorInfo` with code 90001 and statusCode 400 if the channel is in any of the invalid states
    func nosync_validateChannelState(
        notIn invalidStates: [_AblyPluginSupportPrivate.RealtimeChannelState],
        operationDescription: String,
    ) throws(ARTErrorInfo) {
        let currentChannelState = nosync_channelState
        if invalidStates.contains(currentChannelState) {
            throw LiveObjectsError.objectsOperationFailedInvalidChannelState(
                operationDescription: operationDescription,
                channelState: currentChannelState,
            )
            .toARTErrorInfo()
        }
    }
}
