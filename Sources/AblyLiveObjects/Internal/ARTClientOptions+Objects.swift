internal import AblyPlugin

internal extension ARTClientOptions {
    private class Box<T> {
        internal let boxed: T

        internal init(boxed: T) {
            self.boxed = boxed
        }
    }

    private static let garbageCollectionOptionsKey = "Objects.garbageCollectionOptions"

    /// Can be overriden for testing purposes.
    var garbageCollectionOptions: InternalDefaultRealtimeObjects.GarbageCollectionOptions? {
        get {
            let optionsValue = PluginAPI.sharedInstance().pluginOptionsValue(
                forKey: Self.garbageCollectionOptionsKey,
                clientOptions: self,
            )

            guard let optionsValue else {
                return nil
            }

            guard let box = optionsValue as? Box<InternalDefaultRealtimeObjects.GarbageCollectionOptions> else {
                preconditionFailure("Expected GarbageCollectionOptionsBox, got \(optionsValue)")
            }

            return box.boxed
        }

        set {
            guard let newValue else {
                preconditionFailure("Not implemented the ability to un-set GC options")
            }

            PluginAPI.sharedInstance().setPluginOptionsValue(
                Box<InternalDefaultRealtimeObjects.GarbageCollectionOptions>(boxed: newValue),
                forKey: Self.garbageCollectionOptionsKey,
                clientOptions: self,
            )
        }
    }
}
