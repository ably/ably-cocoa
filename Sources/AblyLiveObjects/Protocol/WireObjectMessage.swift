internal import AblyPlugin
import Foundation

// This file contains the ObjectMessage types that we send and receive over the wire. We convert them to and from the corresponding non-wire types (e.g. `InboundObjectMessage`) for use within the codebase.

/// An `ObjectMessage` received in the `state` property of an `OBJECT` or `OBJECT_SYNC` `ProtocolMessage`.
internal struct InboundWireObjectMessage {
    // TODO: Spec has `id`, `connectionId`, `timestamp`, `clientId`, `serial`, `sideCode` as non-nullable but I don't think this is right; raised https://github.com/ably/specification/issues/334
    internal var id: String? // OM2a
    internal var clientId: String? // OM2b
    internal var connectionId: String? // OM2c
    internal var extras: [String: JSONValue]? // OM2d
    internal var timestamp: Date? // OM2e
    internal var operation: WireObjectOperation? // OM2f
    internal var object: WireObjectState? // OM2g
    internal var serial: String? // OM2h
    internal var siteCode: String? // OM2i
}

/// An `ObjectMessage` to be sent in the `state` property of an `OBJECT` `ProtocolMessage`.
internal struct OutboundWireObjectMessage {
    internal var id: String? // OM2a
    internal var clientId: String? // OM2b
    internal var connectionId: String?
    internal var extras: [String: JSONValue]? // OM2d
    internal var timestamp: Date? // OM2e
    internal var operation: WireObjectOperation? // OM2f
    internal var object: WireObjectState? // OM2g
    internal var serial: String? // OM2h
    internal var siteCode: String? // OM2i
}

/// The keys for decoding an `InboundWireObjectMessage` or encoding an `OutboundWireObjectMessage`.
internal enum WireObjectMessageJSONKey: String {
    case id
    case clientId
    case connectionId
    case extras
    case timestamp
    case operation
    case object
    case serial
    case siteCode
}

internal extension InboundWireObjectMessage {
    /// An error that can occur when decoding an ``InboundWireObjectMessage``.
    enum DecodingError: Error {
        // TODO: after https://github.com/ably/specification/issues/334 resolved, throw or remove these as needed
        /// The containing `ProtocolMessage` does not have an `id`.
        case parentMissingID
        /// The containing `ProtocolMessage` does not have a `connectionId`.
        case parentMissingConnectionID
        /// The containing `ProtocolMessage` does not have a `timestamp`.
        case parentMissingTimestamp
    }

    /// Decodes the `ObjectMessage` and then uses the containing `ProtocolMessage` to populate some absent fields per the rules of the specification.
    init(
        jsonObject: [String: JSONValue],
        decodingContext: AblyPlugin.DecodingContextProtocol
    ) throws(InternalError) {
        // OM2a
        if let id = try jsonObject.optionalStringValueForKey(WireObjectMessageJSONKey.id.rawValue) {
            self.id = id
        } else if let parentID = decodingContext.parentID {
            id = "\(parentID):\(decodingContext.indexInParent)"
        }

        clientId = try jsonObject.optionalStringValueForKey(WireObjectMessageJSONKey.clientId.rawValue)

        // OM2c
        if let connectionId = try jsonObject.optionalStringValueForKey(WireObjectMessageJSONKey.connectionId.rawValue) {
            self.connectionId = connectionId
        } else if let parentConnectionID = decodingContext.parentConnectionID {
            connectionId = parentConnectionID
        }

        extras = try jsonObject.optionalObjectValueForKey(WireObjectMessageJSONKey.extras.rawValue)

        // OM2e
        if let timestamp = try jsonObject.optionalAblyProtocolDateValueForKey(WireObjectMessageJSONKey.timestamp.rawValue) {
            self.timestamp = timestamp
        } else if let parentTimestamp = decodingContext.parentTimestamp {
            timestamp = parentTimestamp
        }

        operation = try jsonObject.optionalDecodableValueForKey(WireObjectMessageJSONKey.operation.rawValue)
        object = try jsonObject.optionalDecodableValueForKey(WireObjectMessageJSONKey.object.rawValue)
        serial = try jsonObject.optionalStringValueForKey(WireObjectMessageJSONKey.serial.rawValue)
        siteCode = try jsonObject.optionalStringValueForKey(WireObjectMessageJSONKey.siteCode.rawValue)
    }
}

