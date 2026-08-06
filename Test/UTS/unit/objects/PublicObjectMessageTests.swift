// Derived from the UTS spec `objects/unit/public_object_message.md`.

@testable import AblyLiveObjects
import Foundation
import Testing

/// PublicAPI::ObjectMessage (PAOM) and PublicAPI::ObjectOperation (PAOOP) — public value types.
/// Derived from https://github.com/ably/specification/blob/main/uts/objects/unit/public_object_message.md
///
/// These are pure data-structure tests (no mocks). They exercise the user-facing `ObjectMessage` /
/// `ObjectOperation` / payload value types (`Path Based API/Public/PublicObjectMessage.swift`):
/// construction, field semantics (optionality), the 7-case action enum, and Equatable/Sendable
/// conformance (PAOM1/PAOM2 and PAOOP1/PAOOP2 layer), plus the wire→public conversion itself (PAOM3 /
/// PAOOP3): `ProtocolTypes.InboundObjectMessage.toPublicObjectMessage(channelName:)` and
/// `ProtocolTypes.ObjectOperation.toPublicObjectOperation()` (the spec's
/// `PublicObjectMessage.fromObjectMessage` / `PublicObjectOperation.fromObjectOperation`).
///
/// ## Deviations (recorded in deviations.md)
/// - DEV-5: the public `ObjectOperationAction` has exactly 7 cases and no `UNKNOWN`.
/// - DEV-6: `ObjectData` adds a Swift-only `encoding`; `json` is a raw `String?`; `number` is `Double?`;
///   `CounterCreate.count` / `CounterInc.number` are non-optional `Double`.
///
/// Note: no `@available` annotation is placed on this suite (matching the AblyLiveObjectsTests
/// convention) — the Swift Testing `@Suite`/`@Test` macros cannot be applied to an `@available`
/// declaration, and referencing the macOS-11-gated LiveObjects types directly compiles here.
@Suite(.serialized)
final class PublicObjectMessageTests {
    // MARK: - PAOM1 / PAOM2: public ObjectMessage construction and fields

    // Mirrors the data of objects/unit/PAOM3/construction-all-fields-0, but exercises the *public*
    // `ObjectMessage` initializer directly (PAOM1 user-constructible; PAOM2a–j all fields present).
    @Test
    func PAOM2_all_fields_populated() {
        // Setup — timestamp 1700000000000 ms, serialTimestamp 1700000001000 ms as Date values.
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let serialTimestamp = Date(timeIntervalSince1970: 1_700_000_001)

        let message = ObjectMessage(
            id: "msg-id-1",
            clientId: "client-1",
            connectionId: "conn-1",
            timestamp: timestamp,
            channel: "test-channel",
            operation: ObjectOperation(
                action: .mapSet,
                objectId: "map:abc@1000",
                mapSet: MapSet(key: "name", value: ObjectData(string: "Alice")),
            ),
            serial: "01",
            serialTimestamp: serialTimestamp,
            siteCode: "site1",
            extras: ["key": "value"],
        )

        // Assertions
        #expect(message.id == "msg-id-1") // PAOM2a
        #expect(message.clientId == "client-1") // PAOM2b
        #expect(message.connectionId == "conn-1") // PAOM2c
        #expect(message.timestamp == timestamp) // PAOM2d
        #expect(message.channel == "test-channel") // PAOM2e
        #expect(message.serial == "01") // PAOM2g
        #expect(message.serialTimestamp == serialTimestamp) // PAOM2h
        #expect(message.siteCode == "site1") // PAOM2i
        #expect(message.extras == ["key": "value"]) // PAOM2j
        #expect(message.operation.action == .mapSet) // PAOM2f
        #expect(message.operation.objectId == "map:abc@1000")
        #expect(message.operation.mapSet?.key == "name")
    }

    // Mirrors objects/unit/PAOM3/construction-optional-fields-missing-0: the public `ObjectMessage`
    // initializer defaults every optional field to nil (PAOM2a–d, PAOM2g–j are optional); only
    // `channel` (PAOM2e) and `operation` (PAOM2f) are required.
    @Test
    func PAOM2_optional_fields_default_to_nil() {
        let message = ObjectMessage(
            channel: "my-channel",
            operation: ObjectOperation(
                action: .counterInc,
                objectId: "counter:abc@1000",
                counterInc: CounterInc(number: 5),
            ),
        )

        #expect(message.id == nil) // PAOM2a
        #expect(message.clientId == nil) // PAOM2b
        #expect(message.connectionId == nil) // PAOM2c
        #expect(message.timestamp == nil) // PAOM2d
        #expect(message.channel == "my-channel") // PAOM2e
        #expect(message.serial == nil) // PAOM2g
        #expect(message.serialTimestamp == nil) // PAOM2h
        #expect(message.siteCode == nil) // PAOM2i
        #expect(message.extras == nil) // PAOM2j
        #expect(message.operation.action == .counterInc) // PAOM2f
    }

