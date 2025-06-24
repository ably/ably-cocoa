import Ably
internal import AblyPlugin

public extension ARTRealtimeChannel {
    /// A ``RealtimeObjects`` object.
    var objects: RealtimeObjects {
        internallyTypedObjects
    }

    private var internallyTypedObjects: DefaultRealtimeObjects {
        DefaultInternalPlugin.objectsProperty(for: self, pluginAPI: AblyPlugin.PluginAPI.sharedInstance())
    }

    /// For tests to access the non-public API of `DefaultRealtimeObjects`.
    internal var testsOnly_internallyTypedObjects: DefaultRealtimeObjects {
        internallyTypedObjects
    }
}
