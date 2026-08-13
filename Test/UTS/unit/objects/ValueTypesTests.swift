// Derived from the UTS spec `objects/unit/value_types.md`.

import Ably
@testable import AblyLiveObjects
import Foundation
import Testing

/// LiveCounter / LiveMap value types (blueprints) and their evaluation into `ObjectMessage`s.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/value_types.md
/// (spec points `RTLCV1`–`RTLCV4`, `RTLMV1`–`RTLMV4`).
///
/// Pure construction/evaluation tests — no mocks, no WebSocket. The blueprints are the public
/// `LiveCounter` / `LiveMap` value types (`Path Based API/Public/ValueTypes.swift`); their internal
/// `count` / `entries` are read via `@testable`.
///
/// ## Cocoa evaluation seam (DEV-VT-1)
/// The spec models `evaluate(vt)` as a method on the blueprint returning `ObjectMessage`s. Cocoa has
/// no standalone `evaluate`: blueprint→message generation lives in `ObjectCreationHelpers`
/// (`creationOperationForLiveCounter` / `creationOperationForLiveMap`, and the recursive
/// `evaluate(liveMap:)`/`evaluate(liveCounter:)` used by `InternalLiveMap#set`).
/// `ObjectsUTS.evaluate(counter:)`/`evaluate(map:)` bridge the public blueprint to that seam,
/// evaluating with a fixed timestamp (the production seam fetches a per-object server time).
/// Consequently the retained-local create (spec `msg.operation.counterCreate` / `mapCreate`, RTLCV4g5 /
/// RTLMV4j5) is exposed as `operation.counterCreateWithObjectId.derivedFrom` /
/// `operation.mapCreateWithObjectId.derivedFrom` on the outbound message, not as a separate top-level
/// field.
///
/// ## Compile-time-unrepresentable cases (recorded in deviations.md)
/// Swift's strongly-typed blueprint API makes several spec validation cases impossible to express, so
/// the runtime tests do not exist (the type system enforces at compile time what the spec enforces at
/// runtime):
/// - RTLCV3c / RTLCV4a `LiveCounter.create("not_a_number")`: `initialCount` is `Double`.
/// - RTLMV4a `LiveMap.create(null)`: `create()` (no entries) vs `create(entries:)` — there is no null.
/// - RTLMV4b non-String key: keys are `String` by type.
/// - RTLMV4c / 40013 "invalid value / graph object as map value": values are the closed `LiveMapValue`
///   enum — a function, or a live (non-blueprint) map, cannot be constructed as one.
///
/// ## Notes
/// - RTLMV4d1/RTLMV4d2/RTLMV4k (nested depth-first evaluation) are now ported (`RTLMV4d1_nested_value_types`):
///   `ObjectsUTS.evaluate(map:)` recurses through nested blueprint entries, producing the depth-first
///   ordered array directly from the pure `ObjectCreationHelpers` composition builders.
/// - RTLCV4a finiteness (NaN/Infinity → 40003) is validated in `ObjectCreationHelpers.evaluate(liveCounter:)`,
///   but the spec's `evaluate-validates-count-0` case passes the string `"not_a_number"`, which is
///   compile-time-unrepresentable (`initialCount` is `Double`), so there is no representable runtime case
///   to port through `ObjectsUTS.evaluate(counter:)`.
@Suite(.serialized)
final class ValueTypesTests {
    // MARK: - RTLCV3: LiveCounter.create construction

    // UTS: objects/unit/RTLCV3/create-with-count-0
    // RTLCV3a1/RTLCV3b (DEV-VT-1: `create(initialCount:)`,
    // count is Double).
    @Test
    func RTLCV3_create_with_count() {
        let vt = LiveCounter.create(initialCount: 42)
        #expect(vt.count == 42) // RTLCV3b
    }

    // UTS: objects/unit/RTLCV3/create-default-zero-0
    // omitted initialCount defaults to 0.
    @Test
    func RTLCV3_create_default_zero() {
        let vt = LiveCounter.create()
        #expect(vt.count == 0) // swiftformat:disable:this isEmpty — swiftlint:disable:this empty_count
    }

    // MARK: - RTLMV3: LiveMap.create construction

    // UTS: objects/unit/RTLMV3/create-with-entries-0
    // RTLMV3a1/RTLMV3b. Entries are `LiveMapValue`; a bare
    // string/number literal lands as `.primitive(.string)` / `.primitive(.number)` (DEV-VT-1).
    @Test
    func RTLMV3_create_with_entries() {
        let vt = LiveMap.create(entries: [
            "name": "Alice",
            "age": 30,
        ])
        #expect(vt.entries?["name"] == .primitive(.string("Alice")))
        #expect(vt.entries?["age"] == .primitive(.number(30)))
    }

