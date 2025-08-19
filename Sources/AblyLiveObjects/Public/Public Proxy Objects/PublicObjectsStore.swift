internal import _AblyPluginSupportPrivate
import Foundation

/// Stores the public objects that wrap the SDK's internal components.
///
/// This allows us to provide stable object identity for our public `RealtimeObjects`, `LiveMap`, and `LiveCounter` objects. Concretely, this means that it allows us to, for example, consistently return:
///
/// - the same `PublicDefaultRealtimeObjects` instance across multiple calls to `ARTRealtimeChannel.objects`
/// - the same `PublicDefaultLiveMap` instance across multiple calls to `PublicDefaultRealtimeObjects.getRoot()`
/// - the same `PublicDefaultLiveMap` and `PublicDefaultLiveCounter` instance across multiple calls to `PublicDefaultLiveMap.get(…)` with the same key (similarly for other `LiveMap` getters)
///
/// This differs from the approach that we take in ably-cocoa, in which we create a new public object each time we need to return one. Given that the LiveObjects SDK revolves around the concept of various live-updating objects, it seemed like it might be quite a confusing user experience if the pointer identity of, say, a `LiveMap` changed each time it was fetched.
///
/// - Note: We can only make a best-effort attempt to maintain the pointer identity of the public objects. Since the SDK cannot maintain a strong reference to the public objects (given that the whole reason that these objects exist is for us to know whether the user holds a strong reference to them), if the user releases all of their strong references to a public object then the next time they fetch the public object they will receive a new object.
internal final class PublicObjectsStore: Sendable {
    // Used to synchronize access to mutable state
    private let mutex = NSLock()
    private nonisolated(unsafe) var mutableState = MutableState()

    internal static let shared = PublicObjectsStore()

    internal struct RealtimeObjectsCreationArgs {
        internal var coreSDK: CoreSDK
        internal var logger: Logger
    }

    /// Fetches the cached `PublicDefaultRealtimeObjects` that wraps a given `InternalDefaultRealtimeObjects`, creating a new public object if there isn't already one.
    internal func getOrCreateRealtimeObjects(proxying proxied: InternalDefaultRealtimeObjects, creationArgs: RealtimeObjectsCreationArgs) -> PublicDefaultRealtimeObjects {
        mutex.withLock {
            mutableState.getOrCreateRealtimeObjects(proxying: proxied, creationArgs: creationArgs)
        }
    }

    internal struct CounterCreationArgs {
        internal var coreSDK: CoreSDK
        internal var logger: Logger
    }

    /// Fetches the cached `PublicDefaultLiveCounter` that wraps a given `InternalDefaultLiveCounter`, creating a new public object if there isn't already one.
    internal func getOrCreateCounter(proxying proxied: InternalDefaultLiveCounter, creationArgs: CounterCreationArgs) -> PublicDefaultLiveCounter {
        mutex.withLock {
            mutableState.getOrCreateCounter(proxying: proxied, creationArgs: creationArgs)
        }
    }

    internal struct MapCreationArgs {
        internal var coreSDK: CoreSDK
        internal var delegate: LiveMapObjectPoolDelegate
        internal var logger: Logger
    }

    /// Fetches the cached `PublicDefaultLiveMap` that wraps a given `InternalDefaultLiveMap`, creating a new public object if there isn't already one.
    internal func getOrCreateMap(proxying proxied: InternalDefaultLiveMap, creationArgs: MapCreationArgs) -> PublicDefaultLiveMap {
        mutex.withLock {
            mutableState.getOrCreateMap(proxying: proxied, creationArgs: creationArgs)
        }
    }

    private struct MutableState {
        private var realtimeObjectsProxies = Proxies<PublicDefaultRealtimeObjects>()
        private var counterProxies = Proxies<PublicDefaultLiveCounter>()
        private var mapProxies = Proxies<PublicDefaultLiveMap>()

        /// Stores weak references to proxy objects.
        private struct Proxies<Proxy: AnyObject> {
            private var proxiesByProxiedObjectIdentifier: [ObjectIdentifier: WeakRef<Proxy>] = [:]

            /// Fetches the proxy that wraps `proxied`, creating a new proxy if there isn't already one. Stores a weak reference to the proxy.
            mutating func getOrCreate(
                proxying proxied: some AnyObject,
                logger: Logger,
                logObjectType: String,
                createProxy: () -> Proxy,
            ) -> Proxy {
                // Remove any entries that are no longer useful
                removeDeallocatedEntries(logger: logger, logObjectType: logObjectType)

                // Do the get-or-create
                let proxiedObjectIdentifier = ObjectIdentifier(proxied)

                if let existing = proxiesByProxiedObjectIdentifier[proxiedObjectIdentifier]?.referenced {
                    logger.log("Reusing existing \(logObjectType) proxy (proxy: \(ObjectIdentifier(existing)), proxied: \(proxiedObjectIdentifier))", level: .debug)
                    return existing
                }

                let created = createProxy()
                proxiesByProxiedObjectIdentifier[proxiedObjectIdentifier] = .init(referenced: created)
                logger.log("Creating new \(logObjectType) proxy (proxy: \(ObjectIdentifier(created)), proxied: \(proxiedObjectIdentifier))", level: .debug)

                return created
            }

            private mutating func removeDeallocatedEntries(logger: Logger, logObjectType: String) {
                var keysToRemove: Set<ObjectIdentifier> = []
                for (proxiedObjectIdentifier, weakProxyRef) in proxiesByProxiedObjectIdentifier where weakProxyRef.referenced == nil {
                    logger.log("Clearing unused \(logObjectType) proxy from cache (proxied: \(proxiedObjectIdentifier))", level: .debug)
                    keysToRemove.insert(proxiedObjectIdentifier)
                }

                for key in keysToRemove {
                    proxiesByProxiedObjectIdentifier.removeValue(forKey: key)
                }
            }
        }

        internal mutating func getOrCreateRealtimeObjects(
            proxying proxied: InternalDefaultRealtimeObjects,
            creationArgs: RealtimeObjectsCreationArgs,
        ) -> PublicDefaultRealtimeObjects {
            realtimeObjectsProxies.getOrCreate(
                proxying: proxied,
                logger: creationArgs.logger,
                logObjectType: "RealtimeObjects",
            ) {
                .init(
                    proxied: proxied,
                    coreSDK: creationArgs.coreSDK,
                    logger: creationArgs.logger,
                )
            }
        }

        internal mutating func getOrCreateCounter(
            proxying proxied: InternalDefaultLiveCounter,
            creationArgs: CounterCreationArgs,
        ) -> PublicDefaultLiveCounter {
            counterProxies.getOrCreate(
                proxying: proxied,
                logger: creationArgs.logger,
                logObjectType: "LiveCounter",
            ) {
                .init(
                    proxied: proxied,
                    coreSDK: creationArgs.coreSDK,
                    logger: creationArgs.logger,
                )
            }
        }

        internal mutating func getOrCreateMap(
            proxying proxied: InternalDefaultLiveMap,
            creationArgs: MapCreationArgs,
        ) -> PublicDefaultLiveMap {
            mapProxies.getOrCreate(
                proxying: proxied,
                logger: creationArgs.logger,
                logObjectType: "LiveMap",
            ) {
                .init(
                    proxied: proxied,
                    coreSDK: creationArgs.coreSDK,
                    delegate: creationArgs.delegate,
                    logger: creationArgs.logger,
                )
            }
        }
    }
}
