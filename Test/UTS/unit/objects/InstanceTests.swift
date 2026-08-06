// Derived from the UTS spec `objects/unit/instance.md`.

import Ably
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

/// `Instance` — the identity-addressed view of a LiveObject or primitive.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/instance.md
/// (spec points `RTINS1`–`RTINS16`).
///
/// The spec drives every case through `setup_synced_channel` + a mock WebSocket. Cocoa's `Instance`
/// layer is exercisable without any of that: build the internal node directly via its `testsOnly_`
/// initialiser and wrap it with the internal `Instance.from(...)` factory (the seam
/// `PathObject.instance()` uses in production). This mirrors the Phase-3 native suite
/// `LiveObjects/Tests/AblyLiveObjectsTests/DefaultInstanceTests.swift`; the mocks it relies on are
/// replicated locally in `helpers/ObjectsUTSHelpers.swift` (that target cannot be imported).
///
/// ## DEV-1: Instance enum vs base-type + `as*` casts (recorded in deviations.md)
/// Cocoa models `Instance` as an enum (`.liveMap`/`.liveCounter`/`.primitive`) whose payloads are the
/// distinct `LiveMapInstance` / `LiveCounterInstance` / `PrimitiveInstance` protocols, each carrying
/// only its applicable members. This makes an entire family of spec "wrong-type" cases
/// **compile-time-unrepresentable** — the spec's runtime 92007 / null-return branches cannot be
/// written:
/// - RTINS3b (`Primitive.id() == null`): `PrimitiveInstance` has no `id`.
/// - RTINS4d (`InternalLiveMap.value() == null`): `LiveMapInstance` has no `value`.
/// - RTINS5d / RTINS6c / RTINS9c (non-map `get`/`entries`/`size`): those live only on `LiveMapInstance`.
/// - RTINS12d / RTINS13d (`set`/`remove` on non-map -> 92007): those live only on `LiveMapInstance`.
/// - RTINS14d / RTINS15d (`increment`/`decrement` on non-counter -> 92007): only on `LiveCounterInstance`.
/// - RTINS16c (`subscribe` on a primitive -> 92007): `PrimitiveInstance` has no `subscribe`.
///
/// ## Mock-realtime adaptation
/// The unit mock (`ObjectsUTSRealtimeObjects`) captures `publishAndApply` messages but does not apply
/// them back onto the graph. So the mutation cases (RTINS12/13/14/14a/15/15a) assert the **published
/// operation** rather than the spec's post-apply value (`root.get(...).value() == ...`), which needs
/// the full `InternalDefaultRealtimeObjects` pipeline.
///
/// ## Skipped — out of UNIT scope
/// - RTINS16g (subscription follows identity after the key is repointed): needs a multi-object graph
///   plus a `MAP_SET` that repoints `root.score`, i.e. the mock-WS send path.
/// - RTINS16h (subscribe has no side effects on channel state): needs a real channel/connection.
@Suite(.serialized)
final class InstanceTests {
    // MARK: - RTINS3: id property returns objectId

    // UTS: objects/unit/RTINS3/id-returns-objectid-0 — RTINS3a (LiveObject -> objectId). RTINS3b (primitive
    // -> null) is compile-time-unrepresentable (DEV-1).
    @Test
    func RTINS3a_id_returns_objectid() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let counterNode = ObjectsUTS.makeCounter(objectID: "counter:score@1000", internalQueue: internalQueue)
        let mapNode = ObjectsUTS.makeMap(objectID: "map:profile@1000", internalQueue: internalQueue)

