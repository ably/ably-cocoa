// @UTS objects/unit/path_object.md

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Foundation
import Testing

/// `PathObject` read operations — path navigation, resolution, and the typed read accessors.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/path_object.md
/// (spec points `RTPO1`–`RTPO14`).
///
/// The spec drives every case through `setup_synced_channel` + a mock WebSocket that materialises the
/// standard pool via OBJECT_SYNC. Per the UNIT-only scope this seeds the same standard tree directly
/// into an ``ObjectsPool`` (`ObjectsUTS.standardPool`), wrapped by ``ObjectsUTSSeededRealtimeObjects``
/// so a ``DefaultLiveMapPathObject`` rooted at the empty path resolves root -> children exactly as
/// production does. This mirrors the native `DefaultPathObjectTests`.
///
/// ## Deviations (recorded in deviations.md)
/// - **DEV-2 (no polymorphic `value()`):** cocoa has no base `PathObject.value()`; reads go through a
///   typed cast — `asPrimitive().value()` (`Primitive?`) or `asLiveCounter().value()` (`Double?`).
///   The spec's `po.value()` for a primitive/counter/map maps to those casts; a map or an unresolved
///   path yields `nil` from either cast (the spec's `value() == null`).
/// - **`getType()`/`type()`:** cocoa spells RTTS8's discriminator `type()` (see DEV in deviations.md).
///
/// ## Compile-time-unrepresentable (recorded in deviations.md)
/// - **RTPO5b / RTPO6b** (`get(123)` / `at(123)` throw 40003): `get(key: String)` / `at(path: String)`
///   take `String`, so a non-string argument cannot be constructed.
///
/// ## Skipped — out of UNIT scope (need the mock-WS / raw-native `compact()` surface)
/// - **RTPO13 / RTPO13c / RTPO13c5** (`compact()` returning raw native values: raw bytes, counters as
///   numbers, and cyclic references reused as the same in-memory object): cocoa exposes only
///   `compactJson()` (JSON-shaped: bytes as base64, cycles as `{objectId}`). The JSON-shaped subset is
///   ported below as RTPO14; the raw-native `compact()` has no cocoa surface.
@Suite(.serialized)
final class PathObjectUTSTests {
    // MARK: - Fixture

