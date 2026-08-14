// Derived from the UTS spec `objects/unit/instance.md`.
//
// Drives the public ``Instance`` API (RTINS3–RTINS16) over the standard LiveObjects tree. The spec's
// `{ client, channel, root, mock_ws } = AWAIT setup_synced_channel("test")` fixture (a mock-WebSocket
// synced channel) has no unit-tier counterpart: the standard pool is seeded straight into an
// `ObjectsPool` (`ObjectsUTS.standardPool`) behind an `ObjectsUTSSeededRealtimeObjects`, and the
// spec's `root` is a `DefaultLiveMapPathObject` over it; `root.instance()` / `root.get(key).instance()`
// yield the `Instance` payloads the spec exercises. Writes go through the seeded double, which BOTH
// captures the published message AND asynchronously applies it back onto the pool entry (the RTO20 ACK
// echo), so post-write value reads (`value() == 125`, `get("name").value() == "Bob"`) are portable. The
// subscribe ports stand in for `mock_ws.send_to_client(build_object_message(...))` by applying the
// inbound operation directly to the seeded node (queue-confined), then draining the event collector's
// callback queue — never sleeping. The RTINS16e2 delivery-boundary port sets the CoreSDK channel name so
// the projected PAOM3 message carries it (PAOM2e).
//
// The access/write-API precondition rows (RTINS4a/RTINS5b/RTINS6a/RTINS9a/RTINS10a/RTINS12b/RTINS13b/
// RTINS14b/RTINS15b/RTINS16b -> RTO25/RTO26) are not separately asserted here — they are the subject of
// `objects/unit/realtime_object.md`; the node accessors run those checks and pass under this fixture's
// ATTACHED, object-mode channel.
//
// Deviations from the UTS spec (see Test/UTS/deviations.md):
// - (D-1) RTINS4d (`map_inst.value() == null`) and RTINS9c (`counter_inst.size() == null`) are not
//   expressible: the `Instance` payload protocols expose only the members applicable to the wrapped
//   kind (objects-mapping §5), so `LiveMapInstance` has no `value` and `LiveCounterInstance` has no
//   `size`. The absent-member is a compile-time structural guarantee, stronger than a runtime null; the
//   expressible (counter/map) half of each case is ported.
// - (D-2) RTINS12d / RTINS14d / RTINS16c (wrong-type write/subscribe on an Instance, expecting 92007)
//   are not expressible: `Instance` is an enum with no `as*` casts, so a `.liveCounter` payload has no
//   `set`, a `.liveMap` payload no `increment`, and a `.primitive` payload no `subscribe` (objects-mapping
//   §5/§12; the RTTS9d mismatch path does not exist). The 92007 runtime rejection is impossible to reach;
//   the type system forbids the call outright.
// - (D-3) RTINS10 (`compact()`) is adapted to `compactJson()`: cocoa does not implement the non-JSON
//   `compact()` (RTTS7d — typed SDKs need not implement it; objects-mapping §5). The recursive-compaction
//   values are identical, so the assertions are ported against the JSON-shaped result.

import _AblyPluginSupportPrivate // channel-state read (RTINS16h)
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting // StandardTestPool serial vocabulary
import Foundation
import Testing

struct InstanceTests {
    // MARK: - Fixture

    private typealias Fixture = (
        root: DefaultLiveMapPathObject,
        realtimeObjects: ObjectsUTSSeededRealtimeObjects,
        coreSDK: ObjectsUTSCoreSDK,
        internalQueue: DispatchQueue
    )

