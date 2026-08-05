// Derived from the UTS spec `objects/unit/live_object_subscribe.md`.

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

/// `Instance#subscribe` (RTINS16) — data-update delivery, `Subscription` lifecycle, noop suppression,
/// the enriched `InstanceSubscriptionEvent.message`, and tombstone teardown.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/live_object_subscribe.md
/// (spec points `RTLO4b`, `RTLO4b3`, `RTLO4b4c1`, `RTLO4b4c3a`, `RTLO4b4c3c`, `RTLO4b4d`, `RTLO4b4e`,
/// `RTLO4b6`, `RTLO4b7`).
///
/// The spec drives every case through `setup_synced_channel` + `mock_ws.send_to_client` and subscribes
/// via `root.get("score").instance()` (RTINS16). Instance-subscribe delivery is owned by the engine's
/// apply path (a node emits to its own subscribers, RTLO4b4c3a), and the enriched
/// `InstanceSubscriptionEvent.message` is the public `ObjectMessage` the engine derives from the inbound
/// frame (`toPublicObjectMessage`). So — like `PathObjectSubscribeTests` — these drive the **real**
/// `InternalDefaultRealtimeObjects`: the standard graph is seeded into the engine's owned pool via
/// `testsOnly_setPoolEntry` + `testsOnly_setParentReferences`, and inbound OBJECT frames are replayed
/// via `testsOnly_applyObjectMessages` (the unit stand-in for `mock_ws.send_to_client`). Instances are
/// obtained through the production seam `root.get(key:).instance()`; subscriber callbacks run on the
/// engine's `userCallbackQueue`, drained with a `sync {}` barrier before asserting. No mock-WS /
/// connection is opened. Mirrors the native `DefaultInstanceTests` tombstone/subscribe cases.
///
/// ## Deviations (recorded in deviations.md)
/// - **DEV-1 (Instance enum):** the spec's `instance.subscribe(...)` is reached by unwrapping the
///   `Instance` enum to its concrete `.liveCounter` / `.liveMap` payload (`LiveCounterInstance` /
///   `LiveMapInstance`), each of which carries `subscribe`.
/// - **RTLO4b4c1 noop shape:** the spec's `counterInc: {}` (present but number-less) is represented in
///   cocoa by an absent `counterInc` (its `WireCounterInc.number` is non-optional) — the same RTLC9h
///   noop branch.
@Suite(.serialized)
final class LiveObjectSubscribeTests {
    private static let channelName = "test"

    // MARK: - Fixture (shared with PathObjectSubscribeTests' pattern)

    private struct Fixture {
        let engine: InternalDefaultRealtimeObjects
        let coreSDK: ObjectsUTSCoreSDK
        let internalQueue: DispatchQueue
        let userCallbackQueue: DispatchQueue
    }

    private static func makeFixture() -> Fixture {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let userCallbackQueue = DispatchQueue(label: "LiveObjectSubscribeTests.userCallback")
        let coreSDK = ObjectsUTSCoreSDK(channelState: .attached)
        let engine = InternalDefaultRealtimeObjects(
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: userCallbackQueue,
            clock: MockSimpleClock(),
            channelName: channelName,
        )
        return Fixture(engine: engine, coreSDK: coreSDK, internalQueue: internalQueue, userCallbackQueue: userCallbackQueue)
    }

    private static func rootPath(_ f: Fixture) -> DefaultLiveMapPathObject {
        DefaultLiveMapPathObject(channelObject: f.engine, coreSDK: f.coreSDK, internalQueue: f.internalQueue, path: "")
    }

