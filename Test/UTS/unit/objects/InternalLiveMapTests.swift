// Derived from the UTS spec `objects/unit/internal_live_map.md`.
//
// Drives the internal `InternalDefaultLiveMap` CRDT node directly — no channel, no public path API.
// The spec's `map.applyOperation(msg, source: CHANNEL)` maps to `nosync_apply(_:source:objectMessage:objectsPool:)`
// (the full RTLM15 pipeline: RTLO4a serial/siteCode gate, RTLM15c siteTimeserials, RTLM15e tombstone
// rejection, entry-level LWW), and `map.replaceData(msg)` maps to
// `nosync_replaceData(using:objectMessageSerialTimestamp:objectsPool:)`. Both run on the internal
// queue via `ably_syncNoDeadlock` (the harness pool/node accessors `dispatchPrecondition`-trap off it).
// The static `InternalLiveMap.diff(previous, new)` maps to `ObjectDiffHelpers.calculateMapDiff(previousData:newData:)`.
// Serials are the spec's own literal strings ("01"/"02"/…) kept verbatim — they are not the
// standard_test_pool vocabulary — and compare as strings (RTLM9e).
//
// Deviations from the UTS spec (see Test/UTS/deviations.md):
// - (S-4) The apply pipeline stamps `LiveMapUpdate.objectMessage` (RTLM7f/RTLM8e/RTLM15) via
//   `nosync_emitAndTearDown`, so the op-path `update.objectMessage == msg` assertions hold. The
//   OBJECT_SYNC path (`nosync_replaceData`, RTLM6h) takes the `ObjectState` + `serialTimestamp`
//   rather than the whole `ObjectMessage`, and its returned update carries NO `objectMessage`
//   (nil for sync-originated updates, per RTO4b2a / the `DefaultLiveMapUpdate` doc). So the
//   replaceData/tombstone-via-sync cases assert the diff (the substantive RTLM6h/RTLM22 coverage)
//   and keep the `update.objectMessage == state_msg` ASSERT as a comment documenting nil. See (S-4) in deviations.md.
//
// Infra-driving stand-ins (direct node seeding via `ObjectsUTS.makeMap`, seeding serials/timeserials
// via the `testsOnly_*` setters, `MockSimpleClock` for the RTLM19 GC clock) are NOT deviations.

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct InternalLiveMapTests {
    // MARK: - Helpers

    /// Converts a spec epoch-millis timestamp to the `Date` cocoa stores (objects-mapping §11).
    private static func date(millis: Double) -> Date {
        Date(timeIntervalSince1970: millis / 1000)
    }

    /// Applies an inbound operation message through the full RTLM15 pipeline (`nosync_apply`), on the
    /// internal queue. Returns the update (which may be `.noop`, or `nil` when the op is skipped per
    /// RTLM15b/RTLM15e/RTLM15d4) and the mutated pool (a value type).
    private static func apply(
        _ message: ProtocolTypes.InboundObjectMessage,
        to map: InternalDefaultLiveMap,
        pool: ObjectsPool,
        on queue: DispatchQueue,
    ) throws -> (update: LiveObjectUpdate<DefaultLiveMapUpdate>?, pool: ObjectsPool) {
        let operation = try #require(message.operation)
        var pool = pool
        let update = queue.ably_syncNoDeadlock {
            map.nosync_apply(operation, source: .channel, objectMessage: message, objectsPool: &pool)
        }
        return (update, pool)
    }

    /// Replaces the map's data from an `ObjectState` (`nosync_replaceData`, RTLM6), on the internal queue.
    private static func replaceData(
        _ state: ProtocolTypes.ObjectState,
        into map: InternalDefaultLiveMap,
        pool: ObjectsPool,
        serialTimestamp: Date? = nil,
        on queue: DispatchQueue,
    ) -> (update: LiveObjectUpdate<DefaultLiveMapUpdate>, pool: ObjectsPool) {
        var pool = pool
        let update = queue.ably_syncNoDeadlock {
            map.nosync_replaceData(using: state, objectMessageSerialTimestamp: serialTimestamp, objectsPool: &pool)
        }
        return (update, pool)
    }

    // MARK: - RTLM4: zero-value

    // UTS: objects/unit/RTLM4/zero-value-0
    @Test
    func zeroValueMapIsEmpty() {
        let queue = ObjectsUTS.createInternalQueue()
        // map = InternalLiveMap(objectId: "root", semantics: "LWW")
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // ASSERT map.data == {}
        #expect(map.testsOnly_data.isEmpty)
        // ASSERT map.clearTimeserial == null
        #expect(map.testsOnly_clearTimeserial == nil)
        // ASSERT map.isTombstone == false
        #expect(map.testsOnly_isTombstone == false)
        // ASSERT map.createOperationIsMerged == false
        #expect(map.testsOnly_createOperationIsMerged == false)
        // ASSERT map.siteTimeserials == {}
        #expect(map.testsOnly_siteTimeserials.isEmpty)
    }

    // MARK: - RTLM7: MAP_SET

    // UTS: objects/unit/RTLM7/map-set-new-entry-0
    @Test
    func mapSetCreatesNewEntry() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // msg = build_map_set("root", "name", { string: "Alice" }, "01", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Alice"), serial: "01", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        let entry = try #require(map.testsOnly_data["name"])
        // ASSERT map.data["name"].data == { string: "Alice" }
        #expect(entry.data == ProtocolTypes.ObjectData(string: "Alice"))
        // ASSERT map.data["name"].timeserial == "01"
        #expect(entry.timeserial == "01")
        // ASSERT map.data["name"].tombstone == false
        #expect(entry.tombstone == false)
        // ASSERT update.update == { "name": "updated" }
        #expect(update?.update?.update == ["name": .updated])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM7/map-set-update-entry-0
    @Test
    func mapSetUpdatesExistingEntry() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01")],
            internalQueue: queue,
        )

        // msg = build_map_set("root", "name", { string: "Bob" }, "02", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "02", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        let entry = try #require(map.testsOnly_data["name"])
        // ASSERT map.data["name"].data == { string: "Bob" }
        #expect(entry.data == ProtocolTypes.ObjectData(string: "Bob"))
        // ASSERT map.data["name"].timeserial == "02"
        #expect(entry.timeserial == "02")
        // ASSERT update.update == { "name": "updated" }
        #expect(update?.update?.update == ["name": .updated])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM7/map-set-revives-tombstoned-0
    @Test
    func mapSetRevivesTombstonedEntry() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            // "name": { data: null, timeserial: "01", tombstone: true, tombstonedAt: 1700000000000 }
            data: ["name": InternalObjectsMapEntry(tombstonedAt: Self.date(millis: 1_700_000_000_000), timeserial: "01", data: nil)],
            internalQueue: queue,
        )

        // msg = build_map_set("root", "name", { string: "Alice" }, "02", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Alice"), serial: "02", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        let entry = try #require(map.testsOnly_data["name"])
        // ASSERT map.data["name"].data == { string: "Alice" }
        #expect(entry.data == ProtocolTypes.ObjectData(string: "Alice"))
        // ASSERT map.data["name"].tombstone == false
        #expect(entry.tombstone == false)
        // ASSERT map.data["name"].tombstonedAt == null
        #expect(entry.tombstonedAt == nil)
        // ASSERT update.update == { "name": "updated" }
        #expect(update?.update?.update == ["name": .updated])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // MARK: - RTLM9: LWW entry-level comparison

    // UTS: objects/unit/RTLM9/lww-reject-stale-0
    @Test
    func lwwRejectsStaleSerialOnExistingEntry() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "05")],
            internalQueue: queue,
        )

        // msg = build_map_set("root", "name", { string: "Bob" }, "03", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "03", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["name"].data == { string: "Alice" }
        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        // ASSERT update.noop == true
        #expect(update?.isNoop == true)
    }

    // UTS: objects/unit/RTLM9/lww-reject-equal-0
    @Test
    func lwwRejectsEqualSerial() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "05")],
            internalQueue: queue,
        )

        // msg = build_map_set("root", "name", { string: "Bob" }, "05", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "05", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["name"].data == { string: "Alice" }
        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        // ASSERT update.noop == true
        #expect(update?.isNoop == true)
    }

    // UTS: objects/unit/RTLM9b/both-empty-reject-0
    @Test
    func bothSerialsEmptyRejectsOperation() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "")],
            internalQueue: queue,
        )

        // msg = build_map_set("root", "name", { string: "Bob" }, "", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["name"].data == { string: "Alice" }
        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        // The op's ObjectMessage.serial is empty, so the OBJECT-level gate (RTLO4a3, via
        // canApplyOperation) rejects it before the entry-level RTLM9b comparison, and applyOperation
        // returns false (RTLM15b) — a plain false, not a noop update.
        // ASSERT update == false
        #expect(update == nil)
    }

    // UTS: objects/unit/RTLM9d/missing-entry-serial-allows-0
    @Test
    func missingEntrySerialAllowsOperation() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            // "name": { data: { string: "Alice" }, timeserial: null, tombstone: false }
            data: ["name": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: nil, data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: queue,
        )

        // msg = build_map_set("root", "name", { string: "Bob" }, "01", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Bob"), serial: "01", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["name"].data == { string: "Bob" }
        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Bob"))
        // ASSERT update.update == { "name": "updated" }
        #expect(update?.update?.update == ["name": .updated])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // MARK: - RTLM7h: MAP_SET clearTimeserial floor

    // UTS: objects/unit/RTLM7h/map-set-clear-timeserial-floor-0
    @Test
    func mapSetRejectedWhenSerialBelowClearTimeserial() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)
        map.testsOnly_setClearTimeserial("05")

        // msg = build_map_set("root", "name", { string: "Alice" }, "03", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "name", value: ProtocolTypes.ObjectData(string: "Alice"), serial: "03", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT "name" NOT IN map.data
        #expect(map.testsOnly_data["name"] == nil)
        // ASSERT update.noop == true
        #expect(update?.isNoop == true)
    }

    // MARK: - RTLM7g: MAP_SET with objectId creates zero-value object

    // UTS: objects/unit/RTLM7g/map-set-objectid-creates-zero-value-0
    @Test
    func mapSetWithObjectIdCreatesZeroValueObject() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // msg = build_map_set("root", "score", { objectId: "counter:new@2000" }, "01", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "score", value: ProtocolTypes.ObjectData(objectId: "counter:new@2000"), serial: "01", siteCode: "site1")
        let (_, pool) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT "counter:new@2000" IN pool
        let entry = try #require(pool.entries["counter:new@2000"])
        // ASSERT pool["counter:new@2000"] IS InternalLiveCounter
        let counter = try #require(entry.counterValue)
        // ASSERT pool["counter:new@2000"].data == 0
        #expect(counter.testsOnly_data == 0)
    }

    // MARK: - RTLM8: MAP_REMOVE

    // UTS: objects/unit/RTLM8/map-remove-existing-0
    @Test
    func mapRemoveTombstonesExistingEntry() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01")],
            internalQueue: queue,
        )

        // msg = build_map_remove("root", "name", "02", "site1", 1700000000000)
        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "name", serial: "02", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        let entry = try #require(map.testsOnly_data["name"])
        // ASSERT map.data["name"].data == null
        #expect(entry.data == nil)
        // ASSERT map.data["name"].tombstone == true
        #expect(entry.tombstone == true)
        // ASSERT map.data["name"].timeserial == "02"
        #expect(entry.timeserial == "02")
        // ASSERT map.data["name"].tombstonedAt == 1700000000000
        #expect(entry.tombstonedAt == Self.date(millis: 1_700_000_000_000))
        // ASSERT update.update == { "name": "removed" }
        #expect(update?.update?.update == ["name": .removed])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM8/map-remove-nonexistent-0
    @Test
    func mapRemoveCreatesTombstonedEntryIfNotExists() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // msg = build_map_remove("root", "ghost", "01", "site1", 1700000000000)
        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "ghost", serial: "01", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        let entry = try #require(map.testsOnly_data["ghost"])
        // ASSERT map.data["ghost"].tombstone == true
        #expect(entry.tombstone == true)
        // ASSERT map.data["ghost"].tombstonedAt == 1700000000000
        #expect(entry.tombstonedAt == Self.date(millis: 1_700_000_000_000))
        // ASSERT update.update == { "ghost": "removed" }
        #expect(update?.update?.update == ["ghost": .removed])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // MARK: - RTLM8g: MAP_REMOVE clearTimeserial floor

    // UTS: objects/unit/RTLM8g/map-remove-clear-timeserial-floor-0
    @Test
    func mapRemoveRejectedWhenSerialBelowClearTimeserial() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "04")],
            internalQueue: queue,
        )
        map.testsOnly_setClearTimeserial("05")

        // msg = build_map_remove("root", "name", "03", "site1", 1700000000000)
        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "name", serial: "03", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        let entry = try #require(map.testsOnly_data["name"])
        // ASSERT map.data["name"].data == { string: "Alice" }
        #expect(entry.data == ProtocolTypes.ObjectData(string: "Alice"))
        // ASSERT map.data["name"].tombstone == false
        #expect(entry.tombstone == false)
        // ASSERT update.noop == true
        #expect(update?.isNoop == true)
    }

    // MARK: - RTLM24: MAP_CLEAR

    // UTS: objects/unit/RTLM24/map-clear-basic-0
    @Test
    func mapClearSetsClearTimeserialAndRemovesOlderEntries() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: [
                "old": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "old"), timeserial: "02"),
                "new": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "new"), timeserial: "06"),
                "same": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "same"), timeserial: "04"),
            ],
            internalQueue: queue,
        )

        // msg = build_map_clear("root", "04", "site1")
        let msg = ObjectsUTS.mapClearMessage(objectId: "root", serial: "04", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.clearTimeserial == "04"
        #expect(map.testsOnly_clearTimeserial == "04")
        // ASSERT "old" NOT IN map.data
        #expect(map.testsOnly_data["old"] == nil)
        // "same" has timeserial "04" == the clear serial "04" (not greater per RTLM24e1), so KEPT.
        // ASSERT "same" IN map.data
        #expect(map.testsOnly_data["same"] != nil)
        // ASSERT "new" IN map.data
        #expect(map.testsOnly_data["new"] != nil)
        // ASSERT update.update == { "old": "removed" }
        #expect(update?.update?.update == ["old": .removed])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM24/map-clear-preserves-newer-0
    @Test
    func mapClearPreservesEntriesWithNewerSerial() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: [
                "before": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "a"), timeserial: "03"),
                "after": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "b"), timeserial: "07"),
                // "no_ts": timeserial null
                "no_ts": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: nil, data: ProtocolTypes.ObjectData(string: "c")),
            ],
            internalQueue: queue,
        )

        // msg = build_map_clear("root", "05", "site1")
        let msg = ObjectsUTS.mapClearMessage(objectId: "root", serial: "05", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT "before" NOT IN map.data
        #expect(map.testsOnly_data["before"] == nil)
        // ASSERT "no_ts" NOT IN map.data
        #expect(map.testsOnly_data["no_ts"] == nil)
        // ASSERT map.data["after"].data == { string: "b" }
        #expect(map.testsOnly_data["after"]?.data == ProtocolTypes.ObjectData(string: "b"))
        // ASSERT "before" IN update.update
        #expect(update?.update?.update["before"] == .removed)
        // ASSERT "no_ts" IN update.update
        #expect(update?.update?.update["no_ts"] == .removed)
        // ASSERT "after" NOT IN update.update
        #expect(update?.update?.update["after"] == nil)
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM24c/map-clear-stale-0
    @Test
    func mapClearRejectedWhenClearTimeserialAlreadyGreater() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)
        map.testsOnly_setClearTimeserial("10")

        // msg = build_map_clear("root", "05", "site1")
        let msg = ObjectsUTS.mapClearMessage(objectId: "root", serial: "05", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.clearTimeserial == "10"
        #expect(map.testsOnly_clearTimeserial == "10")
        // ASSERT update.noop == true
        #expect(update?.isNoop == true)
    }

    // MARK: - RTLM16 / RTLM23: MAP_CREATE

    // UTS: objects/unit/RTLM16/map-create-merge-0
    @Test
    func mapCreateMergesEntries() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "map:test@1000", internalQueue: queue)

        // msg = build_map_create("map:test@1000", { entries: { "name": {...}, "removed_key": {tombstone,...} } }, "02", "site1")
        let msg = TestFactories.mapCreateOperationMessage(
            objectId: "map:test@1000",
            entries: [
                "name": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice")),
                "removed_key": ProtocolTypes.ObjectsMapEntry(tombstone: true, timeserial: "01", data: nil, serialTimestamp: Self.date(millis: 1_700_000_000_000)),
            ],
            serial: "02",
            siteCode: "site1",
        )
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["name"].data == { string: "Alice" }
        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        // ASSERT map.data["removed_key"].tombstone == true
        #expect(map.testsOnly_data["removed_key"]?.tombstone == true)
        // ASSERT map.createOperationIsMerged == true
        #expect(map.testsOnly_createOperationIsMerged == true)
        // ASSERT update.update == { "name": "updated", "removed_key": "removed" }
        #expect(update?.update?.update == ["name": .updated, "removed_key": .removed])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM16b/map-create-already-merged-0
    @Test
    func mapCreateNoopWhenAlreadyMerged() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "map:test@1000", internalQueue: queue)
        map.testsOnly_setCreateOperationIsMerged(true)
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        // msg = build_map_create("map:test@1000", { entries: { "name": { string: "Bob" } } }, "01", "site1")
        let msg = TestFactories.mapCreateOperationMessage(
            objectId: "map:test@1000",
            entries: ["name": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "01", data: ProtocolTypes.ObjectData(string: "Bob"))],
            serial: "01",
            siteCode: "site1",
        )
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT "name" NOT IN map.data
        #expect(map.testsOnly_data["name"] == nil)
        // ASSERT update.noop == true
        #expect(update?.isNoop == true)
    }

    // MARK: - RTLM15: apply pipeline gating

    // UTS: objects/unit/RTLM15c/channel-source-updates-serials-0
    @Test
    func channelSourceUpdatesSiteTimeserials() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // msg = build_map_set("root", "x", { number: 1 }, "01", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "x", value: ProtocolTypes.ObjectData(number: NSNumber(value: 1)), serial: "01", siteCode: "site1")
        _ = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.siteTimeserials["site1"] == "01"
        #expect(map.testsOnly_siteTimeserials["site1"] == "01")
    }

    // UTS: objects/unit/RTLM15e/tombstoned-reject-ops-0
    @Test
    func operationsOnTombstonedMapAreRejected() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)
        // map.isTombstone = true (modelled by setting tombstonedAt; isTombstone == tombstonedAt != nil)
        map.testsOnly_setTombstonedAt(Self.date(millis: 1_700_000_000_000))

        // msg = build_map_set("root", "x", { number: 1 }, "01", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "x", value: ProtocolTypes.ObjectData(number: NSNumber(value: 1)), serial: "01", siteCode: "site1")
        let (result, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT result == false
        #expect(result == nil)
        // ASSERT map.data == {}
        #expect(map.testsOnly_data.isEmpty)
    }

    // UTS: objects/unit/RTLM15d4/unsupported-action-0
    @Test
    func unsupportedActionIsDiscarded() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // msg = ObjectMessage(serial: "01", siteCode: "site1", operation: { action: "COUNTER_INC", objectId: "root", counterInc: { number: 5 } })
        let msg = ObjectsUTS.counterIncMessage(objectId: "root", number: 5, serial: "01", siteCode: "site1")
        let (result, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT result == false
        #expect(result == nil)
    }

    // MARK: - RTLO5 / RTLO4e10: OBJECT_DELETE

    // UTS: objects/unit/RTLO5/object-delete-tombstones-map-0
    @Test
    func objectDeleteTombstonesMap() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "map:test@1000",
            data: [
                "name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01"),
                "age": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(number: NSNumber(value: 30)), timeserial: "01"),
            ],
            internalQueue: queue,
        )
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        // msg = build_object_delete("map:test@1000", "01", "site1", 1700000000000)
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "map:test@1000", serial: "01", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.isTombstone == true
        #expect(map.testsOnly_isTombstone == true)
        // ASSERT map.data == {}
        #expect(map.testsOnly_data.isEmpty)
        // ASSERT update.update == { "name": "removed", "age": "removed" }
        #expect(update?.update?.update == ["name": .removed, "age": .removed])
        // ASSERT update.tombstone == true
        #expect(update?.tombstone == true)
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLO5/tombstone-empty-map-emits-update-0
    @Test
    func objectDeleteOnAllTombstonedMapStillEmitsNonNoopTombstoneUpdate() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let deadAt = Self.date(millis: 1_600_000_000_000)
        let map = ObjectsUTS.makeMap(
            objectID: "map:test@1000",
            // every entry already tombstoned (tombstonedAt set)
            data: [
                "name": InternalObjectsMapEntry(tombstonedAt: deadAt, timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice")),
                "age": InternalObjectsMapEntry(tombstonedAt: deadAt, timeserial: "01", data: ProtocolTypes.ObjectData(number: NSNumber(value: 30))),
            ],
            internalQueue: queue,
        )
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        // msg = build_object_delete("map:test@1000", "01", "site1", 1700000000000)
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "map:test@1000", serial: "01", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.isTombstone == true
        #expect(map.testsOnly_isTombstone == true)
        // ASSERT map.data == {}
        #expect(map.testsOnly_data.isEmpty)
        // ASSERT update.noop == false (RTLM22c tombstone carve-out: empty diff still delivered)
        #expect(update?.isNoop == false)
        // ASSERT update.tombstone == true
        #expect(update?.tombstone == true)
        // ASSERT update.update == {}
        #expect(update?.update?.update == [:])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLO4e10/object-delete-root-noop-0
    @Test
    func objectDeleteTargetingRootIsRejected() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01")],
            internalQueue: queue,
        )
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        // msg = build_object_delete("root", "01", "site1", 1700000000000)
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "root", serial: "01", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.isTombstone == false
        #expect(map.testsOnly_isTombstone == false)
        // ASSERT map.data["name"].data.string == "Alice" (data untouched)
        #expect(map.testsOnly_data["name"]?.data?.string == "Alice")
        // ASSERT update.noop == true
        #expect(update?.isNoop == true)
    }

    // MARK: - RTLM14: tombstone check

    // UTS: objects/unit/RTLM14/tombstone-check-objectid-ref-0
    @Test
    func tombstonedEntryCheckIncludesObjectIdReference() throws {
        let queue = ObjectsUTS.createInternalQueue()

        // A tombstoned counter in the pool.
        let deadCounter = ObjectsUTS.makeCounter(objectID: "counter:dead@1000", internalQueue: queue)
        deadCounter.testsOnly_setTombstonedAt(Self.date(millis: 1_700_000_000_000))
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.counter(deadCounter), forObjectID: "counter:dead@1000")

        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: [
                "alive": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(string: "ok")),
                // dead_entry: entry-level tombstone (tombstonedAt set, data null)
                "dead_entry": InternalObjectsMapEntry(tombstonedAt: Self.date(millis: 1_700_000_000_000), timeserial: "01", data: nil),
                // dead_ref: entry not tombstoned, but references a tombstoned object
                "dead_ref": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:dead@1000")),
            ],
            internalQueue: queue,
        )

        let data = map.testsOnly_data
        let aliveEntry = try #require(data["alive"])
        let deadEntryEntry = try #require(data["dead_entry"])
        let deadRefEntry = try #require(data["dead_ref"])
        // `testsOnly_isEntryTombstoned` reads the referenced pool object's `nosync_isTombstone` for the
        // objectId-ref case (RTLM14c), which `dispatchPrecondition`-traps off the internal queue — so
        // run the checks on the queue.
        let (aliveTombstoned, deadEntryTombstoned, deadRefTombstoned) = queue.ably_syncNoDeadlock {
            (
                map.testsOnly_isEntryTombstoned(aliveEntry, objectsPool: pool),
                map.testsOnly_isEntryTombstoned(deadEntryEntry, objectsPool: pool),
                map.testsOnly_isEntryTombstoned(deadRefEntry, objectsPool: pool),
            )
        }
        // ASSERT isTombstoned(map.data["alive"]) == false
        #expect(aliveTombstoned == false)
        // ASSERT isTombstoned(map.data["dead_entry"]) == true
        #expect(deadEntryTombstoned == true)
        // ASSERT isTombstoned(map.data["dead_ref"]) == true
        #expect(deadRefTombstoned == true)
    }

    // UTS: objects/unit/RTLM14c/tombstoned-ref-yields-null-0
    @Test
    func mapSetReferencingTombstonedObjectIdYieldsNullValue() throws {
        let queue = ObjectsUTS.createInternalQueue()

        let deadCounter = ObjectsUTS.makeCounter(objectID: "counter:dead@1000", internalQueue: queue)
        deadCounter.testsOnly_setTombstonedAt(Self.date(millis: 1_700_000_000_000))
        let delegate = ObjectsUTSPoolDelegate(internalQueue: queue, entries: ["counter:dead@1000": .counter(deadCounter)])
        let coreSDK = ObjectsUTSCoreSDK()

        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["ref": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:dead@1000"))],
            internalQueue: queue,
        )

        // ASSERT map.data["ref"].tombstone == false (the entry itself is not tombstoned)
        #expect(map.testsOnly_data["ref"]?.tombstone == false)
        // ASSERT map.size() == 0 (RTLM14c makes the entry tombstoned via its referenced object)
        #expect(try map.size(coreSDK: coreSDK, delegate: delegate) == 0)
        // ASSERT map.get("ref") == null
        #expect(try map.get(key: "ref", coreSDK: coreSDK, delegate: delegate) == nil)
    }

    // MARK: - RTLM6: replaceData (OBJECT_SYNC ingestion)

    // UTS: objects/unit/RTLM6/replace-data-basic-0
    @Test
    func replaceDataSetsDataFromObjectState() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["old": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "old"), timeserial: "01")],
            internalQueue: queue,
        )
        map.testsOnly_setCreateOperationIsMerged(true)

        // state_msg = build_object_state("root", {"site2": "05"}, { map: { clearTimeserial: "03", entries: { "new": ... } } })
        let state = ProtocolTypes.ObjectState(
            objectId: "root",
            siteTimeserials: ["site2": "05"],
            tombstone: false,
            createOp: nil,
            map: ProtocolTypes.ObjectsMap(
                semantics: .known(.lww),
                entries: ["new": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "04", data: ProtocolTypes.ObjectData(string: "new"))],
                clearTimeserial: "03",
            ),
            counter: nil,
        )
        let (update, _) = Self.replaceData(state, into: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.siteTimeserials == { "site2": "05" }
        #expect(map.testsOnly_siteTimeserials == ["site2": "05"])
        // ASSERT map.createOperationIsMerged == false
        #expect(map.testsOnly_createOperationIsMerged == false)
        // ASSERT map.clearTimeserial == "03"
        #expect(map.testsOnly_clearTimeserial == "03")
        // ASSERT "old" NOT IN map.data
        #expect(map.testsOnly_data["old"] == nil)
        // ASSERT map.data["new"].data == { string: "new" }
        #expect(map.testsOnly_data["new"]?.data == ProtocolTypes.ObjectData(string: "new"))
        // ASSERT update.update == { "old": "removed", "new": "updated" }
        #expect(update.update?.update == ["old": .removed, "new": .updated])
        // ASSERT update.objectMessage == state_msg — see (S-4): `nosync_replaceData` takes the
        // ObjectState (not the message) and sync-originated updates carry nil objectMessage (RTO4b2a).
        #expect(update.objectMessage == nil)
    }

    // UTS: objects/unit/RTLM6c1/replace-data-tombstoned-entries-0
    @Test
    func replaceDataSetsTombstonedAtOnTombstonedEntries() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // state_msg = build_object_state("root", {"site1": "01"}, { map: { entries: { "dead": { tombstone, serialTimestamp: 1700000050000 } } } })
        let state = TestFactories.mapObjectState(
            objectId: "root",
            siteTimeserials: ["site1": "01"],
            entries: ["dead": ProtocolTypes.ObjectsMapEntry(tombstone: true, timeserial: "01", data: nil, serialTimestamp: Self.date(millis: 1_700_000_050_000))],
        )
        _ = Self.replaceData(state, into: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["dead"].tombstonedAt == 1700000050000
        #expect(map.testsOnly_data["dead"]?.tombstonedAt == Self.date(millis: 1_700_000_050_000))
    }

    // UTS: objects/unit/RTLM6d/replace-data-with-create-op-0
    @Test
    func replaceDataWithCreateOpMergesInitialEntries() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(objectID: "map:test@1000", internalQueue: queue)

        // state_msg = build_object_state("map:test@1000", {"site1": "01"}, { map: { entries: { "from_sync": ... } }, createOp: { mapCreate: { entries: { "from_create": ... } } } })
        let state = TestFactories.mapObjectState(
            objectId: "map:test@1000",
            siteTimeserials: ["site1": "01"],
            createOp: TestFactories.mapCreateOperation(
                objectId: "map:test@1000",
                entries: ["from_create": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "00", data: ProtocolTypes.ObjectData(string: "created"))],
            ),
            entries: ["from_sync": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "01", data: ProtocolTypes.ObjectData(string: "synced"))],
        )
        _ = Self.replaceData(state, into: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["from_sync"].data == { string: "synced" }
        #expect(map.testsOnly_data["from_sync"]?.data == ProtocolTypes.ObjectData(string: "synced"))
        // ASSERT map.data["from_create"].data == { string: "created" }
        #expect(map.testsOnly_data["from_create"]?.data == ProtocolTypes.ObjectData(string: "created"))
        // ASSERT map.createOperationIsMerged == true
        #expect(map.testsOnly_createOperationIsMerged == true)
    }

    // UTS: objects/unit/RTLM6f/replace-data-tombstone-flag-0
    @Test
    func replaceDataWithTombstoneFlagTombstonesMap() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "map:test@1000",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01")],
            internalQueue: queue,
        )

        // state_msg = build_object_state("map:test@1000", {"site1": "01"}, { map: { entries: {} }, tombstone: true })
        let state = TestFactories.mapObjectState(
            objectId: "map:test@1000",
            siteTimeserials: ["site1": "01"],
            tombstone: true,
            entries: [:],
        )
        let (update, _) = Self.replaceData(state, into: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.isTombstone == true
        #expect(map.testsOnly_isTombstone == true)
        // ASSERT map.data == {}
        #expect(map.testsOnly_data.isEmpty)
        // ASSERT update.update == { "name": "removed" }
        #expect(update.update?.update == ["name": .removed])
        // ASSERT update.tombstone == true
        #expect(update.tombstone == true)
        // ASSERT update.objectMessage == state_msg — see (S-4): the tombstone-via-sync update carries
        // nil objectMessage (the seam takes the ObjectState, not the message).
        #expect(update.objectMessage == nil)
    }

    // UTS: objects/unit/RTLO4e10/replace-data-tombstone-root-noop-0
    @Test
    func replaceDataWithTombstoneFlagTargetingRootIsRejected() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01")],
            internalQueue: queue,
        )

        // state_msg = build_object_state("root", {"site1": "01"}, { map: { entries: {} }, tombstone: true })
        let state = TestFactories.mapObjectState(
            objectId: "root",
            siteTimeserials: ["site1": "01"],
            tombstone: true,
            entries: [:],
        )
        let (update, _) = Self.replaceData(state, into: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.isTombstone == false
        #expect(map.testsOnly_isTombstone == false)
        // ASSERT map.data["name"].data.string == "Alice" (data untouched)
        #expect(map.testsOnly_data["name"]?.data?.string == "Alice")
        // ASSERT update.noop == true
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLM6i/replace-data-resets-clear-timeserial-0
    @Test
    func replaceDataWithoutClearTimeserialResetsToNull() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["x": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(number: NSNumber(value: 1)), timeserial: "03")],
            internalQueue: queue,
        )
        map.testsOnly_setClearTimeserial("05")

        // state_msg = build_object_state("root", {"site1": "01"}, { map: { entries: { "y": { number: 2 } } } }) — no clearTimeserial
        let state = TestFactories.mapObjectState(
            objectId: "root",
            siteTimeserials: ["site1": "01"],
            entries: ["y": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "01", data: ProtocolTypes.ObjectData(number: NSNumber(value: 2)))],
        )
        _ = Self.replaceData(state, into: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.clearTimeserial == null
        #expect(map.testsOnly_clearTimeserial == nil)
        // ASSERT "y" IN map.data
        #expect(map.testsOnly_data["y"] != nil)
    }

    // MARK: - RTLM19: GC of tombstoned entries

    // UTS: objects/unit/RTLM19/gc-tombstoned-entries-0
    @Test
    func gcRemovesTombstonedEntriesPastGracePeriod() {
        let queue = ObjectsUTS.createInternalQueue()
        // grace_period = 86400000 (ms); now = 1700100000000 (ms). cocoa's gracePeriod is a TimeInterval
        // (seconds) and the clock is a Date, so convert both (objects-mapping §11).
        let gracePeriodMillis = 86_400_000.0
        let nowMillis = 1_700_100_000_000.0

        let map = InternalDefaultLiveMap(
            testsOnly_data: [
                // recent_dead: tombstonedAt = now - 1000 (well within grace)
                "recent_dead": InternalObjectsMapEntry(tombstonedAt: Self.date(millis: nowMillis - 1000), timeserial: "01", data: nil),
                // old_dead: tombstonedAt = now - grace_period - 1 (just past grace)
                "old_dead": InternalObjectsMapEntry(tombstonedAt: Self.date(millis: nowMillis - gracePeriodMillis - 1), timeserial: "01", data: nil),
                // alive: not tombstoned
                "alive": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(string: "ok")),
            ],
            objectID: "root",
            logger: TestLogger(),
            internalQueue: queue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )

        // map.gcTombstonedEntries(grace_period, now) — cocoa reads `now` off the passed clock.
        queue.ably_syncNoDeadlock {
            map.nosync_releaseTombstonedEntries(gracePeriod: gracePeriodMillis / 1000, clock: MockSimpleClock(currentTime: Self.date(millis: nowMillis)))
        }

        // ASSERT "recent_dead" IN map.data
        #expect(map.testsOnly_data["recent_dead"] != nil)
        // ASSERT "old_dead" NOT IN map.data
        #expect(map.testsOnly_data["old_dead"] == nil)
        // ASSERT "alive" IN map.data
        #expect(map.testsOnly_data["alive"] != nil)
    }

    // MARK: - RTLM22: diff

    // UTS: objects/unit/RTLM22/diff-calculation-0
    @Test
    func diffBetweenTwoDataStates() throws {
        // previousData / newData — only non-tombstoned entries are considered (RTLM22b).
        let previousData: [String: InternalObjectsMapEntry] = [
            "removed": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(string: "gone")),
            "changed": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(string: "old")),
            "unchanged": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(string: "same")),
            "was_dead": InternalObjectsMapEntry(tombstonedAt: Self.date(millis: 1_600_000_000_000), timeserial: "01", data: nil),
        ]
        let newData: [String: InternalObjectsMapEntry] = [
            "added": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "02", data: ProtocolTypes.ObjectData(string: "new")),
            "changed": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "02", data: ProtocolTypes.ObjectData(string: "new_val")),
            "unchanged": InternalObjectsMapEntry(tombstonedAt: nil, timeserial: "01", data: ProtocolTypes.ObjectData(string: "same")),
            "now_dead": InternalObjectsMapEntry(tombstonedAt: Self.date(millis: 1_600_000_000_000), timeserial: "02", data: nil),
        ]

        // update = InternalLiveMap.diff(previousData, newData)
        let update = ObjectDiffHelpers.calculateMapDiff(previousData: previousData, newData: newData)
        let diff = try #require(update.update?.update)

        // ASSERT update.update["removed"] == "removed"
        #expect(diff["removed"] == .removed)
        // ASSERT update.update["added"] == "updated"
        #expect(diff["added"] == .updated)
        // ASSERT update.update["changed"] == "updated"
        #expect(diff["changed"] == .updated)
        // ASSERT "unchanged" NOT IN update.update
        #expect(diff["unchanged"] == nil)
        // ASSERT "was_dead" NOT IN update.update
        #expect(diff["was_dead"] == nil)
        // ASSERT "now_dead" NOT IN update.update
        #expect(diff["now_dead"] == nil)
    }

    // UTS: objects/unit/RTLM22c/empty-diff-is-noop-0
    @Test
    func emptyDiffIsNoop() {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "alice"), timeserial: "01")],
            internalQueue: queue,
        )

        // state_msg re-states "name" with the same data (only timeserial differs, which is not compared).
        let state = TestFactories.mapObjectState(
            objectId: "root",
            siteTimeserials: ["site1": "02"],
            entries: ["name": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "02", data: ProtocolTypes.ObjectData(string: "alice"))],
        )
        let (update, _) = Self.replaceData(state, into: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT update.noop == true
        #expect(update.isNoop == true)
        // ASSERT map.data["name"].data == { string: "alice" }
        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "alice"))
    }

    // MARK: - parentReferences

    // UTS: objects/unit/RTLM7a3/map-set-overwrite-objectid-parent-refs-0
    @Test
    func mapSetOverwriteObjectIdUpdatesParentReferences() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let oldCounter = ObjectsUTS.makeCounter(objectID: "counter:old@1000", internalQueue: queue)
        let newCounter = ObjectsUTS.makeCounter(objectID: "counter:new@2000", internalQueue: queue)
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.counter(oldCounter), forObjectID: "counter:old@1000")
        pool.testsOnly_setEntry(.counter(newCounter), forObjectID: "counter:new@2000")

        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["ref": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:old@1000"), timeserial: "01")],
            internalQueue: queue,
        )
        // Simulate existing parentReference: old_counter.parentReferences = { "root": {"ref"} }
        oldCounter.testsOnly_setParentReferences(["root": ["ref"]])

        // msg = build_map_set("root", "ref", { objectId: "counter:new@2000" }, "02", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "ref", value: ProtocolTypes.ObjectData(objectId: "counter:new@2000"), serial: "02", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: pool, on: queue)

        // ASSERT map.data["ref"].data == { objectId: "counter:new@2000" }
        #expect(map.testsOnly_data["ref"]?.data == ProtocolTypes.ObjectData(objectId: "counter:new@2000"))
        // removeParentReference was called on the old child
        #expect(oldCounter.testsOnly_parentReferences["root"]?.contains("ref") != true)
        // addParentReference was called on the new child
        // ASSERT "root" IN new_counter.parentReferences
        #expect(newCounter.testsOnly_parentReferences["root"] != nil)
        // ASSERT "ref" IN new_counter.parentReferences["root"]
        #expect(newCounter.testsOnly_parentReferences["root"]?.contains("ref") == true)
        // ASSERT update.update == { "ref": "updated" }
        #expect(update?.update?.update == ["ref": .updated])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM7g2/map-set-new-entry-add-parent-ref-0
    @Test
    func mapSetNewEntryReferencingLiveObjectAddsParentReference() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let childCounter = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: queue)
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.counter(childCounter), forObjectID: "counter:child@1000")

        let map = ObjectsUTS.makeMap(objectID: "root", internalQueue: queue)

        // msg = build_map_set("root", "score", { objectId: "counter:child@1000" }, "01", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "score", value: ProtocolTypes.ObjectData(objectId: "counter:child@1000"), serial: "01", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: pool, on: queue)

        // ASSERT map.data["score"].data == { objectId: "counter:child@1000" }
        #expect(map.testsOnly_data["score"]?.data == ProtocolTypes.ObjectData(objectId: "counter:child@1000"))
        // ASSERT "root" IN child_counter.parentReferences
        #expect(childCounter.testsOnly_parentReferences["root"] != nil)
        // ASSERT "score" IN child_counter.parentReferences["root"]
        #expect(childCounter.testsOnly_parentReferences["root"]?.contains("score") == true)
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM7/map-set-primitive-no-parent-refs-0
    @Test
    func mapSetWithPrimitiveValueDoesNotAffectParentReferences() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let oldCounter = ObjectsUTS.makeCounter(objectID: "counter:old@1000", internalQueue: queue)
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.counter(oldCounter), forObjectID: "counter:old@1000")

        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["ref": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:old@1000"), timeserial: "01")],
            internalQueue: queue,
        )
        oldCounter.testsOnly_setParentReferences(["root": ["ref"]])

        // msg = build_map_set("root", "ref", { string: "plain_value" }, "02", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "ref", value: ProtocolTypes.ObjectData(string: "plain_value"), serial: "02", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: pool, on: queue)

        // ASSERT map.data["ref"].data == { string: "plain_value" }
        #expect(map.testsOnly_data["ref"]?.data == ProtocolTypes.ObjectData(string: "plain_value"))
        // removeParentReference was called on old child (entry previously had objectId)
        #expect(oldCounter.testsOnly_parentReferences["root"]?.contains("ref") != true)
        // ASSERT update.update == { "ref": "updated" }
        #expect(update?.update?.update == ["ref": .updated])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM8a3/map-remove-objectid-parent-refs-0
    @Test
    func mapRemoveEntryReferencingLiveObjectRemovesParentReference() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let childCounter = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: queue)
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.counter(childCounter), forObjectID: "counter:child@1000")

        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["score": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:child@1000"), timeserial: "01")],
            internalQueue: queue,
        )
        childCounter.testsOnly_setParentReferences(["root": ["score"]])

        // msg = build_map_remove("root", "score", "02", "site1", 1700000000000)
        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "score", serial: "02", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: pool, on: queue)

        // ASSERT map.data["score"].tombstone == true
        #expect(map.testsOnly_data["score"]?.tombstone == true)
        // removeParentReference was called on the child
        #expect(childCounter.testsOnly_parentReferences["root"]?.contains("score") != true)
        // ASSERT update.update == { "score": "removed" }
        #expect(update?.update?.update == ["score": .removed])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM8/map-remove-primitive-no-parent-refs-0
    @Test
    func mapRemoveEntryWithNonLiveObjectValue() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01")],
            internalQueue: queue,
        )

        // msg = build_map_remove("root", "name", "02", "site1", 1700000000000)
        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "name", serial: "02", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: ObjectsUTS.freshPool(internalQueue: queue), on: queue)

        // ASSERT map.data["name"].tombstone == true
        #expect(map.testsOnly_data["name"]?.tombstone == true)
        // ASSERT update.update == { "name": "removed" }
        #expect(update?.update?.update == ["name": .removed])
        // ASSERT update.objectMessage == msg (no parentReference calls needed — passes without errors)
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM24e1c/map-clear-parent-refs-0
    @Test
    func mapClearRemovesParentReferencesForClearedEntries() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let counterA = ObjectsUTS.makeCounter(objectID: "counter:a@1000", internalQueue: queue)
        let counterB = ObjectsUTS.makeCounter(objectID: "counter:b@1000", internalQueue: queue)
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.counter(counterA), forObjectID: "counter:a@1000")
        pool.testsOnly_setEntry(.counter(counterB), forObjectID: "counter:b@1000")

        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: [
                "ref_a": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:a@1000"), timeserial: "02"),
                "ref_b": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:b@1000"), timeserial: "02"),
                "primitive": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "hello"), timeserial: "02"),
                "newer": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "kept"), timeserial: "09"),
            ],
            internalQueue: queue,
        )
        counterA.testsOnly_setParentReferences(["root": ["ref_a"]])
        counterB.testsOnly_setParentReferences(["root": ["ref_b"]])

        // msg = build_map_clear("root", "05", "site1")
        let msg = ObjectsUTS.mapClearMessage(objectId: "root", serial: "05", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: pool, on: queue)

        // ref_a and ref_b removed (timeserial "02" < "05"), newer kept (timeserial "09" > "05")
        // ASSERT "ref_a" NOT IN map.data
        #expect(map.testsOnly_data["ref_a"] == nil)
        // ASSERT "ref_b" NOT IN map.data
        #expect(map.testsOnly_data["ref_b"] == nil)
        // ASSERT "primitive" NOT IN map.data
        #expect(map.testsOnly_data["primitive"] == nil)
        // ASSERT "newer" IN map.data
        #expect(map.testsOnly_data["newer"] != nil)
        // removeParentReference was called on both child counters
        #expect(counterA.testsOnly_parentReferences["root"]?.contains("ref_a") != true)
        #expect(counterB.testsOnly_parentReferences["root"]?.contains("ref_b") != true)
        // ASSERT update.update == { "ref_a": "removed", "ref_b": "removed", "primitive": "removed" }
        #expect(update?.update?.update == ["ref_a": .removed, "ref_b": .removed, "primitive": .removed])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLO4e9/tombstone-map-parent-refs-0
    @Test
    func tombstoneMapRemovesParentReferencesForAllEntries() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let childCounter = ObjectsUTS.makeCounter(objectID: "counter:child@1000", internalQueue: queue)
        let childMap = ObjectsUTS.makeMap(objectID: "map:child@1000", internalQueue: queue)
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.counter(childCounter), forObjectID: "counter:child@1000")
        pool.testsOnly_setEntry(.map(childMap), forObjectID: "map:child@1000")

        let map = ObjectsUTS.makeMap(
            objectID: "map:test@1000",
            data: [
                "counter_ref": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "counter:child@1000"), timeserial: "01"),
                "map_ref": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "map:child@1000"), timeserial: "01"),
                "name": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(string: "Alice"), timeserial: "01"),
            ],
            internalQueue: queue,
        )
        map.testsOnly_setSiteTimeserials(["site1": "00"])
        childCounter.testsOnly_setParentReferences(["map:test@1000": ["counter_ref"]])
        childMap.testsOnly_setParentReferences(["map:test@1000": ["map_ref"]])

        // msg = build_object_delete("map:test@1000", "01", "site1", 1700000000000)
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "map:test@1000", serial: "01", siteCode: "site1", serialTimestamp: Self.date(millis: 1_700_000_000_000))
        let (update, _) = try Self.apply(msg, to: map, pool: pool, on: queue)

        // ASSERT map.isTombstone == true
        #expect(map.testsOnly_isTombstone == true)
        // ASSERT map.data == {}
        #expect(map.testsOnly_data.isEmpty)
        // removeParentReference was called on both children
        #expect(childCounter.testsOnly_parentReferences["map:test@1000"]?.contains("counter_ref") != true)
        #expect(childMap.testsOnly_parentReferences["map:test@1000"]?.contains("map_ref") != true)
        // ASSERT update.update == { "counter_ref": "removed", "map_ref": "removed", "name": "removed" }
        #expect(update?.update?.update == ["counter_ref": .removed, "map_ref": .removed, "name": .removed])
        // ASSERT update.tombstone == true
        #expect(update?.tombstone == true)
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM7a3/map-set-replace-objectid-both-refs-0
    @Test
    func mapSetOverwritingLiveObjectWithLiveObjectCallsBothRemoveAndAdd() throws {
        let queue = ObjectsUTS.createInternalQueue()
        let oldMap = ObjectsUTS.makeMap(objectID: "map:old@1000", internalQueue: queue)
        let newMap = ObjectsUTS.makeMap(objectID: "map:new@2000", internalQueue: queue)
        var pool = ObjectsUTS.freshPool(internalQueue: queue)
        pool.testsOnly_setEntry(.map(oldMap), forObjectID: "map:old@1000")
        pool.testsOnly_setEntry(.map(newMap), forObjectID: "map:new@2000")

        let map = ObjectsUTS.makeMap(
            objectID: "root",
            data: ["child": ObjectsUTS.mapEntry(data: ProtocolTypes.ObjectData(objectId: "map:old@1000"), timeserial: "01")],
            internalQueue: queue,
        )
        oldMap.testsOnly_setParentReferences(["root": ["child"]])

        // msg = build_map_set("root", "child", { objectId: "map:new@2000" }, "02", "site1")
        let msg = ObjectsUTS.mapSetMessage(objectId: "root", key: "child", value: ProtocolTypes.ObjectData(objectId: "map:new@2000"), serial: "02", siteCode: "site1")
        let (update, _) = try Self.apply(msg, to: map, pool: pool, on: queue)

        // ASSERT map.data["child"].data == { objectId: "map:new@2000" }
        #expect(map.testsOnly_data["child"]?.data == ProtocolTypes.ObjectData(objectId: "map:new@2000"))
        // Old child no longer references root
        #expect(oldMap.testsOnly_parentReferences["root"]?.contains("child") != true)
        // New child references root
        // ASSERT "root" IN new_map.parentReferences
        #expect(newMap.testsOnly_parentReferences["root"] != nil)
        // ASSERT "child" IN new_map.parentReferences["root"]
        #expect(newMap.testsOnly_parentReferences["root"]?.contains("child") == true)
        // ASSERT update.update == { "child": "updated" }
        #expect(update?.update?.update == ["child": .updated])
        // ASSERT update.objectMessage == msg
        #expect(update?.objectMessage == msg)
    }
}
