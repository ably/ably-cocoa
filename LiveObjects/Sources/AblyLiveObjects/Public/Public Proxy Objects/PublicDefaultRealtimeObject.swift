import Ably

/// The default implementation of the public ``RealtimeObject`` entry point, backing
/// ``ARTRealtimeChannel/object``.
///
/// This is largely a wrapper around ``InternalDefaultRealtimeObjects``. The `Public` prefix
/// expresses the contrast with that internal type, per the documented memory-management policy (the
/// public proxy holds a strong reference to the internal object, not vice versa); hence it lives
/// alongside the other proxy objects in `Public/Public Proxy Objects`.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class PublicDefaultRealtimeObject: RealtimeObject {
    internal let proxied: InternalDefaultRealtimeObjects // internal (not private) for AblyLiveObjectsTesting

    // MARK: - Dependencies that hold a strong reference to `proxied`

    internal let coreSDK: CoreSDK // internal (not private) for AblyLiveObjectsTesting
    private let logger: Logger

    internal init(proxied: InternalDefaultRealtimeObjects, coreSDK: CoreSDK, logger: Logger) {
        self.proxied = proxied
        self.coreSDK = coreSDK
        self.logger = logger
    }

    // MARK: - `RealtimeObject` protocol

    internal func get() async throws(ARTErrorInfo) -> any LiveMapPathObject {
        // RTO23a — object_subscribe mode guard (currently a stub; see ChannelConfigGuards for the
        // plugin-API limitation).
        try ChannelConfigGuards.throwIfMissingObjectSubscribeMode(coreSDK: coreSDK, internalQueue: proxied.internalQueue)
        // RTO23e / RTL33 — ensure the channel is usable: RTL33a (already ATTACHED/SUSPENDED),
        // RTL33b (implicit attach for INITIALIZED/DETACHED/DETACHING/ATTACHING, awaiting ATTACHED),
        // RTL33c (reject FAILED). See ChannelConfigGuards.ensureActiveChannel.
        try await ChannelConfigGuards.ensureActiveChannel(coreSDK: coreSDK, internalQueue: proxied.internalQueue)
        // RTO23c — wait for the initial sync to complete (atomic state-check + waiter registration,
        // 92008 if the channel leaves a usable state while waiting).
        try await proxied.ensureSynced()
        // RTO23d / RTTS6d — a LiveMapPathObject with an empty path, rooted at the channel's root map.
        // The root reference is realised as a pool lookup at resolution time (the pool never replaces
        // the root instance, RTO4b2/RTO5c2a), equivalent to holding the RTPO2b root reference.
        return DefaultLiveMapPathObject(
            channelObject: proxied,
            coreSDK: coreSDK,
            internalQueue: proxied.internalQueue,
            path: "",
        )
    }

    @discardableResult
    internal func on(event: ObjectsEvent, callback: @escaping @Sendable () -> Void) -> any StatusSubscription {
        // RTO18 — register on the internal engine's status-event emitter, which fires `.syncing` /
        // `.synced` on `userCallbackQueue`. The public callback is zero-arg (the event is known from
        // registration, DEV-11), so the internal response is discarded.
        let response = proxied.on(event: event) { _ in
            callback()
        }
        return DefaultStatusSubscription(response: response)
    }
}
