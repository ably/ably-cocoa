import _AblyPluginSupportPrivate
@testable import AblyLiveObjects
import Foundation
import Testing

enum WireObjectMessageTests {
    // Helper: Fake decoding context
    final class FakeDecodingContext: _AblyPluginSupportPrivate.DecodingContextProtocol, @unchecked Sendable {
        let parentID: String?
        let parentConnectionID: String?
        let parentTimestamp: Date?
        let indexInParent: Int
        init(parentID: String?, parentConnectionID: String?, parentTimestamp: Date?, indexInParent: Int) {
            self.parentID = parentID
            self.parentConnectionID = parentConnectionID
            self.parentTimestamp = parentTimestamp
            self.indexInParent = indexInParent
        }
    }

    struct InboundWireObjectMessageDecodingTests {
        @Test
        func decodesAllFields() throws {
            let timestamp = Date(timeIntervalSince1970: 1_234_567_890)
            let wire: [String: WireValue] = [
                "id": "id1",
                "clientId": "client1",
                "connectionId": "conn1",
                "extras": ["foo": "bar"],
                "timestamp": .number(NSNumber(value: Int(timestamp.timeIntervalSince1970 * 1000))),
                "operation": ["action": 0, "objectId": "obj1"],
                "object": ["objectId": "obj2", "map": ["semantics": 0], "siteTimeserials": [:], "tombstone": false],
                "serial": "s1",
                "siteCode": "siteA",
            ]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: nil, parentTimestamp: nil, indexInParent: 0)
            let msg = try InboundWireObjectMessage(wireObject: wire, decodingContext: ctx)
            #expect(msg.id == "id1")
            #expect(msg.clientId == "client1")
            #expect(msg.connectionId == "conn1")
            #expect(msg.extras == ["foo": "bar"])
            #expect(msg.timestamp == timestamp)
            #expect(msg.operation?.objectId == "obj1")
            #expect(msg.object?.objectId == "obj2")
            #expect(msg.serial == "s1")
            #expect(msg.siteCode == "siteA")
        }

        @Test
        func optionalFieldsAbsent() throws {
            let wire: [String: WireValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: nil, parentTimestamp: nil, indexInParent: 0)
            let msg = try InboundWireObjectMessage(wireObject: wire, decodingContext: ctx)
            #expect(msg.id == nil)
            #expect(msg.clientId == nil)
            #expect(msg.connectionId == nil)
            #expect(msg.extras == nil)
            #expect(msg.timestamp == nil)
            #expect(msg.operation == nil)
            #expect(msg.object == nil)
            #expect(msg.serial == nil)
            #expect(msg.siteCode == nil)
        }

        // @specOneOf(1/2) OM2a
        @Test
        func idFromParent_whenPresentInParent() throws {
            let wire: [String: WireValue] = [:]
            let ctx = FakeDecodingContext(parentID: "parent1", parentConnectionID: nil, parentTimestamp: nil, indexInParent: 2)
            let msg = try InboundWireObjectMessage(wireObject: wire, decodingContext: ctx)
            #expect(msg.id == "parent1:2")
        }

        // @specOneOf(2/2) OM2a
        @Test
        func idFromParent_whenAbsentInParent() throws {
            let wire: [String: WireValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: nil, parentTimestamp: nil, indexInParent: 2)
            let msg = try InboundWireObjectMessage(wireObject: wire, decodingContext: ctx)
            #expect(msg.id == nil)
        }

        // @spec OM2c
        @Test(arguments: [nil, "parentConn1"])
        func connectionIdFromParent(parentValue: String?) throws {
            let wire: [String: WireValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: parentValue, parentTimestamp: nil, indexInParent: 0)
            let msg = try InboundWireObjectMessage(wireObject: wire, decodingContext: ctx)
            #expect(msg.connectionId == parentValue)
        }

