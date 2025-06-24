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
    // We hold a weak reference to the channel so that `DefaultLiveObjects` can hold a strong reference to us without causing a strong reference cycle. We'll revisit this in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/9.
    private let weakChannel: WeakRef<ARTRealtimeChannel>
    private let pluginAPI: PluginAPIProtocol

    internal init(
        channel: ARTRealtimeChannel,
        pluginAPI: PluginAPIProtocol
    ) {
        weakChannel = .init(referenced: channel)
        self.pluginAPI = pluginAPI
    }

    // MARK: - Fetching channel

    private var channel: ARTRealtimeChannel {
        guard let channel = weakChannel.referenced else {
            // It's currently completely possible that the channel _does_ become deallocated during the usage of the LiveObjects SDK; in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/9 we'll figure out how to prevent this.
            preconditionFailure("Expected channel to not become deallocated during usage of LiveObjects SDK")
        }

        return channel
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
