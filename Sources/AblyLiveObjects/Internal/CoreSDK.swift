import Ably
internal import AblyPlugin

/// The API that the internal components of the SDK (that is, `DefaultLiveObjects` and down) use to interact with our core SDK (i.e. ably-cocoa).
///
/// This provides us with a mockable interface to ably-cocoa, and it also allows internal components and their tests not to need to worry about some of the boring details of how we bridge Swift types to AblyPlugin's Objective-C API (i.e. boxing).
internal protocol CoreSDK: AnyObject, Sendable {
    func sendObject(objectMessages: [OutboundObjectMessage]) async throws(InternalError)

    /// Returns the current state of the Realtime channel that this wraps.
    var channelState: ARTRealtimeChannelState { get }
}

internal final class DefaultCoreSDK: CoreSDK {
    private let channel: AblyPlugin.RealtimeChannel
    private let client: AblyPlugin.RealtimeClient
    private let pluginAPI: PluginAPIProtocol

    internal init(
        channel: AblyPlugin.RealtimeChannel,
        client: AblyPlugin.RealtimeClient,
        pluginAPI: PluginAPIProtocol
    ) {
        self.channel = channel
        self.client = client
        self.pluginAPI = pluginAPI
    }

    // MARK: - CoreSDK conformance

    internal func sendObject(objectMessages: [OutboundObjectMessage]) async throws(InternalError) {
        try await DefaultInternalPlugin.sendObject(
            objectMessages: objectMessages,
            channel: channel,
            pluginAPI: pluginAPI,
        )
    }

    internal var channelState: ARTRealtimeChannelState {
        channel.state
    }
}
