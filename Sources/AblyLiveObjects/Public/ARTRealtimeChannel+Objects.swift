import Ably
internal import AblyPlugin

public extension ARTRealtimeChannel {
    /// An ``Objects`` object.
    var objects: Objects {
        internallyTypedObjects
    }

    private var internallyTypedObjects: DefaultObjects {
        DefaultInternalPlugin.objectsProperty(for: self, pluginAPI: AblyPlugin.PluginAPI.sharedInstance())
    }

    /// For tests to access the non-public API of `DefaultObjects`.
    internal var testsOnly_internallyTypedObjects: DefaultObjects {
        internallyTypedObjects
    }
}