        // @spec OM2e
        @Test(arguments: [nil, Date(timeIntervalSince1970: 1_234_567_890)])
        func timestampFromParent(parentValue: Date?) throws {
            let wire: [String: WireValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: nil, parentTimestamp: parentValue, indexInParent: 0)
            let msg = try InboundWireObjectMessage(wireObject: wire, decodingContext: ctx)
            #expect(msg.timestamp == parentValue)
        }
    }

    struct OutboundWireObjectMessageEncodingTests {
        @Test
        func encodesAllFields() {
            let timestamp = Date(timeIntervalSince1970: 1_234_567_890)
            let msg = OutboundWireObjectMessage(
                id: "id1",
                clientId: "client1",
                connectionId: "conn1",
                extras: ["foo": "bar"],
                timestamp: timestamp,
                operation: WireObjectOperation(
                    action: .known(.mapCreate),
                    objectId: "obj1",
                ),
                object: nil,
                serial: "s1",
                siteCode: "siteA",
            )
            let wire = msg.toWireObject
            #expect(wire == [
                "id": "id1",
                "clientId": "client1",
                "connectionId": "conn1",
                "extras": ["foo": "bar"],
                "timestamp": .number(NSNumber(value: Int(timestamp.timeIntervalSince1970 * 1000))),
                "operation": ["action": 0, "objectId": "obj1"],
                "serial": "s1",
                "siteCode": "siteA",
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let timestamp = Date(timeIntervalSince1970: 1_234_567_890)
            let msg = OutboundWireObjectMessage(
                id: "id1",
                clientId: nil,
                connectionId: nil,
                extras: nil,
                timestamp: timestamp,
                operation: nil,
                object: nil,
                serial: nil,
                siteCode: nil,
            )
            let wire = msg.toWireObject
            #expect(wire == [
                "id": "id1",
                "timestamp": .number(NSNumber(value: Int(timestamp.timeIntervalSince1970 * 1000))),
            ])
        }
    }

    struct WireObjectOperationTests {
        @Test
        func decodesAllFields() throws {
            let wire: [String: WireValue] = [
                "action": 0, // mapCreate
                "objectId": "obj1",
                "mapCreate": ["semantics": 0, "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]]],
                "mapSet": ["key": "key1", "value": ["string": "value1"]],
                "mapRemove": ["key": "key2"],
                "counterCreate": ["count": 42],
                "counterInc": ["number": 10],
                "objectDelete": [:],
            ]
            let op = try WireObjectOperation(wireObject: wire)
            #expect(op.action == .known(.mapCreate))
            #expect(op.objectId == "obj1")
            #expect(op.mapCreate?.semantics == .known(.lww))
            #expect(op.mapCreate?.entries?["key1"]?.data?.string == "value1")
            #expect(op.mapCreate?.entries?["key1"]?.tombstone == false)
            #expect(op.mapSet?.key == "key1")
            #expect(op.mapSet?.value?.string == "value1")
            #expect(op.mapRemove?.key == "key2")
            #expect(op.counterCreate?.count == 42)
            #expect(op.counterInc?.number == 10)
            #expect(op.objectDelete != nil)
            // Outbound-only — do not access on inbound data
            #expect(op.mapCreateWithObjectId == nil)
            #expect(op.counterCreateWithObjectId == nil)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let wire: [String: WireValue] = [
                "action": 0,
                "objectId": "obj1",
            ]
            let op = try WireObjectOperation(wireObject: wire)
            #expect(op.action == .known(.mapCreate))
            #expect(op.objectId == "obj1")
            #expect(op.mapCreate == nil)
            #expect(op.mapSet == nil)
            #expect(op.mapRemove == nil)
            #expect(op.counterCreate == nil)
            #expect(op.counterInc == nil)
            #expect(op.objectDelete == nil)
            #expect(op.mapCreateWithObjectId == nil)
            #expect(op.counterCreateWithObjectId == nil)
        }

        @Test
        func decodesWithUnknownAction() throws {
            let wire: [String: WireValue] = [
                "action": 999, // Unknown WireObjectOperation
                "objectId": "obj1",
            ]
            let op = try WireObjectOperation(wireObject: wire)
            #expect(op.action == .unknown(999))
        }

        @Test
        func encodesAllFields() {
            let op = WireObjectOperation(
                action: .known(.mapCreate),
                objectId: "obj1",
                mapCreate: WireMapCreate(
                    semantics: .known(.lww),
                    entries: ["key1": WireObjectsMapEntry(tombstone: false, timeserial: nil, data: WireObjectData(string: "value1"))],
                ),
                mapSet: WireMapSet(key: "key1", value: WireObjectData(string: "value1")),
                counterCreate: WireCounterCreate(count: 42),
                counterInc: WireCounterInc(number: 10),
            )
            let wire = op.toWireObject
            #expect(wire == [
                "action": 0,
                "objectId": "obj1",
                "mapCreate": ["semantics": 0, "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]]],
                "mapSet": ["key": "key1", "value": ["string": "value1"]],
                "counterCreate": ["count": 42],
                "counterInc": ["number": 10],
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let op = WireObjectOperation(
                action: .known(.mapCreate),
                objectId: "obj1",
            )
            let wire = op.toWireObject
            #expect(wire == [
                "action": 0,
                "objectId": "obj1",
            ])
        }
    }

    struct WireObjectStateTests {
        @Test
        func decodesAllFields() throws {
            let wire: [String: WireValue] = [
                "objectId": "obj1",
                "siteTimeserials": ["site1": "ts1"],
                "tombstone": true,
                "createOp": ["action": 0, "objectId": "obj1"],
                "map": ["semantics": 0, "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]]],
                "counter": ["count": 42],
            ]
            let state = try WireObjectState(wireObject: wire)
            #expect(state.objectId == "obj1")
            #expect(state.siteTimeserials["site1"] == "ts1")
            #expect(state.tombstone == true)
            #expect(state.createOp?.action == .known(.mapCreate))
            #expect(state.createOp?.objectId == "obj1")
            #expect(state.map?.semantics == .known(.lww))
            #expect(state.map?.entries?["key1"]?.data?.string == "value1")
            #expect(state.map?.entries?["key1"]?.tombstone == false)
            #expect(state.counter?.count == 42)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let wire: [String: WireValue] = [
                "objectId": "obj1",
                "siteTimeserials": [:],
                "tombstone": false,
            ]
            let state = try WireObjectState(wireObject: wire)
            #expect(state.objectId == "obj1")
            #expect(state.siteTimeserials.isEmpty)
            #expect(state.tombstone == false)
            #expect(state.createOp == nil)
            #expect(state.map == nil)
            #expect(state.counter == nil)
        }

        @Test
        func encodesAllFields() {
            let state = WireObjectState(
                objectId: "obj1",
                siteTimeserials: ["site1": "ts1"],
                tombstone: true,
                createOp: WireObjectOperation(
                    action: .known(.mapCreate),
                    objectId: "obj1",
                ),
                map: WireObjectsMap(
                    semantics: .known(.lww),
                    entries: ["key1": WireObjectsMapEntry(tombstone: false, timeserial: nil, data: WireObjectData(string: "value1"))],
                ),
                counter: WireObjectsCounter(count: 42),
            )
            let wire = state.toWireObject
            #expect(wire == [
                "objectId": "obj1",
                "siteTimeserials": ["site1": "ts1"],
                "tombstone": true,
                "createOp": ["action": 0, "objectId": "obj1"],
                "map": ["semantics": 0, "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]]],
                "counter": ["count": 42],
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let state = WireObjectState(
                objectId: "obj1",
                siteTimeserials: [:],
                tombstone: false,
                createOp: nil,
                map: nil,
                counter: nil,
            )
            let wire = state.toWireObject
            #expect(wire == [
                "objectId": "obj1",
                "siteTimeserials": [:],
                "tombstone": false,
            ])
        }
    }

    struct WireObjectDataTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = [
                "objectId": "obj1",
                "boolean": true,
                "number": 42,
                "string": "value1",
            ]
            let data = try WireObjectData(wireObject: json)
            #expect(data.objectId == "obj1")
            #expect(data.boolean == true)
            #expect(data.number == 42)
            #expect(data.string == "value1")
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: WireValue] = [:]
            let data = try WireObjectData(wireObject: json)
            #expect(data.objectId == nil)
            #expect(data.boolean == nil)
            #expect(data.bytes == nil)
            #expect(data.number == nil)
            #expect(data.string == nil)
        }

        @Test
        func encodesAllFields() {
            let data = WireObjectData(
                objectId: "obj1",
                boolean: true,
                bytes: nil,
                number: 42,
                string: "value1",
            )
            let wire = data.toWireObject
            #expect(wire == [
                "objectId": "obj1",
                "boolean": true,
                "number": 42,
                "string": "value1",
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let data = WireObjectData(
                objectId: nil,
                boolean: nil,
                bytes: nil,
                number: nil,
                string: nil,
            )
            let wire = data.toWireObject
            #expect(wire.isEmpty)
        }
    }

    struct WireMapSetTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = [
                "key": "key1",
                "value": ["string": "value1"],
            ]
            let op = try WireMapSet(wireObject: json)
            #expect(op.key == "key1")
            #expect(op.value?.string == "value1")
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: WireValue] = ["key": "key1"]
            let op = try WireMapSet(wireObject: json)
            #expect(op.key == "key1")
            #expect(op.value == nil)
        }

        @Test
        func encodesAllFields() {
            let op = WireMapSet(
                key: "key1",
                value: WireObjectData(string: "value1"),
            )
            let wire = op.toWireObject
            #expect(wire == [
                "key": "key1",
                "value": ["string": "value1"],
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let op = WireMapSet(
                key: "key1",
                value: nil,
            )
            let wire = op.toWireObject
            #expect(wire == [
                "key": "key1",
            ])
        }
    }

    struct WireMapRemoveTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = ["key": "key1"]
            let op = try WireMapRemove(wireObject: json)
            #expect(op.key == "key1")
        }

        @Test
        func encodesAllFields() {
            let op = WireMapRemove(key: "key1")
            let wire = op.toWireObject
            #expect(wire == ["key": "key1"])
        }
    }

    struct WireMapCreateTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = [
                "semantics": 0,
                "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]],
            ]
            let op = try WireMapCreate(wireObject: json)
            #expect(op.semantics == .known(.lww))
            #expect(op.entries?["key1"]?.data?.string == "value1")
            #expect(op.entries?["key1"]?.tombstone == false)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: WireValue] = ["semantics": 0]
            let op = try WireMapCreate(wireObject: json)
            #expect(op.semantics == .known(.lww))
            #expect(op.entries == nil)
        }

        @Test
        func encodesAllFields() {
            let op = WireMapCreate(
                semantics: .known(.lww),
                entries: ["key1": WireObjectsMapEntry(tombstone: false, timeserial: nil, data: WireObjectData(string: "value1"))],
            )
            let wire = op.toWireObject
            #expect(wire == [
                "semantics": 0,
                "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]],
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let op = WireMapCreate(
                semantics: .known(.lww),
                entries: nil,
            )
            let wire = op.toWireObject
            #expect(wire == ["semantics": 0])
        }
    }

    struct WireCounterCreateTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = ["count": 42]
            let op = try WireCounterCreate(wireObject: json)
            #expect(op.count == 42)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: WireValue] = [:]
            let op = try WireCounterCreate(wireObject: json)
            #expect(op.count == nil)
        }

        @Test
        func encodesAllFields() {
            let op = WireCounterCreate(count: 42)
            let wire = op.toWireObject
            #expect(wire == ["count": 42])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let op = WireCounterCreate(count: nil)
            let wire = op.toWireObject
            #expect(wire.isEmpty)
        }
    }

    struct WireCounterIncTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = ["number": 42]
            let op = try WireCounterInc(wireObject: json)
            #expect(op.number == 42)
        }

        @Test
        func encodesAllFields() {
            let op = WireCounterInc(number: 42)
            let wire = op.toWireObject
            #expect(wire == ["number": 42])
        }
    }

    struct WireObjectDeleteTests {
        @Test
        func decodesEmptyObject() throws {
            let json: [String: WireValue] = [:]
            let op = try WireObjectDelete(wireObject: json)
            _ = op // just verify it decodes without error
        }

        @Test
        func encodesEmptyObject() {
            let op = WireObjectDelete()
            let wire = op.toWireObject
            #expect(wire.isEmpty)
        }
    }

    struct WireMapCreateWithObjectIdTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = [
                "nonce": "abc123",
                "initialValue": "someJSON",
            ]
            let op = try WireMapCreateWithObjectId(wireObject: json)
            #expect(op.nonce == "abc123")
            #expect(op.initialValue == "someJSON")
        }

        @Test
        func encodesAllFields() {
            let op = WireMapCreateWithObjectId(initialValue: "someJSON", nonce: "abc123")
            let wire = op.toWireObject
            #expect(wire == [
                "nonce": "abc123",
                "initialValue": "someJSON",
            ])
        }
    }

    struct WireCounterCreateWithObjectIdTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = [
                "nonce": "abc123",
                "initialValue": "someJSON",
            ]
            let op = try WireCounterCreateWithObjectId(wireObject: json)
            #expect(op.nonce == "abc123")
            #expect(op.initialValue == "someJSON")
        }

        @Test
        func encodesAllFields() {
            let op = WireCounterCreateWithObjectId(initialValue: "someJSON", nonce: "abc123")
            let wire = op.toWireObject
            #expect(wire == [
                "nonce": "abc123",
                "initialValue": "someJSON",
            ])
        }
    }

    struct WireMapTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = [
                "semantics": 0,
                "entries": [
                    "key1": ["data": ["string": "value1"], "tombstone": false, "timeserial": "ts1"],
                    "key2": ["data": ["string": "value2"], "tombstone": true],
                ],
            ]
            let map = try WireObjectsMap(wireObject: json)
            #expect(map.semantics == .known(.lww))
            #expect(map.entries?["key1"]?.data?.string == "value1")
            #expect(map.entries?["key1"]?.tombstone == false)
            #expect(map.entries?["key1"]?.timeserial == "ts1")
            #expect(map.entries?["key2"]?.data?.string == "value2")
            #expect(map.entries?["key2"]?.tombstone == true)
            #expect(map.entries?["key2"]?.timeserial == nil)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: WireValue] = ["semantics": 0]
            let map = try WireObjectsMap(wireObject: json)
            #expect(map.semantics == .known(.lww))
            #expect(map.entries == nil)
        }

        @Test
        func decodesWithUnknownSemantics() throws {
            let json: [String: WireValue] = [
                "semantics": 999, // Unknown MapSemantics
            ]
            let map = try WireObjectsMap(wireObject: json)
            #expect(map.semantics == .unknown(999))
        }

        @Test
        func encodesAllFields() {
            let map = WireObjectsMap(
                semantics: .known(.lww),
                entries: [
                    "key1": WireObjectsMapEntry(tombstone: false, timeserial: "ts1", data: WireObjectData(string: "value1")),
                    "key2": WireObjectsMapEntry(tombstone: true, timeserial: nil, data: WireObjectData(string: "value2")),
                ],
            )
            let wire = map.toWireObject
            #expect(wire == [
                "semantics": 0,
                "entries": [
                    "key1": ["data": ["string": "value1"], "tombstone": false, "timeserial": "ts1"],
                    "key2": ["data": ["string": "value2"], "tombstone": true],
                ],
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let map = WireObjectsMap(
                semantics: .known(.lww),
                entries: nil,
            )
            let wire = map.toWireObject
            #expect(wire == [
                "semantics": 0,
            ])
        }
    }

    struct WireCounterTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = ["count": 42]
            let counter = try WireObjectsCounter(wireObject: json)
            #expect(counter.count == 42)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: WireValue] = [:]
            let counter = try WireObjectsCounter(wireObject: json)
            #expect(counter.count == nil)
        }

        @Test
        func encodesAllFields() {
            let counter = WireObjectsCounter(count: 42)
            let wire = counter.toWireObject
            #expect(wire == ["count": 42])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let counter = WireObjectsCounter(count: nil)
            let wire = counter.toWireObject
            #expect(wire.isEmpty)
        }
    }

    struct WireMapEntryTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: WireValue] = [
                "data": ["string": "value1"],
                "tombstone": true,
                "timeserial": "ts1",
            ]
            let entry = try WireObjectsMapEntry(wireObject: json)
            #expect(entry.data?.string == "value1")
            #expect(entry.tombstone == true)
            #expect(entry.timeserial == "ts1")
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: WireValue] = ["data": ["string": "value1"]]
            let entry = try WireObjectsMapEntry(wireObject: json)
            #expect(entry.data?.string == "value1")
            #expect(entry.tombstone == nil)
            #expect(entry.timeserial == nil)
        }

        @Test
        func encodesAllFields() {
            let entry = WireObjectsMapEntry(
                tombstone: true,
                timeserial: "ts1",
                data: WireObjectData(string: "value1"),
            )
            let wire = entry.toWireObject
            #expect(wire == [
                "data": ["string": "value1"],
                "tombstone": true,
                "timeserial": "ts1",
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let entry = WireObjectsMapEntry(
                tombstone: nil,
                timeserial: nil,
                data: WireObjectData(string: "value1"),
            )
            let wire = entry.toWireObject
            #expect(wire == [
                "data": ["string": "value1"],
            ])
        }
    }
}
