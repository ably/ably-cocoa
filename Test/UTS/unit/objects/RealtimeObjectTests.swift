// Derived from the UTS spec `objects/unit/realtime_object.md`.

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

/// The public `RealtimeObject` entry point (`PublicDefaultRealtimeObject`): `get()` (RTO23), the
/// `.syncing`/`.synced` status events and `off()` (RTO17/RTO18/RTO19), the dispose lifecycle, and the
/// channel-state access/write preconditions (RTO25b/RTO26b).
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/realtime_object.md
/// (spec points `RTO2`, `RTO10`, `RTO15`, `RTO17`–`RTO20`, `RTO22`–`RTO27`).
///
/// The spec drives every case through `setup_synced_channel` + `mock_ws.send_to_client`. Per the
/// UNIT-only scope, the engine-drivable subset is driven directly through a real
/// `InternalDefaultRealtimeObjects` proxied by a `PublicDefaultRealtimeObject` (with an
/// `ObjectsUTSCoreSDK` fixing the channel state): sync is completed by feeding the engine an empty
/// OBJECT_SYNC / ATTACHED via `nosync_handleObjectSyncProtocolMessage` / `nosync_onChannelAttached`
/// (the unit stand-in for `mock_ws.send_to_client`). This mirrors the native
/// `PublicRealtimeObjectTests` (whose `MockCoreSDK` / `TestLogger` / `TestFactories` the UTS target
/// cannot import — replicated by the `ObjectsUTS*` helpers). Status callbacks and get() resolution run
/// on `userCallbackQueue` (`.main`), drained before asserting.
///
/// ## Deviations (recorded in deviations.md)
/// - **DEV-11 (zero-arg status callback):** `on(event:callback:)` takes a `() -> Void`; the event is
///   known from registration, so RTO18e's "listeners called with no arguments" is the shipped shape.
/// - **RTL33b (implicit attach not implementable):** `ensureActiveChannel` can only *read* channel
///   state through the plugin API (no attach seam), so `get()` on a DETACHED/INITIALIZED channel cannot
///   implicitly re-attach — only the RTL33c FAILED rejection (90001) is exercised (RTO23e-failed).
///
/// ## Skipped — out of UNIT scope / not implementable (recorded in deviations.md)
/// - **Channel-mode guards (40024):** RTO23a, RTO2 mode-enforcement, RTO25a, RTO26a — the
///   `object_subscribe`/`object_publish` mode checks are stubbed (`ChannelConfigGuards`: no plugin
///   channel-modes accessor). **echoMessages guard (40000):** RTO26c — no plugin accessor.
/// - **Implicit-attach cases:** RTO23 get-implicit-attach, RTO23e get-reattaches-detached — RTL33b is
///   not implementable (see above).
/// - **Publish / apply-on-ACK pipeline:** RTO15, RTO20 (all variants — publish-and-apply-local,
///   missing-site-code, null-serial, waits-for-synced, e1 fails-on-detached/failed, echo-dedup,
///   ack-no-site-timeserials, ack-after-echo, ack-serials-cleared, subscription-fires-on-ack) — need the
///   mock-WS OBJECT publish + ACK-driven local apply, for which no unit harness exists.
/// - **Garbage collection:** RTO10, RTO10b1, RTO10c1b1 — need `enable_fake_timers()` + the GC task.
/// - **Path-subscription dispatch:** RTO24a, RTO24c1 — covered by `PathObjectSubscribeTests`.
/// - **RTO27 (channel-state data lifecycle):** implemented (DEV-51) — `nosync_onChannelStateChanged`
///   clears object data to zero without emitting events on DETACHED/FAILED (RTO27a) and clears the
///   in-progress SyncObjectsPool (RTO27a2), while retaining data on SUSPENDED (RTO27b). Its white-box
///   coverage requires internal `ObjectsPool` data introspection the black-box UTS target does not
///   expose, so it lives in the AblyLiveObjects unit suite
///   (`InternalDefaultRealtimeObjectsTests.ChannelStateChangeTests`).
@Suite(.serialized)
final class RealtimeObjectTests {
    // MARK: - Harness

