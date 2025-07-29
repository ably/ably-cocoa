import Ably
internal import AblyPlugin

/// Our default implementation of ``LiveMap``.
///
/// This is largely a wrapper around ``InternalDefaultLiveMap``.
internal final class PublicDefaultLiveMap: LiveMap {
    internal let proxied: InternalDefaultLiveMap

    // MARK: - Dependencies that hold a strong reference to `proxied`

    private let coreSDK: CoreSDK
    private let delegate: LiveMapObjectPoolDelegate
    private let logger: AblyPlugin.Logger

    internal init(proxied: InternalDefaultLiveMap, coreSDK: CoreSDK, delegate: LiveMapObjectPoolDelegate, logger: AblyPlugin.Logger) {
        self.proxied = proxied
        self.coreSDK = coreSDK
        self.delegate = delegate
        self.logger = logger
    }

    // MARK: - `LiveMap` protocol

    internal func get(key: String) throws(ARTErrorInfo) -> LiveMapValue? {
        try proxied.get(key: key, coreSDK: coreSDK, delegate: delegate)?.toPublic(
            creationArgs: .init(
                coreSDK: coreSDK,
                mapDelegate: delegate,
                logger: logger,
            ),
        )
    }

    internal var size: Int {
        get throws(ARTErrorInfo) {
            try proxied.size(coreSDK: coreSDK)
        }
    }

    internal var entries: [(key: String, value: LiveMapValue)] {
        get throws(ARTErrorInfo) {
            try proxied.entries(coreSDK: coreSDK, delegate: delegate).map { entry in
                (
                    entry.key,
                    entry.value.toPublic(
                        creationArgs: .init(
                            coreSDK: coreSDK,
                            mapDelegate: delegate,
                            logger: logger,
                        ),
                    )
                )
            }
        }
    }

    internal var keys: [String] {
        get throws(ARTErrorInfo) {
            try proxied.keys(coreSDK: coreSDK, delegate: delegate)
        }
    }

    internal var values: [LiveMapValue] {
        get throws(ARTErrorInfo) {
            try proxied.values(coreSDK: coreSDK, delegate: delegate).map { value in
                value.toPublic(
                    creationArgs: .init(
                        coreSDK: coreSDK,
                        mapDelegate: delegate,
                        logger: logger,
                    ),
                )
            }
        }
    }

    internal func set(key: String, value: LiveMapValue) async throws(ARTErrorInfo) {
        try await proxied.set(key: key, value: value)
    }

    internal func remove(key: String) async throws(ARTErrorInfo) {
        try await proxied.remove(key: key)
    }

    internal func subscribe(listener: @escaping LiveObjectUpdateCallback<LiveMapUpdate>) throws(ARTErrorInfo) -> any SubscribeResponse {
        try proxied.subscribe(listener: listener, coreSDK: coreSDK)
    }

    internal func unsubscribeAll() {
        proxied.unsubscribeAll()
    }

    internal func on(event: LiveObjectLifecycleEvent, callback: @escaping LiveObjectLifecycleEventCallback) -> any OnLiveObjectLifecycleEventResponse {
        proxied.on(event: event, callback: callback)
    }

    internal func offAll() {
        proxied.offAll()
    }
}
