// Derived from the UTS spec `objects/unit/internal_live_map_api.md`.

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Foundation
import Testing

/// `InternalLiveMap` public-facing API — value reads (`get`/`size`/`entries`/`keys`) and the v6
/// `MAP_SET`/`MAP_REMOVE` write messages, surfaced through the path layer (`RTPO*` delegate to these).
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/internal_live_map_api.md
/// (spec points `RTLM5`, `RTLM10`–`RTLM12`, `RTLM20`–`RTLM21`, `RTLMV4`, `RTLCV4`).
///
/// The spec declares mock-WebSocket infrastructure (`setup_synced_channel`, `MockWebSocket`,
/// `captured_messages`, `mock_ws.send_to_client`) for these cases. Per the UNIT-only scope this ports
/// the subset exercisable without it: reads run against the standard pool seeded directly
/// (`ObjectsUTS.standardPool`), and the write messages are captured by ``ObjectsUTSSeededRealtimeObjects``
/// (the spec's `captured_messages[0].state[0]` maps to cocoa's `messages[0].operation`). Reads are
/// surfaced through a ``DefaultLiveMapPathObject`` — the map surface the spec's `root` resolves to.
///
/// ## Mock-realtime adaptation (recorded in deviations.md)
/// The seeded double captures the published `ObjectMessage` but does not apply it back onto the map,
/// so the post-apply `set-applies-locally` (`root.get("name").value() == "Bob"`) is out of unit scope
/// (only the published MAP_SET is asserted).
///
/// ## Bytes representation (deviation)
/// RTLM20e7f asserts `mapSet.value.bytes == "AQID"` (base64). Cocoa's outbound `ObjectData.bytes` holds
/// **raw `Data`**; the base64 encoding is applied at wire (JSON) serialization, below this layer. The
/// port asserts the raw `Data([1,2,3])`.
///
/// ## Blueprint value types (RTLM20e7g / RTLM20h1)
/// Setting a `LiveCounter`/`LiveMap` blueprint now evaluates it into its `*_CREATE` `ObjectMessages`
/// and publishes them atomically with the `MAP_SET` in one `publishAndApply` array (RTLM20h1). The
/// seeded double captures the exact array, so these are ported directly against `capturedMessages`.
///
/// ## Skipped — out of UNIT scope (need the concrete engine's async create pipeline / mock-WS)
/// - **RTLM20 set-invalid-values-table (function/undefined/symbol -> 40013):** `LiveMapValue` is a
///   closed enum, so a function / undefined / symbol value is compile-time-unrepresentable (as for
///   value_types.md RTLMV4c, DEV in deviations.md).
/// - **RTLM20d/RTLM21d write preconditions:** replaced by RTO26 (`objects/unit/realtime_object.md`).
@Suite(.serialized)
final class InternalLiveMapApiTests {
    // MARK: - Fixture

    private typealias Fixture = (root: DefaultLiveMapPathObject, realtimeObjects: ObjectsUTSSeededRealtimeObjects)