extension OutboundWireObjectMessage: JSONObjectEncodable {
    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [:]

        if let id {
            result[WireObjectMessageJSONKey.id.rawValue] = .string(id)
        }
        if let connectionId {
            result[WireObjectMessageJSONKey.connectionId.rawValue] = .string(connectionId)
        }
        if let timestamp {
            result[WireObjectMessageJSONKey.timestamp.rawValue] = .number(NSNumber(value: (timestamp.timeIntervalSince1970) * 1000))
        }
        if let siteCode {
            result[WireObjectMessageJSONKey.siteCode.rawValue] = .string(siteCode)
        }
        if let serial {
            result[WireObjectMessageJSONKey.serial.rawValue] = .string(serial)
        }
        if let clientId {
            result[WireObjectMessageJSONKey.clientId.rawValue] = .string(clientId)
        }
        if let extras {
            result[WireObjectMessageJSONKey.extras.rawValue] = .object(extras)
        }
        if let operation {
            result[WireObjectMessageJSONKey.operation.rawValue] = .object(operation.toJSONObject)
        }
        if let object {
            result[WireObjectMessageJSONKey.object.rawValue] = .object(object.toJSONObject)
        }
        return result
    }
}

// OOP2
internal enum ObjectOperationAction: Int {
    case mapCreate = 0
    case mapSet = 1
    case mapRemove = 2
    case counterCreate = 3
    case counterInc = 4
    case objectDelete = 5
}

// MAP2
internal enum MapSemantics: Int {
    case lww = 0
}

internal struct WireObjectOperation {
    internal var action: WireEnum<ObjectOperationAction> // OOP3a
    internal var objectId: String // OOP3b
    internal var mapOp: WireMapOp? // OOP3c
    internal var counterOp: WireCounterOp? // OOP3d
    internal var map: WireMap? // OOP3e
    internal var counter: WireCounter? // OOP3f
    internal var nonce: String? // OOP3g
    // TODO: Not yet clear how to encode / decode this property; I assume it will be properly specified later. Do in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/12
    internal var initialValue: Data? // OOP3h
    internal var initialValueEncoding: String? // OOP3i
}

extension WireObjectOperation: JSONObjectCodable {
    internal enum JSONKey: String {
        case action
        case objectId
        case mapOp
        case counterOp
        case map
        case counter
        case nonce
        case initialValue
        case initialValueEncoding
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        action = try jsonObject.wireEnumValueForKey(JSONKey.action.rawValue)
        objectId = try jsonObject.stringValueForKey(JSONKey.objectId.rawValue)
        mapOp = try jsonObject.optionalDecodableValueForKey(JSONKey.mapOp.rawValue)
        counterOp = try jsonObject.optionalDecodableValueForKey(JSONKey.counterOp.rawValue)
        map = try jsonObject.optionalDecodableValueForKey(JSONKey.map.rawValue)
        counter = try jsonObject.optionalDecodableValueForKey(JSONKey.counter.rawValue)
        nonce = try jsonObject.optionalStringValueForKey(JSONKey.nonce.rawValue)
        initialValueEncoding = try jsonObject.optionalStringValueForKey(JSONKey.initialValueEncoding.rawValue)
    }

    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [
            JSONKey.action.rawValue: .number(action.rawValue as NSNumber),
            JSONKey.objectId.rawValue: .string(objectId),
        ]

