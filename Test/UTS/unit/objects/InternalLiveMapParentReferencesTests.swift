// Derived from the UTS spec `objects/unit/internal_live_map.md`.
//
// Partial port of `objects/unit/internal_live_map.md`: ONLY the six parent-reference cases
// (RTLM7a3 overwrite, RTLM7g2 new-entry, RTLM7 primitive-no-refs, RTLM8a3, RTLM24e1c, RTLO4e9).
// The remaining InternalLiveMap CRDT cases in that spec file are covered by
// `UTS/InternalLiveMapTests.swift` (and the native `InternalDefaultLiveMapTests.swift`).
//
// These verify that map operations maintain the RTLO3f parent-reference graph: MAP_SET drops the old
// child's reference and adds the new child's (RTLM7a3 / RTLM7g2), MAP_REMOVE drops the child's ref
// (RTLM8a3), MAP_CLEAR drops refs for every cleared entry (RTLM24e1c), OBJECT_DELETE drops the refs the
// map holds on all its children (RTLO4e9), and primitive-valued sets touch no references.
//
// Deviations from the UTS spec:
// - (D-1) The spec constructs `InternalLiveCounter(objectId:)` / `InternalLiveMap(objectId:, semantics:)`.
//   The Swift live objects need a logger/queue/callback-queue/clock; counters use
//   `InternalDefaultLiveCounter.createZeroValued(...)` and maps are built via the
//   `InternalDefaultLiveMap(testsOnly_data:objectID:...)` seam so initial `data` can be seeded (D-2).
// - (D-2) Spec `map.data = { "k": { data: { objectId: … }, timeserial: "01", tombstone: false } }` maps to
//   the `testsOnly_data:` initializer argument, with each entry built by `TestFactories.internalMapEntry(
//   timeserial:data:)`. `{ objectId: "x" }` → `ProtocolTypes.ObjectData(objectId: "x")`; `{ string: "x" }`
//   → `ProtocolTypes.ObjectData(string: "x")`. Reads of `map.data[k]` map to `map.testsOnly_data[k]`.
// - (D-3) Drive path: spec `map.applyOperation(build_map_set/remove/clear(…), source: CHANNEL)` maps to
//   the gated `nosync_apply(operation, source:, objectMessageSerial:, objectMessageSiteCode:,
//   objectMessageSerialTimestamp:, sourceObjectMessage:, objectsPool:&)`. The built message is
//   decomposed and its PAOM3 public form passed as `sourceObjectMessage` (RTLO4b4d) so the returned
//   update carries it — see D-6. (An earlier revision drove the granular `testsOnly_applyMap*Operation`
//   seams, which bypass the RTLM15 gate AND the message-stamping; they were switched to `nosync_apply`
//   so the `update.objectMessage` assertions the spec has could be honoured. The maps' `siteTimeserials`
//   start empty, so any first op passes the RTLO4a5 gate with no seeding needed.) `nosync_apply` is
//   `nosync_`, so it runs on the internal queue.
// - (D-4) OBJECT_DELETE (RTLO4e9) is driven through the same `nosync_apply` with an objectDelete
//   operation from `TestFactories.objectDeleteOperationMessage(...)`. The map's siteTimeserials are
//   seeded `["site1": "00"]` so the op serial "01" passes the RTLM15 object gate.
// - (D-5) Spec `pool["id"] = obj` maps to `pool.testsOnly_setEntry(.counter(obj) / .map(obj), forObjectID: "id")`.
//   Child parentReferences seeding `child.parentReferences = {…}` maps to `child.testsOnly_setParentReferences(_:)`,
//   reads to `child.testsOnly_parentReferences`. Spec `Dict<String, Set<String>>` ↔ `[String: Set<String>]`.
// - (D-6) LiveMapUpdate shape: the spec asserts `update.update == { "ref": "updated" }`, `update.objectMessage
//   == msg`, and (for OBJECT_DELETE) `update.tombstone == true`. Swift's `LiveObjectUpdate<
//   DefaultLiveMapUpdate>` exposes `.update` (a `DefaultLiveMapUpdate` whose `.update` is `[String:
//   LiveMapUpdateAction]` of `.updated` / `.removed`), plus `.objectMessage` (the PAOM3 public message,
//   RTLO4b4d) and `.tombstone` (RTLO4b4e). All three are now carried by the gated apply path and asserted
//   here (`update.objectMessage == msg.toPublicObjectMessage(channelName:)`), so — unlike the P1 revision
//   of this file — none are omitted.

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct InternalLiveMapParentReferencesTests {
    /// The channel name used when converting inbound messages to their PAOM3 public form (PAOM2e).
    private static let channelName = "test-channel"

    // MARK: - Helpers (D-1)

    private static func makeCounter(objectID: String, internalQueue: DispatchQueue) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter.createZeroValued(
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

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

    private static func makePool(internalQueue: DispatchQueue) -> ObjectsPool {
        ObjectsPool(logger: TestLogger(), internalQueue: internalQueue, userCallbackQueue: .main, clock: MockSimpleClock())
    }

    /// Drives the gated `nosync_apply` from an inbound message, decomposing it (D-3) and passing its
    /// PAOM3 public form as `sourceObjectMessage` (D-6).
    private static func apply(
        _ message: ProtocolTypes.InboundObjectMessage,
        to map: InternalDefaultLiveMap,
        pool: inout ObjectsPool,
        internalQueue: DispatchQueue,
    ) throws -> LiveObjectUpdate<DefaultLiveMapUpdate>? {
        let operation = try #require(message.operation)
        return internalQueue.ably_syncNoDeadlock {
            map.nosync_apply(
                operation,
                source: .channel,
                objectMessageSerial: message.serial,
                objectMessageSiteCode: message.siteCode,
                objectMessageSerialTimestamp: message.serialTimestamp,
                sourceObjectMessage: message.toPublicObjectMessage(channelName: channelName),
                objectsPool: &pool,
            )
        }
    }

    // UTS: objects/unit/RTLM7a3/map-set-overwrite-objectid-parent-refs-0
    @Test
    func mapSetOverwriteEntryReferencingLiveObject() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let oldCounter = Self.makeCounter(objectID: "counter:old@1000", internalQueue: internalQueue)
        let newCounter = Self.makeCounter(objectID: "counter:new@2000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(oldCounter), forObjectID: "counter:old@1000")
        pool.testsOnly_setEntry(.counter(newCounter), forObjectID: "counter:new@2000")

        let map = Self.makeMap(
            objectID: "root",
            data: ["ref": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:old@1000"))],
            internalQueue: internalQueue,
        )
        // Simulate existing parentReference
        oldCounter.testsOnly_setParentReferences(["root": ["ref"]])

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "ref", data: ProtocolTypes.ObjectData(objectId: "counter:new@2000"), serial: "02", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["ref"]?.data?.objectId == "counter:new@2000")
        // removeParentReference was called on the old child
        #expect(oldCounter.testsOnly_parentReferences["root"]?.contains("ref") != true)
        // addParentReference was called on the new child
        #expect(newCounter.testsOnly_parentReferences["root"]?.contains("ref") == true)
        #expect(update.update?.update == ["ref": .updated])
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLM7g2/map-set-new-entry-add-parent-ref-0
    @Test
    func mapSetNewEntryReferencingLiveObject() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let childCounter = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(childCounter), forObjectID: "counter:child@1000")

        let map = Self.makeMap(objectID: "root", internalQueue: internalQueue)

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "score", data: ProtocolTypes.ObjectData(objectId: "counter:child@1000"), serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["score"]?.data?.objectId == "counter:child@1000")
        #expect(childCounter.testsOnly_parentReferences["root"]?.contains("score") == true)
        #expect(update.update?.update == ["score": .updated])
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLM7/map-set-primitive-no-parent-refs-0
    @Test
    func mapSetWithNonLiveObjectValueDoesNotAffectParentReferences() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let oldCounter = Self.makeCounter(objectID: "counter:old@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(oldCounter), forObjectID: "counter:old@1000")

        let map = Self.makeMap(
            objectID: "root",
            data: ["ref": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:old@1000"))],
            internalQueue: internalQueue,
        )
        oldCounter.testsOnly_setParentReferences(["root": ["ref"]])

        let msg = TestFactories.mapSetOperationMessage(objectId: "root", key: "ref", value: "plain_value", serial: "02", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["ref"]?.data?.string == "plain_value")
        // removeParentReference was called on old child (entry previously had objectId)
        #expect(oldCounter.testsOnly_parentReferences["root"]?.contains("ref") != true)
        // No addParentReference call because the new value is a primitive
        #expect(update.update?.update == ["ref": .updated])
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLM8a3/map-remove-objectid-parent-refs-0
    @Test
    func mapRemoveEntryReferencingLiveObject() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let childCounter = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(childCounter), forObjectID: "counter:child@1000")

        let map = Self.makeMap(
            objectID: "root",
            data: ["score": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:child@1000"))],
            internalQueue: internalQueue,
        )
        childCounter.testsOnly_setParentReferences(["root": ["score"]])

        let msg = TestFactories.mapRemoveOperationMessage(objectId: "root", key: "score", serial: "02", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_data["score"]?.tombstone == true)
        // removeParentReference was called on the child
        #expect(childCounter.testsOnly_parentReferences["root"]?.contains("score") != true)
        #expect(update.update?.update == ["score": .removed])
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLM24e1c/map-clear-parent-refs-0
    @Test
    func mapClearRemovesParentReferencesForClearedEntries() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let counterA = Self.makeCounter(objectID: "counter:a@1000", internalQueue: internalQueue)
        let counterB = Self.makeCounter(objectID: "counter:b@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(counterA), forObjectID: "counter:a@1000")
        pool.testsOnly_setEntry(.counter(counterB), forObjectID: "counter:b@1000")

        let map = Self.makeMap(
            objectID: "root",
            data: [
                "ref_a": TestFactories.internalMapEntry(timeserial: "02", data: ProtocolTypes.ObjectData(objectId: "counter:a@1000")),
                "ref_b": TestFactories.internalMapEntry(timeserial: "02", data: ProtocolTypes.ObjectData(objectId: "counter:b@1000")),
                "primitive": TestFactories.internalMapEntry(timeserial: "02", data: ProtocolTypes.ObjectData(string: "hello")),
                "newer": TestFactories.internalMapEntry(timeserial: "09", data: ProtocolTypes.ObjectData(string: "kept")),
            ],
            internalQueue: internalQueue,
        )
        counterA.testsOnly_setParentReferences(["root": ["ref_a"]])
        counterB.testsOnly_setParentReferences(["root": ["ref_b"]])

        let msg = TestFactories.mapClearOperationMessage(objectId: "root", serial: "05", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        // ref_a and ref_b removed (timeserial "02" < "05"), newer kept (timeserial "09" > "05")
        #expect(map.testsOnly_data["ref_a"] == nil)
        #expect(map.testsOnly_data["ref_b"] == nil)
        #expect(map.testsOnly_data["primitive"] == nil)
        #expect(map.testsOnly_data["newer"] != nil)
        // removeParentReference was called on both child counters
        #expect(counterA.testsOnly_parentReferences["root"]?.contains("ref_a") != true)
        #expect(counterB.testsOnly_parentReferences["root"]?.contains("ref_b") != true)
        #expect(update.update?.update == ["ref_a": .removed, "ref_b": .removed, "primitive": .removed])
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLO4e9/tombstone-map-parent-refs-0
    @Test
    func tombstoneMapRemovesParentReferencesForAllEntries() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)

        let childCounter = Self.makeCounter(objectID: "counter:child@1000", internalQueue: internalQueue)
        let childMap = Self.makeMap(objectID: "map:child@1000", internalQueue: internalQueue)
        pool.testsOnly_setEntry(.counter(childCounter), forObjectID: "counter:child@1000")
        pool.testsOnly_setEntry(.map(childMap), forObjectID: "map:child@1000")

        let map = Self.makeMap(
            objectID: "map:test@1000",
            data: [
                "counter_ref": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "counter:child@1000")),
                "map_ref": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(objectId: "map:child@1000")),
                "name": TestFactories.internalMapEntry(timeserial: "01", data: ProtocolTypes.ObjectData(string: "Alice")),
            ],
            internalQueue: internalQueue,
        )
        // Seed the object gate so the OBJECT_DELETE (serial "01", site "site1") passes RTLM15 (D-4)
        map.testsOnly_setSiteTimeserials(["site1": "00"])
        childCounter.testsOnly_setParentReferences(["map:test@1000": ["counter_ref"]])
        childMap.testsOnly_setParentReferences(["map:test@1000": ["map_ref"]])

        let msg = TestFactories.objectDeleteOperationMessage(objectId: "map:test@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: map, pool: &pool, internalQueue: internalQueue))

        #expect(map.testsOnly_isTombstone == true)
        #expect(map.testsOnly_data.isEmpty)
        // removeParentReference was called on both children
        #expect(childCounter.testsOnly_parentReferences["map:test@1000"]?.contains("counter_ref") != true)
        #expect(childMap.testsOnly_parentReferences["map:test@1000"]?.contains("map_ref") != true)
        #expect(update.update?.update == ["counter_ref": .removed, "map_ref": .removed, "name": .removed])
        #expect(update.tombstone == true)
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }
}
