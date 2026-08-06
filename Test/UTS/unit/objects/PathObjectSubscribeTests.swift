// Derived from the UTS spec `objects/unit/path_object_subscribe.md`.

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

/// `PathObject` subscriptions — path-registered listeners, RTO24 depth-window coverage, the
/// getFullPaths fan-out, and the delivered event's `object`/`message`.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/path_object_subscribe.md
/// (spec points `RTPO19`, `RTO24`, `RTO25`).
///
/// The spec drives every case through `setup_synced_channel` + `mock_ws.send_to_client`. Path dispatch
/// is owned by the engine's apply path (`RTLO4b4c3b -> RTO24b`), so — unlike the resolution/read/write
/// ports (which use a lightweight seeded double) — these drive the **real**
/// ``InternalDefaultRealtimeObjects``: the standard graph is seeded into the engine's owned pool via
/// `testsOnly_setPoolEntry` + `testsOnly_setParentReferences`, and inbound OBJECT / OBJECT_SYNC frames
/// are replayed via `testsOnly_applyObjectMessages` / `nosync_handleObjectSyncProtocolMessage` (the
/// unit stand-in for `mock_ws.send_to_client`). This mirrors the native `PathObjectSubscriptionTests`;
/// no mock-WS / connection is opened. Subscriber callbacks run on the engine's `userCallbackQueue`,
/// drained with a `sync {}` barrier before asserting.
///
/// ## Deviations (recorded in deviations.md)
/// - **RTO24b2b (event object = chosen candidate path):** the event's `object.path` is the chosen
///   (most-preferred) covered candidate path, not the raw change site.
/// - **RTLO4b4c3c1 (path subs survive tombstone):** covered by the native suite; a tombstone update is
///   delivered and the path subscription is NOT torn down.
/// - **RTO4b2a (sync events carry no message):** a sync-originated update delivers `event.message == nil`.
///
/// ## Skipped — out of UNIT scope
/// - **RTPO19g (subscribe has no side effects on channel state):** needs a real channel/connection to
///   observe `channel.state`; the unit fixture has only a fixed `CoreSDK` state.
@Suite(.serialized)
final class PathObjectSubscribeTests {
    private static let channelName = "test"

    // MARK: - Fixture

    private struct Fixture {
        let engine: InternalDefaultRealtimeObjects
        let coreSDK: ObjectsUTSCoreSDK
        let internalQueue: DispatchQueue
        let userCallbackQueue: DispatchQueue
    }

    private static func makeFixture(channelState: _AblyPluginSupportPrivate.RealtimeChannelState = .attached) -> Fixture {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let userCallbackQueue = DispatchQueue(label: "PathObjectSubscribeTests.userCallback")
        let coreSDK = ObjectsUTSCoreSDK(channelState: channelState)
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
    /// engine's owned pool, with the standard parentReferences so path dispatch resolves full paths.
    private static func seedStandardGraph(_ f: Fixture) {
        let score = makeCounter(objectID: "counter:score@1000", data: 100, f)
        let nested = makeCounter(objectID: "counter:nested@1000", data: 5, f)
        // Entries are seeded at POOL_SERIAL "t:0" so remote MAP_SET serials ("t:1", "t:2", …) win the
        // per-entry LWW comparison (RTLM9e) exactly as in the spec's standard pool.
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

    private static func syncAndDrain(_ messages: [ProtocolTypes.InboundObjectMessage], _ f: Fixture) {
        f.internalQueue.ably_syncNoDeadlock {
            f.engine.nosync_handleObjectSyncProtocolMessage(objectMessages: messages, protocolMessageChannelSerial: nil)
        }
        f.userCallbackQueue.sync {}
    }

    // MARK: - RTPO19: subscribe receives events

    // UTS: objects/unit/RTPO19/subscribe-receives-events-0 — RTPO19d/e1/e2: a Subscription is returned, the
    // event's object points at the change path, and the event carries the source public ObjectMessage.
    @Test
    func RTPO19_subscribe_receives_events() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let collector = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "score").subscribe(listener: collector.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")], f)

        #expect(collector.events.count == 1)
        let event = try #require(collector.events.first)
        #expect(event.object.path == "score") // RTPO19e1
        let message = try #require(event.message) // RTPO19e2
        #expect(message.serial == "99")
        #expect(message.siteCode == "remote")
        #expect(message.operation.action == .counterInc)
        #expect(message.channel == Self.channelName)
    }

    // UTS: objects/unit/RTPO19e1/event-path-object-correct-0 — RTPO19e1: the event's PathObject resolves to
    // the just-updated value (100 + 7 = 107).
    @Test
    func RTPO19e1_event_path_object_correct() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let collector = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).subscribe(listener: collector.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")], f)

        let event = try #require(collector.events.first)
        #expect(event.object.path == "score")
        #expect(try event.object.asLiveCounter().value() == 107)
    }

