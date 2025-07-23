@testable import AblyLiveObjects
import AblyPlugin
import Foundation
import Testing

enum WireObjectMessageTests {
    // Helper: Fake decoding context
    final class FakeDecodingContext: AblyPlugin.DecodingContextProtocol, @unchecked Sendable {
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
            let json: [String: JSONValue] = [
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
            let msg = try InboundWireObjectMessage(jsonObject: json, decodingContext: ctx)
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
            let json: [String: JSONValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: nil, parentTimestamp: nil, indexInParent: 0)
            let msg = try InboundWireObjectMessage(jsonObject: json, decodingContext: ctx)
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
            let json: [String: JSONValue] = [:]
            let ctx = FakeDecodingContext(parentID: "parent1", parentConnectionID: nil, parentTimestamp: nil, indexInParent: 2)
            let msg = try InboundWireObjectMessage(jsonObject: json, decodingContext: ctx)
            #expect(msg.id == "parent1:2")
        }

        // @specOneOf(2/2) OM2a
        @Test
        func idFromParent_whenAbsentInParent() throws {
            let json: [String: JSONValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: nil, parentTimestamp: nil, indexInParent: 2)
            let msg = try InboundWireObjectMessage(jsonObject: json, decodingContext: ctx)
            #expect(msg.id == nil)
        }

        // @spec OM2c
        @Test(arguments: [nil, "parentConn1"])
        func connectionIdFromParent(parentValue: String?) throws {
            let json: [String: JSONValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: parentValue, parentTimestamp: nil, indexInParent: 0)
            let msg = try InboundWireObjectMessage(jsonObject: json, decodingContext: ctx)
            #expect(msg.connectionId == parentValue)
        }