        if let mapOp {
            result[JSONKey.mapOp.rawValue] = .object(mapOp.toJSONObject)
        }
        if let counterOp {
            result[JSONKey.counterOp.rawValue] = .object(counterOp.toJSONObject)
        }
        if let map {
            result[JSONKey.map.rawValue] = .object(map.toJSONObject)
        }
        if let counter {
            result[JSONKey.counter.rawValue] = .object(counter.toJSONObject)
        }
        if let nonce {
            result[JSONKey.nonce.rawValue] = .string(nonce)
        }
        if let initialValueEncoding {
            result[JSONKey.initialValueEncoding.rawValue] = .string(initialValueEncoding)
        }

        return result
    }
}

internal struct WireObjectState {
    internal var objectId: String // OST2a
    internal var siteTimeserials: [String: String] // OST2b
    internal var tombstone: Bool // OST2c
    internal var createOp: WireObjectOperation? // OST2d
    internal var map: WireMap? // OST2e
    internal var counter: WireCounter? // OST2f
}

extension WireObjectState: JSONObjectCodable {
    internal enum JSONKey: String {
        case objectId
        case siteTimeserials
        case tombstone
        case createOp
        case map
        case counter
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        objectId = try jsonObject.stringValueForKey(JSONKey.objectId.rawValue)
        siteTimeserials = try jsonObject.objectValueForKey(JSONKey.siteTimeserials.rawValue).ablyLiveObjects_mapValuesWithTypedThrow { value throws(InternalError) in
            guard case let .string(string) = value else {
                throw JSONValueDecodingError.wrongTypeForKey(JSONKey.siteTimeserials.rawValue, actualValue: value).toInternalError()
            }
            return string
        }
        tombstone = try jsonObject.boolValueForKey(JSONKey.tombstone.rawValue)
        createOp = try jsonObject.optionalDecodableValueForKey(JSONKey.createOp.rawValue)
        map = try jsonObject.optionalDecodableValueForKey(JSONKey.map.rawValue)
        counter = try jsonObject.optionalDecodableValueForKey(JSONKey.counter.rawValue)
    }

    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [
            JSONKey.objectId.rawValue: .string(objectId),
            JSONKey.siteTimeserials.rawValue: .object(siteTimeserials.mapValues { .string($0) }),
            JSONKey.tombstone.rawValue: .bool(tombstone),
        ]

        if let createOp {
            result[JSONKey.createOp.rawValue] = .object(createOp.toJSONObject)
        }
        if let map {
            result[JSONKey.map.rawValue] = .object(map.toJSONObject)
        }
        if let counter {
            result[JSONKey.counter.rawValue] = .object(counter.toJSONObject)
        }

        return result
    }
}

internal struct WireMapOp {
    internal var key: String // MOP2a
    internal var data: WireObjectData? // MOP2b
}

extension WireMapOp: JSONObjectCodable {
    internal enum JSONKey: String {
        case key
        case data
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        key = try jsonObject.stringValueForKey(JSONKey.key.rawValue)
        data = try jsonObject.optionalDecodableValueForKey(JSONKey.data.rawValue)
    }

    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [
            JSONKey.key.rawValue: .string(key),
        ]

        if let data {
            result[JSONKey.data.rawValue] = .object(data.toJSONObject)
        }

        return result
    }
}

internal struct WireCounterOp {
    internal var amount: NSNumber // COP2a
}

extension WireCounterOp: JSONObjectCodable {
    internal enum JSONKey: String {
        case amount
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        amount = try jsonObject.numberValueForKey(JSONKey.amount.rawValue)
    }

    internal var toJSONObject: [String: JSONValue] {
        [
            JSONKey.amount.rawValue: .number(amount),
        ]
    }
}

internal struct WireMap {
    internal var semantics: WireEnum<MapSemantics> // MAP3a
    internal var entries: [String: WireMapEntry]? // MAP3b
}

