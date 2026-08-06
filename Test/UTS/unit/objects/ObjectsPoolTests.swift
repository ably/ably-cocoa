// Derived from the UTS spec `objects/unit/objects_pool.md`.
//
// Port of the `objects/unit/objects_pool.md` spec — the ObjectsPool data structure and the
// INITIALIZED -> SYNCING -> SYNCED sync state machine, driven end-to-end through
// `InternalDefaultRealtimeObjects` (the spec's monolithic `pool` splits across `ObjectsPool` +
// `InternalDefaultRealtimeObjects`; see the audit report §3.4).
//
// Name mapping (UTS pseudocode -> Swift):
// - `pool = ObjectsPool()`                 -> `makeRealtimeObjects(internalQueue:)`; the pool is read
//                                             back as `ro.testsOnly_objectsPool` (a struct *copy*, so
//                                             every read re-fetches it; its `Entry` values are class
//                                             instances, so `.root` is the live object).
// - `pool.syncState`                       -> `ro.testsOnly_syncState` (SYNCING/SYNCED/INITIALIZED).
// - `pool.processAttached(ProtocolMessage(flags: HAS_OBJECTS?))` -> `ro.nosync_onChannelAttached(hasObjects:)`.
//                                             The attach path ignores the channelSerial (it is only
//                                             consumed by the subsequent OBJECT_SYNC), so the spec's
//                                             `channelSerial:` on ATTACHED is dropped.
// - `pool.processObjectSync(build_object_sync_message(ch, cursor, [states]))`
//                                          -> `ro.nosync_handleObjectSyncProtocolMessage(objectMessages:
//                                             protocolMessageChannelSerial:)`. The UTS cursor
//                                             `"seq:"` (empty cursor) completes the sync (RTO5a4);
//                                             `"seq:more"` keeps it open (SYNCING).
// - `pool.processObjectMessage(build_object_message(ch, [ops]))`
//                                          -> `ro.nosync_handleObjectProtocolMessage(objectMessages:)`.
// - `pool.applyObjectMessages([...], source: LOCAL)` -> `ro.testsOnly_applyObjectMessages(_:source:)`.
// - `pool["id"] = obj` (seed)              -> `ro.testsOnly_setPoolEntry(.map(...) / .counter(...), forObjectID:)`.
// - `pool["root"].data = {…}` (seed)       -> seed a root `InternalDefaultLiveMap` built with
//                                             `testsOnly_data:` and install it via `testsOnly_setPoolEntry`.
// - `realtime_object.bufferedObjectOperations.length` -> `ro.testsOnly_bufferedObjectOperationsCount`
//                                             (nil unless SYNCING).
// - `realtime_object.appliedOnAckSerials`  -> `ro.testsOnly_appliedOnAckSerials`.
// - `pool["root"].subscribe(cb)`           -> `ro.testsOnly_objectsPool.root.subscribe(listener:coreSDK:)`
//                                             via a `Subscriber` (hence the iOS/tvOS 17 availability on
//                                             the two subscription-based cases, matching the existing
//                                             `InternalDefaultRealtimeObjectsTests` RTO4b test).
// - `build_object_state(id, sts, {map/counter, createOp})` -> `TestFactories.mapObjectState` /
//                                             `counterObjectState` (with `createOp:`), or a hand-built
//                                             `ObjectState` when a `clearTimeserial` is needed
//                                             (`TestFactories.mapObjectState` has no such param).
//
// Deviations from the UTS spec:
// - (D-1) Construction seam: the Swift engine needs logger/queue/callback-queue/clock, so `pool =
//   ObjectsPool()` maps to `makeRealtimeObjects(internalQueue:)`. Reads go through the `testsOnly_*`
//   seams above; every `nosync_*` entry point is wrapped in `internalQueue.ably_syncNoDeadlock { }`.
// - (D-2) `pool.syncState == INITIALIZED` at construction is asserted via `ro.testsOnly_syncState`;
//   the spec's direct `pool.syncState = SYNCED` seed maps to `nosync_onChannelAttached(hasObjects:
//   false)`, which performs the RTO4b immediate sync completion (INITIALIZED -> SYNCED) and leaves an
//   empty pool — equivalent to the spec's intent of "start from a SYNCED empty pool".
// - (D-3) `objectMessage IS null` (RTO4b2a / RTO5c7): the sync-originated update carries
//   `DefaultLiveMapUpdate.objectMessage == nil`; asserted directly on the captured update.
// - (D-4) RTO9a3 seeding: the spec seeds `appliedOnAckSerials = {"echo-serial-1"}` and
//   `counter.data = 10` directly. With no direct serial setter, the serial is armed the way it is in
//   production — a LOCAL apply (`testsOnly_applyObjectMessages(source: .local)`) of a COUNTER_INC of
//   `0` carrying that serial (RTO9a2a4 inserts it; `+0` keeps the seeded value at 10).
// - (D-5) SKIPPED — `objects/unit/RTO7-RTO8/buffer-without-attached-0`: the spec asserts that an
//   OBJECT message received in INITIALIZED (no preceding ATTACHED) is BUFFERED. cocoa deliberately
//   diverges: `nosync_handleObjectProtocolMessage` buffers only in `.syncing`, and applies
//   immediately otherwise (InternalDefaultRealtimeObjects.swift, with an explicit comment that
//   "operations only arrive once attached, and we become SYNCING upon receipt of ATTACHED", so the
//   INITIALIZED-buffer branch is unreachable in practice). The case cannot pass as written; reported
//   as a deviation candidate.
// - (D-6) SKIPPED (cross-reference, not duplicated) — the three `objects/unit/RTO5c10/*` cases
//   (sync-rebuilds / resync-rebuilds / empty-sync parentReferences) are already ported in
//   `UTS/ParentReferencesTests.swift` (its RTO5c10 section). See that file.
// - (D-7) IMPLEMENTATION FIX (surfaced by the RTO9a2b case, like D-11 of the map port): cocoa
//   created the RTO9a2a1 zero-value object BEFORE checking the action, so an unsupported-action
//   OBJECT message left a spurious zero-value object in the pool (the case here asserts pool size
//   1, i.e. only root). Fixed minimally in `Sources/AblyLiveObjects/Internal/
//   InternalDefaultRealtimeObjects.swift`: the RTO9a2b unknown-action guard now runs before the
//   object creation, matching ably-java (`ObjectsManager.applyObjectMessages`, whose RTO9a3 comment
//   likewise notes the discard checks must precede creation).

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct ObjectsPoolTests {
    // MARK: - Helpers (D-1)

    private static func makeRealtimeObjects(internalQueue: DispatchQueue) -> InternalDefaultRealtimeObjects {
        InternalDefaultRealtimeObjects(
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
            channelName: "test-channel",
        )
    }

    private static func coreSDK(internalQueue: DispatchQueue) -> MockCoreSDK {
        MockCoreSDK(channelState: .attached, internalQueue: internalQueue)
    }

    private static func attach(_ ro: InternalDefaultRealtimeObjects, hasObjects: Bool, internalQueue: DispatchQueue) {
        internalQueue.ably_syncNoDeadlock {
            ro.nosync_onChannelAttached(hasObjects: hasObjects)
        }
    }

    /// Note the `messages` array is the trailing parameter so multiline call sites keep every scalar
    /// argument on the opening line (SwiftLint `multiline_arguments`).
    private static func processSync(
        _ ro: InternalDefaultRealtimeObjects,
        channelSerial: String?,
        internalQueue: DispatchQueue,
        _ messages: [ProtocolTypes.InboundObjectMessage],
    ) {
        internalQueue.ably_syncNoDeadlock {
            ro.nosync_handleObjectSyncProtocolMessage(objectMessages: messages, protocolMessageChannelSerial: channelSerial)
        }
    }

    private static func processObject(
        _ ro: InternalDefaultRealtimeObjects,
        internalQueue: DispatchQueue,
        _ messages: [ProtocolTypes.InboundObjectMessage],
    ) {
        internalQueue.ably_syncNoDeadlock {
            ro.nosync_handleObjectProtocolMessage(objectMessages: messages)
        }
    }

    /// Wraps an `ObjectState` as an OBJECT_SYNC `InboundObjectMessage` (`build_object_state` -> a sync
    /// message's `object`).
    private static func syncMsg(_ state: ProtocolTypes.ObjectState) -> ProtocolTypes.InboundObjectMessage {
        TestFactories.inboundObjectMessage(object: state)
    }

    /// The standard `build_object_state("root", {"aaa": "t:0"}, { map: {…}, createOp: mapCreate {} })`
    /// — a sync-completing root map with the given entries and an (empty) create op.
    private static func rootState(entries: [String: ProtocolTypes.ObjectsMapEntry]? = nil) -> ProtocolTypes.ObjectState {
        TestFactories.mapObjectState(
            objectId: "root",
            siteTimeserials: ["aaa": "t:0"],
            createOp: TestFactories.mapCreateOperation(objectId: "root", entries: [:]),
            entries: entries,
        )
    }

    /// `build_object_state(id, {"aaa": "t:0"}, { counter: { count }, createOp?: counterCreate { createCount } })`.
    private static func counterState(objectId: String, count: Int, createCount: Int?) -> ProtocolTypes.ObjectState {
        TestFactories.counterObjectState(
            objectId: objectId,
            siteTimeserials: ["aaa": "t:0"],
            createOp: createCount.map { TestFactories.counterCreateOperation(objectId: objectId, count: $0) },
            count: count,
        )
    }

    /// A single-entry string map entry with the given serial (`{ data: { string }, timeserial }`).
    private static func stringEntry(_ value: String, timeserial: String) -> ProtocolTypes.ObjectsMapEntry {
        TestFactories.mapEntry(timeserial: timeserial, data: ProtocolTypes.ObjectData(string: value))
    }

    /// Builds a root `InternalDefaultLiveMap` pre-seeded with `data`, for the `pool["root"].data = {…}`
    /// seed cases (installed via `testsOnly_setPoolEntry`).
    private static func seededRoot(data: [String: InternalObjectsMapEntry], internalQueue: DispatchQueue) -> InternalDefaultLiveMap {
        InternalDefaultLiveMap(
            testsOnly_data: data,
            objectID: "root",
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    private static func seededCounter(objectID: String, data: Double, internalQueue: DispatchQueue) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter(
            testsOnly_data: data,
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    /// A seeded string `InternalObjectsMapEntry` (`{ data: { string }, timeserial, tombstone: false }`).
    private static func seededStringEntry(_ value: String, timeserial: String) -> InternalObjectsMapEntry {
        InternalObjectsMapEntry(tombstonedAt: nil, timeserial: timeserial, data: ProtocolTypes.ObjectData(string: value))
    }

    // MARK: - RTO3

    // UTS: objects/unit/RTO3/pool-init-root-0
    @Test
    func poolInitialisesWithZeroValueRoot() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        let pool = ro.testsOnly_objectsPool
        // RTO3b, RTO3b1: pool always contains a zero-value InternalLiveMap with id "root".
        let root = try #require(pool.entries["root"]?.mapValue)
        #expect(pool.entries["root"] != nil)
        #expect(root.testsOnly_data.isEmpty)
        #expect(root.testsOnly_objectID == "root")
    }

    // MARK: - RTO4a

    // UTS: objects/unit/RTO4/attached-has-objects-syncing-0
    @Test
    func attachedWithHasObjectsStartsSyncing() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)

        // RTO4c: sync state transitions to SYNCING (server will send OBJECT_SYNC, RTO4a).
        #expect(ro.testsOnly_syncState == .syncing)
    }

    // MARK: - RTO4b

    // UTS: objects/unit/RTO4b/attached-no-objects-synced-0
    @available(iOS 17.0.0, tvOS 17.0.0, *)
    @Test
    func attachedWithoutHasObjectsClearsPoolAndSyncs() async throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        // Seed a non-root object and root data (spec setup).
        ro.testsOnly_setPoolEntry(.counter(Self.seededCounter(objectID: "counter:abc@1000", data: 0, internalQueue: internalQueue)), forObjectID: "counter:abc@1000")
        let root = Self.seededRoot(data: ["name": Self.seededStringEntry("Alice", timeserial: "01")], internalQueue: internalQueue)
        ro.testsOnly_setPoolEntry(.map(root), forObjectID: "root")

        let subscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
        try root.subscribe(listener: subscriber.createListener(), coreSDK: Self.coreSDK(internalQueue: internalQueue))

        Self.attach(ro, hasObjects: false, internalQueue: internalQueue)

        let pool = ro.testsOnly_objectsPool
        #expect(ro.testsOnly_syncState == .synced)
        // RTO4b1: all objects except root removed; RTO3b: root remains.
        #expect(pool.entries["counter:abc@1000"] == nil)
        #expect(pool.entries["root"] != nil)
        // RTO4b2: root cleared to zero-value.
        #expect(try #require(pool.entries["root"]?.mapValue).testsOnly_data.isEmpty)

        // RTO4b2a: a `removed` update was emitted for the removed key, WITHOUT an objectMessage.
        let invocations = await subscriber.getInvocations()
        let update = try #require(invocations.map(\.0).first)
        #expect(update.update == ["name": .removed])
        #expect(update.objectMessage == nil)
    }

    // MARK: - RTO5

    // UTS: objects/unit/RTO5/sync-complete-sequence-0
    @Test
    func objectSyncCompleteSequence() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState(entries: ["name": Self.stringEntry("Alice", timeserial: "t:0")])),
            Self.syncMsg(Self.counterState(objectId: "counter:abc@1000", count: 0, createCount: 42)),
        ])

        let pool = ro.testsOnly_objectsPool
        // RTO5a4, RTO5c8: cursor empty -> sync complete -> SYNCED.
        #expect(ro.testsOnly_syncState == .synced)
        #expect(pool.entries["root"] != nil)
        #expect(pool.entries["counter:abc@1000"] != nil)
        // RTO5f1: entries stored from server state.
        #expect(try #require(pool.entries["root"]?.mapValue).testsOnly_data["name"]?.data?.string == "Alice")
        // count 0 (RTLC6c) + createOp 42 (RTLC16a) = 42.
        #expect(try #require(pool.entries["counter:abc@1000"]?.counterValue).value(coreSDK: coreSDK) == 42)
    }

    // MARK: - RTO5a2

    // UTS: objects/unit/RTO5a2/new-sequence-discards-old-0
    @Test
    func newSyncSequenceDiscardsPrevious() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        // First sequence (kept open).
        Self.processSync(ro, channelSerial: "seq1:more", internalQueue: internalQueue, [
            Self.syncMsg(Self.counterState(objectId: "counter:old@1000", count: 10, createCount: nil)),
        ])

        // New sequence id -> RTO5a2a discards the previous SyncObjectsPool; empty cursor completes.
        Self.processSync(ro, channelSerial: "seq2:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
            Self.syncMsg(Self.counterState(objectId: "counter:new@1000", count: 99, createCount: nil)),
        ])

        let pool = ro.testsOnly_objectsPool
        #expect(ro.testsOnly_syncState == .synced)
        #expect(pool.entries["counter:old@1000"] == nil)
        #expect(pool.entries["counter:new@1000"] != nil)
    }

    // MARK: - RTO5f2a

    // UTS: objects/unit/RTO5f2a/partial-map-merge-0
    @Test
    func partialObjectStateMergeForMaps() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        // First partial state for root (sequence kept open); no createOp.
        Self.processSync(ro, channelSerial: "sync1:more", internalQueue: internalQueue, [
            Self.syncMsg(TestFactories.mapObjectState(
                objectId: "root",
                siteTimeserials: ["aaa": "t:0"],
                entries: ["name": Self.stringEntry("Alice", timeserial: "t:0")],
            )),
        ])

        // Second partial state for root; empty cursor completes.
        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState(entries: ["age": TestFactories.mapEntry(timeserial: "t:0", data: ProtocolTypes.ObjectData(number: NSNumber(value: 30)))])),
        ])

        // RTO5f2a2: entries merged across the two partial states.
        let root = try #require(ro.testsOnly_objectsPool.entries["root"]?.mapValue)
        #expect(root.testsOnly_data["name"]?.data?.string == "Alice")
        #expect(root.testsOnly_data["age"]?.data?.number == NSNumber(value: 30))
    }

    // MARK: - RTO5c2

    // UTS: objects/unit/RTO5c2/remove-absent-objects-0
    @Test
    func syncCompletionRemovesObjectsNotInSync() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        ro.testsOnly_setPoolEntry(.counter(Self.seededCounter(objectID: "counter:old@1000", data: 99, internalQueue: internalQueue)), forObjectID: "counter:old@1000")
        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)

        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
        ])

        let pool = ro.testsOnly_objectsPool
        // RTO5c2: object not received during sync removed; RTO5c2a: root kept.
        #expect(pool.entries["counter:old@1000"] == nil)
        #expect(pool.entries["root"] != nil)
    }

    // MARK: - RTO5c9

    // UTS: objects/unit/RTO5c9/clear-applied-on-ack-serials-0
    @Test
    func syncCompletionClearsAppliedOnAckSerials() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        // Reach SYNCED, seed a counter, then arm appliedOnAckSerials via a LOCAL apply (D-4).
        Self.attach(ro, hasObjects: false, internalQueue: internalQueue)
        ro.testsOnly_setPoolEntry(.counter(Self.seededCounter(objectID: "counter:abc@1000", data: 0, internalQueue: internalQueue)), forObjectID: "counter:abc@1000")
        ro.testsOnly_applyObjectMessages([
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 0, serial: "serial-1", siteCode: "site1"),
        ], source: .local)
        #expect(ro.testsOnly_appliedOnAckSerials.contains("serial-1"))

        // A subsequent sync must clear the set (RTO5c9).
        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
        ])

        #expect(ro.testsOnly_appliedOnAckSerials.isEmpty)
    }

    // MARK: - RTO7, RTO8a

    // UTS: objects/unit/RTO8a/buffer-during-syncing-0
    @Test
    func objectMessagesBufferedDuringSyncing() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1"),
        ])

        // RTO8a: buffered while SYNCING; RTO7a: buffer is an array (count 1); object not yet in pool.
        #expect(ro.testsOnly_syncState == .syncing)
        #expect(ro.testsOnly_bufferedObjectOperationsCount == 1)
        #expect(ro.testsOnly_objectsPool.entries["counter:abc@1000"] == nil)
    }

    // MARK: - RTO5c6, RTO8b

    // UTS: objects/unit/RTO5c6/apply-buffered-on-sync-0
    @Test
    func bufferedOperationsAppliedOnSyncCompletion() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 10, serial: "02", siteCode: "site1"),
        ])

        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
            Self.syncMsg(Self.counterState(objectId: "counter:abc@1000", count: 0, createCount: 100)),
        ])

        // RTO5c6: buffered op applied (source CHANNEL) after sync -> 100 (create) + 10 (buffered inc).
        #expect(try #require(ro.testsOnly_objectsPool.entries["counter:abc@1000"]?.counterValue).value(coreSDK: coreSDK) == 110)
        #expect(ro.testsOnly_bufferedObjectOperationsCount == nil) // no longer SYNCING
    }

    // MARK: - RTO9a1

    // UTS: objects/unit/RTO9a1/null-operation-warning-0
    @Test
    func nullOperationIsDiscarded() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: false, internalQueue: internalQueue) // reach SYNCED
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.inboundObjectMessage(operation: nil, serial: "01", siteCode: "site1"),
        ])

        // RTO9a1: message with no operation discarded (no object created; only root remains).
        #expect(ro.testsOnly_objectsPool.entries.count == 1)
    }

    // MARK: - RTO9a3

    // UTS: objects/unit/RTO9a3/dedup-applied-on-ack-0
    @Test
    func appliedOnAckSerialsDeduplication() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: false, internalQueue: internalQueue) // reach SYNCED
        ro.testsOnly_setPoolEntry(.counter(Self.seededCounter(objectID: "counter:abc@1000", data: 10, internalQueue: internalQueue)), forObjectID: "counter:abc@1000")
        // Arm appliedOnAckSerials = {"echo-serial-1"} via a LOCAL +0 apply (D-4).
        ro.testsOnly_applyObjectMessages([
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 0, serial: "echo-serial-1", siteCode: "site1"),
        ], source: .local)
        #expect(ro.testsOnly_appliedOnAckSerials.contains("echo-serial-1"))

        // Echoed OBJECT message with the same serial -> discarded, serial removed.
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "echo-serial-1", siteCode: "site2"),
        ])

        #expect(try #require(ro.testsOnly_objectsPool.entries["counter:abc@1000"]?.counterValue).value(coreSDK: coreSDK) == 10)
        #expect(!ro.testsOnly_appliedOnAckSerials.contains("echo-serial-1"))
    }

    // MARK: - RTO9a2a4

    // UTS: objects/unit/RTO9a2a4/local-source-adds-serial-0
    @Test
    func localSourceAddsSerialToAppliedOnAckSerials() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: false, internalQueue: internalQueue) // reach SYNCED
        ro.testsOnly_setPoolEntry(.counter(Self.seededCounter(objectID: "counter:abc@1000", data: 0, internalQueue: internalQueue)), forObjectID: "counter:abc@1000")

        ro.testsOnly_applyObjectMessages([
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "local-serial-1", siteCode: "test-site"),
        ], source: .local)

        // RTO9a2a4: LOCAL + applied -> serial added; the operation was applied (0 + 5).
        #expect(ro.testsOnly_appliedOnAckSerials.contains("local-serial-1"))
        #expect(try #require(ro.testsOnly_objectsPool.entries["counter:abc@1000"]?.counterValue).value(coreSDK: coreSDK) == 5)
    }

    // MARK: - RTO9a2b

    // UTS: objects/unit/RTO9a2b/unsupported-action-warning-0
    @Test
    func unsupportedActionIsDiscarded() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: false, internalQueue: internalQueue) // reach SYNCED
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.inboundObjectMessage(
                // `.unknown(999)` — an unrecognised action code (the enum is Int-raw); mirrors the
                // spec's `action: "UNKNOWN_ACTION"`.
                operation: TestFactories.objectOperation(action: .unknown(999), objectId: "counter:abc@1000"),
                serial: "01",
                siteCode: "site1",
            ),
        ])

        // RTO9a2b: unsupported action discarded (no object created; only root remains).
        #expect(ro.testsOnly_objectsPool.entries.count == 1)
    }

    // MARK: - RTO6

    // UTS: objects/unit/RTO6/zero-value-from-prefix-0
    @Test
    func zeroValueObjectCreationFromObjectIdPrefix() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: false, internalQueue: internalQueue) // reach SYNCED

        // RTO6b3: "counter" prefix -> zero-value InternalLiveCounter.
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.counterIncOperationMessage(objectId: "counter:new@2000", number: 5, serial: "01", siteCode: "site1"),
        ])
        // RTO6b2: "map" prefix -> zero-value InternalLiveMap.
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.mapSetOperationMessage(objectId: "map:new@2000", key: "key", value: "val", serial: "01", siteCode: "site1"),
        ])

        let pool = ro.testsOnly_objectsPool
        let counter = try #require(pool.entries["counter:new@2000"]?.counterValue)
        #expect(try counter.value(coreSDK: coreSDK) == 5)
        let map = try #require(pool.entries["map:new@2000"]?.mapValue)
        #expect(map.testsOnly_data["key"]?.data?.string == "val")
    }

    // MARK: - RTO5d

    // UTS: objects/unit/RTO5d/null-object-skipped-0
    @Test
    func objectSyncWithNullObjectFieldIsSkipped() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            TestFactories.inboundObjectMessage(object: nil), // RTO5d: null object -> skipped
            Self.syncMsg(Self.rootState()),
        ])

        // The null-object message is skipped but the sync still completes.
        #expect(ro.testsOnly_syncState == .synced)
    }

    // MARK: - RTO5f3

    // UTS: objects/unit/RTO5f3/unsupported-type-skipped-0
    @Test
    func objectSyncWithUnsupportedObjectTypeIsSkipped() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
            // Neither map nor counter present -> RTO5f3 log warning and skip.
            Self.syncMsg(ProtocolTypes.ObjectState(objectId: "unknown:xyz@1000", siteTimeserials: [:], tombstone: false, createOp: nil, map: nil, counter: nil)),
        ])

        let pool = ro.testsOnly_objectsPool
        #expect(ro.testsOnly_syncState == .synced)
        #expect(pool.entries["unknown:xyz@1000"] == nil)
    }

    // MARK: - RTO5e

    // UTS: objects/unit/RTO5e/object-sync-transitions-syncing-0
    @Test
    func objectSyncTransitionsToSyncing() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        // No preceding ATTACHED; an in-progress OBJECT_SYNC (non-empty cursor) transitions to SYNCING.
        Self.processSync(ro, channelSerial: "sync1:more", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
        ])

        #expect(ro.testsOnly_syncState == .syncing)
    }

    // MARK: - RTO5c7

    // UTS: objects/unit/RTO5c7/sync-emits-updates-0
    @available(iOS 17.0.0, tvOS 17.0.0, *)
    @Test
    func syncCompletionEmitsUpdatesForExistingObjects() async throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        let root = Self.seededRoot(data: ["name": Self.seededStringEntry("Old", timeserial: "01")], internalQueue: internalQueue)
        ro.testsOnly_setPoolEntry(.map(root), forObjectID: "root")

        let subscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
        try root.subscribe(listener: subscriber.createListener(), coreSDK: Self.coreSDK(internalQueue: internalQueue))

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState(entries: ["name": Self.stringEntry("New", timeserial: "t:0")])),
        ])

        // RTO5c7: the previously-existing root emits its stored update; "name" changed -> updated.
        let invocations = await subscriber.getInvocations()
        let update = try #require(invocations.map(\.0).first { $0.update["name"] != nil })
        #expect(update.update["name"] == .updated)
    }

    // MARK: - RTO5f2b

    // UTS: objects/unit/RTO5f2b/partial-counter-error-0
    @Test
    func partialCounterStateIsSkipped() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync1:more", internalQueue: internalQueue, [
            Self.syncMsg(Self.counterState(objectId: "counter:abc@1000", count: 10, createCount: nil)),
        ])
        // Second partial counter state for the same object -> RTO5f2b log error and skip (keep 10).
        Self.processSync(ro, channelSerial: "sync1:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
            Self.syncMsg(Self.counterState(objectId: "counter:abc@1000", count: 5, createCount: nil)),
        ])

        #expect(try #require(ro.testsOnly_objectsPool.entries["counter:abc@1000"]?.counterValue).value(coreSDK: coreSDK) == 10)
    }

    // MARK: - RTO4d

    // UTS: objects/unit/RTO4d/attached-clears-buffer-0
    @Test
    func attachedClearsBufferedOperations() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1"),
        ])
        #expect(ro.testsOnly_bufferedObjectOperationsCount == 1)

        // RTO4d: a new ATTACHED clears bufferedObjectOperations.
        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        #expect(ro.testsOnly_bufferedObjectOperationsCount == 0)
    }

    // MARK: - RTO4, RTO5

    // UTS: objects/unit/RTO4-RTO5/attached-during-syncing-resets-0
    @Test
    func attachedDuringSyncingResetsSync() {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync1:more", internalQueue: internalQueue, [
            Self.syncMsg(Self.counterState(objectId: "counter:old@1000", count: 10, createCount: nil)),
        ])
        #expect(ro.testsOnly_syncState == .syncing)

        // A new ATTACHED during SYNCING resets the state machine; the fresh sync completes.
        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processSync(ro, channelSerial: "sync2:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
            Self.syncMsg(Self.counterState(objectId: "counter:new@1000", count: 99, createCount: nil)),
        ])

        let pool = ro.testsOnly_objectsPool
        #expect(ro.testsOnly_syncState == .synced)
        #expect(pool.entries["counter:old@1000"] == nil)
        #expect(pool.entries["counter:new@1000"] != nil)
    }

    // MARK: - RTO5, RTO7

    // UTS: objects/unit/RTO5-RTO7/new-sync-keeps-buffer-0
    @Test
    func newObjectSyncSequenceDoesNotClearBuffer() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let ro = Self.makeRealtimeObjects(internalQueue: internalQueue)
        let coreSDK = Self.coreSDK(internalQueue: internalQueue)

        Self.attach(ro, hasObjects: true, internalQueue: internalQueue)
        Self.processObject(ro, internalQueue: internalQueue, [
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1"),
        ])
        #expect(ro.testsOnly_bufferedObjectOperationsCount == 1)

        // A new OBJECT_SYNC sequence discards only the SyncObjectsPool; the buffer is retained and
        // applied on completion -> 100 (create) + 5 (retained buffered inc).
        Self.processSync(ro, channelSerial: "seq2:", internalQueue: internalQueue, [
            Self.syncMsg(Self.rootState()),
            Self.syncMsg(Self.counterState(objectId: "counter:abc@1000", count: 0, createCount: 100)),
        ])

        #expect(ro.testsOnly_syncState == .synced)
        #expect(try #require(ro.testsOnly_objectsPool.entries["counter:abc@1000"]?.counterValue).value(coreSDK: coreSDK) == 105)
    }
}
