// Derived from the UTS spec `objects/unit/internal_live_counter.md`.
//
// Full port of `objects/unit/internal_live_counter.md`: every case in that spec file. These drive
// `InternalDefaultLiveCounter` directly (no channel/connection infra), exercising the CRDT: zero
// value, COUNTER_INC / COUNTER_CREATE application, the RTLO4a serial gate, CHANNEL/LOCAL source
// handling, OBJECT_DELETE tombstoning, and `replaceData` (the sync path).
//
// Deviations from the UTS spec:
// - (D-1) Construction: the spec writes `InternalLiveCounter(objectId:)`. The Swift counter needs a
//   logger/queue/callback-queue/clock, so it is built via
//   `InternalDefaultLiveCounter.createZeroValued(...)` (the `makeCounter` helper). Standard mock
//   preamble per the audit §2.
// - (D-2) Queue discipline: every mutating `nosync_*` entry point (`nosync_apply`,
//   `nosync_replaceData`) runs inside `internalQueue.ably_syncNoDeadlock { }`. Construction-time
//   `testsOnly_set*` seams hop onto the queue themselves, so setup writes are called WITHOUT the
//   wrapper (calling them inside it would re-enter the queue mutex).
// - (D-3) Setup writes: the spec assigns internal state directly (`counter.data = 10`,
//   `counter.siteTimeserials = {…}`, `counter.createOperationIsMerged = true`,
//   `counter.isTombstone = true` / `counter.tombstonedAt = …`). These map to the Phase-0 seams
//   `testsOnly_setData`, `testsOnly_setSiteTimeserials`, `testsOnly_setCreateOperationIsMerged`,
//   `testsOnly_setTombstonedAt` (isTombstone is computed from tombstonedAt, so a non-nil
//   `tombstonedAt` makes `isTombstone` true).
// - (D-4) Message decomposition: `counter.applyOperation(msg, source)` maps to
//   `counter.nosync_apply(operation, source:, objectMessageSerial:, objectMessageSiteCode:,
//   objectMessageSerialTimestamp:, sourceObjectMessage:, objectsPool:&)`. The spec's built `msg` is
//   produced by `TestFactories` builders and decomposed into its operation + serial + siteCode +
//   serialTimestamp; the PAOM3 public form `msg.toPublicObjectMessage(channelName:)` is passed as
//   `sourceObjectMessage` (RTLO4b4d) so the returned update carries it.
// - (D-5) `nosync_apply` returns `LiveObjectUpdate<…>?`: `nil` == the operation was gate-rejected
//   (RTLC7g). So the spec's `result == false` maps to `== nil`, `result IS NOT false` / `result ==
//   true` to `!= nil`; `update.noop` maps to `.isNoop`; `update.update.amount` to `update.update?.amount`.
// - (D-6) `update.objectMessage == msg`: the enriched update carries the public `ObjectMessage`
//   (RTLO4b4d), asserted via field-level equality against `msg.toPublicObjectMessage(channelName:)`.
//   `update.tombstone == true` maps to `update.tombstone` (RTLO4b4e, via `LiveObjectUpdatePayload`).
// - (D-7) RTO4b2a — the sync path (`nosync_replaceData`) is sync-originated, so its returned update
//   carries `objectMessage == nil`. The spec's `ASSERT update.objectMessage == state_msg` for the
//   RTLC6 / RTLC6f / RTLC14 cases therefore does NOT hold in cocoa; those are asserted as
//   `update.objectMessage == nil` (the tombstone flag and amount ARE still carried and asserted).
// - (D-8) Reading `counter.data`: no plain getter — read via `counter.value(coreSDK:)` with a
//   `MockCoreSDK` in a non-DETACHED/FAILED state (`.attaching`).
// - (D-9) `counterInc: {}` (operation present, `number` absent) is not constructible —
//   `WireCounterInc.number` is non-optional; translated as an operation with `counterInc: nil`
//   (functionally identical — no number present).
// - (D-10) Time: the spec's epoch-millis ints map to `Date(timeIntervalSince1970:)` seconds; the
//   local clock (RTLO6b) is a controllable `MockSimpleClock`, so the "tombstonedAt from local clock"
//   case asserts exact equality to the mock clock's time rather than a before/after range.

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct InternalLiveCounterTests {
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

    private static func makeCounter(objectID: String, internalQueue: DispatchQueue, clock: SimpleClock) -> InternalDefaultLiveCounter {
        InternalDefaultLiveCounter.createZeroValued(
            objectID: objectID,
            logger: TestLogger(),
            internalQueue: internalQueue,
            userCallbackQueue: .main,
            clock: clock,
        )
    }

    private static func makePool(internalQueue: DispatchQueue) -> ObjectsPool {
        ObjectsPool(logger: TestLogger(), internalQueue: internalQueue, userCallbackQueue: .main, clock: MockSimpleClock())
    }

    /// Reads `counter.data` via `value(coreSDK:)` (D-8).
    private static func data(of counter: InternalDefaultLiveCounter, internalQueue: DispatchQueue) throws -> Double {
        try counter.value(coreSDK: MockCoreSDK(channelState: .attaching, internalQueue: internalQueue))
    }

    /// Drives the gated `nosync_apply` from an inbound message, decomposing it (D-4) and passing its
    /// PAOM3 public form as `sourceObjectMessage`.
    private static func apply(
        _ message: ProtocolTypes.InboundObjectMessage,
        to counter: InternalDefaultLiveCounter,
        source: ObjectsOperationSource = .channel,
        pool: inout ObjectsPool,
        internalQueue: DispatchQueue,
    ) throws -> LiveObjectUpdate<DefaultLiveCounterUpdate>? {
        let operation = try #require(message.operation)
        return internalQueue.ably_syncNoDeadlock {
            counter.nosync_apply(
                operation,
                source: source,
                objectMessageSerial: message.serial,
                objectMessageSiteCode: message.siteCode,
                objectMessageSerialTimestamp: message.serialTimestamp,
                sourceObjectMessage: message.toPublicObjectMessage(channelName: channelName),
                objectsPool: &pool,
            )
        }
    }

    // MARK: - RTLC4

    // UTS: objects/unit/RTLC4/zero-value-0
    @Test
    func zeroValueCounter() {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        #expect(counter.testsOnly_objectID == "counter:abc@1000")
        #expect(counter.testsOnly_isTombstone == false)
        #expect(counter.testsOnly_tombstonedAt == nil)
        #expect(counter.testsOnly_createOperationIsMerged == false)
        #expect(counter.testsOnly_siteTimeserials.isEmpty)
    }

    // MARK: - RTLC9: COUNTER_INC

    // UTS: objects/unit/RTLC9/counter-inc-basic-0
    @Test
    func counterIncAddsNumberToData() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue))

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 5)
        #expect(update.isNoop == false)
        #expect(update.update?.amount == 5)
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLC9/counter-inc-negative-0
    @Test
    func counterIncWithNegativeNumber() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(10)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: -3, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue))

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 7)
        #expect(update.update?.amount == -3)
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLC9/counter-inc-missing-number-0
    @Test
    func counterIncWithMissingNumberIsNoop() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(10)

        // D-9: counterInc present but number absent -> operation with counterInc: nil
        let msg = TestFactories.inboundObjectMessage(
            operation: TestFactories.objectOperation(action: .known(.counterInc), objectId: "counter:abc@1000", counterInc: nil),
            serial: "01",
            siteCode: "site1",
        )
        let update = try #require(Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue))

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 10)
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLC9/counter-inc-accumulate-0
    @Test
    func multipleCounterIncOperationsAccumulate() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        _ = try Self.apply(TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 10, serial: "01", siteCode: "site1"), to: counter, pool: &pool, internalQueue: internalQueue)
        _ = try Self.apply(TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 20, serial: "02", siteCode: "site1"), to: counter, pool: &pool, internalQueue: internalQueue)
        _ = try Self.apply(TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: -5, serial: "01", siteCode: "site2"), to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 25)
    }

    // MARK: - RTLC8, RTLC16: COUNTER_CREATE

    // UTS: objects/unit/RTLC8/counter-create-merge-0
    @Test
    func counterCreateMergesInitialCount() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: 42, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue))

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 42)
        #expect(counter.testsOnly_createOperationIsMerged == true)
        #expect(update.update?.amount == 42)
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLC8/counter-create-already-merged-0
    @Test
    func counterCreateNoopWhenAlreadyMerged() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(42)
        counter.testsOnly_setCreateOperationIsMerged(true)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        let msg = TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: 99, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue))

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 42)
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLC16/counter-create-no-count-0
    @Test
    func counterCreateWithMissingCountIsNoop() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: nil, serial: "01", siteCode: "site1")
        let update = try #require(Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue))

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
        #expect(counter.testsOnly_createOperationIsMerged == true)
        #expect(update.isNoop == true)
    }

    // MARK: - RTLO4a: canApplyOperation (serial gate)

    // UTS: objects/unit/RTLO4a/apply-empty-site-serial-0
    @Test
    func canApplyOperationAllowsWhenSiteSerialEmpty() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let result = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(result != nil)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 5)
    }

    // UTS: objects/unit/RTLO4a/reject-stale-serial-0
    @Test
    func canApplyOperationRejectsStaleSerial() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setSiteTimeserials(["site1": "05"])
        counter.testsOnly_setData(10)

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 99, serial: "03", siteCode: "site1")
        let result = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(result == nil)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 10)
    }

    // UTS: objects/unit/RTLO4a/reject-equal-serial-0
    @Test
    func canApplyOperationRejectsEqualSerial() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setSiteTimeserials(["site1": "05"])
        counter.testsOnly_setData(10)

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 99, serial: "05", siteCode: "site1")
        let result = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(result == nil)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 10)
    }

    // UTS: objects/unit/RTLO4a/warn-invalid-serial-0
    @Test
    func canApplyOperationWarnsOnEmptySerialOrSiteCode() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let result1 = try Self.apply(
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "", siteCode: "site1"),
            to: counter,
            pool: &pool,
            internalQueue: internalQueue,
        )
        let result2 = try Self.apply(
            TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: ""),
            to: counter,
            pool: &pool,
            internalQueue: internalQueue,
        )

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
        #expect(result1 == nil)
        #expect(result2 == nil)
    }

    // MARK: - RTLC7c: source handling

    // UTS: objects/unit/RTLC7c/channel-source-updates-serials-0
    @Test
    func channelSourceUpdatesSiteTimeserials() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        _ = try Self.apply(msg, to: counter, source: .channel, pool: &pool, internalQueue: internalQueue)

        #expect(counter.testsOnly_siteTimeserials["site1"] == "01")
    }

    // UTS: objects/unit/RTLC7c/local-source-no-serial-update-0
    @Test
    func localSourceDoesNotUpdateSiteTimeserials() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        _ = try Self.apply(msg, to: counter, source: .local, pool: &pool, internalQueue: internalQueue)

        #expect(counter.testsOnly_siteTimeserials.isEmpty)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 5)
    }

    // MARK: - RTLC7g

    // UTS: objects/unit/RTLC7g/apply-returns-true-0
    @Test
    func applyOperationReturnsTrueOnSuccess() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let result = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        // D-5: spec `result == true` (applied) maps to a non-nil returned update
        #expect(result != nil)
    }

    // MARK: - RTLO4e, RTLO5, RTLO6: OBJECT_DELETE

    // UTS: objects/unit/RTLO5/object-delete-tombstones-0
    @Test
    func objectDeleteTombstonesCounter() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(42)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        let msg = TestFactories.objectDeleteOperationMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_000))
        let update = try #require(Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue))

        #expect(counter.testsOnly_isTombstone == true)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
        #expect(counter.testsOnly_tombstonedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(update.update?.amount == -42)
        #expect(update.tombstone == true)
        #expect(update.objectMessage == msg.toPublicObjectMessage(channelName: Self.channelName))
    }

    // UTS: objects/unit/RTLC7e/tombstoned-reject-ops-0
    @Test
    func operationsOnTombstonedCounterAreRejected() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        // D-3: isTombstone is computed from tombstonedAt
        counter.testsOnly_setTombstonedAt(Date(timeIntervalSince1970: 1_700_000_000))

        let msg = TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 5, serial: "01", siteCode: "site1")
        let result = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(result == nil)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
    }

    // UTS: objects/unit/RTLO6/tombstoned-at-from-serial-timestamp-0
    @Test
    func tombstonedAtFromSerialTimestamp() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let msg = TestFactories.objectDeleteOperationMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1", serialTimestamp: Date(timeIntervalSince1970: 1_700_000_050))
        _ = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(counter.testsOnly_tombstonedAt == Date(timeIntervalSince1970: 1_700_000_050))
    }

    // UTS: objects/unit/RTLO6/tombstoned-at-local-clock-0
    @Test
    func tombstonedAtFromLocalClockWhenNoSerialTimestamp() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        // D-10: controllable clock; assert exact equality rather than a before/after range
        let clockTime = Date(timeIntervalSince1970: 1_700_000_099)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue, clock: MockSimpleClock(currentTime: clockTime))

        let msg = TestFactories.objectDeleteOperationMessage(objectId: "counter:abc@1000", serial: "01", siteCode: "site1", serialTimestamp: nil)
        _ = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(counter.testsOnly_tombstonedAt == clockTime)
    }

    // MARK: - RTLC7d3

    // UTS: objects/unit/RTLC7d3/unsupported-action-0
    @Test
    func unsupportedActionIsDiscarded() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        // A MAP_SET action targeting the counter is unsupported for LiveCounter
        let msg = TestFactories.mapSetOperationMessage(objectId: "counter:abc@1000", key: "x", value: "y", serial: "01", siteCode: "site1")
        let result = try Self.apply(msg, to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(result == nil)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
    }

    // MARK: - RTLC6: replaceData (sync path)

    // UTS: objects/unit/RTLC6/replace-data-basic-0
    @Test
    func replaceDataSetsDataFromObjectState() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(10)
        counter.testsOnly_setCreateOperationIsMerged(true)
        counter.testsOnly_setSiteTimeserials(["site1": "00"])

        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site2": "05"], count: 50)
        let update = internalQueue.ably_syncNoDeadlock {
            counter.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil)
        }

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 50)
        #expect(counter.testsOnly_siteTimeserials == ["site2": "05"])
        #expect(counter.testsOnly_createOperationIsMerged == false)
        #expect(update.update?.amount == 40)
        // D-7: RTO4b2a — sync-originated, so objectMessage is nil (spec asserts == state_msg)
        #expect(update.objectMessage == nil)
    }

    // UTS: objects/unit/RTLC6/replace-data-with-create-op-0
    @Test
    func replaceDataWithCreateOpMergesInitialValue() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        let state = TestFactories.counterObjectState(
            objectId: "counter:abc@1000",
            siteTimeserials: ["site1": "01"],
            createOp: TestFactories.counterCreateOperation(objectId: "counter:abc@1000", count: 50),
            count: 100,
        )
        let update = internalQueue.ably_syncNoDeadlock {
            counter.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil)
        }

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 150)
        #expect(counter.testsOnly_createOperationIsMerged == true)
        #expect(update.update?.amount == 150)
        #expect(update.objectMessage == nil) // D-7
    }

    // UTS: objects/unit/RTLC6e/replace-data-tombstoned-noop-0
    @Test
    func replaceDataOnTombstonedCounterIsNoop() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setTombstonedAt(Date(timeIntervalSince1970: 1_700_000_000))

        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], count: 999)
        let update = internalQueue.ably_syncNoDeadlock {
            counter.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil)
        }

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
        #expect(update.isNoop == true)
    }

    // UTS: objects/unit/RTLC6f/replace-data-tombstone-flag-0
    @Test
    func replaceDataWithTombstoneFlagTombstonesCounter() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(30)

        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], tombstone: true, count: 0)
        let update = internalQueue.ably_syncNoDeadlock {
            counter.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil)
        }

        #expect(counter.testsOnly_isTombstone == true)
        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
        #expect(update.update?.amount == -30)
        #expect(update.tombstone == true)
        #expect(update.objectMessage == nil) // D-7
    }

    // UTS: objects/unit/RTLC6/replace-data-missing-count-0
    @Test
    func replaceDataWithMissingCountDefaultsToZero() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(42)

        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], count: nil)
        let update = internalQueue.ably_syncNoDeadlock {
            counter.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil)
        }

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 0)
        #expect(update.update?.amount == -42)
        #expect(update.objectMessage == nil) // D-7
    }

    // MARK: - RTLC14

    // UTS: objects/unit/RTLC14/diff-calculation-0
    @Test
    func diffCalculation() throws {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)
        counter.testsOnly_setData(20)

        let state = TestFactories.counterObjectState(objectId: "counter:abc@1000", siteTimeserials: ["site1": "01"], count: 75)
        let update = internalQueue.ably_syncNoDeadlock {
            counter.nosync_replaceData(using: state, objectMessageSerialTimestamp: nil)
        }

        #expect(update.update?.amount == 55)
        #expect(update.objectMessage == nil) // D-7
    }

    // MARK: - RTLC8, RTLC16

    // UTS: objects/unit/RTLC8/create-then-inc-0
    @Test
    func counterCreateThenIncAccumulates() throws {
        let internalQueue = TestFactories.createInternalQueue()
        var pool = Self.makePool(internalQueue: internalQueue)
        let counter = Self.makeCounter(objectID: "counter:abc@1000", internalQueue: internalQueue)

        _ = try Self.apply(TestFactories.counterCreateOperationMessage(objectId: "counter:abc@1000", count: 100, serial: "01", siteCode: "site1"), to: counter, pool: &pool, internalQueue: internalQueue)
        _ = try Self.apply(TestFactories.counterIncOperationMessage(objectId: "counter:abc@1000", number: 25, serial: "02", siteCode: "site1"), to: counter, pool: &pool, internalQueue: internalQueue)

        #expect(try Self.data(of: counter, internalQueue: internalQueue) == 125)
        #expect(counter.testsOnly_createOperationIsMerged == true)
    }

    // MARK: - RTLO3

    // UTS: objects/unit/RTLO3/live-object-init-properties-0
    @Test
    func liveObjectPropertiesInitializedCorrectly() {
        let internalQueue = TestFactories.createInternalQueue()
        let counter = Self.makeCounter(objectID: "counter:test@2000", internalQueue: internalQueue)

        #expect(counter.testsOnly_objectID == "counter:test@2000")
        #expect(counter.testsOnly_siteTimeserials.isEmpty)
        #expect(counter.testsOnly_createOperationIsMerged == false)
        #expect(counter.testsOnly_isTombstone == false)
        #expect(counter.testsOnly_tombstonedAt == nil)
    }
}
