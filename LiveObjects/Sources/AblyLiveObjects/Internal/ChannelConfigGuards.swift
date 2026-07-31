internal import _AblyPluginSupportPrivate
import Ably

/// The channel-configuration precondition guards for the path-based public API (Kotlin
/// `Helpers.kt`'s `throwIf*` family). Each public read/write entry point runs the relevant guard
/// before touching the object graph, per RTO23a/RTO25/RTO26.
///
/// ## Implementability against the plugin API
///
/// Only some of ably-java's guard checks are expressible through `_AblyPluginSupportPrivate`
/// (`PluginAPIProtocol`) as it stands today:
///
/// | Check | Spec | Implemented? |
/// |---|---|---|
/// | Channel state (DETACHED/FAILED, +SUSPENDED for writes) | RTO25/RTO26 | ✅ via `CoreSDK.nosync_channelState` |
/// | `object_subscribe` / `object_publish` channel mode | RTO2a2/RTO2b2 (40024) | ❌ no plugin accessor — stubbed |
/// | `echoMessages` client option | RTO26 | ❌ no plugin accessor — stubbed |
/// | Connection `isActive` (publishable state) | RTO26 | ❌ no plugin accessor — stubbed |
///
/// The unimplementable checks carry a `// TODO(core accessor):` marker; landing them needs a
/// `PluginAPI`/core-SDK accessor (a user-gated core change, out of scope per plan §6.6 — the DEV-23
/// precedent). The channel-state check reuses the exact `CoreSDK.nosync_validateChannelState` the
/// internal engine's node accessors already run (same 90001 code), so no new state check is invented.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum ChannelConfigGuards {
    /// Validates the access (read/subscribe) API preconditions: the channel must be attachable (not
    /// DETACHED/FAILED) and configured with the `object_subscribe` mode. Spec: RTO25.
    internal static func throwIfInvalidAccessApiConfiguration(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // RTO25b — channel-state check (implementable). Reuses the engine's node-accessor check.
        try validateChannelState(coreSDK: coreSDK, internalQueue: internalQueue, notIn: [.detached, .failed], operationDescription: "access API")
        // TODO(core accessor): RTO25a / RTO2a2 — throw `channelModeRequired("object_subscribe")` (40024)
        // when the channel is not configured with the `object_subscribe` mode. The plugin API exposes
        // no channel modes; see the guard-implementability table in this file's doc comment.
    }

    /// Validates only the `object_subscribe` channel mode (no channel-state check), for
    /// `RealtimeObject.get()` (RTO23a). Unlike the access methods, `get()` delegates channel-state
    /// handling to the ensure-attached procedure (RTL33), so it must not pre-empt that with a state
    /// gate. Spec: RTO23a. (Wired in P5's `get()`.)
    internal static func throwIfMissingObjectSubscribeMode(coreSDK _: CoreSDK, internalQueue _: DispatchQueue) throws(ARTErrorInfo) {
        // TODO(core accessor): RTO2a2 — throw `channelModeRequired("object_subscribe")` (40024) when the
        // channel is not configured with the `object_subscribe` mode. No plugin channel-modes accessor.
    }

    /// Validates the write (mutation) API preconditions: message echo must be enabled, the channel
    /// must be usable (not DETACHED/FAILED/SUSPENDED) and configured with the `object_publish` mode.
    /// Spec: RTO26.
    internal static func throwIfInvalidWriteApiConfiguration(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // TODO(core accessor): RTO26 — throw a bad-request error when `echoMessages` is disabled. The
        // plugin API exposes client options only as an opaque marker protocol (no `echoMessages`).
        // RTO26b — channel-state check (implementable). Reuses the engine's node-accessor check.
        try validateChannelState(coreSDK: coreSDK, internalQueue: internalQueue, notIn: [.detached, .failed, .suspended], operationDescription: "write API")
        // TODO(core accessor): RTO2b2 — throw `channelModeRequired("object_publish")` (40024) when the
        // channel is not configured with the `object_publish` mode. No plugin channel-modes accessor.
    }

    /// RTO23e / RTL33 — the *ensure-active-channel* procedure that `RealtimeObject.get()` runs before
    /// waiting for sync. ably-java implicitly attaches a DETACHED/INITIALIZED channel (RTL33b) and
    /// rejects only FAILED (RTL33c, code 90001).
    ///
    /// The plugin API (`PluginAPIProtocol` / `_AblyPluginSupportPrivate`) exposes **no way to
    /// initiate a channel attach** — only `nosync_stateForChannel` (state read) and the inbound
    /// `nosync_onChannelAttached` callback. So the implicit-attach half of RTL33 is not implementable
    /// here; we implement the implementable half — reject a FAILED channel (RTL33c) — and leave the
    /// attach to the application. When the channel is not yet attached, `get()`'s subsequent
    /// `ensureSynced` simply waits until it becomes synced.
    ///
    /// Spec: RTO23e, RTL33.
    internal static func ensureActiveChannel(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // TODO(core accessor): RTL33b — implicitly attach a DETACHED/INITIALIZED channel. The plugin
        // API can only read channel state, not initiate an attach; landing this needs a
        // PluginAPI/core-SDK accessor (user-gated core change, plan §6.6; DEV-38 precedent).
        // RTL33c — reject a FAILED channel (implementable; code 90001).
        try validateChannelState(coreSDK: coreSDK, internalQueue: internalQueue, notIn: [.failed], operationDescription: "get")
    }

    /// Validates that the channel is in a publishable state (connection active, channel not
    /// FAILED/SUSPENDED). Spec: RTO26 (publishable-state variant). (Reserved for P5.)
    internal static func throwIfUnpublishableState(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // TODO(core accessor): the connection `isActive` check — the plugin API exposes no connection
        // state / manager. Only the channel-state portion below is implementable.
        try validateChannelState(coreSDK: coreSDK, internalQueue: internalQueue, notIn: [.failed, .suspended], operationDescription: "publish")
    }

    /// RTPO19c1a / DEV-9 — validates a subscription `depth`. ably-java throws 40003 from the
    /// `PathObjectSubscriptionOptions(int)` constructor; the shipped Swift `init(depth:)` is
    /// non-throwing and frozen, so the check moves here, to be called from `subscribe(options:listener:)`
    /// once path subscriptions land (part 2).
    internal static func validateSubscriptionDepth(_ depth: Int?) throws(ARTErrorInfo) {
        if let depth, depth <= 0 {
            throw LiveObjectsError.invalidInput(message: "Subscription depth must be a positive integer, got \(depth)").toARTErrorInfo()
        }
    }

    // MARK: - Private helpers

    /// Runs `CoreSDK.nosync_validateChannelState` on the internal queue (the `nosync_` accessor must be
    /// invoked there), re-throwing its typed `ARTErrorInfo` to the caller.
    private static func validateChannelState(
        coreSDK: CoreSDK,
        internalQueue: DispatchQueue,
        notIn invalidStates: [_AblyPluginSupportPrivate.RealtimeChannelState],
        operationDescription: String,
    ) throws(ARTErrorInfo) {
        let failure: ARTErrorInfo? = internalQueue.ably_syncNoDeadlock {
            do throws(ARTErrorInfo) {
                try coreSDK.nosync_validateChannelState(notIn: invalidStates, operationDescription: operationDescription)
                return nil
            } catch {
                return error
            }
        }
        if let failure {
            throw failure
        }
    }
}
