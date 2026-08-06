// Derived from the UTS spec `objects/unit/path_object_mutations.md`.

import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Foundation
import Testing

/// `PathObject` write operations — `set`/`remove` (map) and `increment`/`decrement` (counter),
/// their type-mismatch (92007) and unresolved-path (92005) error model.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/path_object_mutations.md
/// (spec points `RTPO15`–`RTPO18`, `RTPO3c2`).
///
/// The spec drives every case through `setup_synced_channel` + a mock WebSocket. Per the UNIT-only
/// scope this seeds the standard pool directly (`ObjectsUTS.standardPool`) behind an
/// ``ObjectsUTSSeededRealtimeObjects`` that captures the published operation. This mirrors the native
/// `DefaultPathObjectTests` write cases.
///
/// ## Mock-realtime adaptation (recorded in deviations.md)
/// The seeded double echoes each captured `publishAndApply` operation back onto its existing pool
/// entry (the RTO20 ACK echo), so the spec's post-apply value reads are asserted directly for
/// primitive writes. Only operations that must *create* objects (`*_CREATE` blueprints) still need
/// the full `InternalDefaultRealtimeObjects` pipeline and remain out of unit scope.
///
/// ## Deviations
/// - **DEV-2 (typed casts):** cocoa splits the spec's polymorphic `PathObject.set/remove/increment/
///   decrement` across the typed casts. A map write goes through `asLiveMap().set(...)`; a counter
///   write through `asLiveCounter().increment(...)`. The RTPO15e/RTPO16e/RTPO17e/RTPO18e "wrong type"
///   branch is exercised by writing through the *mismatched* cast (e.g. `asLiveMap()` on a counter),
///   which throws 92007.
@Suite(.serialized)
final class PathObjectMutationsTests {
    // MARK: - Fixture

    private typealias Fixture = (root: DefaultLiveMapPathObject, realtimeObjects: ObjectsUTSSeededRealtimeObjects)

    private static func makeFixture(channelState: _AblyPluginSupportPrivate.RealtimeChannelState = .attached) -> Fixture {
        let internalQueue = ObjectsUTS.createInternalQueue()
        let pool = ObjectsUTS.standardPool(internalQueue: internalQueue)
        let realtimeObjects = ObjectsUTSSeededRealtimeObjects(pool: pool, internalQueue: internalQueue)
        let coreSDK = ObjectsUTSCoreSDK(channelState: channelState)
        let root = DefaultLiveMapPathObject(channelObject: realtimeObjects, coreSDK: coreSDK, internalQueue: internalQueue, path: "")
        return (root, realtimeObjects)
    }

    // MARK: - RTPO15: set() delegates to InternalLiveMap#set

