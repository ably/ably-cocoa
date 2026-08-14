// Derived from the UTS spec `objects/unit/public_object_message.md`.
//
// Drives the internal PAOM3/PAOOP3 wire→public conversions directly —
// `ProtocolTypes.InboundObjectMessage.toPublicObjectMessage(channelName:)` and
// `ProtocolTypes.ObjectOperation.toPublicObjectOperation()` — pure data-structure construction,
// no mocks or channel. The spec's `PublicObjectMessage.fromObjectMessage(source, channel)` /
// `PublicObjectOperation.fromObjectOperation(source_operation)` are these instance methods; the
// spec's `channel = { name: "..." }` object collapses to the `channelName:` parameter (PAOM3b).

@testable import AblyLiveObjects
@testable import AblyLiveObjectsTesting
import Foundation
import Testing

struct PublicObjectMessageTests {
    // MARK: - PAOM3 message construction

    // UTS: objects/unit/PAOM3/construction-all-fields-0
    @Test
    func constructionCopiesAllFieldsFromSourceObjectMessage() throws {
        // Setup
        // timestamp: 1700000000000 / serialTimestamp: 1700000001000 (spec epoch ms → Date)
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let serialTimestamp = Date(timeIntervalSince1970: 1_700_000_001)
        let source = TestFactories.inboundObjectMessage(
            id: "msg-id-1",
            clientId: "client-1",
            connectionId: "conn-1",
            extras: ["key": "value"],
            timestamp: timestamp,
            operation: TestFactories.objectOperation(
                action: .known(.mapSet),
                objectId: "map:abc@1000",
                mapSet: ProtocolTypes.MapSet(key: "name", value: ProtocolTypes.ObjectData(string: "Alice")),
            ),
            serial: "01",
            siteCode: "site1",
            serialTimestamp: serialTimestamp,
        )
        // channel = { name: "test-channel" } — cocoa passes the channel name directly (PAOM3b)
        let channelName = "test-channel"

        // Test Steps
        let publicMsg = try #require(source.toPublicObjectMessage(channelName: channelName))

        // Assertions
        #expect(publicMsg.id == "msg-id-1")
        #expect(publicMsg.clientId == "client-1")
        #expect(publicMsg.connectionId == "conn-1")
        #expect(publicMsg.timestamp == timestamp)
        #expect(publicMsg.channel == "test-channel")
        #expect(publicMsg.serial == "01")
        #expect(publicMsg.serialTimestamp == serialTimestamp)
        #expect(publicMsg.siteCode == "site1")
        #expect(publicMsg.extras == ["key": "value"])
        // ASSERT public_msg.operation IS NOT null
        // (no separate assertion: `operation` is non-optional on the public ObjectMessage — the
        // successful construction unwrapped by #require above guarantees it, PAOM3a1/PAOM2f)
        #expect(publicMsg.operation.action == .mapSet)
        #expect(publicMsg.operation.objectId == "map:abc@1000")
        #expect(publicMsg.operation.mapSet?.key == "name")
    }

    // UTS: objects/unit/PAOM3/construction-optional-fields-missing-0
    @Test
    func constructionWithOptionalFieldsMissing() throws {
        // Setup
        let source = TestFactories.inboundObjectMessage(
            operation: TestFactories.objectOperation(
                action: .known(.counterInc),
                objectId: "counter:abc@1000",
                counterInc: TestFactories.counterInc(number: 5),
            ),
        )
        // channel = { name: "my-channel" } — cocoa passes the channel name directly (PAOM3b)
        let channelName = "my-channel"

        // Test Steps
        let publicMsg = try #require(source.toPublicObjectMessage(channelName: channelName))

        // Assertions
        #expect(publicMsg.id == nil)
        #expect(publicMsg.clientId == nil)
        #expect(publicMsg.connectionId == nil)
        #expect(publicMsg.timestamp == nil)
        #expect(publicMsg.channel == "my-channel")
        #expect(publicMsg.serial == nil)
        #expect(publicMsg.serialTimestamp == nil)
        #expect(publicMsg.siteCode == nil)
        #expect(publicMsg.extras == nil)
        // ASSERT public_msg.operation IS NOT null
        // (no separate assertion: `operation` is non-optional on the public ObjectMessage — the
        // successful construction unwrapped by #require above guarantees it, PAOM3a1/PAOM2f)
        #expect(publicMsg.operation.action == .counterInc)
    }

