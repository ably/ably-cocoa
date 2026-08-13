// Derived from the UTS spec `objects/unit/internal_live_counter_api.md`.

import Ably
@testable import AblyLiveObjects
import Foundation
import Testing

/// `InternalLiveCounter` public-facing API — value reads, increment/decrement writes, and update
/// events.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/internal_live_counter_api.md
/// (spec points `RTLC5`, `RTLC11`–`RTLC13`).
///
/// The spec declares mock-WebSocket infrastructure (`setup_synced_channel`, `MockWebSocket`,
/// `captured_messages`, `mock_ws.send_to_client`) for these cases. Per the UNIT-only scope, this file
/// ports the subset exercisable without it: the counter node is built directly and driven through the
/// public `LiveCounterInstance` (the counter surface the spec's `root.get("score")` resolves to),
/// with `publishAndApply` captured by a local mock and remote updates simulated by applying an
/// operation to the node (the unit stand-in for `mock_ws.send_to_client`). Mocks are replicated in
/// `helpers/ObjectsUTSHelpers.swift`.
///
/// ## Mock-realtime adaptation
/// `ObjectsUTSRealtimeObjects` captures the published `ObjectMessage` but does not apply it back onto
/// the counter. So the spec's post-apply value assertions are out of unit scope:
/// - RTLC12 `increment-applies-locally` (`value() == 150`) — skipped; only the published COUNTER_INC
///   is asserted (RTLC12 `increment-sends-counter-inc`).
/// - RTLC13 `value() == 85` — skipped; only the negated published number is asserted.
///
/// ## Compile-time-unrepresentable (recorded in deviations.md)
/// RTLC12e1's non-finite table: `increment(amount:)` takes a `Double`, so the `string`/`boolean`/
/// `array`/`object`/`null` rows cannot be constructed. Only the representable non-finite doubles
/// (`NaN`/`Infinity`/`-Infinity`) reach the RTLC12e1 finiteness check — those are ported below. `null`
/// maps to the no-argument `increment()` default of 1 (see `InstanceTests.test_RTINS14a...`).
///
/// ## Cross-referenced elsewhere (not in this spec's scope)
/// RTLC12b/c/d (write preconditions) are replaced by RTO26 and live in `objects/unit/realtime_object.md`.
@Suite(.serialized)
final class InternalLiveCounterApiTests {
    // MARK: - RTLC5: value() returns current counter data