    // UTS: objects/unit/RTPO19e2/event-message-delivery-0 — RTPO19e2/RTO24b2b2: the event's message copies
    // channel/serial/siteCode/operation from the source ObjectMessage.
    @Test
    func RTPO19e2_event_message_delivery() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let collector = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "score").subscribe(listener: collector.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 42, serial: "serial-1", siteCode: "site-a")], f)

        let message = try #require(collector.events.first?.message)
        #expect(message.channel == Self.channelName)
        #expect(message.serial == "serial-1")
        #expect(message.siteCode == "site-a")
        #expect(message.operation.action == .counterInc)
        #expect(message.operation.objectId == "counter:score@1000")
        #expect(message.operation.counterInc?.number == 42)
    }

    // UTS: objects/unit/RTPO19e2/event-message-omitted-no-operation-0 — RTO4b2a: a sync-triggered update has
    // no operation, so the delivered event has no message.
    @Test
    func RTPO19e2_event_message_omitted_for_sync() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let collector = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "score").subscribe(options: .init(depth: 1), listener: collector.listener)
        defer { sub.unsubscribe() }

        // Re-state root unchanged (noop diff) and change the counter's value via sync (200).
        Self.syncAndDrain(
            [
                ObjectsUTS.rootSyncMessage(entries: [
                    "name": ObjectsUTS.wireMapEntry(data: ProtocolTypes.ObjectData(string: "Alice")),
                    "score": ObjectsUTS.wireMapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:score@1000")),
                    "profile": ObjectsUTS.wireMapEntry(data: ProtocolTypes.ObjectData(objectId: "map:profile@1000")),
                ]),
                ObjectsUTS.counterSyncMessage(objectId: "counter:score@1000", count: 200),
            ],
            f,
        )

        #expect(collector.events.count == 1)
        #expect(collector.events.first?.object.path == "score")
        #expect(collector.events.first?.message == nil) // RTO4b2a
    }

    // MARK: - RTPO19b: access-config guard (RTO25)

    // UTS: objects/unit/RTPO19b/subscribe-precondition-detached-0 — RTO25b: subscribe on a DETACHED/FAILED
    // channel throws 90001/400.
    @Test(arguments: [_AblyPluginSupportPrivate.RealtimeChannelState.detached, .failed])
    func RTPO19b_subscribe_precondition_unusable_state(state: _AblyPluginSupportPrivate.RealtimeChannelState) throws {
        let f = Self.makeFixture(channelState: state)
        let error = #expect(throws: ARTErrorInfo.self) {
            _ = try Self.rootPath(f).subscribe { _ in }
        }
        #expect(error?.code == 90001)
        #expect(error?.statusCode == 400)
    }

    // MARK: - RTPO19c1a: depth validation (DEV-9)

    // UTS: objects/unit/RTPO19c1a/subscribe-non-positive-depth-throws-0 & subscribe-negative-depth-throws-0
    // — a non-positive depth throws 40003.
    @Test(arguments: [0, -1])
    func RTPO19c1a_non_positive_depth_throws(depth: Int) throws {
        let f = Self.makeFixture()
        let error = #expect(throws: ARTErrorInfo.self) {
            _ = try Self.rootPath(f).subscribe(options: .init(depth: depth)) { _ in }
        }
        #expect(error?.code == 40003)
    }

    // MARK: - RTPO19c1 / RTO24c1: depth-window coverage

    // UTS: objects/unit/RTPO19c1/subscribe-depth-1-self-only-0 — depth=1 covers only the exact path.
    @Test
    func RTPO19c1_depth_1_self_only() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()
        let control = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).subscribe(options: .init(depth: 1), listener: events.listener)
        let ctrl = try Self.rootPath(f).subscribe(listener: control.listener) // unlimited depth
        defer { sub.unsubscribe(); ctrl.unsubscribe() }

        // Self event (root map update) — covered at depth 1.
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "t:1", siteCode: "remote")], f)
        #expect(events.events.count == 1)

        // Child event (root["score"] counter) — relativeDepth 2 > 1, NOT covered. Control (unlimited)
        // fires, giving the negative-assertion quiescence barrier.
        let controlBefore = control.events.count
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "100", siteCode: "remote")], f)
        #expect(control.events.count > controlBefore)
        #expect(events.events.count == 1)
    }

    // UTS: objects/unit/RTPO19c1/subscribe-depth-2-children-0 — depth=2 covers self and one level of children.
    @Test
    func RTPO19c1_depth_2_children() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()
        let control = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).subscribe(options: .init(depth: 2), listener: events.listener)
        let ctrl = try Self.rootPath(f).subscribe(listener: control.listener)
        defer { sub.unsubscribe(); ctrl.unsubscribe() }

        // Self (root) — covered.
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "t:1", siteCode: "remote")], f)
        #expect(events.events.count == 1)

        // Child (root["score"], relativeDepth 2) — covered.
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "100", siteCode: "remote")], f)
        #expect(events.events.count == 2)

        // Grandchild (root["profile"]["nested_counter"], relativeDepth 3) — NOT covered.
        let controlBefore = control.events.count
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:nested@1000", number: 1, serial: "101", siteCode: "remote")], f)
        #expect(control.events.count > controlBefore)
        #expect(events.events.count == 2)
    }

    // UTS: objects/unit/RTPO19c1/subscribe-unlimited-depth-0 — no depth: events at any depth.
    @Test
    func RTPO19c1_unlimited_depth() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).subscribe(listener: events.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "t:1", siteCode: "remote")], f)
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "100", siteCode: "remote")], f)
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: "map:prefs@1000", key: "theme", value: ProtocolTypes.ObjectData(string: "light"), serial: "t:2", siteCode: "remote")], f)

        #expect(events.events.count >= 3)
    }

    // UTS: objects/unit/RTO24c1/depth-filtering-formula-0 — subPath prefix + depth-window formula: subscribe
    // at "profile" depth 2 covers self and child, not grandchild.
    @Test
    func RTO24c1_depth_filtering_formula() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        // Seed a grandchild counter:deep under profile.prefs so the grandchild stimulus is a single
        // depth-3 candidate (a COUNTER_INC yields only its own path).
        let deep = Self.makeCounter(objectID: "counter:deep@3000", f)
        f.engine.testsOnly_setPoolEntry(.counter(deep), forObjectID: "counter:deep@3000")
        deep.testsOnly_setParentReferences(["map:prefs@1000": ["deep"]])
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: "map:prefs@1000", key: "deep", value: ProtocolTypes.ObjectData(objectId: "counter:deep@3000"), serial: "50", siteCode: "remote")], f)

        let events = ObjectsUTSPathEventCollector()
        let control = ObjectsUTSPathEventCollector()
        let sub = try Self.rootPath(f).get(key: "profile").subscribe(options: .init(depth: 2), listener: events.listener)
        let ctrl = try Self.rootPath(f).subscribe(listener: control.listener)
        defer { sub.unsubscribe(); ctrl.unsubscribe() }

        // Self (profile) — covered.
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: "map:profile@1000", key: "email", value: ProtocolTypes.ObjectData(string: "bob@example.com"), serial: "t:1", siteCode: "remote")], f)
        #expect(events.events.count == 1)

        // Child (profile.nested_counter, relativeDepth 2) — covered.
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:nested@1000", number: 3, serial: "100", siteCode: "remote")], f)
        #expect(events.events.count == 2)

        // Grandchild (profile.prefs.deep, relativeDepth 3) — NOT covered.
        let controlBefore = control.events.count
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:deep@3000", number: 1, serial: "101", siteCode: "remote")], f)
        #expect(control.events.count > controlBefore)
        #expect(events.events.count == 2)
    }

    // UTS: objects/unit/RTO24c1/prefix-mismatch-0 — a subscription at "profile" ignores sibling changes.
    @Test
    func RTO24c1_prefix_mismatch() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let profileEvents = ObjectsUTSPathEventCollector()
        let control = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "profile").subscribe(listener: profileEvents.listener)
        let ctrl = try Self.rootPath(f).subscribe(listener: control.listener)
        defer { sub.unsubscribe(); ctrl.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")], f)
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "t:1", siteCode: "remote")], f)

        #expect(control.events.count >= 2) // quiescence: both sends delivered
        #expect(profileEvents.events.isEmpty)
    }

    // MARK: - RTPO19d: Subscription unsubscribe (SUB2)

    // UTS: objects/unit/RTPO19d/subscribe-returns-subscription-0 — unsubscribe stops further delivery.
    @Test
    func RTPO19d_unsubscribe_stops_delivery() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()
        let control = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "score").subscribe(listener: events.listener)
        let ctrl = try Self.rootPath(f).get(key: "score").subscribe(listener: control.listener)
        defer { ctrl.unsubscribe() }

        sub.unsubscribe()
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")], f)

        #expect(control.events.count >= 1) // quiescence: the still-subscribed control fired
        #expect(events.events.isEmpty)
    }

    // MARK: - RTPO19f: subscription follows path, not identity

    // UTS: objects/unit/RTPO19f/subscribe-follows-path-0 — after "score" is repointed to a new counter, the
    // subscription still receives that new counter's events.
    @Test
    func RTPO19f_subscribe_follows_path() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "score").subscribe(listener: events.listener)
        defer { sub.unsubscribe() }

        // Repoint root["score"] to a brand-new counter, then increment the new counter.
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "score", value: ProtocolTypes.ObjectData(objectId: "counter:new@2000"), serial: "t:1", siteCode: "remote")], f)
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:new@2000", number: 10, serial: "100", siteCode: "remote")], f)

        #expect(events.events.contains { $0.object.path == "score" })
    }

    // MARK: - RTPO19: primitive path & MAP_CLEAR

    // UTS: objects/unit/RTPO19/subscribe-primitive-path-0 — a subscription on a primitive path fires when
    // the map entry at that key changes.
    @Test
    func RTPO19_subscribe_primitive_path() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "name").subscribe(listener: events.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "t:1", siteCode: "remote")], f)

        #expect(events.events.count == 1)
        #expect(events.events.first?.object.path == "name")
    }

    // UTS: objects/unit/RTPO19/map-clear-triggers-child-events-0 — MAP_CLEAR fans out to subscriptions.
    @Test
    func RTPO19_map_clear_triggers_events() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).subscribe(listener: events.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.mapClearMessage(objectId: ObjectsPool.rootKey, serial: "99", siteCode: "remote")], f)

        #expect(events.events.count >= 1)
    }

    // UTS: objects/unit/RTPO19/child-events-bubble-0 — child events bubble up to a parent subscription.
    @Test
    func RTPO19_child_events_bubble() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).get(key: "profile").subscribe(listener: events.listener)
        defer { sub.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: "map:profile@1000", key: "email", value: ProtocolTypes.ObjectData(string: "bob@example.com"), serial: "t:1", siteCode: "remote")], f)
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:nested@1000", number: 3, serial: "100", siteCode: "remote")], f)

        #expect(events.events.count >= 2)
    }

    // MARK: - RTO24b: candidate-path construction & multi-path dispatch

    // UTS: objects/unit/RTO24b2a/candidate-paths-map-keys-0 — a MAP_SET on root with key "score" notifies
    // both the root subscription (candidate []) and the "score" subscription (candidate ["score"]).
    @Test
    func RTO24b2a_candidate_paths_map_keys() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let scoreEvents = ObjectsUTSPathEventCollector()
        let rootEvents = ObjectsUTSPathEventCollector()

        let subScore = try Self.rootPath(f).get(key: "score").subscribe(listener: scoreEvents.listener)
        let subRoot = try Self.rootPath(f).subscribe(listener: rootEvents.listener)
        defer { subScore.unsubscribe(); subRoot.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "score", value: ProtocolTypes.ObjectData(objectId: "counter:new@2000"), serial: "t:1", siteCode: "remote")], f)

        #expect(scoreEvents.events.count == 1)
        #expect(scoreEvents.events.first?.object.path == "score")
        #expect(rootEvents.events.count == 1)
    }

    // UTS: objects/unit/RTO24b2b/fires-once-per-dispatch-0 — a subscription covering multiple candidates
    // fires exactly once per dispatch (with the most-preferred candidate).
    @Test
    func RTO24b2b_fires_once_per_dispatch() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let events = ObjectsUTSPathEventCollector()

        let sub = try Self.rootPath(f).subscribe(listener: events.listener) // unlimited: covers [] and ["score"]
        defer { sub.unsubscribe() }

        // MAP_SET on root key "score": candidates [] and ["score"] — fires once.
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "score", value: ProtocolTypes.ObjectData(objectId: "counter:new@2000"), serial: "t:1", siteCode: "remote")], f)
        // Control single-candidate dispatch — quiescence barrier.
        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:new@2000", number: 1, serial: "100", siteCode: "remote")], f)

        #expect(events.events.count == 2)
    }

    // UTS: objects/unit/RTO24b1/multi-path-dispatch-0 — an object reachable via two paths notifies both.
    @Test
    func RTO24b1_multi_path_dispatch() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let scoreEvents = ObjectsUTSPathEventCollector()
        let aliasEvents = ObjectsUTSPathEventCollector()

        // Add a second reference "alias" -> counter:score@1000 so it has two full paths.
        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "alias", value: ProtocolTypes.ObjectData(objectId: "counter:score@1000"), serial: "98", siteCode: "remote")], f)

        let subScore = try Self.rootPath(f).get(key: "score").subscribe(listener: scoreEvents.listener)
        let subAlias = try Self.rootPath(f).get(key: "alias").subscribe(listener: aliasEvents.listener)
        defer { subScore.unsubscribe(); subAlias.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 5, serial: "99", siteCode: "remote")], f)

        #expect(scoreEvents.events.count == 1)
        #expect(scoreEvents.events.first?.object.path == "score")
        #expect(aliasEvents.events.count == 1)
        #expect(aliasEvents.events.first?.object.path == "alias")
    }

    // UTS: objects/unit/RTO24b2c/listener-exception-caught-0 — the spec's throwing-listener branch is
    // compile-time-unrepresentable: `PathObjectSubscriptionCallback` is a non-throwing `@Sendable`
    // closure, so a listener cannot throw (recorded in deviations.md). The observable part —
    // one listener's dispatch does not stop another's — is exercised with two independent listeners.
    @Test
    func RTO24b2c_multiple_listeners_independent() throws {
        let f = Self.makeFixture()
        Self.seedStandardGraph(f)
        let first = ObjectsUTSPathEventCollector()
        let second = ObjectsUTSPathEventCollector()

        let sub1 = try Self.rootPath(f).subscribe(listener: first.listener)
        let sub2 = try Self.rootPath(f).subscribe(listener: second.listener)
        defer { sub1.unsubscribe(); sub2.unsubscribe() }

        Self.applyAndDrain([ObjectsUTS.mapSetMessage(objectId: ObjectsPool.rootKey, key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "t:1", siteCode: "remote")], f)

        #expect(first.events.count == 1)
        #expect(second.events.count == 1)
    }
}