    // UTS: objects/unit/RTLMV3/create-no-entries-0
    // omitted entries => internal entries is nil.
    @Test
    func RTLMV3_create_no_entries() {
        let vt = LiveMap.create()
        #expect(vt.entries == nil)
    }

    // MARK: - RTLCV4: LiveCounter evaluation

    // UTS: objects/unit/RTLCV4/evaluate-generates-message-0
    // RTLCV4c/d/f/g1–g4.
    @Test
    func RTLCV4_evaluate_generates_message() throws {
        let messages = ObjectsUTS.evaluate(counter: LiveCounter.create(initialCount: 42))

        #expect(messages.count == 1)
        let operation = try #require(messages[0].operation)
        #expect(operation.action == .known(.counterCreate)) // RTLCV4g1
        #expect(operation.objectId.hasPrefix("counter:")) // RTLCV4f/g2
        #expect(operation.objectId.contains("@"))
        let withObjectId = try #require(operation.counterCreateWithObjectId)
        #expect(withObjectId.nonce.count >= 16) // RTLCV4d/g3
        #expect(!withObjectId.initialValue.isEmpty) // RTLCV4c/g4
    }

    // UTS: objects/unit/RTLCV4g5/retains-local-counter-create-0
    // the retained local CounterCreate is
    // `counterCreateWithObjectId.derivedFrom` in cocoa's outbound shape (DEV-VT-1).
    @Test
    func RTLCV4g5_retains_local_counter_create() throws {
        let messages = ObjectsUTS.evaluate(counter: LiveCounter.create(initialCount: 42))
        let derivedFrom = try #require(messages[0].operation?.counterCreateWithObjectId?.derivedFrom)
        #expect(derivedFrom.count == 42)
    }

    // UTS: objects/unit/RTLCV4/evaluate-zero-count-0
    // count 0 is valid and retained.
    @Test
    func RTLCV4_evaluate_zero_count() throws {
        let messages = ObjectsUTS.evaluate(counter: LiveCounter.create(initialCount: 0))
        let derivedFrom = try #require(messages[0].operation?.counterCreateWithObjectId?.derivedFrom)
        #expect(derivedFrom.count == 0) // swiftformat:disable:this isEmpty — swiftlint:disable:this empty_count
    }

    // MARK: - RTLMV4: LiveMap evaluation

    // UTS: objects/unit/RTLMV4/evaluate-generates-message-0
    // RTLMV4f/g/i/j1/j3/j4.
    @Test
    func RTLMV4_evaluate_generates_message() throws {
        let messages = ObjectsUTS.evaluate(map: LiveMap.create(entries: ["name": "Alice"]), internalQueue: ObjectsUTS.createInternalQueue())

        #expect(messages.count == 1)
        let operation = try #require(messages[0].operation)
        #expect(operation.action == .known(.mapCreate)) // RTLMV4j1
        #expect(operation.objectId.hasPrefix("map:")) // RTLMV4i
        let withObjectId = try #require(operation.mapCreateWithObjectId)
        #expect(withObjectId.nonce.count >= 16) // RTLMV4g/j3
        #expect(!withObjectId.initialValue.isEmpty) // RTLMV4f/j4
    }

    // UTS: objects/unit/RTLMV4j5/retains-local-map-create-0
    // retained local MapCreate is
    // `mapCreateWithObjectId.derivedFrom` (DEV-VT-1); semantics is LWW (RTLMV4e1).
    @Test
    func RTLMV4j5_retains_local_map_create() throws {
        let messages = ObjectsUTS.evaluate(map: LiveMap.create(entries: ["name": "Alice"]), internalQueue: ObjectsUTS.createInternalQueue())
        let derivedFrom = try #require(messages[0].operation?.mapCreateWithObjectId?.derivedFrom)
        #expect(derivedFrom.semantics == .known(.lww)) // RTLMV4e1
        #expect(derivedFrom.entries?["name"]?.data?.string == "Alice")
    }