    // MARK: - PAOOP1 / PAOOP2: public ObjectOperation construction (only-relevant-field per action)

    // For each action the public `ObjectOperation` initializer defaults the other operation-specific
    // payloads to nil (PAOOP2c–i optional). Mirrors the per-action shapes of the PAOOP3a spec cases.

    @Test
    func PAOOP2_map_set_only_relevant_field() {
        let op = ObjectOperation(
            action: .mapSet,
            objectId: "map:abc@1000",
            mapSet: MapSet(key: "color", value: ObjectData(string: "blue")),
        )

        #expect(op.action == .mapSet) // PAOOP2a
        #expect(op.objectId == "map:abc@1000") // PAOOP2b
        #expect(op.mapSet?.key == "color") // PAOOP2d
        #expect(op.mapSet?.value.string == "blue")
        #expect(op.mapCreate == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }

    @Test
    func PAOOP2_map_remove_only_relevant_field() {
        let op = ObjectOperation(
            action: .mapRemove,
            objectId: "map:abc@1000",
            mapRemove: MapRemove(key: "old-key"),
        )

        #expect(op.action == .mapRemove)
        #expect(op.mapRemove?.key == "old-key") // PAOOP2e
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }

    @Test
    func PAOOP2_counter_inc_only_relevant_field() {
        let op = ObjectOperation(
            action: .counterInc,
            objectId: "counter:abc@1000",
            counterInc: CounterInc(number: 42),
        )

        #expect(op.action == .counterInc)
        #expect(op.counterInc?.number == 42) // PAOOP2g; DEV-6 number is Double
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }

    @Test
    func PAOOP2_object_delete_only_relevant_field() {
        let op = ObjectOperation(
            action: .objectDelete,
            objectId: "counter:abc@1000",
            objectDelete: ObjectDelete(),
        )

        #expect(op.action == .objectDelete)
        #expect(op.objectDelete != nil) // PAOOP2h
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.mapClear == nil)
    }

    @Test
    func PAOOP2_map_clear_only_relevant_field() {
        let op = ObjectOperation(
            action: .mapClear,
            objectId: "map:abc@1000",
            mapClear: MapClear(),
        )

        #expect(op.action == .mapClear)
        #expect(op.mapClear != nil) // PAOOP2i
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
    }

    // MapCreate with entries — covers MapCreate (PAOOP2c), ObjectsMapEntry, ObjectData and the
    // `.lww` semantics (the only public `ObjectsMapSemantics` case; DEV-5).
    @Test
    func PAOOP2_map_create_with_entries() {
        let op = ObjectOperation(
            action: .mapCreate,
            objectId: "map:new@2000",
            mapCreate: MapCreate(
                semantics: .lww,
                entries: ["key1": ObjectsMapEntry(data: ObjectData(string: "val1"))],
            ),
        )

        #expect(op.action == .mapCreate)
        #expect(op.mapCreate?.semantics == .lww) // MCR2a
        #expect(op.mapCreate?.entries["key1"]?.data?.string == "val1") // MCR2b
        #expect(op.counterCreate == nil)
    }

    // CounterCreate — covers PAOOP2f and DEV-6 (count is a non-optional Double).
    @Test
    func PAOOP2_counter_create_with_count() {
        let op = ObjectOperation(
            action: .counterCreate,
            objectId: "counter:new@2000",
            counterCreate: CounterCreate(count: 50),
        )

        #expect(op.action == .counterCreate)
        #expect(op.counterCreate?.count == 50) // CCR2a; DEV-6 count is Double
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }

    // MARK: - Public payload / data type semantics