    // UTS: objects/unit/RTPO15/set-delegates-to-map-0 — RTPO15d (delegates to InternalLiveMap#set).
    @Test
    func RTPO15_set_delegates_to_map() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.set(key: "name", value: .primitive(.string("Bob")))

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.mapSet))
        #expect(messages[0].operation?.objectId == ObjectsPool.rootKey)
        #expect(messages[0].operation?.mapSet?.key == "name")
        #expect(messages[0].operation?.mapSet?.value?.string == "Bob")
        // The spec's post-apply read (via the double's ACK echo).
        #expect(try fixture.root.get(key: "name").asPrimitive().value() == .string("Bob"))
    }

    // UTS: objects/unit/RTPO15/set-nested-path-0 — RTPO15a2/RTPO15b (nested path resolves to the child map).
    @Test
    func RTPO15_set_nested_path() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.get(key: "profile").asLiveMap().set(key: "email", value: .primitive(.string("bob@example.com")))

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.mapSet))
        #expect(messages[0].operation?.objectId == "map:profile@1000")
        #expect(messages[0].operation?.mapSet?.key == "email")
        // The spec's post-apply read (via the double's ACK echo).
        #expect(try fixture.root.get(key: "profile").asLiveMap().get(key: "email").asPrimitive().value() == .string("bob@example.com"))
    }

    // UTS: objects/unit/RTPO15d/set-non-map-throws-0 — RTPO15e (set on a non-map -> 92007).
    @Test
    func RTPO15d_set_non_map_throws() async throws {
        let fixture = Self.makeFixture()
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await fixture.root.get(key: "score").asLiveMap().set(key: "key", value: .primitive(.string("value")))
        }
        #expect(error?.code == 92007)
    }

    // MARK: - RTPO16: remove() delegates to InternalLiveMap#remove

    // UTS: objects/unit/RTPO16/remove-delegates-to-map-0 — RTPO16d (delegates to InternalLiveMap#remove).
    @Test
    func RTPO16_remove_delegates_to_map() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.remove(key: "name")

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.mapRemove))
        #expect(messages[0].operation?.objectId == ObjectsPool.rootKey)
        #expect(messages[0].operation?.mapRemove?.key == "name")
        // The spec's post-apply read: the removed key resolves to no value (via the double's ACK echo).
        #expect(try fixture.root.get(key: "name").asPrimitive().value() == nil)
    }

    // UTS: objects/unit/RTPO16d/remove-non-map-throws-0 — RTPO16e (remove on a non-map -> 92007).
    @Test
    func RTPO16d_remove_non_map_throws() async throws {
        let fixture = Self.makeFixture()
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await fixture.root.get(key: "score").asLiveMap().remove(key: "key")
        }
        #expect(error?.code == 92007)
    }

    // MARK: - RTPO17: increment() delegates to InternalLiveCounter#increment

    // UTS: objects/unit/RTPO17/increment-delegates-to-counter-0 — RTPO17d (delegates to InternalLiveCounter#
    // increment).
    @Test
    func RTPO17_increment_delegates_to_counter() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.get(key: "score").asLiveCounter().increment(amount: 25)

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.counterInc))
        #expect(messages[0].operation?.objectId == "counter:score@1000")
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: 25))
        // The spec's post-apply read: 100 (seeded) + 25 (via the double's ACK echo).
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 125)
    }

    // UTS: objects/unit/RTPO17/increment-default-amount-0 — RTPO17a1 (amount defaults to 1).
    @Test
    func RTPO17_increment_default_amount() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.get(key: "score").asLiveCounter().increment()

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: 1))
        // The spec's post-apply read: 100 (seeded) + 1 (via the double's ACK echo).
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 101)
    }

    // UTS: objects/unit/RTPO17d/increment-non-counter-throws-0 — RTPO17e (increment on a non-counter -> 92007).
    @Test
    func RTPO17d_increment_non_counter_throws() async throws {
        let fixture = Self.makeFixture()
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await fixture.root.asLiveCounter().increment(amount: 5)
        }
        #expect(error?.code == 92007)
    }

    // MARK: - RTPO18: decrement() delegates to InternalLiveCounter#decrement

    // UTS: objects/unit/RTPO18/decrement-delegates-to-counter-0 — RTPO18d (decrement is increment with a
    // negated amount, so the published COUNTER_INC carries -10).
    @Test
    func RTPO18_decrement_delegates_to_counter() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.get(key: "score").asLiveCounter().decrement(amount: 10)

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages.count == 1)
        #expect(messages[0].operation?.action == .known(.counterInc))
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: -10))
        // The spec's post-apply read: 100 (seeded) - 10 (via the double's ACK echo).
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 90)
    }

    // UTS: objects/unit/RTPO18/decrement-default-amount-0 — RTPO18a1 (amount defaults to 1 => published -1).
    @Test
    func RTPO18_decrement_default_amount() async throws {
        let fixture = Self.makeFixture()
        try await fixture.root.get(key: "score").asLiveCounter().decrement()

        let messages = try #require(fixture.realtimeObjects.capturedMessages)
        #expect(messages[0].operation?.counterInc?.number == NSNumber(value: -1))
        // The spec's post-apply read: 100 (seeded) - 1 (via the double's ACK echo).
        #expect(try fixture.root.get(key: "score").asLiveCounter().value() == 99)
    }

    // UTS: objects/unit/RTPO18d/decrement-non-counter-throws-0 — RTPO18e (decrement on a non-counter -> 92007).
    @Test
    func RTPO18d_decrement_non_counter_throws() async throws {
        let fixture = Self.makeFixture()
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await fixture.root.asLiveCounter().decrement(amount: 5)
        }
        #expect(error?.code == 92007)
    }

    // MARK: - RTPO3c2: writes on an unresolvable path throw 92005

    // UTS: objects/unit/RTPO3c2/set-unresolvable-throws-0 — RTPO3c2 (write on unresolvable path -> 92005/400).
    @Test
    func RTPO3c2_set_unresolvable_throws() async throws {
        let fixture = Self.makeFixture()
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await fixture.root.get(key: "nonexistent").asLiveMap().get(key: "deep").asLiveMap().set(key: "key", value: .primitive(.string("value")))
        }
        #expect(error?.code == 92005)
        #expect(error?.statusCode == 400)
    }

    // UTS: objects/unit/RTPO3c2/increment-unresolvable-throws-0 — RTPO3c2 (write on unresolvable path ->
    // 92005/400).
    @Test
    func RTPO3c2_increment_unresolvable_throws() async throws {
        let fixture = Self.makeFixture()
        let error = await #expect(throws: ARTErrorInfo.self) {
            try await fixture.root.get(key: "nonexistent").asLiveCounter().increment(amount: 5)
        }
        #expect(error?.code == 92005)
        #expect(error?.statusCode == 400)
    }
}
