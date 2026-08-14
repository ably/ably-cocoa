// Derived from the UTS spec `objects/unit/path_object.md`.
//
// Drives the public `PathObject` navigation + read surface (RTPO3–RTPO14, RTTS4/RTTS5) over the
// standard LiveObjects tree. The spec's `{ client, channel, root, mock_ws } = AWAIT
// setup_synced_channel("test")` fixture (a mock-WebSocket synced channel) has no unit-tier
// counterpart: the standard pool is seeded straight into an `ObjectsPool` (`ObjectsUTS.standardPool`)
// behind an `ObjectsUTSSeededRealtimeObjects`, and the spec's `root` is a `DefaultLiveMapPathObject`
// over it. All cases here are read-only navigation, so no publish-capture or ACK echo is exercised.
// The two compactJson cycle cases (RTPO13c5/RTPO14) whose spec setup delivers an inbound MAP_SET
// (`mock_ws.send_to_client` + `poll_until`) adding `prefs.back_ref -> profile` are stood in by seeding
// that entry directly with `prefsBackRef: true` — an infra-driving stand-in (the unit tier has no
// mock transport), NOT a deviation.
//
// Deviations from the UTS spec (see Test/UTS/deviations.md):
// - (D-1) RTPO13/RTPO13c/RTPO3c1 `compact()` is not implemented (RTTS3f — typed SDKs need not
//   implement the non-JSON `compact()`; objects-mapping §5), so those cases are adapted to
//   `compactJson()`, whose recursive-compaction values are identical. Same class as the existing
//   RTINS10/RTTS7d entry. Within RTPO13, binary is additionally base64-encoded by `compactJson`
//   (RTPO14b1) where `compact()` would return raw bytes — the `avatar` line asserts "AQID".
// - (D-2) RTPO13c5 (`compact()` cycle by shared-reference identity) is not adaptable: the assertion
//   is reference identity (`result["prefs"]["back_ref"] IS result`), which only the non-JSON
//   `compact()` provides; `compactJson()` encodes the cycle as `{objectId: ...}` instead — that JSON
//   equivalent is covered by RTPO14/compact-json-0, so RTPO13c5 is retained as comments (not adapted,
//   to avoid duplicating RTPO14).
// - (D-3) RTPO5b/RTPO6b (`get(123)`/`at(123)` -> 40003) are type-blocked: `get(key: String)` /
//   `at(path: String)` reject a non-string at compile time, so the 40003 rejection is
//   compile-time-unrepresentable — a stronger guarantee than the runtime check. Same class as the
//   existing RTLMV4c type-system-guarantee entries.

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct PathObjectTests {
    // MARK: - Fixture

    /// The unit stand-in for `{ client, channel, root, mock_ws } = AWAIT setup_synced_channel("test")`:
    /// seed the standard pool directly and expose it through a seeded realtime-objects double, then
    /// front it with the root map path object (the spec's `root`). `prefsBackRef` seeds the
    /// `prefs.back_ref -> profile` cycle the compactJson cases exercise (the direct-seeding stand-in
    /// for the spec's inbound MAP_SET + poll_until).
    private static func makeRoot(prefsBackRef: Bool = false) -> DefaultLiveMapPathObject {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let pool = ObjectsUTS.standardPool(internalQueue: internalQueue, prefsBackRef: prefsBackRef)
        let realtimeObjects = ObjectsUTSSeededRealtimeObjects(pool: pool, internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK()
        return DefaultLiveMapPathObject(channelObject: realtimeObjects, coreSDK: coreSDK, internalQueue: internalQueue, segments: [])
    }

    // MARK: - RTPO4: path() returns dot-delimited string

    // UTS: objects/unit/RTPO4/path-string-representation-0
    @Test
    func pathReturnsDotDelimitedString() {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.path() == "" (RTPO4c)
        #expect(root.path == "")
        // ASSERT root.get("profile").path() == "profile" (RTPO4a)
        #expect(root.get(key: "profile").path == "profile")
        // ASSERT root.get("profile").get("email").path() == "profile.email"
        #expect(root.get(key: "profile").asLiveMap().get(key: "email").path == "profile.email")
    }

    // MARK: - RTPO4b: path() escapes dots in segments

    // UTS: objects/unit/RTPO4b/path-escapes-dots-0
    @Test
    func pathEscapesDotsInSegments() {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // po = root.get("a.b").get("c")
        let po = root.get(key: "a.b").asLiveMap().get(key: "c")

        // Assertions
        // ASSERT po.path() == "a\.b.c" — the dot inside segment "a.b" is backslash-escaped (Swift
        // literal "a\\.b.c" is the string a\.b.c); segments ["a.b", "c"] round-trip.
        #expect(po.path == "a\\.b.c")
    }

    // MARK: - RTPO5: get() returns new PathObject with appended key

    // UTS: objects/unit/RTPO5/get-appends-key-0
    @Test
    func getAppendsKey() {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // child = root.get("profile")
        let child = root.get(key: "profile")
        // grandchild = child.get("email")
        let grandchild = child.asLiveMap().get(key: "email")

        // Assertions
        // ASSERT child.path() == "profile" (RTPO5c)
        #expect(child.path == "profile")
        // ASSERT grandchild.path() == "profile.email"
        #expect(grandchild.path == "profile.email")
        // ASSERT child IS NOT root (RTPO5d — a new PathObject, not a mutation of root)
        #expect(child as AnyObject !== root as AnyObject)
    }

    // MARK: - RTPO5b: get() throws on non-string key

    // UTS: objects/unit/RTPO5b/get-non-string-throws-0
    // DEVIATION (D-3): type-blocked. `LiveMapPathObject.get(key: String)` rejects a non-string at
    // compile time, so `root.get(123)` cannot be written and the 40003 rejection is
    // compile-time-unrepresentable — a stronger guarantee than the runtime check.
    @Test
    func getNonStringKeyIsCompileTimeBlocked() {
        // root.get(123) FAILS WITH error
        // ASSERT error.code == 40003
        //
        // `123` is not a `String`, so `root.get(key:)` cannot be called with it — the invalid-input
        // path is closed by the type system at compile time.
        #expect(Bool(true))
    }

    // MARK: - RTPO6: at() parses dot-delimited path

    // UTS: objects/unit/RTPO6/at-parses-path-0
    @Test
    func atParsesDotDelimitedPath() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // po = root.at("profile.email")
        let po = root.at(path: "profile.email")

        // Assertions
        // ASSERT po.path() == "profile.email" (RTPO6d — equivalent to chained get() calls)
        #expect(po.path == "profile.email")
        // ASSERT po.value() == "alice@example.com"
        #expect(try po.asPrimitive().value() == .string("alice@example.com"))
    }

    // UTS: objects/unit/RTPO6/at-escaped-dots-0
    @Test
    func atRespectsEscapedDots() {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // po = root.at("a\.b.c") — `\.` is a literal dot within a segment (RTPO6b)
        let po = root.at(path: "a\\.b.c")

        // Assertions
        // ASSERT po.path() == "a\.b.c" — segments ["a.b", "c"] round-trip through the escaped form.
        #expect(po.path == "a\\.b.c")
    }

    // MARK: - RTPO7: value() returns counter numeric value

    // UTS: objects/unit/RTPO7/value-counter-0
    @Test
    func valueReturnsCounterValue() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("score").value() == 100 (RTPO7c — InternalLiveCounter#value)
        #expect(try root.get(key: "score").asLiveCounter().value() == 100)
    }

    // UTS: objects/unit/RTPO7/value-primitive-0
    @Test
    func valueReturnsPrimitiveValue() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("name").value() == "Alice" (RTPO7d — primitive returned directly)
        #expect(try root.get(key: "name").asPrimitive().value() == .string("Alice"))
        // ASSERT root.get("age").value() == 30
        #expect(try root.get(key: "age").asPrimitive().value() == .number(30))
        // ASSERT root.get("active").value() == true
        #expect(try root.get(key: "active").asPrimitive().value() == .bool(true))
    }

    // UTS: objects/unit/RTPO7/value-bytes-0
    @Test
    func valueReturnsBytesForBinaryEntry() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("avatar").value() IS bytes [1, 2, 3] (RTPO7d — raw binary data)
        #expect(try root.get(key: "avatar").asPrimitive().value() == .data(Data([1, 2, 3])))
    }

    // MARK: - RTPO7d: value() returns null for InternalLiveMap

    // UTS: objects/unit/RTPO7d/value-livemap-null-0
    @Test
    func valueReturnsNullForLiveMap() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("profile").value() == null (RTPO7e — InternalLiveMap resolves to no
        // primitive; the primitive value getter returns nil for a live object)
        #expect(try root.get(key: "profile").asPrimitive().value() == nil)
    }

    // MARK: - RTPO7e: value() returns null on resolution failure

    // UTS: objects/unit/RTPO7e/value-unresolvable-null-0
    @Test
    func valueReturnsNullOnResolutionFailure() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("nonexistent").get("deep").value() == null (RTPO7f -> RTPO3c1)
        #expect(try root.get(key: "nonexistent").asLiveMap().get(key: "deep").asPrimitive().value() == nil)
    }

    // MARK: - RTPO8: instance() returns Instance for LiveObject

    // UTS: objects/unit/RTPO8/instance-live-object-0
    @Test
    func instanceReturnsInstanceForLiveObject() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // counter_inst = root.get("score").instance()
        // ASSERT counter_inst IS Instance (non-nil); ASSERT counter_inst.id() == "counter:score@1000" (RTPO8c)
        guard case let .liveCounter(counterInst) = try #require(try root.get(key: "score").instance()) else {
            Issue.record("expected a counter instance at root.get(\"score\")")
            return
        }
        #expect(counterInst.id == "counter:score@1000")

        // map_inst = root.get("profile").instance()
        // ASSERT map_inst IS Instance (non-nil); ASSERT map_inst.id() == "map:profile@1000"
        guard case let .liveMap(mapInst) = try #require(try root.get(key: "profile").instance()) else {
            Issue.record("expected a map instance at root.get(\"profile\")")
            return
        }
        #expect(mapInst.id == "map:profile@1000")
    }

    // MARK: - RTPO8f: instance() returns Instance for primitive

    // UTS: objects/unit/RTPO8f/instance-primitive-wrapped-0
    @Test
    func instanceReturnsInstanceForPrimitive() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // name_inst = root.get("name").instance()
        // ASSERT name_inst IS Instance (non-nil, RTPO8f — the primitive is wrapped in an Instance)
        guard case let .primitive(namePrim) = try #require(try root.get(key: "name").instance()) else {
            Issue.record("expected a primitive instance at root.get(\"name\")")
            return
        }
        // ASSERT name_inst.id() == null (RTINS3b) — not expressible: PrimitiveInstance has no `id`
        // member (objects-mapping §5), a compile-time structural guarantee stronger than a runtime null.
        // ASSERT name_inst.value() == "Alice" (RTINS4c — the primitive value directly)
        #expect(try namePrim.value == .string("Alice"))
    }

    // MARK: - RTPO9: entries() returns array of [key, PathObject] pairs

    // UTS: objects/unit/RTPO9/entries-yields-pairs-0
    @Test
    func entriesYieldsKeyPathObjectPairs() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // entries = {}
        // FOR [key, pathObj] IN root.entries(): entries[key] = pathObj.path()
        var entries: [String: String] = [:]
        for (key, pathObj) in try root.entries() {
            entries[key] = pathObj.path
        }

        // Assertions
        // ASSERT entries["name"] == "name"
        #expect(entries["name"] == "name")
        // ASSERT entries["profile"] == "profile"
        #expect(entries["profile"] == "profile")
        // ASSERT entries.length == 7 (RTPO9d — only non-tombstoned entries)
        #expect(entries.count == 7)
    }

    // MARK: - RTPO9d: entries() returns empty array for non-InternalLiveMap

    // UTS: objects/unit/RTPO9d/entries-non-map-empty-0
    @Test
    func entriesReturnsEmptyForNonMap() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // entries = root.get("score").entries() — score is a counter, not a map
        let entries = try root.get(key: "score").asLiveMap().entries()

        // Assertions
        // ASSERT entries.length == 0 (RTPO9d)
        #expect(entries.count == 0)
    }

    // MARK: - RTPO10: keys() returns array of key strings

    // UTS: objects/unit/RTPO10/keys-returns-array-0
    @Test
    func keysReturnsArray() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // keys = root.keys()
        let keys = try root.keys()

        // Assertions
        // ASSERT keys IS Array — guaranteed by the return type `[String]`.
        // ASSERT keys.length == 7 (RTPO10c — InternalLiveMap#keys)
        #expect(keys.count == 7)
        // ASSERT "name" IN keys; ASSERT "profile" IN keys; ASSERT "score" IN keys
        #expect(keys.contains("name"))
        #expect(keys.contains("profile"))
        #expect(keys.contains("score"))
    }

    // MARK: - RTPO10d: keys() returns empty array for non-InternalLiveMap

    // UTS: objects/unit/RTPO10d/keys-non-map-empty-0
    @Test
    func keysReturnsEmptyForNonMap() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // keys = root.get("score").keys() — score is a counter, not a map
        let keys = try root.get(key: "score").asLiveMap().keys()

        // Assertions
        // ASSERT keys IS Array — guaranteed by the return type `[String]`.
        // ASSERT keys.length == 0 (RTPO10d)
        #expect(keys.count == 0)
    }

    // MARK: - RTPO11: values() returns array of PathObjects

    // UTS: objects/unit/RTPO11/values-returns-array-0
    @Test
    func valuesReturnsArrayOfPathObjects() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // vals = root.values()
        let vals = try root.values()

        // Assertions
        // ASSERT vals IS Array — guaranteed by the return type `[any PathObject]`.
        // ASSERT vals.length == 7 (RTPO11c — InternalLiveMap#keys)
        #expect(vals.count == 7)
        // Each element is a PathObject whose path is the key
        // paths = {}; FOR v IN vals: paths[v.path()] = true
        let paths = Set(vals.map(\.path))
        // ASSERT paths["name"] == true; ASSERT paths["profile"] == true; ASSERT paths["score"] == true
        #expect(paths.contains("name"))
        #expect(paths.contains("profile"))
        #expect(paths.contains("score"))
    }

    // MARK: - RTPO11d: values() returns empty array for non-InternalLiveMap

    // UTS: objects/unit/RTPO11d/values-non-map-empty-0
    @Test
    func valuesReturnsEmptyForNonMap() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // vals = root.get("score").values() — score is a counter, not a map
        let vals = try root.get(key: "score").asLiveMap().values()

        // Assertions
        // ASSERT vals IS Array — guaranteed by the return type `[any PathObject]`.
        // ASSERT vals.length == 0 (RTPO11d)
        #expect(vals.count == 0)
    }

    // MARK: - RTPO12: size() returns non-tombstoned count

    // UTS: objects/unit/RTPO12/size-count-0
    @Test
    func sizeReturnsNonTombstonedCount() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.size() == 7 (RTPO12c — InternalLiveMap#size)
        #expect(try root.size() == 7)
        // ASSERT root.get("profile").size() == 3
        #expect(try root.get(key: "profile").asLiveMap().size() == 3)
    }

    // MARK: - RTPO12c: size() returns null for non-InternalLiveMap

    // UTS: objects/unit/RTPO12c/size-non-map-null-0
    @Test
    func sizeReturnsNullForNonMap() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("score").size() == null (RTPO12d — counter)
        #expect(try root.get(key: "score").asLiveMap().size() == nil)
        // ASSERT root.get("name").size() == null (RTPO12d — primitive)
        #expect(try root.get(key: "name").asLiveMap().size() == nil)
    }

    // MARK: - RTPO13: compact() recursively compacts InternalLiveMap tree

    // UTS: objects/unit/RTPO13/compact-recursive-0
    // DEVIATION (D-1): `compact()` is not implemented (RTTS3f); adapted to `compactJson()`, whose
    // recursive-compaction values are identical. Binary is additionally base64-encoded by compactJson
    // (RTPO14b1) where compact() would return raw bytes — the `avatar` line asserts "AQID".
    @Test
    func compactRecursivelyCompacts() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // result = root.compact()  -> compactJson() (D-1)
        let result = try root.compactJson()

        // Assertions
        // ASSERT result["name"] == "Alice" (RTPO13c4 — primitives as-is)
        #expect(result?.objectValue?["name"] == .string("Alice"))
        // ASSERT result["age"] == 30
        #expect(result?.objectValue?["age"] == .number(30))
        // ASSERT result["active"] == true
        #expect(result?.objectValue?["active"] == .bool(true))
        // ASSERT result["score"] == 100 (RTPO13c3 — nested InternalLiveCounter resolved to number)
        #expect(result?.objectValue?["score"] == .number(100))
        // ASSERT result["data"] == {"tags": ["a", "b"]}
        #expect(result?.objectValue?["data"] == .object(["tags": .array([.string("a"), .string("b")])]))
        // ASSERT result["avatar"] IS bytes [1, 2, 3] — compactJson base64-encodes binary (D-1).
        #expect(result?.objectValue?["avatar"] == .string("AQID"))
        // ASSERT result["profile"]["email"] == "alice@example.com" (RTPO13c2 — nested map recursed)
        #expect(result?.objectValue?["profile"]?.objectValue?["email"] == .string("alice@example.com"))
        // ASSERT result["profile"]["nested_counter"] == 5
        #expect(result?.objectValue?["profile"]?.objectValue?["nested_counter"] == .number(5))
        // ASSERT result["profile"]["prefs"]["theme"] == "dark"
        #expect(result?.objectValue?["profile"]?.objectValue?["prefs"]?.objectValue?["theme"] == .string("dark"))
    }

    // MARK: - RTPO13c5: compact() handles cycles via shared reference

    // UTS: objects/unit/RTPO13c5/compact-cycle-detection-0
    // DEVIATION (D-2): not adaptable. The spec asserts reference identity
    // (`result["prefs"]["back_ref"] IS result`), which only the non-JSON `compact()` provides (RTTS3f
    // — not implemented). `compactJson()` encodes the cycle as `{objectId: ...}` instead; that JSON
    // equivalent is covered by RTPO14/compact-json-0, so this case is retained as comments rather than
    // adapted (adapting would duplicate RTPO14).
    @Test
    func compactHandlesCyclesViaSharedReference() {
        // Setup (spec): mock_ws.send_to_client(build_map_set("map:prefs@1000", "back_ref",
        //   { objectId: "map:profile@1000" }, "99", "remote"))
        // poll_until("back_ref" IN root.get("profile").get("prefs").keys(), timeout: 5s)
        //   -> unit stand-in: seed prefsBackRef directly into the pool.
        //
        // Test Steps: result = root.get("profile").compact()
        // Assertions: ASSERT result["prefs"]["back_ref"] IS result (RTPO13c5 — the cyclic reference
        //   reuses the already-compacted in-memory object).
        //
        // Reference-identity cycle reuse is a property of the non-JSON `compact()` graph only; cocoa
        // implements `compactJson()` (RTPO14b2: cycle -> {objectId: ...}), a value-shaped encoding
        // where an `IS`/identity comparison is meaningless. The JSON cycle behaviour is asserted by
        // RTPO14/compact-json-0 (`compactJsonEncodesCyclesAsObjectId`).
        #expect(Bool(true))
    }

    // MARK: - RTPO13c: compact() returns number for InternalLiveCounter

    // UTS: objects/unit/RTPO13c/compact-counter-0
    // DEVIATION (D-1): `compact()` is not implemented (RTTS3f); adapted to `compactJson()`, which
    // resolves a counter to its numeric value identically.
    @Test
    func compactReturnsNumberForCounter() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("score").compact() == 100 (RTPO13d) -> compactJson() (D-1)
        #expect(try root.get(key: "score").compactJson() == .number(100))
    }

    // MARK: - RTPO14: compactJson() encodes binary as base64 and cycles as objectId

    // UTS: objects/unit/RTPO14/compact-json-0
    @Test
    func compactJsonEncodesCyclesAsObjectId() throws {
        // Setup: seed the prefs.back_ref -> profile cycle (the unit stand-in for the spec's inbound
        // MAP_SET + poll_until).
        let root = Self.makeRoot(prefsBackRef: true)

        // Test Steps
        // result = root.get("profile").compactJson()
        let result = try root.get(key: "profile").compactJson()

        // Assertions
        // ASSERT result["prefs"]["back_ref"] == { "objectId": "map:profile@1000" } (RTPO14b2)
        #expect(result?.objectValue?["prefs"]?.objectValue?["back_ref"] == .object(["objectId": .string("map:profile@1000")]))
    }

    // UTS: objects/unit/RTPO14/compact-json-bytes-0
    @Test
    func compactJsonEncodesBytesAsBase64() throws {
        // Setup
        let root = Self.makeRoot()

        // Test Steps
        // result = root.compactJson()
        let result = try root.compactJson()

        // Assertions
        // ASSERT result["avatar"] == "AQID" (RTPO14b1 — binary as base64 string)
        #expect(result?.objectValue?["avatar"] == .string("AQID"))
    }

    // MARK: - RTPO3: Path resolution walks through InternalLiveMaps

    // UTS: objects/unit/RTPO3/path-resolution-walk-0
    @Test
    func pathResolutionWalksThroughMaps() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.value() == null (RTPO3b — empty path resolves to root, a map, so value() is null)
        #expect(try root.asPrimitive().value() == nil)
        // ASSERT root.get("profile").get("prefs").get("theme").value() == "dark" (RTPO3a — walk maps)
        #expect(try root.get(key: "profile").asLiveMap().get(key: "prefs").asLiveMap().get(key: "theme").asPrimitive().value() == .string("dark"))
    }

    // MARK: - RTPO3a1: Resolution fails if intermediate is not InternalLiveMap

    // UTS: objects/unit/RTPO3a1/intermediate-not-map-0
    @Test
    func resolutionFailsWhenIntermediateNotMap() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("score").get("something").value() == null (score is a counter; navigating
        // further through a non-map fails resolution -> null)
        #expect(try root.get(key: "score").asLiveMap().get(key: "something").asPrimitive().value() == nil)
    }

    // MARK: - RTPO3c1: Read operation returns null on resolution failure

    // UTS: objects/unit/RTPO3c1/read-null-on-failure-0
    // The compact() line is adapted to compactJson() (D-1); the rest port directly.
    @Test
    func readOperationsReturnNullOnResolutionFailure() throws {
        // Setup
        let root = Self.makeRoot()

        // Assertions
        // ASSERT root.get("nonexistent").value() == null
        #expect(try root.get(key: "nonexistent").asPrimitive().value() == nil)
        // ASSERT root.get("nonexistent").instance() == null
        #expect(try root.get(key: "nonexistent").instance() == nil)
        // ASSERT root.get("nonexistent").size() == null
        #expect(try root.get(key: "nonexistent").asLiveMap().size() == nil)
        // ASSERT root.get("nonexistent").compact() == null -> compactJson() (D-1)
        #expect(try root.get(key: "nonexistent").compactJson() == nil)
    }

    // MARK: - RTPO6b: at() throws for non-string input

    // UTS: objects/unit/RTPO6b/at-non-string-throws-0
    // DEVIATION (D-3): type-blocked. `LiveMapPathObject.at(path: String)` rejects a non-string at
    // compile time, so `root.at(123)` cannot be written and the 40003 rejection is
    // compile-time-unrepresentable — a stronger guarantee than the runtime check.
    @Test
    func atNonStringIsCompileTimeBlocked() {
        // root.at(123) FAILS WITH error
        // ASSERT error.code == 40003
        //
        // `123` is not a `String`, so `root.at(path:)` cannot be called with it — the invalid-input
        // path is closed by the type system at compile time.
        #expect(Bool(true))
    }
}
