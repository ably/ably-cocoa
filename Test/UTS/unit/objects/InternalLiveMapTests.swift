// Derived from the UTS spec `objects/unit/internal_live_map.md`.
//
// Port of the REMAINING `objects/unit/internal_live_map.md` cases — everything except the six
// parent-reference cases already covered by `UTS/InternalLiveMapParentReferencesTests.swift`
// (RTLM7a3 overwrite, RTLM7g2 new-entry, RTLM7 primitive-no-refs, RTLM8a3, RTLM24e1c, RTLO4e9).
// The two OTHER parent-reference cases the spec has but that file omitted — RTLM8
// (map-remove-primitive-no-parent-refs) and RTLM7a3 (map-set-replace-objectid-both-refs) — ARE
// remaining, so they are ported here.
//
// These drive `InternalDefaultLiveMap` directly: zero value, MAP_SET / MAP_REMOVE / MAP_CLEAR /
// MAP_CREATE application, LWW (RTLM9) and clearTimeserial (RTLM7h/8g) gating, tombstoning
// (OBJECT_DELETE, RTLO5) and the RTLO4e10 root-delete rejection, the sync `replaceData` path
// (RTLM6*), GC (RTLM19), the RTLM22 diff, and the RTLM14 tombstoned-entry check.
//
// Deviations from the UTS spec:
// - (D-1) Construction: `InternalLiveMap(objectId:, semantics:[, pool:])` maps to
//   `InternalDefaultLiveMap(testsOnly_data:objectID:…)` (so initial `data` can be seeded) or
//   `.createZeroValued(objectID:…)`; there is no pool ctor param — the pool is passed `inout`
//   per-op. Standard mock preamble.
// - (D-2) Queue discipline: mutating `nosync_*` entry points (`nosync_apply`, `nosync_replaceData`,
//   `nosync_releaseTombstonedEntries`) run inside `internalQueue.ably_syncNoDeadlock { }`;
//   `testsOnly_set*` seams hop onto the queue themselves, so setup writes are outside the wrapper.
// - (D-3) Setup writes: spec direct assignments (`map.data = {…}`, `map.clearTimeserial = "05"`,
//   `map.isTombstone = true`, `map.siteTimeserials = {…}`) map to the `testsOnly_data:` ctor arg and
//   the seams `testsOnly_setClearTimeserial`, `testsOnly_setTombstonedAt` (isTombstone is computed
//   from tombstonedAt), `testsOnly_setSiteTimeserials`. Entry fields map to `InternalObjectsMapEntry`
//   (`tombstone` computed from `tombstonedAt`); spec ms epoch → `Date`. A `{ data: null … }`
//   tombstoned entry is built with `InternalObjectsMapEntry(tombstonedAt:timeserial:data:)` directly
//   (the `TestFactories.internalMapEntry` helper's `data` is non-optional).
// - (D-4) Message decomposition: `map.applyOperation(msg, source)` maps to
//   `map.nosync_apply(operation, source:, objectMessage:, objectsPool:&)`. The built `msg` supplies
//   the `operation` and is threaded down as the source message (RTLO4b4d); its PAOM3 public form is
//   projected only at delivery.
// - (D-5) `nosync_apply` returns `LiveObjectUpdate<…>?`: `nil` == gate-rejected (RTLM15b). So the
//   spec's `result == false` / `update == false` maps to `== nil`; `update.noop` to `.isNoop`;
//   `update.update` to `update.update?.update` (a `[String: LiveMapUpdateAction]` of `.updated` /
//   `.removed`).
// - (D-6) `update.objectMessage == msg` maps to equality against the internal source message the
//   update stores (RTLO4b4d — the PAOM3 public form is projected only at delivery); `update.tombstone
//   == true` to `update.tombstone` (RTLO4b4e). Both carried by the enriched update from the gated path.
// - (D-7) RTO4b2a — the sync path (`nosync_replaceData`) is sync-originated, so its returned update
//   carries `objectMessage == nil`. The spec's `ASSERT update.objectMessage == state_msg` for the
//   RTLM6 / RTLM6f cases therefore does NOT hold in cocoa; asserted as `objectMessage == nil`.
// - (D-8) Reads through functional accessors: `map.size()` / `map.get(key)` map to
//   `size(coreSDK:delegate:)` / `get(key:coreSDK:delegate:)` with `MockCoreSDK` (`.attaching`) +
//   `MockLiveMapObjectsPoolDelegate`. `map.data[k]` maps to `map.testsOnly_data[k]`.
// - (D-9) `InternalLiveMap.diff(prev, new)` (RTLM22) maps to
//   `ObjectDiffHelpers.calculateMapDiff(previousData:newData:)`.
// - (D-10) `map.gcTombstonedEntries(grace, now)` (RTLM19) maps to
//   `nosync_releaseTombstonedEntries(gracePeriod:clock:)` with grace in SECONDS (spec ms) and `now`
//   supplied by a `MockSimpleClock`.
// - (D-11) IMPLEMENTATION FIX (flagged in the report): RTLO4e10 (the root object must never be
//   tombstoned) was unimplemented — `InternalDefaultLiveMap`'s OBJECT_DELETE / tombstone-flag paths
//   would wrongly tombstone `root`. Fixed minimally in `Sources/AblyLiveObjects/Internal/
//   InternalDefaultLiveMap.swift` (both `apply` OBJECT_DELETE and `replaceData` tombstone-flag paths
//   now short-circuit to a noop for `objectID == root`). The two RTLO4e10 cases here exercise it.

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct InternalLiveMapTests {
    // MARK: - Helpers (D-1)

    private static func makeMap(objectID: String, data: [String: InternalObjectsMapEntry] = [:], internalQueue: DispatchQueue) -> InternalDefaultLiveMap {
        InternalDefaultLiveMap(
            testsOnly_data: data,
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    private static func makeCounter(objectID: String, internalQueue: DispatchQueue) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter.createZeroValued(
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    private static func makePool(internalQueue: DispatchQueue) -> ObjectsPool {
        ObjectsPool(logger: TestLogger(), internalQueue: internalQueue, userCallbackQueue: .main, clock: MockSimpleClock())
    }

    private static func coreSDK(internalQueue: DispatchQueue) -> MockCoreSDK {
        MockCoreSDK(channelState: .attaching, internalQueue: internalQueue)
    }

    /// Drives the gated `nosync_apply` from an inbound message, decomposing it (D-4) and threading
    /// the source message down; the public form is projected per PAOM3 at delivery.
    private static func apply(
        _ message: ProtocolTypes.InboundObjectMessage,
        to map: InternalDefaultLiveMap,
        source: ObjectsOperationSource = .channel,
        pool: inout ObjectsPool,
        internalQueue: DispatchQueue,
    ) throws -> LiveObjectUpdate<DefaultLiveMapUpdate>? {
        let operation = try #require(message.operation)
        return internalQueue.ably_syncNoDeadlock {
            map.nosync_apply(
                operation,
                source: source,
                objectMessage: message,
                objectsPool: &pool,
            )
        }
    }

    // MARK: - RTLM4

    // UTS: objects/unit/RTLM4/zero-value-0
    @Test
    func zeroValueMap() {
        let internalQueue = TestFactories.createInternalQueue()
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        #expect(map.testsOnly_data.isEmpty)
        #expect(map.testsOnly_clearTimeserial == nil)
        #expect(map.testsOnly_isTombstone == false)
        #expect(map.testsOnly_createOperationIsMerged == false)
        #expect(map.testsOnly_siteTimeserials.isEmpty)
    }

    // MARK: - RTLM7: MAP_SET

    // UTS: objects/unit/RTLM7/map-set-new-entry-0
    @Test
    func mapSetCreatesNewEntry() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Alice", serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        #expect(map.testsOnly_data["name"]?.timeserial == "01")
        #expect(map.testsOnly_data["name"]?.tombstone == false)
        #expect(update.update?.update == ["name": .updated])
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM7/map-set-update-entry-0
    @Test
    func mapSetUpdatesExistingEntry() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Bob", serial: "02", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Bob"))
        #expect(map.testsOnly_data["name"]?.timeserial == "02")
        #expect(update.update?.update == ["name": .updated])
        #expect(update.objectMessage == msg)
    }

    // MARK: - RTLM9: LWW

    // UTS: objects/unit/RTLM9/lww-reject-stale-0
    @Test
    func lwwRejectsStaleSerialOnExistingEntry() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "05", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Bob", serial: "03", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLM9/lww-reject-equal-0
    @Test
    func lwwRejectsEqualSerial() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "05", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Bob", serial: "05", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLM9b/both-empty-reject-0
    @Test
    func bothSerialsEmptyRejectsOperation() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Bob", serial: "", siteCode: "site1")
        let update = try Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue)

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        // The op's serial is empty, so the OBJECT-level gate (RTLO4a3) rejects it before the
        // entry-level RTLM9b comparison; nosync_apply returns nil (D-5). The RTLM9b "both empty" case
        // is thus unreachable via applyOperation — a spec layering tension noted in the spec itself.
        #expect(update == nil)
    }

    // UTS: objects/unit/RTLM9d/missing-entry-serial-allows-0
    @Test
    func missingEntrySerialAllowsOperation() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: nil, data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Bob", serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Bob"))
        #expect(update.update?.update == ["name": .updated])
        #expect(update.objectMessage == msg)
    }

    // MARK: - RTLM7h, RTLM7g

    // UTS: objects/unit/RTLM7h/map-set-clear-timeserial-floor-0
    @Test
    func mapSetRejectedWhenSerialAtOrBelowClearTimeserial() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)
        map.testsOnly_setClearTimeserial("05")

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Alice", serial: "03", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"] == nil)
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLM7g/map-set-objectid-creates-zero-value-0
    @Test
    func mapSetWithObjectIdCreatesZeroValueObject() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "score", data: ProtocolTypes.ObjectData(objectId: "counter:new@2000"), serial: "01", siteCode: "site1")
        _ = try Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue)

        let createdCounter = try #require(pool.entries["counter:new@2000"]?.counterValue)
        #expect(try createdCounter.value(coreSDK: Self.coreSDK(internalQueue: internalQueue)) == 0)
    }

    // MARK: - RTLM8: MAP_REMOVE

    // UTS: objects/unit/RTLM8/map-remove-existing-0
    @Test
    func mapRemoveTombstonesExistingEntry() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "name", serial: "02", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == nil)
        #expect(map.testsOnly_data["name"]?.tombstone == true)
        #expect(map.testsOnly_data["name"]?.timeserial == "02")
        #expect(map.testsOnly_data["name"]?.tombstonedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(update.update?.update == ["name": .removed])
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM8/map-remove-nonexistent-0
    @Test
    func mapRemoveCreatesTombstonedEntryIfNotExists() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "ghost", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["ghost"]?.tombstone == true)
        #expect(map.testsOnly_data["ghost"]?.tombstonedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(update.update?.update == ["ghost": .removed])
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM8g/map-remove-clear-timeserial-floor-0
    @Test
    func mapRemoveRejectedWhenSerialAtOrBelowClearTimeserial() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "04", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )
        map.testsOnly_setClearTimeserial("05")

        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "name", serial: "03", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        #expect(map.testsOnly_data["name"]?.tombstone == false)
        #expect(update.isNoop == true)
    }

    // MARK: - RTLM24: MAP_CLEAR

    // UTS: objects/unit/RTLM24/map-clear-basic-0
    @Test
    func mapClearSetsClearTimeserialAndRemovesOlderEntries() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: [
                "old": TestFactories.internalMapEntry(timeserial: "02", data: ProtocolTypes.ObjectData(string: "old")),
                "new": TestFactories.internalMapEntry(timeserial: "06", data: ProtocolTypes.ObjectData(string: "new")),
                "same": TestFactories.internalMapEntry(timeserial: "04", data: ProtocolTypes.ObjectData(string: "same")),
            ],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapClearOperationMessage(objectId: "root", serial: "04", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_clearTimeserial == "04")
        #expect(map.testsOnly_data["old"] == nil)
        // RTLM24e1: removed only if clear serial is strictly greater than the entry's timeserial;
        // "same" has timeserial "04" == the clear serial (not greater), so it is KEPT.
        #expect(map.testsOnly_data["same"] != nil)
        #expect(map.testsOnly_data["new"] != nil)
        #expect(update.update?.update == ["old": .removed])
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM24c/map-clear-stale-0
    @Test
    func mapClearRejectedWhenClearTimeserialAlreadyGreater() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)
        map.testsOnly_setClearTimeserial("10")

        let msg = TestFactories.mapClearOperationMessage(objectId: "root", serial: "05", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_clearTimeserial == "10")
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLM24/map-clear-preserves-newer-0
    @Test
    func mapClearPreservesEntriesWithNewerSerial() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: [
                "before": TestFactories.internalMapEntry(timeserial: "03", data: ProtocolTypes.ObjectData(string: "a")),
                "after": TestFactories.internalMapEntry(timeserial: "07", data: ProtocolTypes.ObjectData(string: "b")),
                "no_ts": TestFactories.internalMapEntry(timeserial: nil, data: ProtocolTypes.ObjectData(string: "c")),
            ],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapClearOperationMessage(objectId: "root", serial: "05", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["before"] == nil)
        #expect(map.testsOnly_data["no_ts"] == nil)
        #expect(map.testsOnly_data["after"]?.data == ProtocolTypes.ObjectData(string: "b"))
        #expect(update.update?.update["before"] == .removed)
        #expect(update.update?.update["no_ts"] == .removed)
        #expect(update.update?.update["after"] == nil)
        #expect(update.objectMessage == msg)
    }

    // MARK: - RTLM16, RTLM23: MAP_CREATE

    // UTS: objects/unit/RTLM16/map-create-merge-0
    @Test
    func mapCreateMergesEntries() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "map:test@1000", internalQueue: internalQueue)

        let entries: [String: ProtocolTypes.ObjectsMapEntry] = [
            "name": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice")),
            "removed_key": ProtocolTypes.ObjectsMapEntry(tombstone: true, timeserial: "01", data: nil, serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000)),
        ]
        let msg = TestFactories.mapCreateOperationMessage(objectId: "map:test@1000", entries: entries, serial: "02", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        #expect(map.testsOnly_data["removed_key"]?.tombstone == true)
        #expect(map.testsOnly_createOperationIsMerged == true)
        #expect(update.update?.update == ["name": .updated, "removed_key": .removed])
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM16b/map-create-already-merged-0
    @Test
    func mapCreateNoopWhenAlreadyMerged() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "map:test@1000", internalQueue: internalQueue)
        map.testsOnly_setCreateOperationIsMerged(true)
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        let entries: [String: ProtocolTypes.ObjectsMapEntry] = [
            "name": ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: "01", data: ProtocolTypes.ObjectData(string: "Bob")),
        ]
        let msg = TestFactories.mapCreateOperationMessage(objectId: "map:test@1000", entries: entries, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"] == nil)
        #expect(update.isNoop == true)
    }

    // MARK: - RTLM15c, RTLM15e

    // UTS: objects/unit/RTLM15c/channel-source-updates-serials-0
    @Test
    func channelSourceUpdatesSiteTimeserials() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "x", data: ProtocolTypes.ObjectData(number: NSNumber(value: 1)), serial: "01", siteCode: "site1")
        _ = try Self.apply(msg, to: map, source: .channel, pool: &pool, internalQueue: internalQueue)

        #expect(map.testsOnly_siteTimeserials["site1"] == "01")
    }

    // UTS: objects/unit/RTLM15e/tombstoned-reject-ops-0
    @Test
    func operationsOnTombstonedMapAreRejected() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)
        // D-3: isTombstone is computed from tombstonedAt
        map.testsOnly_setTombstonedAt(Date(timeIntervalSince1970: 1_700_000_000))

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "x", data: ProtocolTypes.ObjectData(number: NSNumber(value: 1)), serial: "01", siteCode: "site1")
        let result = try Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue)

        #expect(result == nil)
        #expect(map.testsOnly_data.isEmpty)
    }

    // MARK: - RTLO5, RTLO4e10: OBJECT_DELETE / tombstoning

    // UTS: objects/unit/RTLO5/object-delete-tombstones-map-0
    @Test
    func objectDeleteTombstonesMap() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "map:test@1000",
            data: [
                "name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice")),
                "age": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(number: NSNumber(value: 30))),
            ],
            internalQueue: internalQueue,
        )
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        let msg = TestFactories.objectDeleteOperationMessage(objectId: "map:test@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_isTombstone == true)
        #expect(map.testsOnly_data.isEmpty)
        #expect(update.update?.update == ["name": .removed, "age": .removed])
        #expect(update.tombstone == true)
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLO5/tombstone-empty-map-emits-update-0
    // RTLM22c: when every entry is already
    // tombstoned the tombstone diff (RTLM22b considers only non-tombstoned entries) has no changed keys, but
    // the RTLM22c tombstone carve-out means this empty diff must NOT be marked a noop; it is still delivered
    // (tombstone flag, empty payload) so the RTLO4b4c3c listener teardown runs. Complements
    // object-delete-tombstones-map-0 (which tombstones a map with live entries).
    @Test
    func objectDeleteOnMapWithNoLiveEntriesStillEmitsNonNoopTombstoneUpdate() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "map:test@1000",
            data: [
                "name": InternalObjectsMapEntry(tombstonedAt: Date(timeIntervalSince1970: 1_600_000_000), timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice")),
                "age": InternalObjectsMapEntry(tombstonedAt: Date(timeIntervalSince1970: 1_600_000_000), timeserial: "01", data: ProtocolTypes.ObjectData(number: NSNumber(value: 30))),
            ],
            internalQueue: internalQueue,
        )
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        let msg = TestFactories.objectDeleteOperationMessage(objectId: "map:test@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_isTombstone == true)
        #expect(map.testsOnly_data.isEmpty)
        // RTLM22c: the empty tombstone diff is NOT a noop; the payload carries no changed keys.
        #expect(update.isNoop == false)
        #expect(update.tombstone == true)
        #expect(update.update?.update.isEmpty == true)
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLO4e10/object-delete-root-noop-0
    // D-11: exercises the RTLO4e10 implementation fix.
    @Test
    func objectDeleteTargetingRootIsRejected() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )
        map.testsOnly_setSiteTimeserials(["site1": "00"])

        let msg = TestFactories.objectDeleteOperationMessage(objectId: "root", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_isTombstone == false)
        #expect(map.testsOnly_data["name"]?.data?.string == "Alice")
        #expect(update.isNoop == true)
    }

    // MARK: - RTLM14: tombstoned-entry check

    // UTS: objects/unit/RTLM14/tombstone-check-objectid-ref-0
    @Test
    func tombstonedEntryCheckIncludesObjectIdReference() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let tombstonedCounter = Self.makeCounter(objectID: "counter:dead@1000", internalQueue: internalQueue)
        tombstonedCounter.testsOnly_setTombstonedAt(Date(timeIntervalSince1970: 1_700_000_000))
        pool.testsOnly_setEntry(.counter(tombstonedCounter), forObjectID: "counter:dead@1000")

        let map = Self.makeMap(
            objectID: "root",
            data: [
                "alive": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "ok")),
                "dead_entry": InternalObjectsMapEntry(tombstonedAt: Date(timeIntervalSince1970: 1_700_000_000), timeserial: "01", data: nil),
                "dead_ref": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:dead@1000")),
            ],
            internalQueue: internalQueue,
        )

        let alive = try #require(map.testsOnly_data["alive"])
        let deadEntry = try #require(map.testsOnly_data["dead_entry"])
        let deadRef = try #require(map.testsOnly_data["dead_ref"])

        // isEntryTombstoned reads the referenced object's `nosync_isTombstone`, which asserts
        // ownership of the internal queue (D-2), so the checks run inside the queue block.
        let (aliveTombstoned, deadEntryTombstoned, deadRefTombstoned) = internalQueue.ably_syncNoDeadlock {
            (
                map.testsOnly_isEntryTombstoned(alive, objectsPool: pool),
                map.testsOnly_isEntryTombstoned(deadEntry, objectsPool: pool),
                map.testsOnly_isEntryTombstoned(deadRef, objectsPool: pool),
            )
        }

        #expect(aliveTombstoned == false)
        #expect(deadEntryTombstoned == true)
        #expect(deadRefTombstoned == true)
    }

    // UTS: objects/unit/RTLM14c/tombstoned-ref-yields-null-0
    @Test
    func mapSetReferencingTombstonedObjectIdYieldsNull() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let tombstonedCounter = Self.makeCounter(objectID: "counter:dead@1000", internalQueue: internalQueue)
        tombstonedCounter.testsOnly_setTombstonedAt(Date(timeIntervalSince1970: 1_700_000_000))

        let delegate = MockLiveMapObjectsPoolDelegate(internalQueue: internalQueue)
        delegate.objects["counter:dead@1000"] = .counter(tombstonedCounter)

        let map = Self.makeMap(
            objectID: "root",
            data: ["ref": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:dead@1000"))],
            internalQueue: internalQueue,
        )
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        // The entry itself is not tombstoned, but the referenced object is (RTLM14c)
        #expect(map.testsOnly_data["ref"]?.tombstone == false)
        #expect(try map.size(coreSDK: coreSDK, delegate: delegate) == 0)
        #expect(try map.get(key: "ref", coreSDK: coreSDK, delegate: delegate) == nil)
    }

    // UTS: objects/unit/RTLM7/map-set-revives-tombstoned-0
    @Test
    func mapSetRevivesTombstonedEntry() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": InternalObjectsMapEntry(tombstonedAt: Date(timeIntervalSince1970: 1_700_000_000), timeserial: "01", data: nil)],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "name", value: "Alice", serial: "02", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "Alice"))
        #expect(map.testsOnly_data["name"]?.tombstone == false)
        #expect(map.testsOnly_data["name"]?.tombstonedAt == nil)
        #expect(update.update?.update == ["name": .updated])
        #expect(update.objectMessage == msg)
    }

    // MARK: - RTLM15d4

    // UTS: objects/unit/RTLM15d4/unsupported-action-0
    @Test
    func unsupportedActionIsDiscarded() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        // A COUNTER_INC action targeting the map is unsupported for LiveMap
        let msg = TestFactories.counterIncOperationMessage(objectId: "root", number: 5, serial: "01", siteCode: "site1")
        let result = try Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue)

        #expect(result == nil)
    }

    // MARK: - RTLM6: replaceData (sync path)

    // UTS: objects/unit/RTLM6/replace-data-basic-0
    @Test
    func replaceDataSetsDataFromObjectState() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["old": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "old"))],
            internalQueue: internalQueue,
        )
        map.testsOnly_setCreateOperationIsMerged(true)

        let state = TestFactories.objectState(
            objectId: "root",
            siteTimeserials: ["site2": "05"],
            map: TestFactories.objectsMap(
                entries: ["new": TestFactories.mapEntry(timeserial: "04", data: ProtocolTypes.ObjectData(string: "new"))],
                clearTimeserial: "03",
            ),
        )
        let update = internalQueue.ably_syncNoDeadlock {
            map.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
        }

        #expect(map.testsOnly_siteTimeserials == ["site2": "05"])
        #expect(map.testsOnly_createOperationIsMerged == false)
        #expect(map.testsOnly_clearTimeserial == "03")
        #expect(map.testsOnly_data["old"] == nil)
        #expect(map.testsOnly_data["new"]?.data == ProtocolTypes.ObjectData(string: "new"))
        #expect(update.update?.update == ["old": .removed, "new": .updated])
        // D-7: RTO4b2a — sync-originated, so objectMessage is nil (spec asserts == state_msg)
        #expect(update.objectMessage == nil)
    }

    // UTS: objects/unit/RTLM6c1/replace-data-tombstoned-entries-0
    @Test
    func replaceDataSetsTombstonedAtOnTombstonedEntries() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        let state = TestFactories.objectState(
            objectId: "root",
            siteTimeserials: ["site1": "01"],
            map: TestFactories.objectsMap(entries: [
                "dead": ProtocolTypes.ObjectsMapEntry(tombstone: true, timeserial: "01", data: nil, serialTimestamp: Date(timeIntervalSince1970: 1_700_000_050)),
            ]),
        )
        internalQueue.ably_syncNoDeadlock {
            _ = map.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
        }

        #expect(map.testsOnly_data["dead"]?.tombstonedAt == Date(timeIntervalSince1970: 1_700_000_050))
    }

    // UTS: objects/unit/RTLM6d/replace-data-with-create-op-0
    @Test
    func replaceDataWithCreateOpMergesInitialEntries() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(objectID: "map:test@1000", internalQueue: internalQueue)

        let state = TestFactories.mapObjectState(
            objectId: "map:test@1000",
            siteTimeserials: ["site1": "01"],
            createOp: TestFactories.mapCreateOperation(
                objectId: "map:test@1000",
                entries: ["from_create": TestFactories.mapEntry(timeserial: "00", data: ProtocolTypes.ObjectData(string: "created"))],
            ),
            entries: ["from_sync": TestFactories.mapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "synced"))],
        )
        internalQueue.ably_syncNoDeadlock {
            _ = map.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
        }

        #expect(map.testsOnly_data["from_sync"]?.data == ProtocolTypes.ObjectData(string: "synced"))
        #expect(map.testsOnly_data["from_create"]?.data == ProtocolTypes.ObjectData(string: "created"))
        #expect(map.testsOnly_createOperationIsMerged == true)
    }

    // UTS: objects/unit/RTLM6f/replace-data-tombstone-flag-0
    @Test
    func replaceDataWithTombstoneFlagTombstonesMap() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "map:test@1000",
            data: ["name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let state = TestFactories.mapObjectState(objectId: "map:test@1000", siteTimeserials: ["site1": "01"], tombstone: true, entries: [:])
        let update = internalQueue.ably_syncNoDeadlock {
            map.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
        }

        #expect(map.testsOnly_isTombstone == true)
        #expect(map.testsOnly_data.isEmpty)
        #expect(update.update?.update == ["name": .removed])
        #expect(update.tombstone == true)
        #expect(update.objectMessage == nil) // D-7
    }

    // UTS: objects/unit/RTLO4e10/replace-data-tombstone-root-noop-0
    // D-11: exercises the RTLO4e10 implementation fix on the sync path.
    @Test
    func replaceDataWithTombstoneFlagTargetingRootIsRejected() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let state = TestFactories.mapObjectState(objectId: "root", siteTimeserials: ["site1": "01"], tombstone: true, entries: [:])
        let update = internalQueue.ably_syncNoDeadlock {
            map.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
        }

        #expect(map.testsOnly_isTombstone == false)
        #expect(map.testsOnly_data["name"]?.data?.string == "Alice")
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLM6i/replace-data-resets-clear-timeserial-0
    @Test
    func replaceDataWithoutClearTimeserialResetsToNull() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["x": TestFactories.internalMapEntry(timeserial: "03", data: ProtocolTypes.ObjectData(number: NSNumber(value: 1)))],
            internalQueue: internalQueue,
        )
        map.testsOnly_setClearTimeserial("05")

        let state = TestFactories.mapObjectState(
            objectId: "root",
            siteTimeserials: ["site1": "01"],
            entries: ["y": TestFactories.mapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(number: NSNumber(value: 2)))],
        )
        internalQueue.ably_syncNoDeadlock {
            _ = map.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
        }

        #expect(map.testsOnly_clearTimeserial == nil)
        #expect(map.testsOnly_data["y"] != nil)
    }

    // MARK: - RTLM19: GC

    // UTS: objects/unit/RTLM19/gc-tombstoned-entries-0
    @Test
    func gcRemovesTombstonedEntriesPastGracePeriod() {
        let internalQueue = TestFactories.createInternalQueue()
        // D-10: grace in SECONDS; `now` supplied by the mock clock.
        let gracePeriod: TimeInterval = 86400
        let now = Date(timeIntervalSince1970: 1_700_100_000)
        let clock = MockSimpleClock(currentTime: now)

        let map = Self.makeMap(
            objectID: "root",
            data: [
                "recent_dead": InternalObjectsMapEntry(tombstonedAt: now.addingTimeInterval(-1), timeserial: "01", data: nil),
                "old_dead": InternalObjectsMapEntry(tombstonedAt: now.addingTimeInterval(-gracePeriod - 1), timeserial: "01", data: nil),
                "alive": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "ok")),
            ],
            internalQueue: internalQueue,
        )

        internalQueue.ably_syncNoDeadlock {
            map.nosync_releaseTombstonedEntries(gracePeriod: gracePeriod, clock: clock)
        }

        #expect(map.testsOnly_data["recent_dead"] != nil)
        #expect(map.testsOnly_data["old_dead"] == nil)
        #expect(map.testsOnly_data["alive"] != nil)
    }

    // MARK: - RTLM22: diff

    // UTS: objects/unit/RTLM22/diff-calculation-0
    @Test
    func diffBetweenTwoDataStates() {
        let previousData: [String: InternalObjectsMapEntry] = [
            "removed": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "gone")),
            "changed": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "old")),
            "unchanged": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "same")),
            "was_dead": InternalObjectsMapEntry(tombstonedAt: Date(timeIntervalSince1970: 1_700_000_000), timeserial: "01", data: nil),
        ]
        let newData: [String: InternalObjectsMapEntry] = [
            "added": TestFactories.internalMapEntry(timeserial: "02", data: ProtocolTypes.ObjectData(string: "new")),
            "changed": TestFactories.internalMapEntry(timeserial: "02", data: ProtocolTypes.ObjectData(string: "new_val")),
            "unchanged": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "same")),
            "now_dead": InternalObjectsMapEntry(tombstonedAt: Date(timeIntervalSince1970: 1_700_000_000), timeserial: "02", data: nil),
        ]

        let update = ObjectDiffHelpers.calculateMapDiff(previousData: previousData, newData: newData)

        #expect(update.update?.update["removed"] == .removed)
        #expect(update.update?.update["added"] == .updated)
        #expect(update.update?.update["changed"] == .updated)
        #expect(update.update?.update["unchanged"] == nil)
        #expect(update.update?.update["was_dead"] == nil)
        #expect(update.update?.update["now_dead"] == nil)
    }

    // UTS: objects/unit/RTLM22c/empty-diff-is-noop-0
    // As an exception to RTLM22b, when the computed LiveMapUpdate.update contains no changed keys the
    // diff returns a LiveMapUpdate marked as a no-op per RTLO4b4b. A no-op update is never delivered
    // to subscribers (RTLO4b4c1), so at the internal tier the flake-free proxy for "no event fires"
    // is asserting update.noop == true. Here the map's non-tombstoned entries before and after
    // replaceData are identical under the RTLM22b comparison rules (same key "name", same data; only
    // timeserial differs 01->02, which RTLM22b3 does not compare), so no key changed.
    @Test
    func emptyDiffIsNoop() throws {
        // Setup
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "alice"))],
            internalQueue: internalQueue,
        )

        // Test Steps
        let state = TestFactories.mapObjectState(
            objectId: "root",
            siteTimeserials: ["site1": "02"],
            entries: ["name": TestFactories.mapEntry(timeserial: "02", data: ProtocolTypes.ObjectData(string: "alice"))],
        )
        let update = internalQueue.ably_syncNoDeadlock {
            map.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
        }

        // Assertions
        #expect(update.isNoop == true)
        #expect(map.testsOnly_data["name"]?.data == ProtocolTypes.ObjectData(string: "alice"))
    }

    // MARK: - Remaining parent-reference cases (not among the six ported elsewhere)

    // UTS: objects/unit/RTLM8/map-remove-primitive-no-parent-refs-0
    @Test
    func mapRemovePrimitiveDoesNotAffectParentReferences() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let map = Self.makeMap(
            objectID: "root",
            data: ["name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice"))],
            internalQueue: internalQueue,
        )

        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "name", serial: "02", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["name"]?.tombstone == true)
        #expect(update.update?.update == ["name": .removed])
        #expect(update.objectMessage == msg)
    }

    // UTS: objects/unit/RTLM7a3/map-set-replace-objectid-both-refs-0
    @Test
    func mapSetReplacingObjectIdCallsBothRemoveAndAdd() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let oldMap = Self.makeMap(objectID: "map:old@1000", internalQueue: internalQueue)
        let newMap = Self.makeMap(objectID: "map:new@2000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.map(oldMap), forObjectID: "map:old@1000")
        pool.testsOnly_setEntry(.map(newMap), forObjectID: "map:new@2000")

        let map = Self.makeMap(
            objectID: "root",
            data: ["child": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "map:old@1000"))],
            internalQueue: internalQueue,
        )
        oldMap.testsOnly_setParentReferences(["root": ["child"]])

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "child", data: ProtocolTypes.ObjectData(objectId: "map:new@2000"), serial: "02", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["child"]?.data?.objectId == "map:new@2000")
        // Old child no longer references root
        #expect(oldMap.testsOnly_parentReferences["root"]?.contains("child") != true)
        // New child references root
        #expect(newMap.testsOnly_parentReferences["root"]?.contains("child") == true)
        #expect(update.update?.update == ["child": .updated])
        #expect(update.objectMessage == msg)
    }
}