    /// A thread-safe ordered log of emitted status-event names, for the sync-sequence assertions.
    private final class EventLog: @unchecked Sendable {
        private let lock = NSLock()
        private var names: [String] = []
        func append(_ name: String) { lock.withLock { names.append(name) } }
        var snapshot: [String] { lock.withLock { names } }
    }

    /// A thread-safe call counter for asynchronously-delivered status callbacks.
    private final class CallCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0
        func increment() { lock.withLock { value += 1 } }
        var count: Int { lock.withLock { value } }
    }

    private static func makeProxied(internalQueue: DispatchQueue) -> InternalDefaultRealtimeObjects {
        InternalDefaultRealtimeObjects(
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
            channelName: "test",
        )
    }

    private static func makePublicObject(
        channelState: _AblyPluginSupportPrivate.RealtimeChannelState = .attached,
    ) -> (publicObject: PublicDefaultRealtimeObject, proxied: InternalDefaultRealtimeObjects, coreSDK: ObjectsUTSCoreSDK, internalQueue: DispatchQueue) {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let proxied = makeProxied(internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK(channelState: channelState)
        let publicObject = PublicDefaultRealtimeObject(proxied: proxied, coreSDK: coreSDK, logger: TestLogger())
        return (publicObject, proxied, coreSDK, internalQueue)
    }

    /// Drives the engine to `.synced` via an empty OBJECT_SYNC (Initialized/Syncing -> Synced), the unit
    /// stand-in for the spec's `build_object_sync_message` frame.
    private static func driveToSynced(_ proxied: InternalDefaultRealtimeObjects, on internalQueue: DispatchQueue) {
        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_handleObjectSyncProtocolMessage(objectMessages: [], protocolMessageChannelSerial: nil)
        }
    }

    /// A root `LiveMapPathObject` backed by an engine whose `CoreSDK` reports `channelState`, for the
    /// access/write precondition guards (which read `CoreSDK.nosync_channelState`).
    private static func makeRootPath(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) -> DefaultLiveMapPathObject {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let proxied = makeProxied(internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK(channelState: channelState)
        return DefaultLiveMapPathObject(channelObject: proxied, coreSDK: coreSDK, internalQueue: internalQueue, path: "")
    }

    /// Awaits one hop on `.main` so any status/get callbacks dispatched to `userCallbackQueue` are
    /// delivered before assertions read them.
    private static func drainMain() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    // MARK: - get() (RTO23)

    // UTS: objects/unit/RTO23/get-returns-path-object-0 & RTO23d/get-resolves-immediately-synced-0 — RTO23d:
    // get() returns a LiveMapPathObject rooted at the root map (empty path) once synced.
    @Test
    func RTO23d_get_returns_root_path_object() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        Self.driveToSynced(proxied, on: internalQueue)

        let root = try await publicObject.get()
        #expect(root.path.isEmpty) // RTO23d / RTPO4c
        #expect(try root.type() == .liveMap)

        // Already SYNCED: a second get() resolves immediately, still rooted at the empty path.
        let root2 = try await publicObject.get()
        #expect(root2.path.isEmpty)
    }

    // UTS: objects/unit/RTO23c/get-waits-for-synced-0 — RTO23c: get() before the sync completes waits, then
    // resolves once SYNCED.
    @Test
    func RTO23c_get_waits_for_synced() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        async let getTask = publicObject.get()
        // Confirm get() has parked waiting for the sync.
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        Self.driveToSynced(proxied, on: internalQueue)

        let root = try await getTask
        #expect(root.path.isEmpty)
    }

    // UTS: objects/unit/RTO23e/get-rejects-failed-0 — RTO23e/RTL33c: get() on a FAILED channel is rejected by
    // ensure-active-channel with code 90001 / statusCode 400.
    @Test
    func RTO23e_get_rejects_failed_channel() async throws {
        let (publicObject, _, _, _) = Self.makePublicObject(channelState: .failed)

        let error = await #expect(throws: ARTErrorInfo.self) {
            _ = try await publicObject.get()
        }
        #expect(error?.code == 90001)
        #expect(error?.statusCode == 400)
    }

    // UTS: objects/unit/RTO4b — get() resolves via an ATTACHED with HAS_OBJECTS false (no-objects sync
    // completion): the root is an empty map.
    @Test
    func RTO4b_get_resolves_after_no_objects_attach() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        async let getTask = publicObject.get()
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_onChannelAttached(hasObjects: false)
        }

        let root = try await getTask
        #expect(root.path.isEmpty)
        #expect(try root.size() == 0)
    }

    // MARK: - Status events (RTO17 / RTO18 / RTO19)

    // UTS: objects/unit/RTO17/sync-state-events-0 — RTO17b/RTO18b1/RTO18b2/RTO18e: on(.syncing) and
    // on(.synced) fire, in that order, as the sync completes. (Zero-arg callbacks — DEV-11.)
    @Test
    func RTO17_RTO18_sync_state_events() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        let events = EventLog()

        publicObject.on(event: .syncing) { events.append("SYNCING") }
        publicObject.on(event: .synced) { events.append("SYNCED") }

        Self.driveToSynced(proxied, on: internalQueue)
        await Self.drainMain()

        #expect(events.snapshot == ["SYNCING", "SYNCED"])
    }

    // UTS: objects/unit/RTO18/on-synced-fires-0 — RTO18: on(.synced) fires when the sync completes.
    @Test
    func RTO18_on_synced_fires() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            publicObject.on(event: .synced) { continuation.resume() }
            Self.driveToSynced(proxied, on: internalQueue)
        }
    }

    // UTS: objects/unit/RTO18d/duplicate-listener-0 — the SAME listener registered twice (via two on() calls)
    // fires twice per event (RTE4 reference behaviour; cocoa does not de-duplicate).
    @Test
    func RTO18d_duplicate_listener_fires_twice() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        let counter = CallCounter()
        let listener: @Sendable () -> Void = { counter.increment() }

        publicObject.on(event: .synced, callback: listener)
        publicObject.on(event: .synced, callback: listener)

        Self.driveToSynced(proxied, on: internalQueue)
        await Self.drainMain()

        #expect(counter.count == 2)
    }

    // UTS: objects/unit/RTO19/off-deregisters-0 — RTO19/RTO18f1: off() deregisters the listener; it is not
    // called for the subsequent sync.
    @Test
    func RTO19_off_deregisters() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        let counter = CallCounter()

        let subscription = publicObject.on(event: .synced) { counter.increment() }
        subscription.off()

        Self.driveToSynced(proxied, on: internalQueue)
        await Self.drainMain()

        #expect(counter.count == 0) // swiftformat:disable:this isEmpty — swiftlint:disable:this empty_count
    }

    // UTS: objects/unit/RTO17-RTO18/sync-event-sequences-0 (scenario "initial attach") — a first sync emits
    // [SYNCING, SYNCED] to listeners registered before it.
    @Test
    func RTO17_RTO18_sequence_initial_attach() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        let events = EventLog()
        publicObject.on(event: .syncing) { events.append("SYNCING") }
        publicObject.on(event: .synced) { events.append("SYNCED") }

        Self.driveToSynced(proxied, on: internalQueue)
        await Self.drainMain()

        #expect(events.snapshot == ["SYNCING", "SYNCED"])
    }

    // UTS: objects/unit/RTO17-RTO18/sync-event-sequences-0 (scenario "re-sync on new ATTACHED") — a new
    // ATTACHED (HAS_OBJECTS) followed by an OBJECT_SYNC re-emits [SYNCING, SYNCED].
    @Test
    func RTO17_RTO18_sequence_resync_on_attached() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        Self.driveToSynced(proxied, on: internalQueue) // reach SYNCED first
        await Self.drainMain()

        let events = EventLog()
        publicObject.on(event: .syncing) { events.append("SYNCING") }
        publicObject.on(event: .synced) { events.append("SYNCED") }

        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_onChannelAttached(hasObjects: true)
        }
        Self.driveToSynced(proxied, on: internalQueue)
        await Self.drainMain()

        #expect(events.snapshot == ["SYNCING", "SYNCED"])
    }

    // UTS: objects/unit/RTO17-RTO18/sync-event-sequences-0 (scenario "ATTACHED without HAS_OBJECTS") — RTO4c
    // emits SYNCING, RTO4b then completes immediately emitting SYNCED.
    @Test
    func RTO17_RTO18_sequence_attached_without_objects() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        Self.driveToSynced(proxied, on: internalQueue)
        await Self.drainMain()

        let events = EventLog()
        publicObject.on(event: .syncing) { events.append("SYNCING") }
        publicObject.on(event: .synced) { events.append("SYNCED") }

        internalQueue.ably_syncNoDeadlock {
            proxied.nosync_onChannelAttached(hasObjects: false)
        }
        await Self.drainMain()

        #expect(events.snapshot == ["SYNCING", "SYNCED"])
    }

    // MARK: - Access / write preconditions on channel state (RTO25b / RTO26b)

    // UTS: objects/unit/RTO25b/access-throws-detached-0 & access-throws-failed-0 — an access method (keys())
    // on a DETACHED/FAILED channel throws 90001 / 400.
    @Test(arguments: [_AblyPluginSupportPrivate.RealtimeChannelState.detached, .failed])
    func RTO25b_access_throws_on_unusable_state(state: _AblyPluginSupportPrivate.RealtimeChannelState) throws {
        let root = Self.makeRootPath(channelState: state)
        let error = #expect(throws: ARTErrorInfo.self) {
            _ = try root.keys()
        }
        #expect(error?.code == 90001)
        #expect(error?.statusCode == 400)
    }

    // UTS: objects/unit/RTO26b/write-throws-detached-0 & write-throws-failed-0 (+ SUSPENDED per RTO26b) — a
    // write (set()) on a DETACHED/FAILED/SUSPENDED channel throws 90001 / 400.
    @Test(arguments: [_AblyPluginSupportPrivate.RealtimeChannelState.detached, .failed, .suspended])
    func RTO26b_write_throws_on_unusable_state(state: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
        let root = Self.makeRootPath(channelState: state)
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await root.set(key: "name", value: .primitive(.string("Bob")))
        }
        #expect(error?.code == 90001)
        #expect(error?.statusCode == 400)
    }

    // MARK: - Dispose lifecycle

    // dispose() fails an in-flight get() that is waiting for sync (surfacing 92008), but the instance
    // remains usable for a later get().
    @Test
    func dispose_cancels_waiting_get_and_instance_stays_usable() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()

        async let getTask = publicObject.get()
        _ = try #require(await proxied.testsOnly_waitingForSyncEvents.first { _ in true })

        proxied.dispose()
        do {
            _ = try await getTask
            Issue.record("Expected the in-flight get() to be cancelled by dispose()")
        } catch {
            #expect((error as? ARTErrorInfo)?.code == 92008)
        }

        // The instance stays usable: a fresh sync + get() resolves.
        Self.driveToSynced(proxied, on: internalQueue)
        let root = try await publicObject.get()
        #expect(root.path.isEmpty)
    }

    // dispose() drops existing status subscriptions; a subscription registered afterwards still fires.
    @Test
    func dispose_drops_status_subscriptions_but_on_still_works() async throws {
        let (publicObject, proxied, _, internalQueue) = Self.makePublicObject()
        let preDispose = CallCounter()

        publicObject.on(event: .synced) { preDispose.increment() }
        proxied.dispose()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            publicObject.on(event: .synced) { continuation.resume() }
            Self.driveToSynced(proxied, on: internalQueue)
        }

        #expect(preDispose.count == 0) // swiftformat:disable:this isEmpty — swiftlint:disable:this empty_count
    }
}
