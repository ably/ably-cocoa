internal import _AblyPluginSupportPrivate
import Ably

/// The class that provides the public API for interacting with LiveObjects, via the ``ARTRealtimeChannel/objects`` property.
///
/// This is largely a wrapper around ``InternalDefaultRealtimeObjects``.
internal final class PublicDefaultRealtimeObjects: RealtimeObjects {
    private let proxied: InternalDefaultRealtimeObjects
    internal var testsOnly_proxied: InternalDefaultRealtimeObjects {
        proxied
    }

    // MARK: - Dependencies that hold a strong reference to `proxied`

    private let coreSDK: CoreSDK
    private let logger: Logger

    internal init(proxied: InternalDefaultRealtimeObjects, coreSDK: CoreSDK, logger: Logger) {
        self.proxied = proxied
        self.coreSDK = coreSDK
        self.logger = logger
    }

    // MARK: - `RealtimeObjects` protocol

    internal func getRoot() async throws(ARTErrorInfo) -> any LiveMap {
        let internalMap = try await proxied.getRoot(coreSDK: coreSDK)
        return PublicObjectsStore.shared.getOrCreateMap(
            proxying: internalMap,
            creationArgs: .init(
                coreSDK: coreSDK,
                delegate: proxied,
                logger: logger,
            ),
        )
    }

    internal func createMap(entries: [String: LiveMapValue]) async throws(ARTErrorInfo) -> any LiveMap {
        let internalEntries: [String: InternalLiveMapValue] = entries.mapValues { .init(liveMapValue: $0) }
        let internalMap = try await proxied.createMap(entries: internalEntries, coreSDK: coreSDK)

        return PublicObjectsStore.shared.getOrCreateMap(
            proxying: internalMap,
            creationArgs: .init(
                coreSDK: coreSDK,
                delegate: proxied,
                logger: logger,
            ),
        )
    }

    internal func createMap() async throws(ARTErrorInfo) -> any LiveMap {
        let internalMap = try await proxied.createMap(coreSDK: coreSDK)

        return PublicObjectsStore.shared.getOrCreateMap(
            proxying: internalMap,
            creationArgs: .init(
                coreSDK: coreSDK,
                delegate: proxied,
                logger: logger,
            ),
        )
    }

    internal func createCounter(count: Double) async throws(ARTErrorInfo) -> any LiveCounter {
        let internalCounter = try await proxied.createCounter(count: count, coreSDK: coreSDK)

        return PublicObjectsStore.shared.getOrCreateCounter(
            proxying: internalCounter,
            creationArgs: .init(
                coreSDK: coreSDK,
                logger: logger,
            ),
        )
    }

    internal func createCounter() async throws(ARTErrorInfo) -> any LiveCounter {
        let internalCounter = try await proxied.createCounter(coreSDK: coreSDK)

        return PublicObjectsStore.shared.getOrCreateCounter(
            proxying: internalCounter,
            creationArgs: .init(
                coreSDK: coreSDK,
                logger: logger,
            ),
        )
    }

    internal func on(event: ObjectsEvent, callback: @escaping ObjectsEventCallback) -> any OnObjectsEventResponse {
        proxied.on(event: event, callback: callback)
    }

    internal func offAll() {
        proxied.offAll()
    }

    // MARK: - Test-only APIs

    // These are only used by our plumbingSmokeTest (the rest of our unit tests test the internal classes, not the public ones).

    internal var testsOnly_onChannelAttachedHasObjects: Bool? {
        proxied.testsOnly_onChannelAttachedHasObjects
    }

    internal var testsOnly_receivedObjectProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        proxied.testsOnly_receivedObjectProtocolMessages
    }

    internal func testsOnly_publish(objectMessages: [OutboundObjectMessage]) async throws(InternalError) {
        try await proxied.testsOnly_publish(objectMessages: objectMessages, coreSDK: coreSDK)
    }

    internal var testsOnly_receivedObjectSyncProtocolMessages: AsyncStream<[InboundObjectMessage]> {
        proxied.testsOnly_receivedObjectSyncProtocolMessages
    }

    // These are used by the integration tests.

    /// Replaces the method that this `RealtimeObjects` uses to send any outbound `ObjectMessage`s.
    ///
    /// Used by integration tests, for example to disable `ObjectMessage` publishing so that a test can verify that a behaviour is not a side effect of an `ObjectMessage` sent by the SDK.
    internal func testsOnly_overridePublish(with newImplementation: @escaping ([OutboundObjectMessage]) async throws(InternalError) -> Void) {
        coreSDK.testsOnly_overridePublish(with: newImplementation)
    }
}