extension WireMap: JSONObjectCodable {
    internal enum JSONKey: String {
        case semantics
        case entries
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        semantics = try jsonObject.wireEnumValueForKey(JSONKey.semantics.rawValue)
        entries = try jsonObject.optionalObjectValueForKey(JSONKey.entries.rawValue)?.ablyLiveObjects_mapValuesWithTypedThrow { value throws(InternalError) in
            guard case let .object(object) = value else {
                throw JSONValueDecodingError.wrongTypeForKey(JSONKey.entries.rawValue, actualValue: value).toInternalError()
            }
            return try WireMapEntry(jsonObject: object)
        }
    }

    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [
            JSONKey.semantics.rawValue: .number(semantics.rawValue as NSNumber),
        ]

        if let entries {
            result[JSONKey.entries.rawValue] = .object(entries.mapValues { .object($0.toJSONObject) })
        }

        return result
    }
}

internal struct WireCounter {
    internal var count: NSNumber? // CNT2a
}

extension WireCounter: JSONObjectCodable {
    internal enum JSONKey: String {
        case count
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        count = try jsonObject.optionalNumberValueForKey(JSONKey.count.rawValue)
    }

    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [:]
        if let count {
            result[JSONKey.count.rawValue] = .number(count)
        }
        return result
    }
}

internal struct WireMapEntry {
    internal var tombstone: Bool? // ME2a
    internal var timeserial: String? // ME2b
    internal var data: WireObjectData // ME2c
}

extension WireMapEntry: JSONObjectCodable {
    internal enum JSONKey: String {
        case tombstone
        case timeserial
        case data
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        tombstone = try jsonObject.optionalBoolValueForKey(JSONKey.tombstone.rawValue)
        timeserial = try jsonObject.optionalStringValueForKey(JSONKey.timeserial.rawValue)
        data = try jsonObject.decodableValueForKey(JSONKey.data.rawValue)
    }

    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [
            JSONKey.data.rawValue: .object(data.toJSONObject),
        ]

        if let tombstone {
            result[JSONKey.tombstone.rawValue] = .bool(tombstone)
        }
        if let timeserial {
            result[JSONKey.timeserial.rawValue] = .string(timeserial)
        }

        return result
    }
}

internal struct WireObjectData {
    internal var objectId: String? // OD2a
    internal var encoding: String? // OD2b
    internal var boolean: Bool? // OD2c
    // TODO: Not yet clear how to encode / decode this property; I assume it will be properly specified later. Do in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/12
    internal var bytes: Data? // OD2d
    internal var number: NSNumber? // OD2e
    internal var string: String? // OD2f
}

extension WireObjectData: JSONObjectCodable {
    internal enum JSONKey: String {
        case objectId
        case encoding
        case boolean
        case bytes
        case number
        case string
    }

    internal init(jsonObject: [String: JSONValue]) throws(InternalError) {
        objectId = try jsonObject.optionalStringValueForKey(JSONKey.objectId.rawValue)
        encoding = try jsonObject.optionalStringValueForKey(JSONKey.encoding.rawValue)
        boolean = try jsonObject.optionalBoolValueForKey(JSONKey.boolean.rawValue)
        number = try jsonObject.optionalNumberValueForKey(JSONKey.number.rawValue)
        string = try jsonObject.optionalStringValueForKey(JSONKey.string.rawValue)
    }

    internal var toJSONObject: [String: JSONValue] {
        var result: [String: JSONValue] = [:]

        if let objectId {
            result[JSONKey.objectId.rawValue] = .string(objectId)
        }
        if let encoding {
            result[JSONKey.encoding.rawValue] = .string(encoding)
        }
        if let boolean {
            result[JSONKey.boolean.rawValue] = .bool(boolean)
        }
        if let number {
            result[JSONKey.number.rawValue] = .number(number)
        }
        if let string {
            result[JSONKey.string.rawValue] = .string(string)
        }

        return result
    }
}
