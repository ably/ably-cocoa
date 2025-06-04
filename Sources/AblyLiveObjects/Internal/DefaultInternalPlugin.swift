internal import AblyPlugin

// We explicitly import the NSObject class, else it seems to get transitively imported from  `internal import AblyPlugin`, leading to the error "Class cannot be declared public because its superclass is internal".
import ObjectiveC.NSObject

/// The default implementation of `AblyPlugin`'s `LiveObjectsInternalPluginProtocol`. Implements the interface that ably-cocoa uses to access the functionality provided by the LiveObjects plugin.
@objc
internal final class DefaultInternalPlugin: NSObject, AblyPlugin.LiveObjectsInternalPluginProtocol {
    private let pluginAPI: AblyPlugin.PluginAPIProtocol

    internal init(pluginAPI: AblyPlugin.PluginAPIProtocol) {
        self.pluginAPI = pluginAPI
    }

    // MARK: - Channel `objects` property

    /// The `pluginDataValue(forKey:channel:)` key that we use to store the value of the `ARTRealtimeChannel.objects` property.
    private static let pluginDataKey = "LiveObjects"

    /// Retrieves the value that should be returned by `ARTRealtimeChannel.objects`.
    ///
    /// We expect this value to have been previously set by ``prepare(_:)``.
    internal static func objectsProperty(for channel: ARTRealtimeChannel, pluginAPI: AblyPlugin.PluginAPIProtocol) -> DefaultLiveObjects {
        guard let pluginData = pluginAPI.pluginDataValue(forKey: pluginDataKey, channel: channel) else {
            // InternalPlugin.prepare was not called
            fatalError("To access LiveObjects functionality, you must pass the LiveObjects plugin in the client options when creating the ARTRealtime instance: `clientOptions.plugins = [.liveObjects: AblyLiveObjects.Plugin.self]`")
        }

        // swiftlint:disable:next force_cast
        return pluginData as! DefaultLiveObjects
    }

    // MARK: - LiveObjectsInternalPluginProtocol

    // Populates the channel's `objects` property.
    internal func prepare(_ channel: ARTRealtimeChannel) {
        let logger = pluginAPI.logger(for: channel)

        logger.log("LiveObjects.DefaultInternalPlugin received prepare(_:)", level: .debug)
        let liveObjects = DefaultLiveObjects(channel: channel, logger: logger, pluginAPI: pluginAPI)
        pluginAPI.setPluginDataValue(liveObjects, forKey: Self.pluginDataKey, channel: channel)
    }
}
