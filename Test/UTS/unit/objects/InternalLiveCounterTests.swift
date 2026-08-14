// Derived from the UTS spec `objects/unit/internal_live_counter.md`.
//
// Drives the `InternalDefaultLiveCounter` CRDT node directly — the apply pipeline
// (`nosync_apply`, RTLC7/RTLC8/RTLC9 incl. RTLO4a serial gating), OBJECT_DELETE tombstoning
// (RTLO4e/RTLO5/RTLO6), and OBJECT_SYNC state ingestion (`nosync_replaceData`, RTLC6/RTLC14) — with
// no channel or connection. Nodes are built with `ObjectsUTS.makeCounter` /
// `createZeroValued`; inbound operation/state messages come from `ObjectsUTS.*` /
// `TestFactories.*`; every queue-confined `nosync_*` node call runs inside one
// `internalQueue.ably_syncNoDeadlock { … }` block (the harness pool/state holders
// `dispatchPrecondition`-assert their queue).
//
// Deviations from the UTS spec:
// - (RTLO4b4c1 / RTLC9h, deviations.md "noop increment shape") the COUNTER_INC noop is modelled as
//   an ABSENT `counterInc` (cocoa's `WireCounterInc.number` is non-optional), not the spec's
//   present-but-empty `counterInc: {}`; same RTLC9h branch. Built via `ObjectsUTS.counterIncNoopMessage`.
// - (S-3) The apply seam `nosync_apply` returns an OPTIONAL `LiveObjectUpdate` (nil ==
//   discarded, RTLC7g) rather than the spec's `applyOperation` Bool; `result == nil` is the spec's
//   `result == false`, `result != nil` its `true`/`IS NOT false`.
// - (S-4) The `replaceData` seam takes an `ObjectState` (+ serialTimestamp), not the full
//   ObjectMessage, and sync-originated updates carry no `objectMessage` (RTO4b2a) — so the spec's
//   `update.objectMessage == state_msg` is not assertable on the returned update; the state's
//   identity is preserved via the `ObjectState` passed in. Kept as an annotated comment per case.
//
// Infra-driving stand-ins (direct node seeding instead of `setup_synced_channel`, the
// `ably_syncNoDeadlock` queue confinement, the injected `MockSimpleClock`) are NOT deviations.

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct InternalLiveCounterTests {
    // MARK: - Helpers

    /// A zero-value ``InternalDefaultLiveCounter`` (RTLC4): the unit stand-in for the spec's
    /// `InternalLiveCounter(objectId:)` constructor.
    private static func makeCounter(objectID: String, internalQueue: DispatchQueue) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter.createZeroValued(
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: MockSimpleClock(),
        )
    }

    /// Applies an inbound operation message to the counter, on the internal queue. The spec's
    /// `counter.applyOperation(msg, source)`; returns the optional `LiveObjectUpdate` (S-3:
    /// nil == the spec's `false`).
    @discardableResult
    private static func apply(
        _ message: ProtocolTypes.InboundObjectMessage,
        source: ObjectsOperationSource,
        to counter: InternalDefaultLiveCounter,
        internalQueue: DispatchQueue,
    ) -> LiveObjectUpdate<DefaultLiveCounterUpdate>? {
        internalQueue.ably_syncNoDeadlock {
            var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)
            guard let operation = message.operation else {
                return nil
            }
            return counter.nosync_apply(operation, source: source, objectMessage: message, objectsPool: &pool)
        }
    }

    /// Replaces the counter's data from an OBJECT_SYNC `ObjectState`, on the internal queue. The
    /// spec's `counter.replaceData(state_msg)`.
    private static func replaceData(
        _ state: ProtocolTypes.ObjectState,
        on counter: InternalDefaultLiveCounter,
        internalQueue: DispatchQueue,
    ) -> LiveObjectUpdate<DefaultLiveCounterUpdate> {
        internalQueue.ably_syncNoDeadlock {
            counter.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil)
        }
    }

    // MARK: - RTLC4: Zero-value InternalLiveCounter

    // UTS: objects/unit/RTLC4/zero-value-0
    @Test
    func zeroValueCounter() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 0)
        #expect(counter.testsOnly_objectID == "counter:abc@1000")
        #expect(counter.testsOnly_isTombstone == false)
        #expect(counter.testsOnly_tombstonedAt == nil)
        #expect(counter.testsOnly_createOperationIsMerged == false)
        #expect(counter.testsOnly_siteTimeserials == [:])
    }

    // MARK: - RTLC9: COUNTER_INC adds number to data

    // UTS: objects/unit/RTLC9/counter-inc-basic-0
    @Test
    func counterIncBasic() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_data == 5) // RTLC9f
        #expect(update.isNoop == false)
        #expect(update.update?.amount == 5) // RTLC9g
        #expect(update.objectMessage == msg) // RTLC9g
    }

    // MARK: - RTLC9: COUNTER_INC with negative number

    // UTS: objects/unit/RTLC9/counter-inc-negative-0
    @Test
    func counterIncNegative() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 10, internalQueue: internalQueue)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: -3, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_data == 7)
        #expect(update.update?.amount == -3)
        #expect(update.objectMessage == msg)
    }

    // MARK: - RTLC9: COUNTER_INC with missing number is noop

    // UTS: objects/unit/RTLC9/counter-inc-missing-number-0
    @Test
    func counterIncMissingNumberIsNoop() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 10, internalQueue: internalQueue)

        // Test Steps
        // Spec: `counterInc: {}` (present but empty). Modelled as an ABSENT counterInc — the same
        // RTLC9h noop branch (deviations.md "noop increment shape").
        let msg = ObjectsUTS.counterIncNoopMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_data == 10)
        #expect(update.isNoop == true) // RTLC9h
    }

    // MARK: - RTLC9: Multiple COUNTER_INC operations accumulate

    // UTS: objects/unit/RTLC9/counter-inc-accumulate-0
    @Test
    func counterIncAccumulates() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        Self.apply(ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 10, serial: "01", siteCode: "site1"), source: .channel, to: counter, internalQueue: internalQueue)
        Self.apply(ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 20, serial: "02", siteCode: "site1"), source: .channel, to: counter, internalQueue: internalQueue)
        Self.apply(ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: -5, serial: "01", siteCode: "site2"), source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 25)
    }

    // MARK: - RTLC8, RTLC16: COUNTER_CREATE merges initial count

    // UTS: objects/unit/RTLC8/counter-create-merge-0
    @Test
    func counterCreateMergesInitialCount() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: 42, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_data == 42) // RTLC16a
        #expect(counter.testsOnly_createOperationIsMerged == true) // RTLC16b
        #expect(update.update?.amount == 42) // RTLC16c
        #expect(update.objectMessage == msg) // RTLC16c
    }

    // MARK: - RTLC8: COUNTER_CREATE noop when already merged

    // UTS: objects/unit/RTLC8/counter-create-already-merged-0
    @Test
    func counterCreateNoopWhenAlreadyMerged() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 42, internalQueue: internalQueue)
        counter.testsOnly_setCreateOperationIsMerged(true)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        // Test Steps
        let msg = TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: 99, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_data == 42)
        #expect(update.isNoop == true) // RTLC8b
    }

    // MARK: - RTLC16: COUNTER_CREATE with missing count is noop

    // UTS: objects/unit/RTLC16/counter-create-no-count-0
    @Test
    func counterCreateNoCountIsNoop() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: nil, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_data == 0)
        #expect(counter.testsOnly_createOperationIsMerged == true) // RTLC16b
        #expect(update.isNoop == true) // RTLC16d
    }

    // MARK: - RTLO4a: canApplyOperation allows when siteSerial is empty

    // UTS: objects/unit/RTLO4a/apply-empty-site-serial-0
    @Test
    func applyAllowedWhenSiteSerialEmpty() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let result = Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(result != nil) // RTLO4a5: applied (spec's `IS NOT false`; S-3)
        #expect(counter.testsOnly_data == 5)
    }

    // MARK: - RTLO4a: canApplyOperation rejects stale serial

    // UTS: objects/unit/RTLO4a/reject-stale-serial-0
    @Test
    func applyRejectsStaleSerial() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 10, internalQueue: internalQueue)
        counter.testsOnly_setSiteTimeserials(["site1": "05"])

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 99, serial: "03", siteCode: "site1")
        let result = Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(result == nil) // RTLO4a6 / RTLC7b: discarded (spec's `false`; S-3)
        #expect(counter.testsOnly_data == 10)
    }

    // MARK: - RTLO4a: canApplyOperation rejects equal serial

    // UTS: objects/unit/RTLO4a/reject-equal-serial-0
    @Test
    func applyRejectsEqualSerial() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 10, internalQueue: internalQueue)
        counter.testsOnly_setSiteTimeserials(["site1": "05"])

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 99, serial: "05", siteCode: "site1")
        let result = Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(result == nil) // RTLO4a6: serial must be strictly greater (S-3)
        #expect(counter.testsOnly_data == 10)
    }

    // MARK: - RTLO4a: canApplyOperation warns on empty serial or siteCode

    // UTS: objects/unit/RTLO4a/warn-invalid-serial-0
    @Test
    func applyWarnsOnEmptySerialOrSiteCode() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msgNoSerial = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "", siteCode: "site1")
        let result1 = Self.apply(msgNoSerial, source: .channel, to: counter, internalQueue: internalQueue)

        let msgNoSite = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "")
        let result2 = Self.apply(msgNoSite, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 0)
        #expect(result1 == nil) // RTLO4a3: not applied (S-3)
        #expect(result2 == nil)
    }

    // MARK: - RTLC7c: CHANNEL source updates siteTimeserials

    // UTS: objects/unit/RTLC7c/channel-source-updates-serials-0
    @Test
    func channelSourceUpdatesSiteTimeserials() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_siteTimeserials["site1"] == "01") // RTLC7c
    }

    // MARK: - RTLC7c: LOCAL source does not update siteTimeserials

    // UTS: objects/unit/RTLC7c/local-source-no-serial-update-0
    @Test
    func localSourceDoesNotUpdateSiteTimeserials() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        Self.apply(msg, source: .local, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_siteTimeserials == [:]) // RTLC7c: LOCAL leaves siteTimeserials untouched
        #expect(counter.testsOnly_data == 5)
    }

    // MARK: - RTLC7g: applyOperation returns true on success

    // UTS: objects/unit/RTLC7g/apply-returns-true-0
    @Test
    func applyReturnsTrueOnSuccess() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let result = Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(result != nil) // RTLC7g: applied (spec's `result == true`; S-3)
    }

    // MARK: - RTLO4e, RTLO5: OBJECT_DELETE tombstones counter

    // UTS: objects/unit/RTLO5/object-delete-tombstones-0
    @Test
    func objectDeleteTombstonesCounter() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 42, internalQueue: internalQueue)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        // Test Steps
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_isTombstone == true) // RTLO4e2
        #expect(counter.testsOnly_data == 0) // RTLO4e4
        #expect(counter.testsOnly_tombstonedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(update.update?.amount == -42) // RTLO4e5
        #expect(update.tombstone == true) // RTLO4e6
        #expect(update.objectMessage == msg) // RTLO4e7 / RTLC7d4c
    }

    // MARK: - RTLO5, RTLO4e5: OBJECT_DELETE on an already-zero counter still emits a non-noop tombstone update

    // UTS: objects/unit/RTLO5/tombstone-zero-value-counter-emits-update-0
    @Test
    func objectDeleteOnZeroValueCounterEmitsUpdate() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        // Test Steps
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue))

        // Assertions
        #expect(counter.testsOnly_isTombstone == true)
        #expect(counter.testsOnly_data == 0)
        // RTLC14c tombstone carve-out: the zero delta must NOT be marked a no-op (drives RTLO4b4c3c teardown).
        #expect(update.isNoop == false)
        #expect(update.tombstone == true) // RTLO4e6
        #expect(update.update?.amount == 0) // RTLO4e5
        #expect(update.objectMessage == msg) // RTLO4e7
    }

    // MARK: - RTLC7e: Operations on tombstoned counter are rejected

    // UTS: objects/unit/RTLC7e/tombstoned-reject-ops-0
    @Test
    func operationsOnTombstonedCounterRejected() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        // isTombstone is derived from tombstonedAt (RTLO3d): setting tombstonedAt makes it true.
        counter.testsOnly_setTombstonedAt(Date(timeIntervalSince1970: 1_700_000_000))

        // Test Steps
        let msg = ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let result = Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(result == nil) // RTLC7e: not applied (spec's `false`; S-3)
        #expect(counter.testsOnly_data == 0)
    }

    // MARK: - RTLO6: tombstonedAt from serialTimestamp

    // UTS: objects/unit/RTLO6/tombstoned-at-from-serial-timestamp-0
    @Test
    func tombstonedAtFromSerialTimestamp() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_050))
        Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_tombstonedAt == Date(timeIntervalSince1970: 1_700_000_050)) // RTLO6a
    }

    // MARK: - RTLO6: tombstonedAt from local clock when no serialTimestamp

    // UTS: objects/unit/RTLO6/tombstoned-at-local-clock-0
    @Test
    func tombstonedAtFromLocalClockWhenNoSerialTimestamp() throws {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        // The unit MockSimpleClock pins its `now` to its construction instant (the local-clock value
        // RTLO6b reads); capture `before` BEFORE constructing the counter so the wall-clock bracket
        // encloses that pinned instant. (Spec captures `before_time` after construction; the
        // observable requirement — tombstonedAt derives from the local clock, not a serialTimestamp —
        // is preserved.)
        let beforeTime = Date()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let msg = TestFactories.objectDeleteOperationMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1")
        Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        let afterTime = Date()
        let tombstonedAt = try #require(counter.testsOnly_tombstonedAt)
        #expect(tombstonedAt >= beforeTime) // RTLO6b
        #expect(tombstonedAt <= afterTime) // RTLO6b
    }

    // MARK: - RTLC7d3: Unsupported action is discarded

    // UTS: objects/unit/RTLC7d3/unsupported-action-0
    @Test
    func unsupportedActionDiscarded() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        // A MAP_SET operation targeting a counter — unsupported for LiveCounter (RTLC7d3).
        let msg = ObjectsUTS.mapSetMessage(objectId: "counter:abc@1000", key: "x", value: ProtocolTypes.ObjectData(string: "y"), serial: "01", siteCode: "site1")
        let result = Self.apply(msg, source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(result == nil) // RTLC7d3: discarded (spec's `false`; S-3)
        #expect(counter.testsOnly_data == 0)
    }

    // MARK: - RTLC6: replaceData sets data from ObjectState

    // UTS: objects/unit/RTLC6/replace-data-basic-0
    @Test
    func replaceDataSetsDataFromObjectState() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 10, internalQueue: internalQueue)
        counter.testsOnly_setCreateOperationIsMerged(true)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        // Test Steps
        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site2": "05"], count: 50)
        let update = Self.replaceData(state, on: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 50) // RTLC6c
        #expect(counter.testsOnly_siteTimeserials == ["site2": "05"]) // RTLC6a
        #expect(counter.testsOnly_createOperationIsMerged == false) // RTLC6b
        #expect(update.update?.amount == 40) // RTLC6h
        // ASSERT update.objectMessage == state_msg — not assertable: the replaceData seam takes an
        // ObjectState, and sync-originated updates carry no objectMessage (RTO4b2a; S-4).
    }

    // MARK: - RTLC6: replaceData with createOp merges initial value

    // UTS: objects/unit/RTLC6/replace-data-with-create-op-0
    @Test
    func replaceDataWithCreateOpMergesInitialValue() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        let state = TestFactories.counterObjectState(
            objectId: "counter:abc@1000",
            siteTimeserials: ["site1": "01"],
            createOp: TestFactories.counterCreateOperation(objectId: "counter:abc@1000", count: 50),
            count: 100,
        )
        let update = Self.replaceData(state, on: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 150) // RTLC6c + RTLC6d (100 + 50)
        #expect(counter.testsOnly_createOperationIsMerged == true) // RTLC6d / RTLC16b
        #expect(update.update?.amount == 150)
        // ASSERT update.objectMessage == state_msg — not assertable (RTO4b2a; S-4).
    }

    // MARK: - RTLC6e: replaceData on tombstoned counter is noop

    // UTS: objects/unit/RTLC6e/replace-data-tombstoned-noop-0
    @Test
    func replaceDataOnTombstonedCounterIsNoop() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setTombstonedAt(Date(timeIntervalSince1970: 1_700_000_000)) // isTombstone == true

        // Test Steps
        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], count: 999)
        let update = Self.replaceData(state, on: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 0)
        #expect(update.isNoop == true) // RTLC6e / RTLC6e1
    }

    // MARK: - RTLC6f: replaceData with tombstone flag tombstones counter

    // UTS: objects/unit/RTLC6f/replace-data-tombstone-flag-0
    @Test
    func replaceDataWithTombstoneFlagTombstonesCounter() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 30, internalQueue: internalQueue)

        // Test Steps
        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], tombstone: true, count: 0)
        let update = Self.replaceData(state, on: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_isTombstone == true) // RTLC6f
        #expect(counter.testsOnly_data == 0)
        #expect(update.update?.amount == -30) // RTLC6f2
        #expect(update.tombstone == true) // RTLO4e6
        // ASSERT update.objectMessage == state_msg — not assertable (RTO4b2a; S-4).
    }

    // MARK: - RTLC6: replaceData with missing counter.count defaults to 0

    // UTS: objects/unit/RTLC6/replace-data-missing-count-0
    @Test
    func replaceDataMissingCountDefaultsToZero() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 42, internalQueue: internalQueue)

        // Test Steps
        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], count: nil)
        let update = Self.replaceData(state, on: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 0) // RTLC6c: count absent defaults to 0
        #expect(update.update?.amount == -42)
        // ASSERT update.objectMessage == state_msg — not assertable (RTO4b2a; S-4).
    }

    // MARK: - RTLC14: Diff calculation

    // UTS: objects/unit/RTLC14/diff-calculation-0
    @Test
    func diffCalculation() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 20, internalQueue: internalQueue)

        // Test Steps
        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], count: 75)
        let update = Self.replaceData(state, on: counter, internalQueue: internalQueue)

        // Assertions
        #expect(update.update?.amount == 55) // RTLC14: newData - previousData (75 - 20)
        // ASSERT update.objectMessage == state_msg — not assertable (RTO4b2a; S-4).
    }

    // MARK: - RTLC14c: Zero-delta diff is a no-op

    // UTS: objects/unit/RTLC14c/zero-delta-diff-is-noop-0
    @Test
    func zeroDeltaDiffIsNoop() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = ObjectsUTS.makeCounter(objectID: "counter:abc@1000", data: 100, internalQueue: internalQueue)

        // Test Steps
        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], count: 100)
        let update = Self.replaceData(state, on: counter, internalQueue: internalQueue)

        // Assertions
        #expect(update.isNoop == true) // RTLC14c: zero delta -> noop (RTLO4b4b)
        #expect(counter.testsOnly_data == 100)
    }

    // MARK: - RTLC8, RTLC16: COUNTER_CREATE then COUNTER_INC accumulates

    // UTS: objects/unit/RTLC8/create-then-inc-0
    @Test
    func counterCreateThenIncAccumulates() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // Test Steps
        Self.apply(TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: 100, serial: "01", siteCode: "site1"), source: .channel, to: counter, internalQueue: internalQueue)
        Self.apply(ObjectsUTS.counterIncMessage(objectId: "counter:abc@1000", number: 25, serial: "02", siteCode: "site1"), source: .channel, to: counter, internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_data == 125)
        #expect(counter.testsOnly_createOperationIsMerged == true)
    }

    // MARK: - RTLO3: LiveObject properties initialized correctly

    // UTS: objects/unit/RTLO3/live-object-init-properties-0
    @Test
    func liveObjectInitProperties() {
        // Setup
        let internalQueue = ObjectsUTS.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:test@2000", internalQueue: internalQueue)

        // Assertions
        #expect(counter.testsOnly_objectID == "counter:test@2000") // RTLO3a1
        #expect(counter.testsOnly_siteTimeserials == [:]) // RTLO3b1
        #expect(counter.testsOnly_createOperationIsMerged == false) // RTLO3c1
        #expect(counter.testsOnly_isTombstone == false) // RTLO3d1
        #expect(counter.testsOnly_tombstonedAt == nil) // RTLO3e1
    }
}