    // UTS: objects/unit/PAOM3/channel-from-channel-name-0
    @Test
    func channelIsSetFromChannelNameNotFromObjectMessage() throws {
        // Setup
        let source = TestFactories.inboundObjectMessage(
            operation: TestFactories.objectOperation(
                action: .known(.objectDelete),
                objectId: "counter:abc@1000",
            ),
        )
        // channel = { name: "different-channel-name" } — cocoa passes the channel name directly (PAOM3b)
        let channelName = "different-channel-name"

        // Test Steps
        let publicMsg = try #require(source.toPublicObjectMessage(channelName: channelName))

        // Assertions
        #expect(publicMsg.channel == "different-channel-name")
    }

    // MARK: - PAOOP3 operation construction

    // UTS: objects/unit/PAOOP3/map-set-copies-fields-0
    @Test
    func mapSetOperationCopiesMapSetOmitsUnrelatedFields() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.mapSet),
            objectId: "map:abc@1000",
            mapSet: ProtocolTypes.MapSet(key: "color", value: ProtocolTypes.ObjectData(string: "blue")),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .mapSet)
        #expect(publicOp.objectId == "map:abc@1000")
        #expect(publicOp.mapSet?.key == "color")
        #expect(publicOp.mapSet?.value.string == "blue")
        #expect(publicOp.mapCreate == nil)
        #expect(publicOp.mapRemove == nil)
        #expect(publicOp.counterCreate == nil)
        #expect(publicOp.counterInc == nil)
        #expect(publicOp.objectDelete == nil)
        #expect(publicOp.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/map-remove-copies-fields-0
    @Test
    func mapRemoveOperationCopiesMapRemoveOmitsUnrelatedFields() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.mapRemove),
            objectId: "map:abc@1000",
            mapRemove: WireMapRemove(key: "old-key"),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .mapRemove)
        #expect(publicOp.objectId == "map:abc@1000")
        #expect(publicOp.mapRemove?.key == "old-key")
        #expect(publicOp.mapCreate == nil)
        #expect(publicOp.mapSet == nil)
        #expect(publicOp.counterCreate == nil)
        #expect(publicOp.counterInc == nil)
        #expect(publicOp.objectDelete == nil)
        #expect(publicOp.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/counter-inc-copies-fields-0
    @Test
    func counterIncOperationCopiesCounterIncOmitsUnrelatedFields() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.counterInc),
            objectId: "counter:abc@1000",
            counterInc: TestFactories.counterInc(number: 42),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .counterInc)
        #expect(publicOp.objectId == "counter:abc@1000")
        #expect(publicOp.counterInc?.number == 42)
        #expect(publicOp.mapCreate == nil)
        #expect(publicOp.mapSet == nil)
        #expect(publicOp.mapRemove == nil)
        #expect(publicOp.counterCreate == nil)
        #expect(publicOp.objectDelete == nil)
        #expect(publicOp.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/object-delete-copies-fields-0
    @Test
    func objectDeleteOperationCopiesObjectDeleteOmitsUnrelatedFields() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.objectDelete),
            objectId: "counter:abc@1000",
            objectDelete: WireObjectDelete(),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .objectDelete)
        #expect(publicOp.objectId == "counter:abc@1000")
        #expect(publicOp.objectDelete != nil)
        #expect(publicOp.mapCreate == nil)
        #expect(publicOp.mapSet == nil)
        #expect(publicOp.mapRemove == nil)
        #expect(publicOp.counterCreate == nil)
        #expect(publicOp.counterInc == nil)
        #expect(publicOp.mapClear == nil)
    }

    // UTS: objects/unit/PAOOP3/map-clear-copies-fields-0
    @Test
    func mapClearOperationCopiesMapClearOmitsUnrelatedFields() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.mapClear),
            objectId: "map:abc@1000",
            mapClear: WireMapClear(),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .mapClear)
        #expect(publicOp.objectId == "map:abc@1000")
        #expect(publicOp.mapClear != nil)
        #expect(publicOp.mapCreate == nil)
        #expect(publicOp.mapSet == nil)
        #expect(publicOp.mapRemove == nil)
        #expect(publicOp.counterCreate == nil)
        #expect(publicOp.counterInc == nil)
        #expect(publicOp.objectDelete == nil)
    }

    // UTS: objects/unit/PAOOP3/map-create-direct-0
    @Test
    func mapCreateWithMapCreateDirectlyPresent() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.mapCreate),
            objectId: "map:new@2000",
            mapCreate: ProtocolTypes.MapCreate(
                semantics: .known(.lww),
                entries: ["key1": TestFactories.mapEntry(tombstone: nil, timeserial: nil, data: ProtocolTypes.ObjectData(string: "val1"))],
            ),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .mapCreate)
        #expect(publicOp.objectId == "map:new@2000")
        let mapCreate = try #require(publicOp.mapCreate)
        #expect(mapCreate.semantics == .lww)
        #expect(mapCreate.entries["key1"]?.data?.string == "val1")
        #expect(publicOp.counterCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/map-create-from-with-object-id-0
    @Test
    func mapCreateResolvedFromMapCreateWithObjectId() throws {
        // Setup
        let derivedMapCreate = ProtocolTypes.MapCreate(
            semantics: .known(.lww),
            entries: ["x": TestFactories.mapEntry(tombstone: nil, timeserial: nil, data: ProtocolTypes.ObjectData(number: 10))],
        )
        // The spec's pseudo-shape for mapCreateWithObjectId lists objectId/semantics/entries inline;
        // cocoa's ProtocolTypes.MapCreateWithObjectId instead carries the wire fields (initialValue,
        // nonce — MCRO2a/MCRO2b) plus the retained source MapCreate. The objectId lives on the
        // operation itself, and the semantics/entries live on `derivedFrom`.
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.mapCreate),
            objectId: "map:derived@3000",
            mapCreateWithObjectId: ProtocolTypes.MapCreateWithObjectId(
                initialValue: #"{"x":10}"#,
                nonce: "nonce-1",
                derivedFrom: derivedMapCreate, // retained MapCreate per RTLMV4j5 (local-only; not a wire field name)
            ),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .mapCreate)
        #expect(publicOp.objectId == "map:derived@3000")
        let mapCreate = try #require(publicOp.mapCreate)
        #expect(mapCreate.semantics == .lww)
        #expect(mapCreate.entries["x"]?.data?.number == 10)
        #expect(publicOp.counterCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/counter-create-from-with-object-id-0
    @Test
    func counterCreateResolvedFromCounterCreateWithObjectId() throws {
        // Setup
        let derivedCounterCreate = WireCounterCreate(count: 100)
        // The spec's pseudo-shape for counterCreateWithObjectId lists objectId/count inline; cocoa's
        // ProtocolTypes.CounterCreateWithObjectId instead carries the wire fields (initialValue,
        // nonce — CCRO2a/CCRO2b) plus the retained source CounterCreate. The objectId lives on the
        // operation itself, and the count lives on `derivedFrom`.
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.counterCreate),
            objectId: "counter:derived@3000",
            counterCreateWithObjectId: ProtocolTypes.CounterCreateWithObjectId(
                initialValue: "100",
                nonce: "nonce-1",
                derivedFrom: derivedCounterCreate, // retained CounterCreate per RTLCV4g5 (local-only; not a wire field name)
            ),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .counterCreate)
        #expect(publicOp.objectId == "counter:derived@3000")
        let counterCreate = try #require(publicOp.counterCreate)
        #expect(counterCreate.count == 100)
        #expect(publicOp.mapCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/create-payloads-omitted-0
    @Test
    func createPayloadsOmittedWhenNeitherVariantIsPresent() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.mapSet),
            objectId: "map:abc@1000",
            mapSet: ProtocolTypes.MapSet(key: "k", value: ProtocolTypes.ObjectData(string: "v")),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.mapCreate == nil)
        #expect(publicOp.counterCreate == nil)
    }

    // UTS: objects/unit/PAOOP3/only-relevant-field-per-action-0
    @Test
    func onlyRelevantOperationFieldIsPresentPerActionType() throws {
        // Setup
        let sourceOperation = TestFactories.objectOperation(
            action: .known(.counterCreate),
            objectId: "counter:new@2000",
            counterCreate: WireCounterCreate(count: 50),
        )

        // Test Steps
        let publicOp = try #require(sourceOperation.toPublicObjectOperation())

        // Assertions
        #expect(publicOp.action == .counterCreate)
        #expect(publicOp.objectId == "counter:new@2000")
        let counterCreate = try #require(publicOp.counterCreate)
        #expect(counterCreate.count == 50)
        #expect(publicOp.mapCreate == nil)
        #expect(publicOp.mapSet == nil)
        #expect(publicOp.mapRemove == nil)
        #expect(publicOp.counterInc == nil)
        #expect(publicOp.objectDelete == nil)
        #expect(publicOp.mapClear == nil)
    }
}