    /// The unit stand-in for `{ client, channel, root, mock_ws } = AWAIT setup_synced_channel("test")`:
    /// seed the standard pool directly and expose it through a seeded realtime-objects double, then front
    /// it with the root map path object (the spec's `root`). `channelName` is the CoreSDK's channel name,
    /// used by the RTINS16e2 delivery boundary to stamp the projected public message (PAOM2e).
    private static func makeFixture(channelName: String = "") -> Fixture {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let pool = ObjectsUTS.standardPool(internalQueue: internalQueue)
        let realtimeObjects = ObjectsUTSSeededRealtimeObjects(pool: pool, internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK(channelName: channelName)
        let root = DefaultLiveMapPathObject(channelObject: realtimeObjects, coreSDK: coreSDK, internalQueue: internalQueue, segments: [])
        return (root, realtimeObjects, coreSDK, internalQueue)
    }

    /// The unit stand-in for `mock_ws.send_to_client(build_object_message("test", [op]))`: applies the
    /// inbound operation directly to the seeded node it targets. Pool access and `nosync_apply` are
    /// queue-confined (the seeded double's mutex asserts on-queue).
    private static func applyInbound(_ objectMessage: ProtocolTypes.InboundObjectMessage, to objectID: String, fixture: Fixture) throws {
        let operation = try #require(objectMessage.operation)
        fixture.internalQueue.ably_syncNoDeadlock {
            var pool = fixture.realtimeObjects.nosync_objectsPool
            switch pool.entries[objectID] {
            case let .map(node):
                _ = node.nosync_apply(operation, source: .channel, objectMessage: objectMessage, objectsPool: &pool)
            case let .counter(node):
                _ = node.nosync_apply(operation, source: .channel, objectMessage: objectMessage, objectsPool: &pool)
            case nil:
                Issue.record("expected an object at \(objectID) in the seeded pool")
            }
        }
    }

    // MARK: - RTINS3: id property returns objectId

    // UTS: objects/unit/RTINS3/id-returns-objectid-0
    @Test
    func idReturnsObjectId() throws {
        // Setup
        let root = Self.makeFixture().root

        // Assertions
        // counter_inst = root.get("score").instance(); ASSERT counter_inst.id() == "counter:score@1000" (RTINS3a)
        guard case let .liveCounter(counterInst) = try #require(try root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        #expect(counterInst.id == "counter:score@1000")

        // map_inst = root.get("profile").instance(); ASSERT map_inst.id() == "map:profile@1000" (RTINS3a)
        guard case let .liveMap(mapInst) = try #require(try root.get(key: "profile").instance()) else {
            Issue.record("expected a map instance at root.get(\"profile\")")
            return
        }
        #expect(mapInst.id == "map:profile@1000")
        // RTINS3b (Primitive -> null id) is not exercised by the spec's own assertions and is
        // structurally unrepresentable here: PrimitiveInstance has no `id` member.
    }

    // MARK: - RTINS4: value() returns counter number or primitive

    // UTS: objects/unit/RTINS4/value-counter-0
    @Test
    func valueReturnsCounterNumberOrPrimitive() throws {
        // Setup
        let root = Self.makeFixture().root

        // Assertions
        // counter_inst = root.get("score").instance(); ASSERT counter_inst.value() == 100 (RTINS4b)
        guard case let .liveCounter(counterInst) = try #require(try root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        #expect(try counterInst.value == 100)

        // map_inst = root.instance(); ASSERT map_inst.value() == null (RTINS4d)
        // Not expressible (D-1): LiveMapInstance exposes no `value()` — the map-returns-null case is a
        // compile-time structural guarantee (the method does not exist), stronger than a runtime null.
    }

    // MARK: - RTINS5: get() returns Instance wrapping entry value

    // UTS: objects/unit/RTINS5/get-wraps-entry-0
    @Test
    func getWrapsEntryValueInInstance() throws {
        // Setup
        // root_inst = root.instance()
        let root = Self.makeFixture().root
        guard case let .liveMap(rootInst) = try #require(try root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }

        // Assertions
        // name_inst = root_inst.get("name"); ASSERT name_inst IS Instance; ASSERT name_inst.value() == "Alice"
        let nameInst = try #require(try rootInst.get(key: "name")) // IS Instance (non-nil)
        guard case let .primitive(namePrim) = nameInst else {
            Issue.record("expected a primitive instance at get(\"name\")")
            return
        }
        #expect(try namePrim.value == .string("Alice"))

        // score_inst = root_inst.get("score"); ASSERT score_inst.id() == "counter:score@1000"
        guard case let .liveCounter(scoreInst) = try #require(try rootInst.get(key: "score")) else {
            Issue.record("expected a counter instance at get(\"score\")")
            return
        }
        #expect(scoreInst.id == "counter:score@1000")

