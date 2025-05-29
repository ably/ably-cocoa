import Ably
internal import AblyPlugin

public extension ARTRealtimeChannel {
    /// An ``Objects`` object.
    var objects: Objects {
        DefaultInternalPlugin.objectsProperty(for: self, pluginAPI: AblyPlugin.PluginAPI.sharedInstance())
    }
}
