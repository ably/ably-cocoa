internal import _AblyPluginSupportPrivate
import Ably

public extension ARTRealtimeChannel {
    /// A ``RealtimeObjects`` object.
    var objects: RealtimeObjects {
        nonTypeErasedObjects
    }

    private var nonTypeErasedObjects: PublicDefaultRealtimeObjects {
        let pluginAPI = Plugin.defaultPluginAPI
        let underlyingObjects = pluginAPI.underlyingObjects(for: asPluginPublicRealtimeChannel)
        let internalObjects = DefaultInternalPlugin.realtimeObjects(for: underlyingObjects.channel, pluginAPI: pluginAPI)

        let pluginLogger = pluginAPI.logger(for: underlyingObjects.channel)
        let logger = DefaultLogger(pluginLogger: pluginLogger, pluginAPI: pluginAPI)

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
