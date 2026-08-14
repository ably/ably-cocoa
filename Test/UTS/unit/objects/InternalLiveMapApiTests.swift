// Derived from the UTS spec `objects/unit/internal_live_map_api.md`.
//
// Drives the `InternalLiveMap` public read/write surface (RTLM5/RTLM10–RTLM12 value reads;
// RTLM20/RTLM21 v6 MAP_SET/MAP_REMOVE writes; RTLM20e7g/RTLM20h1 blueprint evaluation) through the
// path layer: reads resolve against the standard pool seeded directly by
// `ObjectsUTS.standardPool` (the unit stand-in for the spec's `setup_synced_channel`, which would
// materialise the tree via an OBJECT_SYNC), and writes are captured at the `publishAndApply` seam by
// `ObjectsUTSSeededRealtimeObjects.capturedMessages`. The spec's `captured_messages[0].state[0]`
// maps to `realtimeObjects.capturedMessages[0]` and `.operation` on it. `root` is a
// `DefaultLiveMapPathObject` over the seeded pool — the map surface the spec's `root` resolves to.
//
// The mock-WebSocket infrastructure the spec declares (`MockWebSocket`, `mock_ws.send_to_client`,
// `build_ack_message`) has no unit-tier counterpart; the seeded double both captures the outbound
// messages AND asynchronously applies each operation back onto its seeded pool entry (the RTO20 ACK
// echo, reduced to what the pool can express). So the awaited write happens-after its echo, and
// `set-applies-locally` is a real post-apply value assertion. `capturedMessages` retains only the most
// recent publish, so `set-value-types` (whose spec indexes `captured_messages[0..2]` across three
// writes) reads `capturedMessages[0]` after each write — an infra-driving stand-in, not a deviation.
//
// Deviations from the UTS spec (see Test/UTS/deviations.md):
// - (bytes) RTLM20e7f asserts `mapSet.value.bytes == "AQID"` (base64). Cocoa's outbound
//   `ProtocolTypes.ObjectData.bytes` holds raw `Data`; base64 is applied at wire (JSON) serialization,
//   below this capture point. Ported as `Data([1, 2, 3])` (which base64-encodes to "AQID").
// - (invalid values) RTLM20/set-invalid-values-table (function/undefined/symbol -> 40013) is
//   type-blocked: `LiveMapValue` is a closed enum with no case for those JS constructs, so the 40013
//   rejection is compile-time-unrepresentable. The case documents the stronger compile-time guarantee.

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct InternalLiveMapApiTests {
    // MARK: - Fixture

    private typealias Fixture = (root: DefaultLiveMapPathObject, realtimeObjects: ObjectsUTSSeededRealtimeObjects)

    /// The unit stand-in for `{ client, channel, root, mock_ws } = AWAIT setup_synced_channel("test")`:
    /// seed the standard pool directly and expose it through a seeded realtime-objects double, then
    /// front it with the root map path object (the spec's `root`).
    private static func makeFixture() -> Fixture {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let pool = ObjectsUTS.standardPool(internalQueue: internalQueue)
        let realtimeObjects = ObjectsUTSSeededRealtimeObjects(pool: pool, internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK()
        let root = DefaultLiveMapPathObject(channelObject: realtimeObjects, coreSDK: coreSDK, internalQueue: internalQueue, segments: [])
        return (root, realtimeObjects)
    }

    // MARK: - RTLM5: get() returns resolved value from InternalLiveMap

    // UTS: objects/unit/RTLM5/get-string-value-0
    @Test
    func getReturnsResolvedPrimitiveValues() throws {
        // Setup
        let root = Self.makeFixture().root

        // Assertions
        // ASSERT root.get("name").value() == "Alice"
        #expect(try root.get(key: "name").asPrimitive().value() == .string("Alice"))
        // ASSERT root.get("age").value() == 30
        #expect(try root.get(key: "age").asPrimitive().value() == .number(30))
        // ASSERT root.get("active").value() == true
        #expect(try root.get(key: "active").asPrimitive().value() == .bool(true))
    }

    // UTS: objects/unit/RTLM5/get-nonexistent-key-0
    @Test
    func getReturnsNullForNonExistentKey() throws {
        // Setup
        let root = Self.makeFixture().root

        // Assertions
        // ASSERT root.get("nonexistent").value() == null
        #expect(try root.get(key: "nonexistent").asPrimitive().value() == nil)
    }

    // UTS: objects/unit/RTLM5/get-objectid-reference-0
    @Test
    func getResolvesObjectIdToLiveObject() throws {
        // Setup
        let root = Self.makeFixture().root

        // Assertions
        // ASSERT root.get("score").value() == 100
        #expect(try root.get(key: "score").asLiveCounter().value() == 100)
        // ASSERT root.get("profile").get("email").value() == "alice@example.com"
        #expect(try root.get(key: "profile").asLiveMap().get(key: "email").asPrimitive().value() == .string("alice@example.com"))
    }

    // MARK: - RTLM10: size() returns non-tombstoned entry count

    // UTS: objects/unit/RTLM10/size-non-tombstoned-0
    @Test
    func sizeReturnsNonTombstonedEntryCount() throws {
        // Setup
        let root = Self.makeFixture().root

        // Assertions
        // ASSERT root.size() == 7 (RTLM10d)
        #expect(try root.size() == 7)
    }

    // MARK: - RTLM11: entries() yields key-value pairs

    // UTS: objects/unit/RTLM11/entries-yields-pairs-0
    @Test
    func entriesYieldsNonTombstonedKeyValuePairs() throws {
        // Setup
        let root = Self.makeFixture().root

        // Test Steps
        // entries = []
        // FOR [key, pathObj] IN root.entries(): entries.append(key)
        let entries = try root.entries().map(\.key)

        // Assertions
        #expect(entries.contains("name")) // ASSERT "name" IN entries
        #expect(entries.contains("age")) // ASSERT "age" IN entries
        #expect(entries.contains("active")) // ASSERT "active" IN entries
        #expect(entries.contains("score")) // ASSERT "score" IN entries
        #expect(entries.contains("profile")) // ASSERT "profile" IN entries
        #expect(entries.contains("data")) // ASSERT "data" IN entries
        #expect(entries.contains("avatar")) // ASSERT "avatar" IN entries
        #expect(entries.count == 7) // ASSERT entries.length == 7
    }

    // MARK: - RTLM12: keys() yields only keys

    // UTS: objects/unit/RTLM12/keys-0
    @Test
    func keysYieldsOnlyKeys() throws {
        // Setup
        let root = Self.makeFixture().root

        // Test Steps
        // keys = list(root.keys())
        let keys = try root.keys()

        // Assertions
        #expect(keys.count == 7) // ASSERT keys.length == 7
        #expect(keys.contains("name")) // ASSERT "name" IN keys
    }

    // MARK: - RTLM20: set() sends MAP_SET message with v6 format

    // UTS: objects/unit/RTLM20/set-sends-map-set-0
    @Test
    func setSendsMapSetMessage() async throws {
        // Setup
        let fixture = Self.makeFixture()

        // Test Steps
        // AWAIT root.set("name", "Bob")
        try await fixture.root.set(key: "name", value: .primitive(.string("Bob")))

        // Assertions
        // ASSERT captured_messages.length == 1
        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 1) // RTLM20h2 (single-element array for a non-value-type value)
        // obj_msg = captured_messages[0].state[0]
        let op = try #require(messages[0].operation)
        #expect(op.action == .known(.mapSet)) // ASSERT obj_msg.operation.action == "MAP_SET" (RTLM20e2)
        #expect(op.objectId == ObjectsPool.rootKey) // ASSERT obj_msg.operation.objectId == "root" (RTLM20e3)
        #expect(op.mapSet?.key == "name") // ASSERT obj_msg.operation.mapSet.key == "name" (RTLM20e6)
        #expect(op.mapSet?.value?.string == "Bob") // ASSERT obj_msg.operation.mapSet.value.string == "Bob" (RTLM20e7c)
    }

    // UTS: objects/unit/RTLM20/set-value-types-0
    // capturedMessages holds only the most recent publishAndApply's messages, so each spec
    // per-message assertion (captured_messages[0..2]) is read after its own write.
    @Test
    func setWithDifferentValueTypes() async throws {
        // Setup
        let fixture = Self.makeFixture()

        // Test Steps + Assertions (per-write, per the captured-messages adaptation above)
        // AWAIT root.set("num_key", 42)
        try await fixture.root.set(key: "num_key", value: .primitive(.number(42)))
        // ASSERT captured_messages[0].state[0].operation.mapSet.value.number == 42 (RTLM20e7d)
        #expect(try #require(fixture.realtimeObjects.capturedMessages)[0].operation?.mapSet?.value?.number?.doubleValue == 42)

        // AWAIT root.set("bool_key", false)
        try await fixture.root.set(key: "bool_key", value: .primitive(.bool(false)))
        // ASSERT captured_messages[1].state[0].operation.mapSet.value.boolean == false (RTLM20e7e)
        #expect(try #require(fixture.realtimeObjects.capturedMessages)[0].operation?.mapSet?.value?.boolean == false)

        // AWAIT root.set("json_key", {"nested": true})
        try await fixture.root.set(key: "json_key", value: .primitive(.jsonObject(["nested": .bool(true)])))
        // ASSERT captured_messages[2].state[0].operation.mapSet.value.json == {"nested": true} (RTLM20e7b)
        #expect(try #require(fixture.realtimeObjects.capturedMessages)[0].operation?.mapSet?.value?.json == .object(["nested": .bool(true)]))
    }

    // UTS: objects/unit/RTLM20/set-bytes-value-0
    // DEVIATION (bytes): the spec asserts the base64 string "AQID"; cocoa's outbound ObjectData.bytes
    // holds raw Data (base64 is applied at wire serialization below this capture point), so this
    // asserts Data([1, 2, 3]), which base64-encodes to "AQID".
    @Test
    func setWithBytesValueType() async throws {
        // Setup
        let fixture = Self.makeFixture()

        // Test Steps
        // AWAIT root.set("binary_data", bytes([1, 2, 3]))
        try await fixture.root.set(key: "binary_data", value: .primitive(.data(Data([1, 2, 3]))))

        // Assertions
        // ASSERT captured_messages[0].state[0].operation.mapSet.value.bytes == "AQID" (RTLM20e7f)
        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages[0].operation?.mapSet?.value?.bytes == Data([1, 2, 3]))
    }

    // MARK: - RTLM20e7g: set() with a value-type blueprint generates *_CREATE + MAP_SET

    // UTS: objects/unit/RTLM20e7g/set-counter-value-type-0
    @Test
    func setWithLiveCounterGeneratesCounterCreatePlusMapSet() async throws {
        // Setup
        let fixture = Self.makeFixture()

        // Test Steps
        // AWAIT root.set("new_counter", LiveCounter.create(50))
        try await fixture.root.set(key: "new_counter", value: .liveCounter(.create(initialCount: 50)))

        // Assertions
        // ASSERT captured_messages.length == 1
        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        // state = captured_messages[0].state; ASSERT state.length == 2 (RTLM20h1)
        #expect(messages.count == 2)
        // ASSERT state[0].operation.action == "COUNTER_CREATE" (RTLM20e7g1)
        #expect(messages[0].operation?.action == .known(.counterCreate))
        // ASSERT state[0].operation.objectId STARTS WITH "counter:"
        #expect(messages[0].operation?.objectId.hasPrefix("counter:") == true)
        // ASSERT state[1].operation.action == "MAP_SET"
        #expect(messages[1].operation?.action == .known(.mapSet))
        // ASSERT state[1].operation.mapSet.value.objectId == state[0].operation.objectId (RTLM20e7g2)
        #expect(messages[1].operation?.mapSet?.value?.objectId == messages[0].operation?.objectId)
    }

    // UTS: objects/unit/RTLM20e7g/set-map-value-type-0
    @Test
    func setWithLiveMapGeneratesMapCreatePlusMapSet() async throws {
        // Setup
        let fixture = Self.makeFixture()

        // Test Steps
        // AWAIT root.set("nested_map", LiveMap.create({ "key1": "value1" }))
        try await fixture.root.set(key: "nested_map", value: .liveMap(.create(entries: ["key1": "value1"])))

        // Assertions
        // ASSERT captured_messages.length == 1
        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        // state = captured_messages[0].state; ASSERT state.length == 2 (RTLM20h1)
        #expect(messages.count == 2)
        // ASSERT state[0].operation.action == "MAP_CREATE" (RTLM20e7g1)
        #expect(messages[0].operation?.action == .known(.mapCreate))
        // ASSERT state[0].operation.objectId STARTS WITH "map:"
        #expect(messages[0].operation?.objectId.hasPrefix("map:") == true)
        // ASSERT state[1].operation.action == "MAP_SET"
        #expect(messages[1].operation?.action == .known(.mapSet))
        // ASSERT state[1].operation.mapSet.key == "nested_map"
        #expect(messages[1].operation?.mapSet?.key == "nested_map")
        // ASSERT state[1].operation.mapSet.value.objectId == state[0].operation.objectId (RTLM20e7g2)
        #expect(messages[1].operation?.mapSet?.value?.objectId == messages[0].operation?.objectId)
    }

    // MARK: - RTLM20h1: set() with nested LiveMap containing LiveCounter

    // UTS: objects/unit/RTLM20h1/set-nested-value-types-0
    @Test
    func setWithNestedLiveMapContainingLiveCounter() async throws {
        // Setup
        let fixture = Self.makeFixture()

        // Test Steps
        // AWAIT root.set("stats", LiveMap.create({ "count": LiveCounter.create(0), "label": "test" }))
        try await fixture.root.set(key: "stats", value: .liveMap(.create(entries: [
            "count": .liveCounter(.create(initialCount: 0)),
            "label": "test",
        ])))

        // Assertions
        // ASSERT captured_messages.length == 1
        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        // state = captured_messages[0].state
        // # Expect: COUNTER_CREATE, MAP_CREATE, MAP_SET (depth-first, then the MAP_SET at root)
        // ASSERT state.length == 3 (RTLM20h1)
        #expect(messages.count == 3)
        // ASSERT state[0].operation.action == "COUNTER_CREATE" (RTLMV4d1)
        #expect(messages[0].operation?.action == .known(.counterCreate))
        // ASSERT state[0].operation.objectId STARTS WITH "counter:"
        #expect(messages[0].operation?.objectId.hasPrefix("counter:") == true)
        // ASSERT state[1].operation.action == "MAP_CREATE" (RTLMV4d2 — the "stats" map)
        #expect(messages[1].operation?.action == .known(.mapCreate))
        // ASSERT state[1].operation.objectId STARTS WITH "map:"
        #expect(messages[1].operation?.objectId.hasPrefix("map:") == true)
        // ASSERT state[2].operation.action == "MAP_SET"
        #expect(messages[2].operation?.action == .known(.mapSet))
        // ASSERT state[2].operation.mapSet.key == "stats"
        #expect(messages[2].operation?.mapSet?.key == "stats")
        // ASSERT state[2].operation.mapSet.value.objectId == state[1].operation.objectId
        #expect(messages[2].operation?.mapSet?.value?.objectId == messages[1].operation?.objectId)
    }

    // MARK: - RTLM21: remove() sends MAP_REMOVE message

    // UTS: objects/unit/RTLM21/remove-sends-map-remove-0
    @Test
    func removeSendsMapRemoveMessage() async throws {
        // Setup
        let fixture = Self.makeFixture()

        // Test Steps
        // AWAIT root.remove("name")
        try await fixture.root.remove(key: "name")

        // Assertions
        // obj_msg = captured_messages[0].state[0]
        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        let op = try #require(messages[0].operation)
        #expect(op.action == .known(.mapRemove)) // ASSERT obj_msg.operation.action == "MAP_REMOVE" (RTLM21e2)
        #expect(op.objectId == ObjectsPool.rootKey) // ASSERT obj_msg.operation.objectId == "root"
        #expect(op.mapRemove?.key == "name") // ASSERT obj_msg.operation.mapRemove.key == "name" (RTLM21e5)
    }

    // MARK: - RTLM20: set() applies locally after ACK

    // UTS: objects/unit/RTLM20/set-applies-locally-0
    // The seeded double applies the published operation back onto the pool entry (the RTO20 ACK echo),
    // so the awaited write happens-after its local apply and the post-apply read reflects the change.
    @Test
    func setAppliesLocallyAfterAck() async throws {
        // Setup
        let root = Self.makeFixture().root

        // Test Steps
        // AWAIT root.set("name", "Bob")
        try await root.set(key: "name", value: .primitive(.string("Bob")))

        // Assertions
        // ASSERT root.get("name").value() == "Bob"
        #expect(try root.get(key: "name").asPrimitive().value() == .string("Bob"))
    }

    // MARK: - RTLM20: table-driven invalid set value types

    // UTS: objects/unit/RTLM20/set-invalid-values-table-0
    // DEVIATION (type-blocked): the spec's invalid values are `function` / `undefined` / `symbol` —
    // JavaScript constructs with no Swift representation. `LiveMapValue` is a closed enum
    // (.primitive / .liveMap / .liveCounter), so none of them is constructible and the 40013 rejection
    // (RTLMV4c) is compile-time-unrepresentable — a stronger guarantee than the runtime check. The
    // spec pseudocode is retained below; the method documents the type-system guarantee and passes
    // trivially.
    @Test
    func setWithInvalidValueTypesIsCompileTimeBlocked() {
        // invalid_values = [
        //   { value: some_function,  label: "function" },
        //   { value: undefined,      label: "undefined" },
        //   { value: some_symbol,    label: "symbol" }
        // ]
        // FOR scenario IN invalid_values:
        //   AWAIT root.set("key", scenario.value) FAILS WITH error
        //   ASSERT error.code == 40013
        //
        // None of `function` / `undefined` / `symbol` can be expressed as a `LiveMapValue`, so
        // `root.set(key:value:)` cannot even be called with them — the invalid-input path is closed by
        // the type system at compile time.
        #expect(Bool(true))
    }
}