    // UTS: objects/unit/RTLC5/value-returns-data-0
    // RTLC5c (returns current data value).
    @Test
    func RTLC5c_value_returns_data() throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let node = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)

        guard case let .liveCounter(counter) = Instance.from(internalValue: .liveCounter(node), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .liveCounter")
            return
        }
        #expect(try counter.value == 100)
    }

    // MARK: - RTLC12: increment sends v6 COUNTER_INC message

    // UTS: objects/unit/RTLC12/increment-sends-counter-inc-0
    // RTLC12e2/e3/e5/g. Asserts the published
    // COUNTER_INC (the spec's `captured_messages[0].state[0]`).
    @Test
    func RTLC12_increment_sends_counter_inc() async throws {
        let (counter, published) = try makeCounter(objectID: "counter:score@1000", data: 100)
        try await counter.increment(amount: 25)

        let messages = try #require(published.get())
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.counterInc)) // RTLC12e2
        #expect(messages[0].operation?.objectId == "counter:score@1000") // RTLC12e3
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: 25)) // RTLC12e5
    }

    // MARK: - RTLC12e1: increment with non-finite amount throws 40003

    // UTS: objects/unit/RTLC12e1/increment-non-number-0
    // the representable non-finite doubles throw 40003.
    @Test
    func RTLC12e1_increment_non_finite_throws() async throws {
        let (counter, _) = try makeCounter(objectID: "counter:score@1000", data: 100)
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await counter.increment(amount: .nan)
        }
        #expect(error?.code == 40003)
        // Ported from the native IncrementTests.throwsErrorForInvalidAmount before its removal
        // (Wave-1 dedup): the invalid-amount error also carries HTTP status 400.
        #expect(error?.statusCode == 400)
    }

    // UTS: objects/unit/RTLC12e1/increment-invalid-amounts-table-0
    // every representable non-finite amount
    // throws 40003. The non-numeric rows are compile-time-unrepresentable (Double parameter).
    @Test
    func RTLC12e1_increment_invalid_amounts_table() async throws {
        let invalidAmounts: [(Double, String)] = [
            (.nan, "NaN"),
            (.infinity, "Infinity"),
            (-.infinity, "-Infinity"),
        ]
        for (amount, label) in invalidAmounts {
            let (counter, _) = try makeCounter(objectID: "counter:score@1000", data: 100)
            let error = await #expect(throws: ARTErrorInfo.self, "increment(\(label)) should throw 40003") {
                try await counter.increment(amount: amount)
            }
            #expect(error?.code == 40003)
            #expect(error?.statusCode == 400)
        }
    }

    // MARK: - RTLC13: decrement delegates to increment with negated amount

    // UTS: objects/unit/RTLC13/decrement-negates-0
    // RTLC13b. Asserts the negated published number (the
    // spec's `value() == 85` post-apply assertion needs the full pipeline; out of unit scope).
    @Test
    func RTLC13_decrement_negates() async throws {
        let (counter, published) = try makeCounter(objectID: "counter:score@1000", data: 100)
        try await counter.decrement(amount: 15)

        let messages = try #require(published.get())
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: -15))
    }

    // MARK: - RTLC11: LiveCounterUpdate emitted on increment

    // UTS: objects/unit/RTLC11/counter-update-on-inc-0
    // RTLC11b1 (update carries the increment value). The
    // remote update is simulated by applying a COUNTER_INC to the node with a stamped source message.
    @Test
    func RTLC11_counter_update_on_inc() async throws {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let node = ObjectsUTS.makeCounter(objectID: "counter:score@1000", data: 100, internalQueue: internalQueue)

        guard case let .liveCounter(counter) = Instance.from(internalValue: .liveCounter(node), coreSDK: coreSDK, realtimeObjects: ObjectsUTSRealtimeObjects(), internalQueue: internalQueue) else {
            Issue.record("Expected .liveCounter")
            return
        }

        let collector = ObjectsUTSEventCollector()
        try counter.subscribe(listener: collector.listener)

        // The internal source message threaded through apply; its PAOM3 public form is delivered.
        let sourceMessage = ObjectsUTS.counterIncMessage(objectId: "counter:score@1000", number: 7, serial: "ts1", siteCode: "remote-site")
        var pool = ObjectsUTS.freshPool(internalQueue: internalQueue)
        internalQueue.ably_syncNoDeadlock {
            _ = node.nosync_apply(
                ProtocolTypes.ObjectOperation(action: .known(.counterInc), objectId: "counter:score@1000", counterInc: WireCounterInc(number: NSNumber(value: 7))),
                source: .channel,
                objectMessage: sourceMessage,
                objectsPool: &pool,
            )
        }

        let events = await collector.events()
        #expect(events.count == 1)
        let event = try #require(events.first)
        #expect(event.message?.operation.counterInc?.number == 7) // RTLC11b1
    }

    // MARK: - Helpers

    private func makeCounter(objectID: String, data: Double) throws -> (any LiveCounterInstance, ObjectsUTSPublished) {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let coreSDK = ObjectsUTSCoreSDK()
        let realtimeObjects = ObjectsUTSRealtimeObjects()
        let published = ObjectsUTSPublished()
        realtimeObjects.setPublishAndApplyHandler { messages in
            published.set(messages)
            return .success(())
        }
        let node = ObjectsUTS.makeCounter(objectID: objectID, data: data, internalQueue: internalQueue)
        guard case let .liveCounter(counter) = Instance.from(internalValue: .liveCounter(node), coreSDK: coreSDK, realtimeObjects: realtimeObjects, internalQueue: internalQueue) else {
            throw NSError(domain: "InternalLiveCounterApiTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expected .liveCounter"])
        }
        return (counter, published)
    }
}
