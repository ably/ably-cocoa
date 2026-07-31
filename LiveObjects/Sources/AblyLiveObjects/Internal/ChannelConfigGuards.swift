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
/// | `object_subscribe` / `object_publish` channel mode | RTO2a2/RTO2b2 (40024) | ✅ via `CoreSDK.nosync_objectChannelModes` |
/// | `echoMessages` client option | RTO26 | ✅ via `CoreSDK.echoMessages` |
/// | Connection `isActive` (publishable state) | RTO26 | ✅ via `CoreSDK.nosync_connectionStateError` |
///
/// The channel-state check produces the same 90001 error the internal engine's node accessors run
/// (`CoreSDK.nosync_validateChannelState`), so no new state check is invented. The mode /
/// echo-messages / connection-active checks were formerly stubbed (DEV-38); the `nosync_objectChannelModes`,
/// `echoMessages` and `nosync_connectionStateError` bridge accessors now make them real.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal enum ChannelConfigGuards {
    /// Validates the access (read/subscribe) API preconditions: the channel must be attachable (not
    /// DETACHED/FAILED) and configured with the `object_subscribe` mode. Spec: RTO25.
    internal static func throwIfInvalidAccessApiConfiguration(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // ably-java `Helpers.kt:40` — order: channel state, then `object_subscribe` mode.
        let error = internalQueue.ably_syncNoDeadlock { () -> ARTErrorInfo? in
            // RTO25b — channel state (reuses the engine's node-accessor check).
            nosync_channelStateError(coreSDK: coreSDK, notIn: [.detached, .failed], operationDescription: "access API")
                // RTO25a / RTO2a2 — `object_subscribe` mode.
                ?? nosync_missingChannelModeError(coreSDK: coreSDK, requiredMode: .objectSubscribe, modeName: "object_subscribe")
        }
        if let error {
            throw error
        }
    }

    /// Validates only the `object_subscribe` channel mode (no channel-state check), for
    /// `RealtimeObject.get()` (RTO23a). Unlike the access methods, `get()` delegates channel-state
    /// handling to the ensure-attached procedure (RTL33), so it must not pre-empt that with a state
    /// gate. Spec: RTO23a. (Wired in P5's `get()`.)
    internal static func throwIfMissingObjectSubscribeMode(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // ably-java `Helpers.kt:53` — the `object_subscribe` mode only (no channel-state check).
        let error = internalQueue.ably_syncNoDeadlock { () -> ARTErrorInfo? in
            nosync_missingChannelModeError(coreSDK: coreSDK, requiredMode: .objectSubscribe, modeName: "object_subscribe")
        }
        if let error {
            throw error
        }
    }

    /// Validates the write (mutation) API preconditions: message echo must be enabled, the channel
    /// must be usable (not DETACHED/FAILED/SUSPENDED) and configured with the `object_publish` mode.
    /// Spec: RTO26.
    internal static func throwIfInvalidWriteApiConfiguration(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // ably-java `Helpers.kt:64` — order: echoMessages, then channel state, then `object_publish` mode.
        let error = internalQueue.ably_syncNoDeadlock { () -> ARTErrorInfo? in
            // RTO26 — `echoMessages` must be enabled.
            nosync_echoMessagesDisabledError(coreSDK: coreSDK)
                // RTO26b — channel state (reuses the engine's node-accessor check).
                ?? nosync_channelStateError(coreSDK: coreSDK, notIn: [.detached, .failed, .suspended], operationDescription: "write API")
                // RTO2b2 — `object_publish` mode.
                ?? nosync_missingChannelModeError(coreSDK: coreSDK, requiredMode: .objectPublish, modeName: "object_publish")
        }
        if let error {
            throw error
        }
    }

    /// RTO23e / RTL33 — the *ensure-active-channel* procedure that `RealtimeObject.get()` runs before
    /// waiting for sync. Mirrors ably-java's `Helpers.kt` `ensureAttached` / `attachAsync`:
    ///
    /// - **RTL33a** — ATTACHED or SUSPENDED: already usable, no attach performed.
    /// - **RTL33b** — INITIALIZED / DETACHED / DETACHING / ATTACHING: implicitly attach (per RTL4, via
    ///   the `CoreSDK.nosync_attach` plugin bridge) and await completion. A single attach resolves the
    ///   in-flight ATTACHING/DETACHING cases per RTL4h, so one call covers all four states. The
    ///   `ARTErrorInfo` that caused an attach failure is propagated (RTL33b1).
    /// - **RTL33c** — FAILED (and any unknown state): reject with code 90001, statusCode 400.
    ///
    /// The state read and the attach initiation happen in a **single** internal-queue block, so no
    /// channel-state change can be lost between the read and the attach's callback registration
    /// (lost-wakeup discipline). Formerly DEV-46 (implicit attach was not implementable through the
    /// plugin API); the `nosync_attach` bridge accessor now makes it real.
    ///
    /// Spec: RTO23e, RTL33.
    internal static func ensureActiveChannel(coreSDK: CoreSDK, internalQueue: DispatchQueue) async throws(ARTErrorInfo) {
        let result: Result<Void, ARTErrorInfo> = await withCheckedContinuation { continuation in
            internalQueue.async {
                let state = coreSDK.nosync_channelState

                // The RTL33c rejection, reused for FAILED and any unknown state.
                let invalidStateError = LiveObjectsError.objectsOperationFailedInvalidChannelState(
                    operationDescription: "get",
                    channelState: state,
                )
                let invalidStateFailure: Result<Void, ARTErrorInfo> = .failure(invalidStateError.toARTErrorInfo())

                switch state {
                case .attached, .suspended:
                    // RTL33a
                    continuation.resume(returning: .success(()))
                case .initialized, .detached, .detaching, .attaching:
                    // RTL33b — implicit attach; the callback fires on the internal queue (RTL33b1
                    // propagates the attach-failure error).
                    coreSDK.nosync_attach { error in
                        continuation.resume(returning: error.map { .failure($0) } ?? .success(()))
                    }
                case .failed:
                    // RTL33c
                    continuation.resume(returning: invalidStateFailure)
                @unknown default:
                    continuation.resume(returning: invalidStateFailure)
                }
            }
        }

        switch result {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }

    /// Validates that the channel is in a publishable state (connection active, channel not
    /// FAILED/SUSPENDED). Spec: RTO26 (publishable-state variant). (Reserved for P5.)
    internal static func throwIfUnpublishableState(coreSDK: CoreSDK, internalQueue: DispatchQueue) throws(ARTErrorInfo) {
        // ably-java `Helpers.kt:110` — order: connection active, then channel state (FAILED/SUSPENDED).
        let error = internalQueue.ably_syncNoDeadlock { () -> ARTErrorInfo? in
            // The connection must be in a publishable (active) state; if not, surface the connection's
            // own state error (DEV-38 note: cocoa returns the connection's `errorReason`, or a synthetic
            // 80002 error when it has none, in place of ably-java's `connectionManager.stateErrorInfo`).
            coreSDK.nosync_connectionStateError
                ?? nosync_channelStateError(coreSDK: coreSDK, notIn: [.failed, .suspended], operationDescription: "publish")
        }
        if let error {
            throw error
        }
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

    // MARK: - Private on-queue checks

    // The following helpers read `nosync_` core-SDK accessors and so must be called on the internal
    // queue (each guard wraps its checks in a single `ably_syncNoDeadlock` hop). Each returns the
    // relevant `ARTErrorInfo` if the check fails, or `nil` if it passes — so a guard can chain them
    // with `??` to mirror ably-java's short-circuiting check order.

    /// RTO25b/RTO26b — the channel-state check (reuses the engine's node-accessor precondition).
    /// ably-java `Helpers.kt:94` `throwIfInChannelState`.
    private static func nosync_channelStateError(
        coreSDK: CoreSDK,
        notIn invalidStates: [_AblyPluginSupportPrivate.RealtimeChannelState],
        operationDescription: String,
    ) -> ARTErrorInfo? {
        let currentState = coreSDK.nosync_channelState
        if invalidStates.contains(currentState) {
            let error = LiveObjectsError.objectsOperationFailedInvalidChannelState(
                operationDescription: operationDescription,
                channelState: currentState,
            )
            return error.toARTErrorInfo()
        }
        return nil
    }

    /// RTO2a2/RTO2b2 — the required-channel-mode check (40024). ably-java `Helpers.kt:84`
    /// `throwIfMissingChannelMode`: throws when the effective modes are absent or do not contain the
    /// required mode.
    private static func nosync_missingChannelModeError(
        coreSDK: CoreSDK,
        requiredMode: _AblyPluginSupportPrivate.ChannelMode,
        modeName: String,
    ) -> ARTErrorInfo? {
        if !coreSDK.nosync_objectChannelModes.contains(requiredMode) {
            return LiveObjectsError.channelModeRequired(mode: modeName).toARTErrorInfo()
        }
        return nil
    }

    /// RTO26 — the `echoMessages` client-option check. ably-java `Helpers.kt:101`
    /// `throwIfEchoMessagesDisabled`.
    private static func nosync_echoMessagesDisabledError(coreSDK: CoreSDK) -> ARTErrorInfo? {
        if !coreSDK.echoMessages {
            return LiveObjectsError.echoMessagesDisabled.toARTErrorInfo()
        }
        return nil
    }
}