        guard case let .liveCounter(counterInstance) = Instance.from(internalValue: .liveCounter(counterNode), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .liveCounter")
            return
        }
        #expect(counterInstance.id == "counter:score@1000")

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(mapNode), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }
        #expect(mapInstance.id == "map:profile@1000")
    }

    // MARK: - RTINS4: value() returns counter number or primitive

    // UTS: objects/unit/RTINS4/value-counter-0 — RTINS4b (counter -> value) and RTINS4c (primitive ->
    // value). RTINS4d (map -> null) is compile-time-unrepresentable (DEV-1).
    @Test
    func RTINS4_value_counter_and_primitive() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let counterNode = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)

        guard case let .liveCounter(counterInstance) = Instance.from(internalValue: .liveCounter(counterNode), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .liveCounter")
            return
        }
        #expect(try counterInstance.value == 100) // RTINS4b

        guard case let .primitive(primitive) = Instance.from(internalValue: .string("Alice"), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .primitive")
            return
        }
        #expect(try primitive.value == .string("Alice")) // RTINS4c
    }

    // MARK: - RTINS5: get() returns Instance wrapping entry value

    // UTS: objects/unit/RTINS5/get-wraps-entry-0 — RTINS5c (look up key, wrap in Instance; nil when absent).
    // RTINS5d (non-map -> null) is compile-time-unrepresentable (DEV-1).
    @Test
    func RTINS5c_get_wraps_entry() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        // A pool holding the counter that the "score" entry references by objectId.
        let scoreCounter = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)
        let poolDelegate = ObjectsUTSPoolDelegate(internalQueue: internalQueue, entries: ["counter:score@1000": .counter(scoreCounter)])
        let realtimeObjects = ObjectsUTSRealtimeObjects(poolDelegate: poolDelegate)

        let root = ObjectsUTS.makeMap(
            objectID: "root",
            data: [
                "name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice")),
                "score": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:score@1000")),
            ],
            internalQueue: internalQueue,
        )

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(root), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }

        let nameInst = try #require(try mapInstance.get(key: "name"))
        guard case let .primitive(namePrimitive) = nameInst else {
            Issue.record("Expected .primitive for name")
            return
        }
        #expect(try namePrimitive.value == .string("Alice"))

        let scoreInst = try #require(try mapInstance.get(key: "score"))
        guard case let .liveCounter(scoreCounterInstance) = scoreInst else {
            Issue.record("Expected .liveCounter for score")
            return
        }
        #expect(scoreCounterInstance.id == "counter:score@1000")

        #expect(try mapInstance.get(key: "nonexistent") == nil)
    }

    // MARK: - RTINS6: entries() returns array of [key, Instance] pairs

    // UTS: objects/unit/RTINS6/entries-yields-instances-0 — RTINS6b. RTINS6c (non-map -> empty array) is
    // compile-time-unrepresentable (DEV-1).
    @Test
    func RTINS6b_entries_yields_instances() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let realtimeObjects = ObjectsUTSRealtimeObjects(poolDelegate: ObjectsUTSPoolDelegate(internalQueue: internalQueue))
        let root = ObjectsUTS.makeMap(
            data: [
                "name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice")),
                "age": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(number: NSNumber(value: 30))),
            ],
            internalQueue: internalQueue,
        )

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(root), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }

        let entries = try mapInstance.entries()
        let entriesByKey = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0.value) })
        #expect(entries.count == 2)
        let nameInst = try #require(entriesByKey["name"])
        guard case let .primitive(namePrimitive) = nameInst else {
            Issue.record("Expected .primitive for name")
            return
        }
        #expect(try namePrimitive.value == .string("Alice"))
    }

    // MARK: - RTINS9: size() returns non-tombstoned count

    // UTS: objects/unit/RTINS9/size-0 — RTINS9b (map -> entry count). RTINS9c (non-map -> null) is
    // compile-time-unrepresentable (DEV-1).
    @Test
    func RTINS9b_size() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let realtimeObjects = ObjectsUTSRealtimeObjects(poolDelegate: ObjectsUTSPoolDelegate(internalQueue: internalQueue))
        let root = ObjectsUTS.makeMap(
            data: [
                "a": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "x")),
                "b": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "y")),
                "c": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "z")),
            ],
            internalQueue: internalQueue,
        )

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(root), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }
        #expect(try mapInstance.size == 3)
    }

    // MARK: - RTINS10: compact() recursively compacts

    // UTS: objects/unit/RTINS10/compact-0 — RTINS10b (behaves like PathObject#compact on the wrapped value).
    @Test
    func RTINS10_compact() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()

        let scoreCounter = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)
        let profileMap = ObjectsUTS.makeMap(objectID: "map:profile@1000", data: ["email": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "alice@example.com"))], internalQueue: internalQueue)
        let poolDelegate = ObjectsUTSPoolDelegate(internalQueue: internalQueue, entries: [
            "counter:score@1000": .counter(scoreCounter),
            "map:profile@1000": .map(profileMap),
        ])

        let root = ObjectsUTS.makeMap(
            objectID: "root",
            data: [
                "name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice")),
                "score": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:score@1000")),
                "profile": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "map:profile@1000")),
            ],
            internalQueue: internalQueue,
        )
        let realtimeObjects = ObjectsUTSRealtimeObjects(poolDelegate: poolDelegate)

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(root), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }
        let expected: JSONValue = .object([
            "name": .string("Alice"),
            "score": .number(100),
            "profile": .object(["email": .string("alice@example.com")]),
        ])
        #expect(try mapInstance.compactJson() == expected)
    }

    // MARK: - RTINS12: set() delegates to InternalLiveMap#set

    // UTS: objects/unit/RTINS12/set-delegates-0 — RTINS12c. Asserts the published MAP_SET operation (the
    // mock does not apply locally, so the spec's post-apply `root.get("name").value() == "Bob"` is out
    // of unit scope).
    @Test
    func RTINS12c_set_delegates() async throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let realtimeObjects = ObjectsUTSRealtimeObjects()
        let published = ObjectsUTSPublished()
        realtimeObjects.setPublishAndApplyHandler { messages in
            published.set(messages)
            return .success(())
        }
        let root = ObjectsUTS.makeMap(objectID: "root", internalQueue: internalQueue)

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(root), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }
        try await mapInstance.set(key: "name", value: .primitive(.string("Bob")))

        let messages = try #require(published.get())
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.mapSet))
        #expect(messages[0].operation?.objectId == "root")
        #expect(messages[0].operation?.mapSet?.key == "name")
        #expect(messages[0].operation?.mapSet?.value?.string == "Bob")
    }

    // MARK: - RTINS13: remove() delegates to InternalLiveMap#remove

    // UTS: objects/unit/RTINS13/remove-delegates-0 — RTINS13c. Asserts the published MAP_REMOVE operation.
    @Test
    func RTINS13c_remove_delegates() async throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let realtimeObjects = ObjectsUTSRealtimeObjects()
        let published = ObjectsUTSPublished()
        realtimeObjects.setPublishAndApplyHandler { messages in
            published.set(messages)
            return .success(())
        }
        let root = ObjectsUTS.makeMap(objectID: "root", data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"))], internalQueue: internalQueue)

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(root), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }
        try await mapInstance.remove(key: "name")

        let messages = try #require(published.get())
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.mapRemove))
        #expect(messages[0].operation?.objectId == "root")
        #expect(messages[0].operation?.mapRemove?.key == "name")
    }

    // MARK: - RTINS14 / RTINS14a: increment() delegates to InternalLiveCounter#increment

    // UTS: objects/unit/RTINS14/increment-delegates-0 — RTINS14c. Asserts the published COUNTER_INC.
    @Test
    func RTINS14c_increment_delegates() async throws {
        let (counterInstance, published) = try makeCounterInstanceCapturingPublish(objectID: "counter:score@1000", data: 100)
        try await counterInstance.increment(amount: 25)

        let messages = try #require(published.get())
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.counterInc))
        #expect(messages[0].operation?.objectId == "counter:score@1000")
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: 25))
    }

    // UTS: objects/unit/RTINS14a/increment-default-0 — RTINS14a1 (amount defaults to 1). Asserts the
    // published number is 1 (the spec's post-apply `value() == 101` needs the full pipeline).
    @Test
    func RTINS14a_increment_default() async throws {
        let (counterInstance, published) = try makeCounterInstanceCapturingPublish(objectID: "counter:score@1000", data: 100)
        try await counterInstance.increment()

        let messages = try #require(published.get())
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: 1))
    }

    // MARK: - RTINS15 / RTINS15a: decrement() delegates to InternalLiveCounter#decrement

    // UTS: objects/unit/RTINS15/decrement-delegates-0 — RTINS15c. Decrement is increment with a negated
    // amount, so the published COUNTER_INC carries a negative number.
    @Test
    func RTINS15c_decrement_delegates() async throws {
        let (counterInstance, published) = try makeCounterInstanceCapturingPublish(objectID: "counter:score@1000", data: 100)
        try await counterInstance.decrement(amount: 10)

        let messages = try #require(published.get())
        #expect(messages[0].operation?.action == .known(.counterInc))
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: -10))
    }

    // UTS: objects/unit/RTINS15a/decrement-default-0 — RTINS15a1 (amount defaults to 1 => published -1).
    @Test
    func RTINS15a_decrement_default() async throws {
        let (counterInstance, published) = try makeCounterInstanceCapturingPublish(objectID: "counter:score@1000", data: 100)
        try await counterInstance.decrement()

        let messages = try #require(published.get())
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: -1))
    }

    // MARK: - RTINS16: subscribe() receives InstanceSubscriptionEvent

    // UTS: objects/unit/RTINS16/subscribe-receives-events-0 — RTINS16d/e1/f/g. The update is driven by
    // applying a COUNTER_INC to the node directly (the unit stand-in for `mock_ws.send_to_client`).
    @Test
    func RTINS16_subscribe_receives_events() async throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let node = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)

        guard case let .liveCounter(counterInstance) = Instance.from(internalValue: .liveCounter(node), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .liveCounter")
            return
        }

        let collector = ObjectsUTSEventCollector()
        let sub = try counterInstance.subscribe(listener: collector.listener) // RTINS16f

        applyCounterInc(to: node, objectID: "counter:score@1000", number: 7, internalQueue: internalQueue)

        let events = await collector.events()
        #expect(events.count == 1)
        let event = try #require(events.first)
        // RTINS16e1/g: the delivered event carries the Instance wrapping the counter that fired.
        guard case let .liveCounter(eventCounter) = event.object else {
            Issue.record("Expected .liveCounter in event")
            return
        }
        #expect(eventCounter.id == "counter:score@1000")
        sub.unsubscribe()
    }

    // UTS: objects/unit/RTINS16e2/subscription-event-message-0 — RTINS16e1/e2. The event carries both the
    // Instance and the PublicAPI::ObjectMessage derived from the triggering ObjectMessage.
    @Test
    func RTINS16e2_subscription_event_message() async throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let realtimeObjects = ObjectsUTSRealtimeObjects(poolDelegate: ObjectsUTSPoolDelegate(internalQueue: internalQueue))
        let node = ObjectsUTS.makeMap(objectID: "root", internalQueue: internalQueue)

        guard case let .liveMap(mapInstance) = Instance.from(internalValue: .liveMap(node), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            Issue.record("Expected .liveMap")
            return
        }

        let collector = ObjectsUTSEventCollector()
        try mapInstance.subscribe(listener: collector.listener)

        // The public ObjectMessage that the update is stamped with (RTINS16e2).
        let sourceMessage = ObjectMessage(
            channel: "test",
            operation: ObjectOperation(action: .mapSet, objectId: "root", mapSet: MapSet(key: "name", value: ObjectData(string: "Bob"))),
        )
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)
        internalQueue.ably_syncNoDeadlock {
            _ = node.nosync_apply(
                ProtocolTypes.ObjectOperation(action: .known(.mapSet), objectId: "root", mapSet: ProtocolTypes.MapSet(key: "name", value: ProtocolTypes.ObjectData(string: "Bob"))),
                source: .channel,
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                sourceObjectMessage: sourceMessage,
                objectsPool: &pool,
            )
        }

        let events = await collector.events()
        #expect(events.count == 1)
        let event = try #require(events.first)
        guard case let .liveMap(eventMap) = event.object else { // RTINS16e1
            Issue.record("Expected .liveMap in event")
            return
        }
        #expect(eventMap.id == "root")
        let message = try #require(event.message) // RTINS16e2
        #expect(message.channel == "test")
        #expect(message.operation.action == .mapSet)
        #expect(message.operation.objectId == "root")
        #expect(message.operation.mapSet?.key == "name")
    }

    // MARK: - RTINS16f: subscribe() returns Subscription for deregistration

    // UTS: objects/unit/RTINS16f/subscribe-returns-subscription-0 — after `unsubscribe()` the listener must
    // not fire for a subsequent update.
    @Test
    func RTINS16f_unsubscribe_stops_delivery() async throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let node = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)

        guard case let .liveCounter(counterInstance) = Instance.from(internalValue: .liveCounter(node), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .liveCounter")
            return
        }

        let collector = ObjectsUTSEventCollector()
        let sub = try counterInstance.subscribe(listener: collector.listener)
        sub.unsubscribe()

        applyCounterInc(to: node, objectID: "counter:score@1000", number: 7, internalQueue: internalQueue)

        let events = await collector.events()
        #expect(events.isEmpty)
    }

    // MARK: - Helpers

    private func makeCounterInstanceCapturingPublish(objectID: String, data: Double) throws -> (any LiveCounterInstance, ObjectsUTSPublished) {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let realtimeObjects = ObjectsUTSRealtimeObjects()
        let published = ObjectsUTSPublished()
        realtimeObjects.setPublishAndApplyHandler { messages in
            published.set(messages)
            return .success(())
        }
        let node = ObjectsUTS.makeCounter(objectID: objectID, data: data, internalQueue: internalQueue)
        guard case let .liveCounter(counterInstance) = Instance.from(internalValue: .liveCounter(node), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            throw NSError(domain: "InstanceTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expected .liveCounter"])
        }
        return (counterInstance, published)
    }

    private func applyCounterInc(to node: InternalDefaultLiveCounter, objectID: String, number: Int, internalQueue: DispatchQueue) {
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)
        internalQueue.ably_syncNoDeadlock {
            _ = node.nosync_apply(
                ProtocolTypes.ObjectOperation(action: .known(.counterInc), objectId: objectID, counterInc: WireCounterInc(number: NSNumber(value: number))),
                source: .channel,
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )
        }
    }
}