        // null_inst = root_inst.get("nonexistent"); ASSERT null_inst == null (RTINS5c)
        #expect(try rootInst.get(key: "nonexistent") == nil)
    }

    // MARK: - RTINS6: entries() returns array of [key, Instance] pairs

    // UTS: objects/unit/RTINS6/entries-yields-instances-0
    @Test
    func entriesYieldsKeyInstancePairs() throws {
        // Setup
        // root_inst = root.instance()
        let root = Self.makeFixture().root
        guard case let .liveMap(rootInst) = try #require(try root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }

        // Test Steps
        // entries = {}
        // FOR [key, inst] IN root_inst.entries(): entries[key] = inst
        var entries: [String: Instance] = [:]
        for (key, inst) in try rootInst.entries() {
            entries[key] = inst
        }

        // Assertions
        #expect(entries.count == 7) // ASSERT entries.length == 7
        let nameInst = try #require(entries["name"]) // ASSERT entries["name"] IS Instance
        guard case let .primitive(namePrim) = nameInst else {
            Issue.record("expected a primitive instance for entries[\"name\"]")
            return
        }
        #expect(try namePrim.value == .string("Alice")) // ASSERT entries["name"].value() == "Alice"
    }

    // MARK: - RTINS9: size() returns non-tombstoned count

    // UTS: objects/unit/RTINS9/size-0
    @Test
    func sizeReturnsNonTombstonedCount() throws {
        // Setup
        let root = Self.makeFixture().root

        // Assertions
        // root_inst = root.instance(); ASSERT root_inst.size() == 7 (RTINS9b)
        guard case let .liveMap(rootInst) = try #require(try root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }
        #expect(try rootInst.size == 7)

        // counter_inst = root.get("score").instance(); ASSERT counter_inst.size() == null (RTINS9c)
        // Not expressible (D-1): LiveCounterInstance exposes no `size()` — the non-map-returns-null case
        // is a compile-time structural guarantee (the method does not exist), stronger than a runtime null.
    }

    // MARK: - RTINS10: compact() recursively compacts

    // UTS: objects/unit/RTINS10/compact-0
    // DEVIATION (D-3): cocoa does not implement `compact()` (RTTS7d); this is adapted to `compactJson()`,
    // whose recursive-compaction values are identical (a nested counter resolves to its number, a nested
    // map to a JSON object). Assertions are ported against the JSON-shaped result.
    @Test
    func compactRecursivelyCompacts() throws {
        // Setup
        // root_inst = root.instance()
        let root = Self.makeFixture().root
        guard case let .liveMap(rootInst) = try #require(try root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }

        // Test Steps
        // result = root_inst.compact()  -> compactJson() (D-3)
        let result = try rootInst.compactJson()

        // Assertions
        #expect(result.objectValue?["name"] == .string("Alice")) // ASSERT result["name"] == "Alice"
        #expect(result.objectValue?["score"] == .number(100)) // ASSERT result["score"] == 100
        // ASSERT result["profile"]["email"] == "alice@example.com"
        #expect(result.objectValue?["profile"]?.objectValue?["email"] == .string("alice@example.com"))
    }

    // MARK: - RTINS12: set() delegates to InternalLiveMap#set

    // UTS: objects/unit/RTINS12/set-delegates-0
    @Test
    func setDelegatesToMap() async throws {
        // Setup
        // root_inst = root.instance()
        let fixture = Self.makeFixture()
        guard case let .liveMap(rootInst) = try #require(try fixture.root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }

        // Test Steps
        // AWAIT root_inst.set("name", "Bob")
        try await rootInst.set(key: "name", value: "Bob")

        // Assertions
        // ASSERT root.get("name").value() == "Bob" (via the seeded double's ACK echo)
        #expect(try fixture.root.get(key: "name").asPrimitive().value() == .string("Bob"))
    }

    // MARK: - RTINS12d: set() on non-InternalLiveMap throws 92007

    // UTS: objects/unit/RTINS12d/set-non-map-throws-0
    // DEVIATION (D-2): not expressible. `counter_inst` is a `.liveCounter` payload (LiveCounterInstance),
    // which has no `set` member — there is no cast on the `Instance` enum, so the wrong-type write can
    // never be issued and the 92007 rejection is unreachable. The type system forbids the call outright.
    @Test
    func setOnNonMapThrows() throws {
        // counter_inst = root.get("score").instance()
        // AWAIT counter_inst.set("key", "value") FAILS WITH error
        // ASSERT error.code == 92007
        //
        // `counter_inst.set(...)` does not compile: LiveCounterInstance exposes no `set`, and the
        // `Instance` enum has no `asLiveMap()` cast (objects-mapping §5). The invalid-write path is
        // closed at compile time — a stronger guarantee than the runtime 92007.
        let root = Self.makeFixture().root
        guard case .liveCounter = try #require(try root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        #expect(Bool(true))
    }

    // MARK: - RTINS13: remove() delegates to InternalLiveMap#remove

    // UTS: objects/unit/RTINS13/remove-delegates-0
    @Test
    func removeDelegatesToMap() async throws {
        // Setup
        // root_inst = root.instance()
        let fixture = Self.makeFixture()
        guard case let .liveMap(rootInst) = try #require(try fixture.root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }

        // Test Steps
        // AWAIT root_inst.remove("name")
        try await rootInst.remove(key: "name")

        // Assertions
        // ASSERT root.get("name").value() == null (via the seeded double's ACK echo — the key is tombstoned)
        #expect(try fixture.root.get(key: "name").asPrimitive().value() == nil)
    }

    // MARK: - RTINS14: increment() delegates to InternalLiveCounter#increment

    // UTS: objects/unit/RTINS14/increment-delegates-0
    @Test
    func incrementDelegatesToCounter() async throws {
        // Setup
        // counter_inst = root.get("score").instance()
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }

        // Test Steps
        // AWAIT counter_inst.increment(25)
        try await counterInst.increment(amount: 25)

        // Assertions
        // ASSERT root.get("score").value() == 125 (100 + 25, via the ACK echo)
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 125)
    }

    // MARK: - RTINS14d: increment() on non-InternalLiveCounter throws 92007

    // UTS: objects/unit/RTINS14d/increment-non-counter-throws-0
    // DEVIATION (D-2): not expressible. `map_inst` is a `.liveMap` payload (LiveMapInstance), which has no
    // `increment` member — no cast exists on the `Instance` enum, so the wrong-type write can never be
    // issued and the 92007 rejection is unreachable.
    @Test
    func incrementOnNonCounterThrows() throws {
        // map_inst = root.instance()
        // AWAIT map_inst.increment(5) FAILS WITH error
        // ASSERT error.code == 92007
        //
        // `map_inst.increment(...)` does not compile: LiveMapInstance exposes no `increment`, and the
        // `Instance` enum has no `asLiveCounter()` cast (objects-mapping §5). The invalid-write path is
        // closed at compile time — a stronger guarantee than the runtime 92007.
        let root = Self.makeFixture().root
        guard case .liveMap = try #require(try root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }
        #expect(Bool(true))
    }

    // MARK: - RTINS15: decrement() delegates to InternalLiveCounter#decrement

    // UTS: objects/unit/RTINS15/decrement-delegates-0
    @Test
    func decrementDelegatesToCounter() async throws {
        // Setup
        // counter_inst = root.get("score").instance()
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }

        // Test Steps
        // AWAIT counter_inst.decrement(10)
        try await counterInst.decrement(amount: 10)

        // Assertions
        // ASSERT root.get("score").value() == 90 (100 - 10, via the ACK echo)
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 90)
    }

    // MARK: - RTINS14a: increment() defaults to 1

    // UTS: objects/unit/RTINS14a/increment-default-0
    @Test
    func incrementDefaultsToOne() async throws {
        // Setup
        // counter_inst = root.get("score").instance()
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }

        // Test Steps
        // AWAIT counter_inst.increment()  — amount defaults to 1 (RTINS14a1)
        try await counterInst.increment()

        // Assertions
        // ASSERT root.get("score").value() == 101 (100 + 1)
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 101)
    }

    // MARK: - RTINS15a: decrement() defaults to 1

    // UTS: objects/unit/RTINS15a/decrement-default-0
    @Test
    func decrementDefaultsToOne() async throws {
        // Setup
        // counter_inst = root.get("score").instance()
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }

        // Test Steps
        // AWAIT counter_inst.decrement()  — amount defaults to 1 (RTINS15a1)
        try await counterInst.decrement()

        // Assertions
        // ASSERT root.get("score").value() == 99 (100 - 1)
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 99)
    }

    // MARK: - RTINS16: subscribe() receives InstanceSubscriptionEvent

    // UTS: objects/unit/RTINS16/subscribe-receives-events-0
    @Test
    func subscribeReceivesEvents() async throws {
        // Setup
        // counter_inst = root.get("score").instance(); events = []
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        let collector = ObjectsUTSEventCollector()
        // sub = counter_inst.subscribe(...)
        let sub: any Subscription = try counterInst.subscribe(listener: collector.listener)

        // Test Steps
        // mock_ws.send_to_client(build_object_message("test", [build_counter_inc("counter:score@1000", 7, "99", "remote")]))
        let objectMessage = ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")
        try Self.applyInbound(objectMessage, to: "counter:score@1000", fixture: fixture)
        // poll_until(events.length >= 1): drain the callback queue (never sleep).
        let events = await collector.events()

        // Assertions
        // ASSERT sub IS Subscription — guaranteed by the return type `any Subscription`.
        _ = sub
        #expect(events.count == 1) // ASSERT events.length == 1
        let event = try #require(events.first)
        // ASSERT events[0].object IS Instance; ASSERT events[0].object.id() == "counter:score@1000"
        guard case let .liveCounter(eventCounter) = event.object else {
            Issue.record("expected the delivered event to carry a counter instance")
            return
        }
        #expect(eventCounter.id == "counter:score@1000")
    }

    // MARK: - RTINS16c: subscribe() on primitive throws 92007

    // UTS: objects/unit/RTINS16c/subscribe-primitive-throws-0
    // DEVIATION (D-2): not expressible. `name_inst` is a `.primitive` payload (PrimitiveInstance), which
    // has no `subscribe` member — no cast exists on the `Instance` enum, so the subscribe call can never
    // be issued and the 92007 rejection is unreachable.
    @Test
    func subscribeOnPrimitiveThrows() throws {
        // name_inst = root.instance().get("name")
        // name_inst.subscribe((event) => {}) FAILS WITH error
        // ASSERT error.code == 92007
        //
        // `name_inst.subscribe(...)` does not compile: PrimitiveInstance exposes no `subscribe`
        // (objects-mapping §5). The invalid-subscribe path is closed at compile time — a stronger
        // guarantee than the runtime 92007.
        let root = Self.makeFixture().root
        guard case let .liveMap(rootInst) = try #require(try root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }
        guard case .primitive = try #require(try rootInst.get(key: "name")) else {
            Issue.record("expected a primitive instance at get(\"name\")")
            return
        }
        #expect(Bool(true))
    }

    // MARK: - RTINS16e2: InstanceSubscriptionEvent contains PublicAPI::ObjectMessage

    // UTS: objects/unit/RTINS16e2/subscription-event-message-0
    @Test
    func subscriptionEventContainsPublicMessage() async throws {
        // Setup
        // root_inst = root.instance(); events = []
        // The CoreSDK channel name ("test") stamps the projected public message (PAOM2e).
        let fixture = Self.makeFixture(channelName: "test")
        guard case let .liveMap(rootInst) = try #require(try fixture.root.instance()) else {
            Issue.record("expected a map instance for root")
            return
        }
        let collector = ObjectsUTSEventCollector()
        try rootInst.subscribe(listener: collector.listener)

        // Test Steps
        // mock_ws.send_to_client(build_object_message("test", [build_map_set("root", "name", { string: "Bob" }, remote_serial(0), "remote")]))
        let objectMessage = ObjectsUTS.mapSetMessage(
            objectId: ObjectsPool.rootKey,
            key: "name",
            value: ProtocolTypes.ObjectData(string: "Bob"),
            serial: StandardTestPool.remoteSerial(0),
            siteCode: "remote",
        )
        try Self.applyInbound(objectMessage, to: ObjectsPool.rootKey, fixture: fixture)
        // poll_until(events.length >= 1)
        let events = await collector.events()

        // Assertions
        let event = try #require(events.first)
        // ASSERT events[0].object IS Instance; ASSERT events[0].object.id() == "root"
        guard case let .liveMap(eventMap) = event.object else {
            Issue.record("expected the delivered event to carry a map instance")
            return
        }
        #expect(eventMap.id == ObjectsPool.rootKey) // == "root"
        // ASSERT events[0].message IS NOT null
        let message = try #require(event.message)
        #expect(message.channel == "test") // ASSERT events[0].message.channel == "test"
        #expect(message.operation.action == .mapSet) // ASSERT ...operation.action == "MAP_SET"
        #expect(message.operation.objectId == ObjectsPool.rootKey) // ASSERT ...operation.objectId == "root"
        #expect(message.operation.mapSet?.key == "name") // ASSERT ...operation.mapSet.key == "name"
    }

    // MARK: - RTINS16f: subscribe() returns Subscription for deregistration

    // UTS: objects/unit/RTINS16f/subscribe-returns-subscription-0
    @Test
    func subscribeReturnsSubscriptionForDeregistration() async throws {
        // Setup
        // counter_inst = root.get("score").instance(); events = []
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        let collector = ObjectsUTSEventCollector()
        // sub = counter_inst.subscribe(...); sub.unsubscribe()
        let sub = try counterInst.subscribe(listener: collector.listener)
        sub.unsubscribe()

        // Quiescence control: a second, still-subscribed listener on the same counter instance that WILL
        // fire on the same dispatch as the send below (Negative-assertion quiescence).
        let controlCollector = ObjectsUTSEventCollector()
        try counterInst.subscribe(listener: controlCollector.listener)

        // Test Steps
        // mock_ws.send_to_client(build_object_message("test", [build_counter_inc("counter:score@1000", 7, "99", "remote")]))
        let objectMessage = ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "99", siteCode: "remote")
        try Self.applyInbound(objectMessage, to: "counter:score@1000", fixture: fixture)

        // Assertions
        // poll_until(control_events.length >= 1): once the control listener has been delivered (same
        // dispatch), the unsubscribed listener would also have fired had it remained subscribed.
        let controlEvents = await controlCollector.events()
        #expect(controlEvents.count >= 1)
        // THEN assert the unsubscribed listener's count is unchanged.
        let events = await collector.events()
        #expect(events.count == 0) // ASSERT events.length == 0
    }

    // MARK: - RTINS16g: Instance subscription follows identity not path

    // UTS: objects/unit/RTINS16g/subscription-follows-identity-0
    @Test
    func subscriptionFollowsIdentityNotPath() async throws {
        // Setup
        // counter_inst = root.get("score").instance(); events = []
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        let collector = ObjectsUTSEventCollector()
        try counterInst.subscribe(listener: collector.listener)

        // Test Steps
        // mock_ws.send_to_client(build_object_message("test", [build_map_set("root", "score", { objectId: "counter:new@2000" }, remote_serial(0), "remote")]))
        // Repoint root.score away from the subscribed counter to a different object.
        let repointMessage = ObjectsUTS.mapSetMessage(
            objectId: ObjectsPool.rootKey,
            key: "score",
            value: ProtocolTypes.ObjectData(objectId: "counter:new@2000"),
            serial: StandardTestPool.remoteSerial(0),
            siteCode: "remote",
        )
        try Self.applyInbound(repointMessage, to: ObjectsPool.rootKey, fixture: fixture)

        // mock_ws.send_to_client(build_object_message("test", [build_counter_inc("counter:score@1000", 10, "100", "remote")]))
        // Increment the ORIGINAL counter — the identity the subscription follows.
        let incMessage = ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 10, serial: "100", siteCode: "remote")
        try Self.applyInbound(incMessage, to: "counter:score@1000", fixture: fixture)
        // poll_until(events.length >= 1)
        let events = await collector.events()

        // Assertions
        #expect(events.count >= 1) // ASSERT events.length >= 1
        let event = try #require(events.first)
        // RTINS16e1: assert against the DELIVERED EVENT's object id (identity-based), not the pre-existing
        // counter_inst handle.
        guard case let .liveCounter(eventCounter) = event.object else {
            Issue.record("expected the delivered event to carry a counter instance")
            return
        }
        #expect(eventCounter.id == "counter:score@1000") // ASSERT events[0].object.id() == "counter:score@1000"
    }

    // MARK: - RTINS16h: subscribe() has no side effects

    // UTS: objects/unit/RTINS16h/subscribe-no-side-effects-0
    @Test
    func subscribeHasNoSideEffects() throws {
        // Setup
        // counter_inst = root.get("score").instance(); channel_state_before = channel.state
        let fixture = Self.makeFixture()
        guard case let .liveCounter(counterInst) = try #require(try fixture.root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        let channelStateBefore = fixture.coreSDK.nosync_channelState

        // Test Steps
        // sub = counter_inst.subscribe((event) => {})
        let sub: any Subscription = try counterInst.subscribe(listener: { _ in })
        _ = sub

        // Assertions
        // ASSERT channel.state == channel_state_before
        #expect(fixture.coreSDK.nosync_channelState == channelStateBefore)
    }
}