    private static func makeCounter(objectID: String, data: Double = 0, _ f: Fixture) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter(testsOnly_data: data, objectID: objectID, logger: TestLogger(), internalQueue: f.internalQueue, userCallbackQueue: f.userCallbackQueue, clock: MockSimpleClock())
    }

    private static func makeMap(objectID: String, data: [String: InternalObjectsMapEntry] = [:], _ f: Fixture) -> InternalDefaultLiveMap {
        InternalDefaultLiveMap(testsOnly_data: data, objectID: objectID, logger: TestLogger(), internalQueue: f.internalQueue, userCallbackQueue: f.userCallbackQueue, clock: MockSimpleClock())
    }

    /// Seeds the standard test graph (root + score/nested counters + profile/prefs maps) into the
    /// engine's owned pool, with the standard parentReferences so path resolution reaches every node.
    /// Entries are seeded at POOL_SERIAL "t:0" so remote MAP_SET serials ("t:1", …) win per-entry LWW.
    private static func seedStandardGraph(_ f: Fixture) {
        let score = makeCounter(objectID: "counter:score@1000", data: 100, f)
        let nested = makeCounter(objectID: "counter:nested@1000", data: 5, f)
        let prefs = makeMap(objectID: "map:prefs@1000", data: ["theme": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "dark"), timeserial: "t:0")], f)
        let profile = makeMap(
            objectID: "map:profile@1000",
            data: [
                "email": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "alice@example.com"), timeserial: "t:0"),
                "nested_counter": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:nested@1000"), timeserial: "t:0"),
                "prefs": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "map:prefs@1000"), timeserial: "t:0"),
            ],
            f,
        )
        let root = makeMap(
            objectID: ObjectsPool.rootKey,
            data: [
                "name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "t:0"),
                "score": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:score@1000"), timeserial: "t:0"),
                "profile": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "map:profile@1000"), timeserial: "t:0"),
            ],
            f,
        )
        f.engine.testsOnly_setPoolEntry(.counter(score), forObjectID: "counter:score@1000")
        f.engine.testsOnly_setPoolEntry(.counter(nested), forObjectID: "counter:nested@1000")
        f.engine.testsOnly_setPoolEntry(.map(prefs), forObjectID: "map:prefs@1000")
        f.engine.testsOnly_setPoolEntry(.map(profile), forObjectID: "map:profile@1000")
        f.engine.testsOnly_setPoolEntry(.map(root), forObjectID: ObjectsPool.rootKey)
        score.testsOnly_setParentReferences([ObjectsPool.rootKey: ["score"]])
        profile.testsOnly_setParentReferences([ObjectsPool.rootKey: ["profile"]])
        nested.testsOnly_setParentReferences(["map:profile@1000": ["nested_counter"]])
        prefs.testsOnly_setParentReferences(["map:profile@1000": ["prefs"]])
    }

    private static func applyAndDrain(_ messages: [ProtocolTypes.InboundObjectMessage], _ f: Fixture) {
        f.engine.testsOnly_applyObjectMessages(messages, source: .channel)
        f.userCallbackQueue.sync {}
    }

    /// The `.liveCounter` instance for `root.get(key)` (RTINS16 wrapping via `PathObject.instance()`).
    private static func counterInstance(_ f: Fixture, key: String) throws -> any LiveCounterInstance {
        let instance = try #require(try Self.rootPath(f).get(key: key).instance())
        guard case let .liveCounter(counterInstance) = instance else {
            throw NSError(domain: "LiveObjectSubscribeTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expected .liveCounter for \(key)"])
        }
        return counterInstance
    }

    /// The `.liveMap` instance for `root.get(key)` (or root itself when `key` is nil).
    private static func mapInstance(_ f: Fixture, key: String?) throws -> any LiveMapInstance {
        let pathObject: any PathObject = key.map { Self.rootPath(f).get(key: $0) } ?? Self.rootPath(f)
        let instance = try #require(try pathObject.instance())
        guard case let .liveMap(mapInstance) = instance else {
            throw NSError(domain: "LiveObjectSubscribeTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expected .liveMap"])
        }
        return mapInstance
    }

    // MARK: - RTLO4b: subscribe registers a listener for data updates

    // UTS: objects/unit/RTLO4b/subscribe-receives-updates-0 — RTLO4b3/RTLO4b4c3a/RTLO4b7: a Subscription is
    // returned and the listener is called with the update.
    @Test
    func RTLO4b_subscribe_receives_updates() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let collector = ObjectsUTSInstanceEventCollector()

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe(listener: collector.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")], f)

        #expect(collector.events.count == 1)
    }

    // UTS: objects/unit/RTLO4b7/subscribe-returns-subscription-0 — RTLO4b7: `subscribe` returns a
    // `Subscription` with an `unsubscribe` method (the returned value is usable to deregister).
    @Test
    func RTLO4b7_subscribe_returns_subscription() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe { _ in }
        // A Subscription is returned; unsubscribe is callable (idempotently).
        sub.unsubscribe()
    }

    // UTS: objects/unit/RTLO4b7/subscription-unsubscribe-stops-delivery-0 — after `unsubscribe()`, subsequent
    // updates do not reach the listener (verified via a still-subscribed control listener).
    @Test
    func RTLO4b7_unsubscribe_stops_delivery() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let updates = ObjectsUTSInstanceEventCollector()
        let control = ObjectsUTSInstanceEventCollector()

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe(listener: updates.listener)

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 5, serial: "01", siteCode: "remote")], f)
        #expect(updates.events.count == 1)

        sub.unsubscribe()

        // Negative-assertion quiescence: a control listener that WILL fire on the next dispatch.
        let ctrl = try instance.subscribe(listener: control.listener)
        defer { ctrl.unsubscribe() }
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 10, serial: "02", siteCode: "remote")], f)

        #expect(control.events.count >= 1) // control delivered — an unsubscribed listener would also have fired
        #expect(updates.events.count == 1) // …but it did not
    }

    // UTS: objects/unit/RTLO4b7/subscription-unsubscribe-idempotent-0 — calling `unsubscribe()` twice does not
    // throw.
    @Test
    func RTLO4b7_unsubscribe_idempotent() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe { _ in }
        sub.unsubscribe()
        sub.unsubscribe()
    }

    // MARK: - RTLO4b4c1: noop update does not trigger the listener

    // UTS: objects/unit/RTLO4b4c1/noop-no-trigger-0 — a number-less COUNTER_INC yields a `.noop` (RTLC9h) and
    // must not fire the listener; the surrounding "01"/"03" increments (which do fire) bracket it.
    @Test
    func RTLO4b4c1_noop_no_trigger() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let updates = ObjectsUTSInstanceEventCollector()
        let control = ObjectsUTSInstanceEventCollector()

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe(listener: updates.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 5, serial: "01", siteCode: "remote")], f)
        #expect(updates.events.count == 1)

        // The noop "02": passes the newness check but produces no LiveObjectUpdate.
        Self.applyAndDrain([ObjectsUTS.counterIncNoopMessage(objectId: "counter:score@1000", serial: "02", siteCode: "remote")], f)

        // Quiescence via a separate control listener: "03" is dispatched after the noop, so once the
        // control fires the noop has certainly been processed.
        let ctrl = try instance.subscribe(listener: control.listener)
        defer { ctrl.unsubscribe() }
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 3, serial: "03", siteCode: "remote")], f)
        #expect(control.events.count >= 1)

        // The noop produced no update: the original listener fired only for "01" and "03".
        #expect(updates.events.count == 2)
    }

    // MARK: - RTLO4b6: subscribe has no side effects

    // UTS: objects/unit/RTLO4b6/subscribe-no-side-effects-0 — subscribing must not mutate the channel state.
    // (The spec observes `channel.state`; the unit fixture has only the fixed `CoreSDK` state, so the
    // observable subset is that subscribe neither throws nor changes that state.)
    @Test
    func RTLO4b6_subscribe_no_side_effects() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let stateBefore = f.coreSDK.nosync_channelState

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe { _ in }
        defer { sub.unsubscribe() }

        #expect(f.coreSDK.nosync_channelState == stateBefore)
    }

    // MARK: - RTLO4b: subscribe on a map instance receives a LiveMapUpdate

    // UTS: objects/unit/RTLO4b/subscribe-map-update-0 — a MAP_SET on the subscribed map fires its listener.
    @Test
    func RTLO4b_subscribe_map_update() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let updates = ObjectsUTSInstanceEventCollector()

        let instance = try Self.mapInstance(f, key: nil) // root map
        let sub = try instance.subscribe(listener: updates.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "t:1", siteCode: "remote")], f)

        #expect(updates.events.count == 1)
    }

    // MARK: - RTLO4b4c3c: tombstone deregisters all Instance#subscribe listeners

    // UTS: objects/unit/RTLO4b4c3c/tombstone-deregisters-listeners-0 — an OBJECT_DELETE tombstone is delivered
    // to every listener (RTLO4b4c3a) and then deregisters them (RTLO4b4c3c); subsequent operations to
    // the tombstoned object do not fire the (now-deregistered) listeners.
    @Test
    func RTLO4b4c3c_tombstone_deregisters_listeners() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let updatesA = ObjectsUTSInstanceEventCollector()
        let updatesB = ObjectsUTSInstanceEventCollector()
        let control = ObjectsUTSInstanceEventCollector()

        let instance = try Self.counterInstance(f, key: "score")
        let subA = try instance.subscribe(listener: updatesA.listener)
        let subB = try instance.subscribe(listener: updatesB.listener)
        defer { subA.unsubscribe(); subB.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.objectDeleteMessage(objectId: "counter:score@1000", serial: "50", siteCode: "remote")], f)

        // Both listeners received the tombstone update.
        #expect(updatesA.events.count == 1)
        #expect(updatesA.events.first?.message?.operation.action == .objectDelete)
        #expect(updatesB.events.count == 1)
        #expect(updatesB.events.first?.message?.operation.action == .objectDelete)

        // Quiescence: a tombstoned object ignores further ops (RTLC7e), so use a SEPARATE live object as
        // the control barrier. Once the control fires, the "51" dispatch to the dead object is processed.
        let controlInstance = try Self.mapInstance(f, key: "profile")
        let ctrl = try controlInstance.subscribe(listener: control.listener)
        defer { ctrl.unsubscribe() }
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 3, serial: "51", siteCode: "remote")], f)
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: "map:profile@1000", key: "quiescence_probe", value: ProtocolTypes.ObjectData(string: "x"), serial: "52", siteCode: "remote")], f)
        #expect(control.events.count >= 1)

        // The deregistered listeners did not fire again.
        #expect(updatesA.events.count == 1)
        #expect(updatesB.events.count == 1)
    }

    // MARK: - RTLO4b4d: the event carries the source public ObjectMessage

    // UTS: objects/unit/RTLO4b4d/update-has-object-message-0 — RTLO4b4d/RTINS16e: the delivered event carries
    // the public `ObjectMessage` derived from the triggering inbound frame.
    @Test
    func RTLO4b4d_update_has_object_message() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let updates = ObjectsUTSInstanceEventCollector()

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe(listener: updates.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")], f)

        #expect(updates.events.count == 1)
        let message = try #require(updates.events.first?.message)
        #expect(message.serial == "99")
        #expect(message.siteCode == "remote")
        #expect(message.operation.action == .counterInc)
        #expect(message.operation.objectId == "counter:score@1000")
        #expect(message.channel == Self.channelName)
    }

    // MARK: - RTLO4b4e: tombstone identified by OBJECT_DELETE action

    // UTS: objects/unit/RTLO4b4e/tombstone-flag-true-0 — a tombstoning event carries an OBJECT_DELETE action.
    @Test
    func RTLO4b4e_tombstone_flag_true() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let updates = ObjectsUTSInstanceEventCollector()

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe(listener: updates.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.objectDeleteMessage(objectId: "counter:score@1000", serial: "50", siteCode: "remote")], f)

        #expect(updates.events.count == 1)
        #expect(updates.events.first?.message?.operation.action == .objectDelete)
    }

    // UTS: objects/unit/RTLO4b4e/tombstone-flag-false-0 — a normal update carries a non-OBJECT_DELETE action.
    @Test
    func RTLO4b4e_tombstone_flag_false() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let updates = ObjectsUTSInstanceEventCollector()

        let instance = try Self.counterInstance(f, key: "score")
        let sub = try instance.subscribe(listener: updates.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")], f)

        #expect(updates.events.count == 1)
        #expect(updates.events.first?.message?.operation.action == .counterInc)
    }
}
