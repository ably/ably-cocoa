import Ably
internal import AblyPlugin

public extension ARTRealtimeChannel {
    /// A ``RealtimeObjects`` object.
    var objects: RealtimeObjects {
        nonTypeErasedObjects
    }

    private var nonTypeErasedObjects: PublicDefaultRealtimeObjects {
        let pluginAPI = Plugin.defaultPluginAPI
        let underlyingObjects = pluginAPI.underlyingObjects(forPublicRealtimeChannel: self)
        let internalObjects = DefaultInternalPlugin.realtimeObjects(for: underlyingObjects.channel, pluginAPI: pluginAPI)

        let logger = pluginAPI.logger(for: underlyingObjects.channel)

        let coreSDK = DefaultCoreSDK(
            channel: underlyingObjects.channel,
            client: underlyingObjects.client,
            pluginAPI: Plugin.defaultPluginAPI,
            logger: logger,
        )

        return PublicObjectsStore.shared.getOrCreateRealtimeObjects(
            proxying: internalObjects,
            creationArgs: .init(
                coreSDK: coreSDK,
                logger: logger,
            ),
        )
    }

    /// For tests to access the non-public API of `PublicDefaultRealtimeObjects`.
    internal var testsOnly_nonTypeErasedObjects: PublicDefaultRealtimeObjects {
        nonTypeErasedObjects
    }
}