    // OD2: `ObjectData` holds typed, decoded values. DEV-6: `number` is `Double?`, `json` is a raw
    // `String?`, and `encoding` is a Swift-only field with no wire/Java counterpart.
    @Test
    func objectData_holds_typed_values() {
        let data = ObjectData(
            objectId: "map:ref@1",
            encoding: "json",
            boolean: true,
            bytes: Data([1, 2, 3, 4]),
            number: 3.5,
            string: "hello",
            json: #"{"a":1}"#,
        )

        #expect(data.objectId == "map:ref@1") // OD2a
        #expect(data.encoding == "json") // OD2b (Swift-only; DEV-6)
        #expect(data.boolean == true) // OD2c
        #expect(data.bytes == Data([1, 2, 3, 4])) // OD2d
        #expect(data.number == 3.5) // OD2e (Double; DEV-6)
        #expect(data.string == "hello") // OD2f
        #expect(data.json == #"{"a":1}"#) // OD2g (raw String; DEV-6)

        // All fields are optional and default to nil.
        let empty = ObjectData()
        #expect(empty.objectId == nil)
        #expect(empty.encoding == nil)
        #expect(empty.boolean == nil)
        #expect(empty.bytes == nil)
        #expect(empty.number == nil)
        #expect(empty.string == nil)
        #expect(empty.json == nil)
    }

    // MARK: - DEV-5: action enum has 7 known cases, no UNKNOWN

    // The public `ObjectOperationAction` exposes exactly the 7 known actions and no `UNKNOWN` case
    // (DEV-5). Verified by pairwise distinctness of the 7 cases (Equatable).
    @Test
    func DEV5_object_operation_action_seven_distinct_cases() {
        let allActions: [ObjectOperationAction] = [
            .mapCreate,
            .mapSet,
            .mapRemove,
            .counterCreate,
            .counterInc,
            .objectDelete,
            .mapClear,
        ]

        // 7 cases, all pairwise distinct.
        #expect(allActions.count == 7)
        for i in allActions.indices {
            for j in allActions.indices where i != j {
                #expect(allActions[i] != allActions[j])
            }
        }
    }

    // MARK: - Equatable conformance

    // The public value types are `Equatable`: two identically-constructed messages compare equal, and
    // a difference in any field makes them unequal.
    @Test
    func public_types_are_equatable() {
        func makeMessage(clientId: String) -> ObjectMessage {
            ObjectMessage(
                clientId: clientId,
                channel: "ch",
                operation: ObjectOperation(
                    action: .mapSet,
                    objectId: "map:abc@1000",
                    mapSet: MapSet(key: "k", value: ObjectData(string: "v")),
                ),
            )
        }

        #expect(makeMessage(clientId: "a") == makeMessage(clientId: "a"))
        #expect(makeMessage(clientId: "a") != makeMessage(clientId: "b"))
    }

    // MARK: - PAOM3: wire (protocol) -> public ObjectMessage conversion

    // UTS: objects/unit/PAOM3/construction-all-fields-0 — PAOM3b/PAOM3c/PAOM3d. A fully-populated inbound
    // message converts to a public `ObjectMessage` with every field copied and the operation derived.
    // Wire timestamps are `Date` values here (the wire↔Date translation happens at decode time); the
    // spec's 1700000000000 ms / 1700000001000 ms are the same instants as the Dates below.
    @Test
    func PAOM3_construction_copies_all_fields() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let serialTimestamp = Date(timeIntervalSince1970: 1_700_000_001)

        let source = ProtocolTypes.InboundObjectMessage(
            id: "msg-id-1",
            clientId: "client-1",
            connectionId: "conn-1",
            extras: ["key": "value"],
            timestamp: timestamp,
            operation: ProtocolTypes.ObjectOperation(
                action: .known(.mapSet),
                objectId: "map:abc@1000",
                mapSet: ProtocolTypes.MapSet(key: "name", value: ProtocolTypes.ObjectData(string: "Alice")),
            ),
            serial: "01",
            siteCode: "site1",
            serialTimestamp: serialTimestamp,
        )

        let publicMsg = try #require(source.toPublicObjectMessage(channelName: "test-channel"))