    // UTS: objects/unit/RTLMV4d1/nested-value-types-0
    // RTLMV4d1/RTLMV4d2/RTLMV4k. Nested value types
    // produce depth-first ObjectMessages: inner creates before outer, each entry pointing at its child's
    // objectId. The spec's `messages[i].operation.mapCreate.entries` is cocoa's retained
    // `mapCreateWithObjectId.derivedFrom.entries` (DEV-VT-1).
    @Test
    func RTLMV4d1_nested_value_types() throws {
        let innerCounter = LiveCounter.create(initialCount: 10)
        let innerMap = LiveMap.create(entries: ["nested_count": .liveCounter(innerCounter)])
        let outer = LiveMap.create(entries: ["child": .liveMap(innerMap)])
        let messages = ObjectsUTS.evaluate(map: outer, internalQueue: ObjectsUTS.createInternalQueue())

        #expect(messages.count == 3)
        #expect(messages[0].operation?.action == .known(.counterCreate)) // RTLMV4d1
        #expect(messages[0].operation?.objectId.hasPrefix("counter:") == true)
        #expect(messages[1].operation?.action == .known(.mapCreate)) // RTLMV4d2
        #expect(messages[1].operation?.objectId.hasPrefix("map:") == true)
        #expect(messages[2].operation?.action == .known(.mapCreate)) // RTLMV4k: outer map last
        #expect(messages[2].operation?.objectId.hasPrefix("map:") == true)

        let innerCounterId = try #require(messages[0].operation?.objectId)
        let innerMapId = try #require(messages[1].operation?.objectId)

        // The inner map's `nested_count` entry references the created counter.
        #expect(messages[1].operation?.mapCreateWithObjectId?.derivedFrom?.entries?["nested_count"]?.data?.objectId == innerCounterId)
        // The outer map's `child` entry references the created inner map.
        #expect(messages[2].operation?.mapCreateWithObjectId?.derivedFrom?.entries?["child"]?.data?.objectId == innerMapId)
    }

    // UTS: objects/unit/RTLMV4d/entry-value-types-0
    // RTLMV4d3–d6 value-type -> data-field mapping.
    @Test
    func RTLMV4d_entry_value_types() throws {
        let vt = LiveMap.create(entries: [
            "str": "hello",
            "num": 42,
            "bool": true,
            "json_arr": [1, 2, 3],
            "json_obj": ["key": "value"],
        ])
        let messages = ObjectsUTS.evaluate(map: vt, internalQueue: ObjectsUTS.createInternalQueue())
        let entries = try #require(messages[0].operation?.mapCreateWithObjectId?.derivedFrom?.entries)

        #expect(entries["str"]?.data?.string == "hello") // RTLMV4d4
        #expect(entries["num"]?.data?.number == NSNumber(value: 42)) // RTLMV4d5
        #expect(entries["bool"]?.data?.boolean == true) // RTLMV4d6
        #expect(entries["json_arr"]?.data?.json == .array([1, 2, 3])) // RTLMV4d3
        #expect(entries["json_obj"]?.data?.json == .object(["key": "value"])) // RTLMV4d3
    }

    // UTS: objects/unit/RTLMV4e2/empty-entries-0
    // undefined internal entries => empty MapCreate.entries.
    @Test
    func RTLMV4e2_empty_entries() throws {
        let messages = ObjectsUTS.evaluate(map: LiveMap.create(), internalQueue: ObjectsUTS.createInternalQueue())
        let derivedFrom = try #require(messages[0].operation?.mapCreateWithObjectId?.derivedFrom)
        #expect(derivedFrom.entries?.isEmpty == true)
    }

    // UTS: objects/unit/RTLMV4d/map-set-all-types-table-0
    // every supported value type maps to the correct
    // data field (adapted to MAP_CREATE entries, the cocoa evaluate seam). The `null` scenario is
    // omitted: `LiveMapValue` has no null case (compile-time-unrepresentable).
    @Test
    func RTLMV4d_all_types_table() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()

        func dataFor(_ value: LiveMapValue) throws -> ProtocolTypes.ObjectData {
            let messages = ObjectsUTS.evaluate(map: LiveMap.create(entries: ["test_key": value]), internalQueue: internalQueue)
            return try #require(messages[0].operation?.mapCreateWithObjectId?.derivedFrom?.entries?["test_key"]?.data)
        }

        #expect(try dataFor("hello").string == "hello")
        #expect(try dataFor(42).number == NSNumber(value: 42))
        #expect(try dataFor(3.14).number == NSNumber(value: 3.14))
        #expect(try dataFor(0).number == NSNumber(value: 0))
        #expect(try dataFor(-1).number == NSNumber(value: -1))
        #expect(try dataFor(true).boolean == true)
        #expect(try dataFor(false).boolean == false)
        #expect(try dataFor([1, "a"]).json == .array([1, "a"]))
        #expect(try dataFor(["k": "v"]).json == .object(["k": "v"]))
        // Binary: there is no binary literal for LiveMapValue; construct the primitive explicitly.
        #expect(try dataFor(.primitive(.data(Data([1, 2, 3])))).bytes == Data([1, 2, 3]))
    }
}