        // @spec OM2e
        @Test(arguments: [nil, Date(timeIntervalSince1970: 1_234_567_890)])
        func timestampFromParent(parentValue: Date?) throws {
            let json: [String: JSONValue] = [:]
            let ctx = FakeDecodingContext(parentID: nil, parentConnectionID: nil, parentTimestamp: parentValue, indexInParent: 0)
            let msg = try InboundWireObjectMessage(jsonObject: json, decodingContext: ctx)
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
                    mapOp: nil,
                    counterOp: nil,
                    map: nil,
                    counter: nil,
                    nonce: nil,
                    initialValue: nil,
                    initialValueEncoding: nil,
                ),
                object: nil,
                serial: "s1",
                siteCode: "siteA",
            )
            let json = msg.toJSONObject
            #expect(json == [
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
            let json = msg.toJSONObject
            #expect(json == [
                "id": "id1",
                "timestamp": .number(NSNumber(value: Int(timestamp.timeIntervalSince1970 * 1000))),
            ])
        }
    }

    struct WireObjectOperationTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = [
                "action": 0, // mapCreate
                "objectId": "obj1",
                "mapOp": ["key": "key1", "data": ["string": "value1"]],
                "counterOp": ["amount": 42],
                "map": ["semantics": 0, "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]]],
                "counter": ["count": 42],
                "nonce": "nonce1",
                "initialValueEncoding": "utf8",
            ]
            let op = try WireObjectOperation(jsonObject: json)
            #expect(op.action == .known(.mapCreate))
            #expect(op.objectId == "obj1")
            #expect(op.mapOp?.key == "key1")
            #expect(op.mapOp?.data?.string == "value1")
            #expect(op.counterOp?.amount == 42)
            #expect(op.map?.semantics == .known(.lww))
            #expect(op.map?.entries?["key1"]?.data.string == "value1")
            #expect(op.map?.entries?["key1"]?.tombstone == false)
            #expect(op.counter?.count == 42)
            #expect(op.nonce == "nonce1")
            #expect(op.initialValueEncoding == "utf8")
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: JSONValue] = [
                "action": 0,
                "objectId": "obj1",
            ]
            let op = try WireObjectOperation(jsonObject: json)
            #expect(op.action == .known(.mapCreate))
            #expect(op.objectId == "obj1")
            #expect(op.mapOp == nil)
            #expect(op.counterOp == nil)
            #expect(op.map == nil)
            #expect(op.counter == nil)
            #expect(op.nonce == nil)
            #expect(op.initialValue == nil)
            #expect(op.initialValueEncoding == nil)
        }

        @Test
        func decodesWithUnknownAction() throws {
            let json: [String: JSONValue] = [
                "action": 999, // Unknown WireObjectOperation
                "objectId": "obj1",
            ]
            let op = try WireObjectOperation(jsonObject: json)
            #expect(op.action == .unknown(999))
        }

        @Test
        func encodesAllFields() {
            let op = WireObjectOperation(
                action: .known(.mapCreate),
                objectId: "obj1",
                mapOp: WireMapOp(key: "key1", data: WireObjectData(string: "value1")),
                counterOp: WireCounterOp(amount: 42),
                map: WireMap(
                    semantics: .known(.lww),
                    entries: ["key1": WireMapEntry(tombstone: false, timeserial: nil, data: WireObjectData(string: "value1"))],
                ),
                counter: WireCounter(count: 42),
                nonce: "nonce1",
                initialValue: nil,
                initialValueEncoding: "utf8",
            )
            let json = op.toJSONObject
            #expect(json == [
                "action": 0,
                "objectId": "obj1",
                "mapOp": ["key": "key1", "data": ["string": "value1"]],
                "counterOp": ["amount": 42],
                "map": ["semantics": 0, "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]]],
                "counter": ["count": 42],
                "nonce": "nonce1",
                "initialValueEncoding": "utf8",
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let op = WireObjectOperation(
                action: .known(.mapCreate),
                objectId: "obj1",
                mapOp: nil,
                counterOp: nil,
                map: nil,
                counter: nil,
                nonce: nil,
                initialValue: nil,
                initialValueEncoding: nil,
            )
            let json = op.toJSONObject
            #expect(json == [
                "action": 0,
                "objectId": "obj1",
            ])
        }
    }

    struct WireObjectStateTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = [
                "objectId": "obj1",
                "siteTimeserials": ["site1": "ts1"],
                "tombstone": true,
                "createOp": ["action": 0, "objectId": "obj1"],
                "map": ["semantics": 0, "entries": ["key1": ["data": ["string": "value1"], "tombstone": false]]],
                "counter": ["count": 42],
            ]
            let state = try WireObjectState(jsonObject: json)
            #expect(state.objectId == "obj1")
            #expect(state.siteTimeserials["site1"] == "ts1")
            #expect(state.tombstone == true)
            #expect(state.createOp?.action == .known(.mapCreate))
            #expect(state.createOp?.objectId == "obj1")
            #expect(state.map?.semantics == .known(.lww))
            #expect(state.map?.entries?["key1"]?.data.string == "value1")
            #expect(state.map?.entries?["key1"]?.tombstone == false)
            #expect(state.counter?.count == 42)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: JSONValue] = [
                "objectId": "obj1",
                "siteTimeserials": [:],
                "tombstone": false,
            ]
            let state = try WireObjectState(jsonObject: json)
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
                    mapOp: nil,
                    counterOp: nil,
                    map: nil,
                    counter: nil,
                    nonce: nil,
                    initialValue: nil,
                    initialValueEncoding: nil,
                ),
                map: WireMap(
                    semantics: .known(.lww),
                    entries: ["key1": WireMapEntry(tombstone: false, timeserial: nil, data: WireObjectData(string: "value1"))],
                ),
                counter: WireCounter(count: 42),
            )
            let json = state.toJSONObject
            #expect(json == [
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
            let json = state.toJSONObject
            #expect(json == [
                "objectId": "obj1",
                "siteTimeserials": [:],
                "tombstone": false,
            ])
        }
    }

    struct WireObjectDataTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = [
                "objectId": "obj1",
                "encoding": "utf8",
                "boolean": true,
                "number": 42,
                "string": "value1",
            ]
            let data = try WireObjectData(jsonObject: json)
            #expect(data.objectId == "obj1")
            #expect(data.encoding == "utf8")
            #expect(data.boolean == true)
            #expect(data.number == 42)
            #expect(data.string == "value1")
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: JSONValue] = [:]
            let data = try WireObjectData(jsonObject: json)
            #expect(data.objectId == nil)
            #expect(data.encoding == nil)
            #expect(data.boolean == nil)
            #expect(data.bytes == nil)
            #expect(data.number == nil)
            #expect(data.string == nil)
        }

        @Test
        func encodesAllFields() {
            let data = WireObjectData(
                objectId: "obj1",
                encoding: "utf8",
                boolean: true,
                bytes: nil,
                number: 42,
                string: "value1",
            )
            let json = data.toJSONObject
            #expect(json == [
                "objectId": "obj1",
                "encoding": "utf8",
                "boolean": true,
                "number": 42,
                "string": "value1",
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let data = WireObjectData(
                objectId: nil,
                encoding: nil,
                boolean: nil,
                bytes: nil,
                number: nil,
                string: nil,
            )
            let json = data.toJSONObject
            #expect(json.isEmpty)
        }
    }

    struct WireMapOpTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = [
                "key": "key1",
                "data": ["string": "value1"],
            ]
            let op = try WireMapOp(jsonObject: json)
            #expect(op.key == "key1")
            #expect(op.data?.string == "value1")
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: JSONValue] = ["key": "key1"]
            let op = try WireMapOp(jsonObject: json)
            #expect(op.key == "key1")
            #expect(op.data == nil)
        }

        @Test
        func encodesAllFields() {
            let op = WireMapOp(
                key: "key1",
                data: WireObjectData(string: "value1"),
            )
            let json = op.toJSONObject
            #expect(json == [
                "key": "key1",
                "data": ["string": "value1"],
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let op = WireMapOp(
                key: "key1",
                data: nil,
            )
            let json = op.toJSONObject
            #expect(json == [
                "key": "key1",
            ])
        }
    }

    struct WireCounterOpTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = ["amount": 42]
            let op = try WireCounterOp(jsonObject: json)
            #expect(op.amount == 42)
        }

        @Test
        func encodesAllFields() {
            let op = WireCounterOp(amount: 42)
            let json = op.toJSONObject
            #expect(json == ["amount": 42])
        }
    }

    struct WireMapTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = [
                "semantics": 0,
                "entries": [
                    "key1": ["data": ["string": "value1"], "tombstone": false, "timeserial": "ts1"],
                    "key2": ["data": ["string": "value2"], "tombstone": true],
                ],
            ]
            let map = try WireMap(jsonObject: json)
            #expect(map.semantics == .known(.lww))
            #expect(map.entries?["key1"]?.data.string == "value1")
            #expect(map.entries?["key1"]?.tombstone == false)
            #expect(map.entries?["key1"]?.timeserial == "ts1")
            #expect(map.entries?["key2"]?.data.string == "value2")
            #expect(map.entries?["key2"]?.tombstone == true)
            #expect(map.entries?["key2"]?.timeserial == nil)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: JSONValue] = ["semantics": 0]
            let map = try WireMap(jsonObject: json)
            #expect(map.semantics == .known(.lww))
            #expect(map.entries == nil)
        }

        @Test
        func decodesWithUnknownSemantics() throws {
            let json: [String: JSONValue] = [
                "semantics": 999, // Unknown MapSemantics
            ]
            let map = try WireMap(jsonObject: json)
            #expect(map.semantics == .unknown(999))
        }

        @Test
        func encodesAllFields() {
            let map = WireMap(
                semantics: .known(.lww),
                entries: [
                    "key1": WireMapEntry(tombstone: false, timeserial: "ts1", data: WireObjectData(string: "value1")),
                    "key2": WireMapEntry(tombstone: true, timeserial: nil, data: WireObjectData(string: "value2")),
                ],
            )
            let json = map.toJSONObject
            #expect(json == [
                "semantics": 0,
                "entries": [
                    "key1": ["data": ["string": "value1"], "tombstone": false, "timeserial": "ts1"],
                    "key2": ["data": ["string": "value2"], "tombstone": true],
                ],
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let map = WireMap(
                semantics: .known(.lww),
                entries: nil,
            )
            let json = map.toJSONObject
            #expect(json == [
                "semantics": 0,
            ])
        }
    }

    struct WireCounterTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = ["count": 42]
            let counter = try WireCounter(jsonObject: json)
            #expect(counter.count == 42)
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: JSONValue] = [:]
            let counter = try WireCounter(jsonObject: json)
            #expect(counter.count == nil)
        }

        @Test
        func encodesAllFields() {
            let counter = WireCounter(count: 42)
            let json = counter.toJSONObject
            #expect(json == ["count": 42])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let counter = WireCounter(count: nil)
            let json = counter.toJSONObject
            #expect(json.isEmpty)
        }
    }

    struct WireMapEntryTests {
        @Test
        func decodesAllFields() throws {
            let json: [String: JSONValue] = [
                "data": ["string": "value1"],
                "tombstone": true,
                "timeserial": "ts1",
            ]
            let entry = try WireMapEntry(jsonObject: json)
            #expect(entry.data.string == "value1")
            #expect(entry.tombstone == true)
            #expect(entry.timeserial == "ts1")
        }

        @Test
        func decodesWithOptionalFieldsAbsent() throws {
            let json: [String: JSONValue] = ["data": ["string": "value1"]]
            let entry = try WireMapEntry(jsonObject: json)
            #expect(entry.data.string == "value1")
            #expect(entry.tombstone == nil)
            #expect(entry.timeserial == nil)
        }

        @Test
        func encodesAllFields() {
            let entry = WireMapEntry(
                tombstone: true,
                timeserial: "ts1",
                data: WireObjectData(string: "value1"),
            )
            let json = entry.toJSONObject
            #expect(json == [
                "data": ["string": "value1"],
                "tombstone": true,
                "timeserial": "ts1",
            ])
        }

        @Test
        func encodesWithOptionalFieldsNil() {
            let entry = WireMapEntry(
                tombstone: nil,
                timeserial: nil,
                data: WireObjectData(string: "value1"),
            )
            let json = entry.toJSONObject
            #expect(json == [
                "data": ["string": "value1"],
            ])
        }
    }
}
