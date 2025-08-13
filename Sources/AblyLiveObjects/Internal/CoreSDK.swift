import Ably
internal import AblyPlugin

/// The API that the internal components of the SDK (that is, `DefaultLiveObjects` and down) use to interact with our core SDK (i.e. ably-cocoa).
///
/// This provides us with a mockable interface to ably-cocoa, and it also allows internal components and their tests not to need to worry about some of the boring details of how we bridge Swift types to AblyPlugin's Objective-C API (i.e. boxing).
internal protocol CoreSDK: AnyObject, Sendable {
    /// Implements the internal `#publish` method of RTO15.
    func publish(objectMessages: [OutboundObjectMessage]) async throws(InternalError)

    /// Returns the current state of the Realtime channel that this wraps.
    var channelState: ARTRealtimeChannelState { get }
}

internal final class DefaultCoreSDK: CoreSDK {
    private let channel: AblyPlugin.RealtimeChannel
    private let client: AblyPlugin.RealtimeClient
    private let pluginAPI: PluginAPIProtocol
    private let logger: AblyPlugin.Logger

    internal init(
        channel: AblyPlugin.RealtimeChannel,
        client: AblyPlugin.RealtimeClient,
        pluginAPI: PluginAPIProtocol,
        logger: AblyPlugin.Logger
    ) {
        self.channel = channel
        self.client = client
        self.pluginAPI = pluginAPI
        self.logger = logger
    }

    // MARK: - CoreSDK conformance

    internal func publish(objectMessages: [OutboundObjectMessage]) async throws(InternalError) {
        logger.log("publish(objectMessages: \(LoggingUtilities.formatObjectMessagesForLogging(objectMessages)))", level: .debug)

        // TODO: Implement the full spec of RTO15 (https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/47)
        try await DefaultInternalPlugin.sendObject(
            objectMessages: objectMessages,
            channel: channel,
            client: client,
            pluginAPI: pluginAPI,
        )
    }

    internal var channelState: ARTRealtimeChannelState {
        channel.state
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
    func validateChannelState(
        notIn invalidStates: [ARTRealtimeChannelState],
        operationDescription: String,
    ) throws(ARTErrorInfo) {
        let currentChannelState = channelState
        if invalidStates.contains(currentChannelState) {
            throw LiveObjectsError.objectsOperationFailedInvalidChannelState(
                operationDescription: operationDescription,
                channelState: currentChannelState,
            )
            .toARTErrorInfo()
        }
    }
}