        #expect(publicMsg.id == "msg-id-1") // PAOM2a
        #expect(publicMsg.clientId == "client-1") // PAOM2b
        #expect(publicMsg.connectionId == "conn-1") // PAOM2c
        #expect(publicMsg.timestamp == timestamp) // PAOM2d
        #expect(publicMsg.channel == "test-channel") // PAOM2e, PAOM3b
        #expect(publicMsg.serial == "01") // PAOM2g
        #expect(publicMsg.serialTimestamp == serialTimestamp) // PAOM2h
        #expect(publicMsg.siteCode == "site1") // PAOM2i
        #expect(publicMsg.extras == ["key": "value"]) // PAOM2j
        #expect(publicMsg.operation.action == .mapSet) // PAOM3d, PAOOP2a
        #expect(publicMsg.operation.objectId == "map:abc@1000")
        #expect(publicMsg.operation.mapSet?.key == "name")
    }

    // UTS: objects/unit/PAOM3/construction-optional-fields-missing-0 — PAOM2a–d/PAOM2g–j optional, PAOM3c.
    // An inbound message with only the operation set converts with all optional fields nil.
    @Test
    func PAOM3_construction_optional_fields_missing() throws {
        let source = ProtocolTypes.InboundObjectMessage(
            operation: ProtocolTypes.ObjectOperation(
                action: .known(.counterInc),
                objectId: "counter:abc@1000",
                counterInc: WireCounterInc(number: 5),
            ),
        )

        let publicMsg = try #require(source.toPublicObjectMessage(channelName: "my-channel"))

        #expect(publicMsg.id == nil) // PAOM2a
        #expect(publicMsg.clientId == nil) // PAOM2b
        #expect(publicMsg.connectionId == nil) // PAOM2c
        #expect(publicMsg.timestamp == nil) // PAOM2d
        #expect(publicMsg.channel == "my-channel") // PAOM2e
        #expect(publicMsg.serial == nil) // PAOM2g
        #expect(publicMsg.serialTimestamp == nil) // PAOM2h
        #expect(publicMsg.siteCode == nil) // PAOM2i
        #expect(publicMsg.extras == nil) // PAOM2j
        #expect(publicMsg.operation.action == .counterInc) // PAOM2f
    }

    // UTS: objects/unit/PAOM3/channel-from-channel-name-0 — PAOM3b: `channel` comes from the passed-in
    // channel name, never from the message itself (the inbound message has no channel field).
    @Test
    func PAOM3_channel_from_channel_name() throws {
        let source = ProtocolTypes.InboundObjectMessage(
            operation: ProtocolTypes.ObjectOperation(
                action: .known(.objectDelete),
                objectId: "counter:abc@1000",
                objectDelete: WireObjectDelete(),
            ),
        )

        let publicMsg = try #require(source.toPublicObjectMessage(channelName: "different-channel-name"))

        #expect(publicMsg.channel == "different-channel-name")
    }

    // MARK: - PAOOP3: wire (protocol) -> public ObjectOperation conversion

    // UTS: objects/unit/PAOOP3/map-set-copies-fields-0 — PAOOP3a/PAOOP2d.
    @Test
    func PAOOP3_map_set_copies_fields() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.mapSet),
            objectId: "map:abc@1000",
            mapSet: ProtocolTypes.MapSet(key: "color", value: ProtocolTypes.ObjectData(string: "blue")),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .mapSet)
        #expect(op.objectId == "map:abc@1000")
        #expect(op.mapSet?.key == "color") // PAOOP2d
        #expect(op.mapSet?.value.string == "blue")
        #expect(op.mapCreate == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/map-remove-copies-fields-0 — PAOOP3a/PAOOP2e.
    @Test
    func PAOOP3_map_remove_copies_fields() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.mapRemove),
            objectId: "map:abc@1000",
            mapRemove: WireMapRemove(key: "old-key"),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .mapRemove)
        #expect(op.objectId == "map:abc@1000")
        #expect(op.mapRemove?.key == "old-key") // PAOOP2e
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/counter-inc-copies-fields-0 — PAOOP3a/PAOOP2g.
    @Test
    func PAOOP3_counter_inc_copies_fields() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.counterInc),
            objectId: "counter:abc@1000",
            counterInc: WireCounterInc(number: 42),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .counterInc)
        #expect(op.objectId == "counter:abc@1000")
        #expect(op.counterInc?.number == 42) // PAOOP2g; DEV-6 number is Double
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/object-delete-copies-fields-0 — PAOOP3a/PAOOP2h.
    @Test
    func PAOOP3_object_delete_copies_fields() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.objectDelete),
            objectId: "counter:abc@1000",
            objectDelete: WireObjectDelete(),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .objectDelete)
        #expect(op.objectId == "counter:abc@1000")
        #expect(op.objectDelete != nil) // PAOOP2h
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/map-clear-copies-fields-0 — PAOOP3a/PAOOP2i.
    @Test
    func PAOOP3_map_clear_copies_fields() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.mapClear),
            objectId: "map:abc@1000",
            mapClear: WireMapClear(),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .mapClear)
        #expect(op.objectId == "map:abc@1000")
        #expect(op.mapClear != nil) // PAOOP2i
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterCreate == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
    }

    // UTS: objects/unit/PAOOP3/map-create-direct-0 — PAOOP3b1: a directly-present `mapCreate` is used as-is.
    @Test
    func PAOOP3_map_create_direct() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.mapCreate),
            objectId: "map:new@2000",
            mapCreate: ProtocolTypes.MapCreate(
                semantics: .known(.lww),
                entries: ["key1": ProtocolTypes.ObjectsMapEntry(data: ProtocolTypes.ObjectData(string: "val1"))],
            ),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .mapCreate)
        #expect(op.objectId == "map:new@2000")
        #expect(op.mapCreate != nil)
        #expect(op.mapCreate?.semantics == .lww) // DEV-5: LWW is the only semantics
        #expect(op.mapCreate?.entries["key1"]?.data?.string == "val1")
        #expect(op.counterCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/map-create-from-with-object-id-0 — PAOOP3b2: when only
    // `mapCreateWithObjectId` is present, `mapCreate` resolves to the `MapCreate` it was derived from.
    @Test
    func PAOOP3_map_create_from_with_object_id() throws {
        let derivedMapCreate = ProtocolTypes.MapCreate(
            semantics: .known(.lww),
            entries: ["x": ProtocolTypes.ObjectsMapEntry(data: ProtocolTypes.ObjectData(number: 10))],
        )

        let source = ProtocolTypes.ObjectOperation(
            action: .known(.mapCreate),
            objectId: "map:derived@3000",
            mapCreateWithObjectId: ProtocolTypes.MapCreateWithObjectId(
                initialValue: "aW5pdGlhbA==",
                nonce: "nonce-1",
                derivedFrom: derivedMapCreate,
            ),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .mapCreate)
        #expect(op.objectId == "map:derived@3000")
        #expect(op.mapCreate != nil)
        #expect(op.mapCreate?.semantics == .lww)
        #expect(op.mapCreate?.entries["x"]?.data?.number == 10)
        #expect(op.counterCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/counter-create-from-with-object-id-0 — PAOOP3c2: when only
    // `counterCreateWithObjectId` is present, `counterCreate` resolves to the `CounterCreate` derived from.
    @Test
    func PAOOP3_counter_create_from_with_object_id() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.counterCreate),
            objectId: "counter:derived@3000",
            counterCreateWithObjectId: ProtocolTypes.CounterCreateWithObjectId(
                initialValue: "aW5pdGlhbA==",
                nonce: "nonce-1",
                derivedFrom: WireCounterCreate(count: 100),
            ),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .counterCreate)
        #expect(op.objectId == "counter:derived@3000")
        #expect(op.counterCreate != nil)
        #expect(op.counterCreate?.count == 100) // DEV-6: count is Double
        #expect(op.mapCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/create-payloads-omitted-0 — PAOOP3b3/PAOOP3c3: with neither create variant
    // present, both `mapCreate` and `counterCreate` are omitted.
    @Test
    func PAOOP3_create_payloads_omitted() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.mapSet),
            objectId: "map:abc@1000",
            mapSet: ProtocolTypes.MapSet(key: "k", value: ProtocolTypes.ObjectData(string: "v")),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.mapCreate == nil)
        #expect(op.counterCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/only-relevant-field-per-action-0 — PAOOP3a: a directly-present `counterCreate`
    // is the only operation-specific field set; all others are nil.
    @Test
    func PAOOP3_only_relevant_field_per_action() throws {
        let source = ProtocolTypes.ObjectOperation(
            action: .known(.counterCreate),
            objectId: "counter:new@2000",
            counterCreate: WireCounterCreate(count: 50),
        )

        let op = try #require(source.toPublicObjectOperation())

        #expect(op.action == .counterCreate)
        #expect(op.objectId == "counter:new@2000")
        #expect(op.counterCreate != nil)
        #expect(op.counterCreate?.count == 50)
        #expect(op.mapCreate == nil)
        #expect(op.mapSet == nil)
        #expect(op.mapRemove == nil)
        #expect(op.counterInc == nil)
        #expect(op.objectDelete == nil)
        #expect(op.mapClear == nil)
    }
}
