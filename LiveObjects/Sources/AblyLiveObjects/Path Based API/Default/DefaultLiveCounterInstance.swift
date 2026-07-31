import Ably
import Foundation

/// Default implementation of ``LiveCounterInstance`` (Kotlin `DefaultLiveCounterInstance`), bound to a
/// specific ``InternalDefaultLiveCounter`` (RTINS2a). Operations dereference the wrapped counter in
/// O(1) — no path resolution. Spec: `RTINS1`, `RTTS10b`.
///
/// The RTO25b access-precondition checks are performed by the underlying node accessors
/// (`value(coreSDK:)`, `subscribe(...)`, `increment(...)`) — the same checks the internal engine
/// already enforces; no new checks are invented here.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class DefaultLiveCounterInstance: LiveCounterInstance {
    private let node: InternalDefaultLiveCounter
    private let coreSDK: CoreSDK
    private let realtimeObjects: any InternalRealtimeObjectsProtocol
    private let internalQueue: DispatchQueue

    /// The wrapped counter's `objectId`, captured once at construction (RTINS3a). It is immutable, so
    /// the frozen non-throwing `id` property is a plain stored read (O(1)).
    internal let id: String

    internal init(
        node: InternalDefaultLiveCounter,
        coreSDK: CoreSDK,
        realtimeObjects: any InternalRealtimeObjectsProtocol,
        internalQueue: DispatchQueue,
    ) {
        self.node = node
        self.coreSDK = coreSDK
        self.realtimeObjects = realtimeObjects
        self.internalQueue = internalQueue
        // RTINS3a: read the immutable objectId on the shared internal queue.
        id = internalQueue.ably_syncNoDeadlock { node.nosync_objectID }
    }

    // MARK: - LiveCounterInstance

    internal var value: Double {
        get throws(ARTErrorInfo) {
            // RTINS4a/RTINS4b -> RTLC5 (the node accessor runs the RTO25b check)
            try node.value(coreSDK: coreSDK)
        }
    }

    internal func increment(amount: Double) async throws(ARTErrorInfo) {
        // RTINS14c -> RTLC12
        try await node.increment(amount: amount, coreSDK: coreSDK, realtimeObjects: realtimeObjects)
    }

    internal func decrement(amount: Double) async throws(ARTErrorInfo) {
        // RTINS15c -> RTLC13
        try await node.decrement(amount: amount, coreSDK: coreSDK, realtimeObjects: realtimeObjects)
    }

    @discardableResult
    internal func subscribe(listener: @escaping InstanceSubscriptionCallback) throws(ARTErrorInfo) -> any Subscription {
        // RTINS16b (the node's subscribe runs the RTO25b check), RTINS16d -> RTLO4b
        let response = try node.subscribe(
            listener: { [weak self] update, _ in
                guard let self else {
                    return
                }
                // RTINS16e1: an Instance wrapping this counter (identity-based, RTINS16g).
                // RTINS16e2: the PAOM3-converted public message stamped onto the update in P2 (nil for
                // sync-originated updates).
                listener(.init(object: .liveCounter(self), message: update.objectMessage))
            },
            coreSDK: coreSDK,
        )
        // RTINS16f
        return DefaultSubscription(response: response)
    }

    internal func compactJson() throws(ARTErrorInfo) -> JSONValue {
        // RTINS11a/RTINS11b -> RTPO14 -> RTPO13d: a counter compacts to its current numeric value.
        // The node's `value(coreSDK:)` runs the RTO25b check.
        try .number(node.value(coreSDK: coreSDK))
    }
}