    private static func makeFixture() -> Fixture {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let pool = ObjectsUTS.standardPool(internalQueue: internalQueue)
        let realtimeObjects = ObjectsUTSSeededRealtimeObjects(pool: pool, internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK()
        let root = DefaultLiveMapPathObject(channelObject: realtimeObjects, coreSDK: coreSDK, internalQueue: internalQueue, segments: [])
        return (root, realtimeObjects)
    }

    // MARK: - RTLM5: get() returns resolved value

    // UTS: objects/unit/RTLM5/get-string-value-0 — RTLM5d2 (returns the value at key, resolved).
    @Test
    func RTLM5_get_string_value() throws {
        let root = Self.makeFixture().root
        #expect(try root.get(key: "name").asPrimitive().value() == .string("Alice"))
        #expect(try root.get(key: "age").asPrimitive().value() == .number(30))
        #expect(try root.get(key: "active").asPrimitive().value() == .bool(true))
    }

    // UTS: objects/unit/RTLM5/get-nonexistent-key-0 — no entry at key -> null.
    @Test
    func RTLM5_get_nonexistent_key() throws {
        let root = Self.makeFixture().root
        #expect(try root.get(key: "nonexistent").asPrimitive().value() == nil)
    }

    // UTS: objects/unit/RTLM5/get-objectid-reference-0 — a data.objectId entry resolves from the pool.
    @Test
    func RTLM5_get_objectid_reference() throws {
        let root = Self.makeFixture().root
        #expect(try root.get(key: "score").asLiveCounter().value() == 100)
        #expect(try root.at(path: "profile.email").asPrimitive().value() == .string("alice@example.com"))
    }

    // MARK: - RTLM10: size() returns non-tombstoned count

    // UTS: objects/unit/RTLM10/size-non-tombstoned-0 — RTLM10d (number of non-tombstoned entries).
    @Test
    func RTLM10_size_non_tombstoned() throws {
        let root = Self.makeFixture().root
        #expect(try root.size() == 7)
    }

    // MARK: - RTLM11: entries() yields key-value pairs

    // UTS: objects/unit/RTLM11/entries-yields-pairs-0 — RTLM11d (non-tombstoned key-value pairs).
    @Test
    func RTLM11_entries_yields_pairs() throws {
        let root = Self.makeFixture().root
        let keys = try Set(root.entries().map(\.key))
        #expect(keys == ["name", "age", "active", "score", "profile", "data", "avatar"])
    }

    // MARK: - RTLM12: keys() yields only keys

    // UTS: objects/unit/RTLM12/keys-0 — keys() returns the 7 non-tombstoned keys.
    @Test
    func RTLM12_keys() throws {
        let root = Self.makeFixture().root
        let keys = try root.keys()
        #expect(keys.count == 7)
        #expect(keys.contains("name"))
    }

    // MARK: - RTLM20: set() sends MAP_SET message with v6 format

    // UTS: objects/unit/RTLM20/set-sends-map-set-0 — RTLM20e2/e3/e6/e7c/h2 (MAP_SET, objectId, key, string
    // value, single-element array).
    @Test
    func RTLM20_set_sends_map_set() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.set(key: "name", value: .primitive(.string("Bob")))

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 1) // RTLM20h2
        let op = try #require(messages[0].operation)
        #expect(op.action == .known(.mapSet)) // RTLM20e2
        #expect(op.objectId == ObjectsPool.rootKey) // RTLM20e3
        #expect(op.mapSet?.key == "name") // RTLM20e6
        #expect(op.mapSet?.value?.string == "Bob") // RTLM20e7c
    }

    // UTS: objects/unit/RTLM20/set-value-types-0 — RTLM20e7b/d/e (json/number/boolean values).
    @Test
    func RTLM20_set_value_types() async throws {
        let fixture = Self.makeFixture()

        try await fixture.root.set(key: "num_key", value: .primitive(.number(42)))
        #expect(try #require(fixture.realtimeObjects.capturedMessages)[0].operation?.mapSet?.value?.number == NSNumber(value: 42)) // RTLM20e7d

        try await fixture.root.set(key: "bool_key", value: .primitive(.bool(false)))
        #expect(try #require(fixture.realtimeObjects.capturedMessages)[0].operation?.mapSet?.value?.boolean == false) // RTLM20e7e

        try await fixture.root.set(key: "json_key", value: .primitive(.jsonObject(["nested": .bool(true)])))
        #expect(try #require(fixture.realtimeObjects.capturedMessages)[0].operation?.mapSet?.value?.json == .object(["nested": .bool(true)])) // RTLM20e7b
    }

    // UTS: objects/unit/RTLM20/set-bytes-value-0 — RTLM20e7f (binary value). Cocoa holds raw Data; base64 is
    // applied at wire serialization (deviation).
    @Test
    func RTLM20_set_bytes_value() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.set(key: "binary_data", value: .primitive(.data(Data([1, 2, 3]))))

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages[0].operation?.mapSet?.value?.bytes == Data([1, 2, 3]))
    }

    // MARK: - RTLM20e7g: set() with a value-type blueprint publishes CREATE(s) + MAP_SET atomically

    // UTS: objects/unit/RTLM20e7g/set-counter-value-type-0 — RTLM20e7g1/g2/h1 (COUNTER_CREATE then MAP_SET,
    // value.objectId chained to the created counter).
    @Test
    func RTLM20e7g_set_counter_value_type() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.set(key: "new_counter", value: .liveCounter(.create(initialCount: 50)))

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 2) // RTLM20h1
        #expect(messages[0].operation?.action == .known(.counterCreate)) // RTLM20e7g1
        #expect(messages[0].operation?.objectId.hasPrefix("counter:") == true)
        #expect(messages[1].operation?.action == .known(.mapSet))
        // RTLM20e7g2: the MAP_SET references the created counter's objectId
        #expect(messages[1].operation?.mapSet?.value?.objectId == messages[0].operation?.objectId)
    }

    // UTS: objects/unit/RTLM20e7g/set-map-value-type-0 — RTLM20e7g1/g2/h1 (MAP_CREATE then MAP_SET).
    @Test
    func RTLM20e7g_set_map_value_type() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.set(key: "nested_map", value: .liveMap(.create(entries: ["key1": "value1"])))

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 2) // RTLM20h1
        #expect(messages[0].operation?.action == .known(.mapCreate)) // RTLM20e7g1
        #expect(messages[0].operation?.objectId.hasPrefix("map:") == true)
        #expect(messages[1].operation?.action == .known(.mapSet))
        #expect(messages[1].operation?.mapSet?.key == "nested_map")
        // RTLM20e7g2: the MAP_SET references the final message's (the created map's) objectId
        #expect(messages[1].operation?.mapSet?.value?.objectId == messages[0].operation?.objectId)
    }

    // UTS: objects/unit/RTLM20h1/set-nested-value-types-0 — RTLM20h1/RTLMV4d1/RTLMV4d2. A LiveMap
    // containing a nested LiveCounter: all *_CREATE messages appear before the MAP_SET, depth-first
    // (COUNTER_CREATE, MAP_CREATE, then the root MAP_SET).
    @Test
    func RTLM20h1_set_nested_value_types() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.set(key: "stats", value: .liveMap(.create(entries: [
            "count": .liveCounter(.create(initialCount: 0)),
            "label": "test",
        ])))

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 3) // RTLM20h1: COUNTER_CREATE, MAP_CREATE, MAP_SET
        #expect(messages[0].operation?.action == .known(.counterCreate)) // RTLMV4d1
        #expect(messages[0].operation?.objectId.hasPrefix("counter:") == true)
        #expect(messages[1].operation?.action == .known(.mapCreate)) // RTLMV4d2 (the "stats" map)
        #expect(messages[1].operation?.objectId.hasPrefix("map:") == true)
        #expect(messages[2].operation?.action == .known(.mapSet))
        #expect(messages[2].operation?.mapSet?.key == "stats")
        // RTLM20e7g2: the MAP_SET references the "stats" map's objectId (the final CREATE message)
        #expect(messages[2].operation?.mapSet?.value?.objectId == messages[1].operation?.objectId)
    }

    // MARK: - RTLM21: remove() sends MAP_REMOVE message

    // UTS: objects/unit/RTLM21/remove-sends-map-remove-0 — RTLM21e2/e5 (MAP_REMOVE action, key).
    @Test
    func RTLM21_remove_sends_map_remove() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.remove(key: "name")

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        let op = try #require(messages[0].operation)
        #expect(op.action == .known(.mapRemove)) // RTLM21e2
        #expect(op.objectId == ObjectsPool.rootKey) // RTLM21e3
        #expect(op.mapRemove?.key == "name") // RTLM21e5
    }
}