    private static func makeRoot(prefsBackRef: Bool = false, channelState: _AblyPluginSupportPrivate.RealtimeChannelState = .attached) -> DefaultLiveMapPathObject {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let pool = ObjectsUTS.standardPool(internalQueue: internalQueue, prefsBackRef: prefsBackRef)
        let realtimeObjects = ObjectsUTSSeededRealtimeObjects(pool: pool, internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK(channelState: channelState)
        return DefaultLiveMapPathObject(channelObject: realtimeObjects, coreSDK: coreSDK, internalQueue: internalQueue, path: "")
    }

    // MARK: - RTPO4: path() returns dot-delimited string

    // objects/unit/RTPO4/path-string-representation-0 — RTPO4a (dot-delimited), RTPO4c (empty == root).
    @Test
    func RTPO4_path_string_representation() {
        let root = Self.makeRoot()
        #expect(root.path.isEmpty)
        #expect(root.get(key: "profile").path == "profile")
        #expect(root.get(key: "profile").asLiveMap().get(key: "email").path == "profile.email")
    }

    // objects/unit/RTPO4b/path-escapes-dots-0 — RTPO4b (dots within a segment escaped with backslash).
    @Test
    func RTPO4b_path_escapes_dots() {
        let root = Self.makeRoot()
        let po = root.get(key: "a.b").asLiveMap().get(key: "c")
        #expect(po.path == #"a\.b.c"#)
    }

    // MARK: - RTPO5: get() returns new PathObject with appended key

    // objects/unit/RTPO5/get-appends-key-0 — RTPO5c (key appended), RTPO5d (purely navigational).
    @Test
    func RTPO5_get_appends_key() {
        let root = Self.makeRoot()
        let child = root.get(key: "profile")
        let grandchild = child.asLiveMap().get(key: "email")
        #expect(child.path == "profile")
        #expect(grandchild.path == "profile.email")
        // RTPO5d: navigation does not resolve — a fresh object with a different (deeper) path.
        #expect(child.path != root.path)
    }

    // MARK: - RTPO6: at() parses dot-delimited path

    // objects/unit/RTPO6/at-parses-path-0 — RTPO6b (dots are separators), RTPO6d (== chained get()).
    @Test
    func RTPO6_at_parses_path() throws {
        let root = Self.makeRoot()
        let po = root.at(path: "profile.email")
        #expect(po.path == "profile.email")
        #expect(try po.asPrimitive().value() == .string("alice@example.com"))
    }

    // objects/unit/RTPO6/at-escaped-dots-0 — RTPO6b (`\.` is a literal dot within a segment).
    @Test
    func RTPO6_at_respects_escaped_dots() {
        let root = Self.makeRoot()
        let po = root.at(path: #"a\.b.c"#)
        #expect(po.path == #"a\.b.c"#)
    }

    // MARK: - RTPO7: value() returns resolved primitive / counter value

    // objects/unit/RTPO7/value-counter-0 — RTPO7c (counter -> its numeric value).
    @Test
    func RTPO7_value_counter() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "score").asLiveCounter().value() == 100)
    }

    // objects/unit/RTPO7/value-primitive-0 — RTPO7d (primitive -> value directly).
    @Test
    func RTPO7_value_primitive() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "name").asPrimitive().value() == .string("Alice"))
        #expect(try root.get(key: "age").asPrimitive().value() == .number(30))
        #expect(try root.get(key: "active").asPrimitive().value() == .bool(true))
    }

    // objects/unit/RTPO7/value-bytes-0 — RTPO7d (binary primitive -> raw bytes).
    @Test
    func RTPO7_value_bytes() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "avatar").asPrimitive().value() == .data(Data([1, 2, 3])))
    }

    // objects/unit/RTPO7d/value-livemap-null-0 — RTPO7e (map -> null; DEV-2: neither typed cast yields
    // a value for a map).
    @Test
    func RTPO7d_value_livemap_null() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "profile").asPrimitive().value() == nil)
        #expect(try root.get(key: "profile").asLiveCounter().value() == nil)
    }

    // objects/unit/RTPO7e/value-unresolvable-null-0 — RTPO7f (resolution failure -> null per RTPO3c1).
    @Test
    func RTPO7e_value_unresolvable_null() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "nonexistent").asLiveMap().get(key: "deep").asPrimitive().value() == nil)
    }

    // MARK: - RTPO8: instance() wraps the resolved value

    // objects/unit/RTPO8/instance-live-object-0 — RTPO8c (LiveObject -> Instance wrapping it).
    @Test
    func RTPO8_instance_live_object() throws {
        let root = Self.makeRoot()

        guard case let .liveCounter(counterInst) = try #require(try root.get(key: "score").instance()) else {
            Issue.record("Expected .liveCounter instance")
            return
        }
        #expect(counterInst.id == "counter:score@1000")

        guard case let .liveMap(mapInst) = try #require(try root.get(key: "profile").instance()) else {
            Issue.record("Expected .liveMap instance")
            return
        }
        #expect(mapInst.id == "map:profile@1000")
    }

    // objects/unit/RTPO8f/instance-primitive-wrapped-0 — RTPO8f (primitive -> Instance wrapping the
    // primitive value), RTINS3b (primitive Instance has no id — compile-time-unrepresentable, DEV-1),
    // RTINS4c (Instance#value returns the primitive directly).
    @Test
    func RTPO8f_instance_primitive_wrapped() throws {
        let root = Self.makeRoot()
        guard case let .primitive(primitive) = try #require(try root.get(key: "name").instance()) else {
            Issue.record("Expected .primitive instance")
            return
        }
        #expect(try primitive.value == .string("Alice"))
    }

    // MARK: - RTPO9: entries() returns [key, PathObject] pairs

    // objects/unit/RTPO9/entries-yields-pairs-0 — RTPO9c (array of [key, PathObject]), RTPO9d
    // (non-tombstoned only).
    @Test
    func RTPO9_entries_yields_pairs() throws {
        let root = Self.makeRoot()
        let entriesByKey = try Dictionary(uniqueKeysWithValues: root.entries().map { ($0.key, $0.value.path) })
        #expect(entriesByKey.count == 7)
        #expect(entriesByKey["name"] == "name")
        #expect(entriesByKey["profile"] == "profile")
    }

    // objects/unit/RTPO9d/entries-non-map-empty-0 — RTPO9d (non-map -> empty array).
    @Test
    func RTPO9d_entries_non_map_empty() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "score").asLiveMap().entries().isEmpty)
    }

    // MARK: - RTPO10: keys() returns key strings

    // objects/unit/RTPO10/keys-returns-array-0 — RTPO10c (delegates to InternalLiveMap#keys).
    @Test
    func RTPO10_keys_returns_array() throws {
        let root = Self.makeRoot()
        let keys = try root.keys()
        #expect(keys.count == 7)
        #expect(Set(keys).isSuperset(of: ["name", "profile", "score"]))
    }

    // objects/unit/RTPO10d/keys-non-map-empty-0 — RTPO10d (non-map -> empty array).
    @Test
    func RTPO10d_keys_non_map_empty() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "score").asLiveMap().keys().isEmpty)
    }

    // MARK: - RTPO11: values() returns PathObjects

    // objects/unit/RTPO11/values-returns-array-0 — RTPO11c (array of PathObjects; each path == key).
    @Test
    func RTPO11_values_returns_array() throws {
        let root = Self.makeRoot()
        let paths = try Set(root.values().map(\.path))
        #expect(paths.count == 7)
        #expect(paths.isSuperset(of: ["name", "profile", "score"]))
    }

    // objects/unit/RTPO11d/values-non-map-empty-0 — RTPO11d (non-map -> empty array).
    @Test
    func RTPO11d_values_non_map_empty() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "score").asLiveMap().values().isEmpty)
    }

    // MARK: - RTPO12: size() returns non-tombstoned count

    // objects/unit/RTPO12/size-count-0 — RTPO12c (delegates to InternalLiveMap#size).
    @Test
    func RTPO12_size_count() throws {
        let root = Self.makeRoot()
        #expect(try root.size() == 7)
        #expect(try root.get(key: "profile").asLiveMap().size() == 3)
    }

    // objects/unit/RTPO12c/size-non-map-null-0 — RTPO12d (non-map or resolution failure -> null).
    @Test
    func RTPO12c_size_non_map_null() throws {
        let root = Self.makeRoot()
        #expect(try root.get(key: "score").asLiveMap().size() == nil)
        #expect(try root.get(key: "name").asLiveMap().size() == nil)
    }

    // MARK: - RTPO14: compactJson() encodes binary as base64 and cycles as objectId

    // objects/unit/RTPO14/compact-json-bytes-0 — RTPO14b1 (binary values encoded as base64 strings).
    // Also covers RTPO13's JSON-shaped subset (primitives/counter/nested map).
    @Test
    func RTPO14_compact_json_bytes() throws {
        let root = Self.makeRoot()
        let result = try #require(try root.compactJson())
        guard case let .object(obj) = result else {
            Issue.record("Expected object")
            return
        }
        #expect(obj["avatar"] == .string("AQID")) // base64([1,2,3])
        #expect(obj["name"] == .string("Alice"))
        #expect(obj["age"] == .number(30))
        #expect(obj["active"] == .bool(true))
        #expect(obj["score"] == .number(100)) // RTPO13c: counter -> numeric value
        #expect(obj["data"] == .object(["tags": .array([.string("a"), .string("b")])]))
        // RTPO13c2: nested map recursively compacted.
        #expect(obj["profile"] == .object([
            "email": .string("alice@example.com"),
            "nested_counter": .number(5),
            "prefs": .object(["theme": .string("dark")]),
        ]))
    }

    // objects/unit/RTPO14/compact-json-0 — RTPO14b2 (a cyclic reference is encoded as {objectId: ...}).
    // The cycle is seeded directly (prefs.back_ref -> profile), the unit stand-in for the spec's
    // `mock_ws.send_to_client` MAP_SET.
    @Test
    func RTPO14_compact_json_cycle_as_objectid() throws {
        let root = Self.makeRoot(prefsBackRef: true)
        let result = try #require(try root.get(key: "profile").compactJson())
        guard case let .object(profile) = result,
              case let .object(prefs) = profile["prefs"]
        else {
            Issue.record("Expected profile.prefs object")
            return
        }
        #expect(prefs["back_ref"] == .object(["objectId": .string("map:profile@1000")]))
    }

    // MARK: - RTPO3: path resolution walks through InternalLiveMaps

    // objects/unit/RTPO3/path-resolution-walk-0 — RTPO3a (walk segments), RTPO3b (empty path -> root).
    @Test
    func RTPO3_path_resolution_walk() throws {
        let root = Self.makeRoot()
        #expect(try root.asPrimitive().value() == nil) // root is a map -> value() null (RTPO7e)
        #expect(try root.at(path: "profile.prefs.theme").asPrimitive().value() == .string("dark"))
    }

    // objects/unit/RTPO3a1/intermediate-not-map-0 — resolution fails when an intermediate is not a map.
    @Test
    func RTPO3a1_intermediate_not_map() throws {
        let root = Self.makeRoot()
        // "score" is a counter, so navigating through it fails -> read degrades to nil.
        #expect(try root.get(key: "score").asLiveMap().get(key: "something").asPrimitive().value() == nil)
    }

    // objects/unit/RTPO3c1/read-null-on-failure-0 — read operations return null on resolution failure.
    @Test
    func RTPO3c1_read_null_on_failure() throws {
        let root = Self.makeRoot()
        let missing = root.get(key: "nonexistent")
        #expect(try missing.asPrimitive().value() == nil)
        #expect(try missing.instance() == nil)
        #expect(try missing.asLiveMap().size() == nil)
        #expect(try missing.compactJson() == nil)
    }
}
