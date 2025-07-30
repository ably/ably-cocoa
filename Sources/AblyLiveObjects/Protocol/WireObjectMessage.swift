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
    internal var serialTimestamp: Date? // OM2j
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
    internal var serialTimestamp: Date? // OM2j
}

/// The keys for decoding an `InboundWireObjectMessage` or encoding an `OutboundWireObjectMessage`.
internal enum WireObjectMessageWireKey: String {
    case id
    case clientId
    case connectionId
    case extras
    case timestamp
    case operation
    case object
    case serial
    case siteCode
    case serialTimestamp
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
        wireObject: [String: WireValue],
        decodingContext: AblyPlugin.DecodingContextProtocol
    ) throws(InternalError) {
        // OM2a
        if let id = try wireObject.optionalStringValueForKey(WireObjectMessageWireKey.id.rawValue) {
            self.id = id
        } else if let parentID = decodingContext.parentID {
            id = "\(parentID):\(decodingContext.indexInParent)"
        }

        clientId = try wireObject.optionalStringValueForKey(WireObjectMessageWireKey.clientId.rawValue)

        // OM2c
        if let connectionId = try wireObject.optionalStringValueForKey(WireObjectMessageWireKey.connectionId.rawValue) {
            self.connectionId = connectionId
        } else if let parentConnectionID = decodingContext.parentConnectionID {
            connectionId = parentConnectionID
        }

        // Convert WireValue extras to JSONValue extras
        if let wireExtras = try wireObject.optionalObjectValueForKey(WireObjectMessageWireKey.extras.rawValue) {
            extras = try wireExtras.ablyLiveObjects_mapValuesWithTypedThrow { wireValue throws(InternalError) in
                try wireValue.toJSONValue
            }
        } else {
            extras = nil
        }

        // OM2e
        if let timestamp = try wireObject.optionalAblyProtocolDateValueForKey(WireObjectMessageWireKey.timestamp.rawValue) {
            self.timestamp = timestamp
        } else if let parentTimestamp = decodingContext.parentTimestamp {
            timestamp = parentTimestamp
        }

        operation = try wireObject.optionalDecodableValueForKey(WireObjectMessageWireKey.operation.rawValue)
        object = try wireObject.optionalDecodableValueForKey(WireObjectMessageWireKey.object.rawValue)
        serial = try wireObject.optionalStringValueForKey(WireObjectMessageWireKey.serial.rawValue)
        siteCode = try wireObject.optionalStringValueForKey(WireObjectMessageWireKey.siteCode.rawValue)
        serialTimestamp = try wireObject.optionalAblyProtocolDateValueForKey(WireObjectMessageWireKey.serialTimestamp.rawValue)
    }
}

extension OutboundWireObjectMessage: WireObjectEncodable {
    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [:]

        if let id {
            result[WireObjectMessageWireKey.id.rawValue] = .string(id)
        }
        if let connectionId {
            result[WireObjectMessageWireKey.connectionId.rawValue] = .string(connectionId)
        }
        if let timestamp {
            result[WireObjectMessageWireKey.timestamp.rawValue] = .number(NSNumber(value: (timestamp.timeIntervalSince1970) * 1000))
        }
        if let siteCode {
            result[WireObjectMessageWireKey.siteCode.rawValue] = .string(siteCode)
        }
        if let serial {
            result[WireObjectMessageWireKey.serial.rawValue] = .string(serial)
        }
        if let clientId {
            result[WireObjectMessageWireKey.clientId.rawValue] = .string(clientId)
        }
        if let extras {
            // Convert JSONValue extras to WireValue extras
            result[WireObjectMessageWireKey.extras.rawValue] = .object(extras.mapValues { .init(jsonValue: $0) })
        }
        if let operation {
            result[WireObjectMessageWireKey.operation.rawValue] = .object(operation.toWireObject)
        }
        if let object {
            result[WireObjectMessageWireKey.object.rawValue] = .object(object.toWireObject)
        }
        if let serialTimestamp {
            result[WireObjectMessageWireKey.serialTimestamp.rawValue] = .number(NSNumber(value: serialTimestamp.timeIntervalSince1970 * 1000))
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

// OMP2
internal enum ObjectsMapSemantics: Int {
    case lww = 0
}

/// A partial version of `WireObjectOperation` that excludes the `objectId` property. Used for encoding initial values where the `objectId` is not yet known.
///
/// `WireObjectOperation` delegates its encoding and decoding to `PartialWireObjectOperation`.
internal struct PartialWireObjectOperation {
    internal var action: WireEnum<ObjectOperationAction> // OOP3a
    internal var mapOp: WireObjectsMapOp? // OOP3c
    internal var counterOp: WireObjectsCounterOp? // OOP3d
    internal var map: WireObjectsMap? // OOP3e
    internal var counter: WireObjectsCounter? // OOP3f
    internal var nonce: String? // OOP3g
    internal var initialValue: String? // OOP3h
}

extension PartialWireObjectOperation: WireObjectCodable {
    internal enum WireKey: String {
        case action
        case mapOp
        case counterOp
        case map
        case counter
        case nonce
        case initialValue
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        action = try wireObject.wireEnumValueForKey(WireKey.action.rawValue)
        mapOp = try wireObject.optionalDecodableValueForKey(WireKey.mapOp.rawValue)
        counterOp = try wireObject.optionalDecodableValueForKey(WireKey.counterOp.rawValue)
        map = try wireObject.optionalDecodableValueForKey(WireKey.map.rawValue)
        counter = try wireObject.optionalDecodableValueForKey(WireKey.counter.rawValue)

        // Do not access on inbound data, per OOP3g
        nonce = nil
        // Do not access on inbound data, per OOP3h
        initialValue = nil
    }

    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [
            WireKey.action.rawValue: .number(action.rawValue as NSNumber),
        ]

        if let mapOp {
            result[WireKey.mapOp.rawValue] = .object(mapOp.toWireObject)
        }
        if let counterOp {
            result[WireKey.counterOp.rawValue] = .object(counterOp.toWireObject)
        }
        if let map {
            result[WireKey.map.rawValue] = .object(map.toWireObject)
        }
        if let counter {
            result[WireKey.counter.rawValue] = .object(counter.toWireObject)
        }
        if let nonce {
            result[WireKey.nonce.rawValue] = .string(nonce)
        }
        if let initialValue {
            result[WireKey.initialValue.rawValue] = .string(initialValue)
        }

        return result
    }
}

internal struct WireObjectOperation {
    internal var action: WireEnum<ObjectOperationAction> // OOP3a
    internal var objectId: String // OOP3b
    internal var mapOp: WireObjectsMapOp? // OOP3c
    internal var counterOp: WireObjectsCounterOp? // OOP3d
    internal var map: WireObjectsMap? // OOP3e
    internal var counter: WireObjectsCounter? // OOP3f
    internal var nonce: String? // OOP3g
    internal var initialValue: String? // OOP3h
}

extension WireObjectOperation: WireObjectCodable {
    internal enum WireKey: String {
        case objectId
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        // Decode the objectId first since it's not part of PartialWireObjectOperation
        objectId = try wireObject.stringValueForKey(WireKey.objectId.rawValue)

        // Delegate to PartialWireObjectOperation for decoding
        let partialOperation = try PartialWireObjectOperation(wireObject: wireObject)

        // Copy the decoded values
        action = partialOperation.action
        mapOp = partialOperation.mapOp
        counterOp = partialOperation.counterOp
        map = partialOperation.map
        counter = partialOperation.counter
        nonce = partialOperation.nonce
        initialValue = partialOperation.initialValue
    }

    internal var toWireObject: [String: WireValue] {
        var result = PartialWireObjectOperation(
            action: action,
            mapOp: mapOp,
            counterOp: counterOp,
            map: map,
            counter: counter,
            nonce: nonce,
            initialValue: initialValue,
        ).toWireObject

        // Add the objectId field
        result[WireKey.objectId.rawValue] = .string(objectId)

        return result
    }
}

internal struct WireObjectState {
    internal var objectId: String // OST2a
    internal var siteTimeserials: [String: String] // OST2b
    internal var tombstone: Bool // OST2c
    internal var createOp: WireObjectOperation? // OST2d
    internal var map: WireObjectsMap? // OST2e
    internal var counter: WireObjectsCounter? // OST2f
}

extension WireObjectState: WireObjectCodable {
    internal enum WireKey: String {
        case objectId
        case siteTimeserials
        case tombstone
        case createOp
        case map
        case counter
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        objectId = try wireObject.stringValueForKey(WireKey.objectId.rawValue)
        siteTimeserials = try wireObject.objectValueForKey(WireKey.siteTimeserials.rawValue).ablyLiveObjects_mapValuesWithTypedThrow { value throws(InternalError) in
            guard case let .string(string) = value else {
                throw WireValueDecodingError.wrongTypeForKey(WireKey.siteTimeserials.rawValue, actualValue: value).toInternalError()
            }
            return string
        }
        tombstone = try wireObject.boolValueForKey(WireKey.tombstone.rawValue)
        createOp = try wireObject.optionalDecodableValueForKey(WireKey.createOp.rawValue)
        map = try wireObject.optionalDecodableValueForKey(WireKey.map.rawValue)
        counter = try wireObject.optionalDecodableValueForKey(WireKey.counter.rawValue)
    }

    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [
            WireKey.objectId.rawValue: .string(objectId),
            WireKey.siteTimeserials.rawValue: .object(siteTimeserials.mapValues { .string($0) }),
            WireKey.tombstone.rawValue: .bool(tombstone),
        ]

        if let createOp {
            result[WireKey.createOp.rawValue] = .object(createOp.toWireObject)
        }
        if let map {
            result[WireKey.map.rawValue] = .object(map.toWireObject)
        }
        if let counter {
            result[WireKey.counter.rawValue] = .object(counter.toWireObject)
        }

        return result
    }
}

internal struct WireObjectsMapOp {
    internal var key: String // OMO2a
    internal var data: WireObjectData? // OMO2b
}

extension WireObjectsMapOp: WireObjectCodable {
    internal enum WireKey: String {
        case key
        case data
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        key = try wireObject.stringValueForKey(WireKey.key.rawValue)
        data = try wireObject.optionalDecodableValueForKey(WireKey.data.rawValue)
    }

    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [
            WireKey.key.rawValue: .string(key),
        ]

        if let data {
            result[WireKey.data.rawValue] = .object(data.toWireObject)
        }

        return result
    }
}

internal struct WireObjectsCounterOp {
    internal var amount: NSNumber // OCO2a
}

extension WireObjectsCounterOp: WireObjectCodable {
    internal enum WireKey: String {
        case amount
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        amount = try wireObject.numberValueForKey(WireKey.amount.rawValue)
    }

    internal var toWireObject: [String: WireValue] {
        [
            WireKey.amount.rawValue: .number(amount),
        ]
    }
}

internal struct WireObjectsMap {
    internal var semantics: WireEnum<ObjectsMapSemantics> // OMP3a
    internal var entries: [String: WireObjectsMapEntry]? // OMP3b
}

extension WireObjectsMap: WireObjectCodable {
    internal enum WireKey: String {
        case semantics
        case entries
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        semantics = try wireObject.wireEnumValueForKey(WireKey.semantics.rawValue)
        entries = try wireObject.optionalObjectValueForKey(WireKey.entries.rawValue)?.ablyLiveObjects_mapValuesWithTypedThrow { value throws(InternalError) in
            guard case let .object(object) = value else {
                throw WireValueDecodingError.wrongTypeForKey(WireKey.entries.rawValue, actualValue: value).toInternalError()
            }
            return try WireObjectsMapEntry(wireObject: object)
        }
    }

    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [
            WireKey.semantics.rawValue: .number(semantics.rawValue as NSNumber),
        ]

        if let entries {
            result[WireKey.entries.rawValue] = .object(entries.mapValues { .object($0.toWireObject) })
        }

        return result
    }
}

internal struct WireObjectsCounter {
    internal var count: NSNumber? // OCN2a
}

extension WireObjectsCounter: WireObjectCodable {
    internal enum WireKey: String {
        case count
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        count = try wireObject.optionalNumberValueForKey(WireKey.count.rawValue)
    }

    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [:]
        if let count {
            result[WireKey.count.rawValue] = .number(count)
        }
        return result
    }
}

internal struct WireObjectsMapEntry {
    internal var tombstone: Bool? // OME2a
    internal var timeserial: String? // OME2b
    internal var data: WireObjectData // OME2c
    internal var serialTimestamp: Date? // OME2d
}

extension WireObjectsMapEntry: WireObjectCodable {
    internal enum WireKey: String {
        case tombstone
        case timeserial
        case data
        case serialTimestamp
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        tombstone = try wireObject.optionalBoolValueForKey(WireKey.tombstone.rawValue)
        timeserial = try wireObject.optionalStringValueForKey(WireKey.timeserial.rawValue)
        data = try wireObject.decodableValueForKey(WireKey.data.rawValue)
        serialTimestamp = try wireObject.optionalAblyProtocolDateValueForKey(WireKey.serialTimestamp.rawValue)
    }

    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [
            WireKey.data.rawValue: .object(data.toWireObject),
        ]

        if let tombstone {
            result[WireKey.tombstone.rawValue] = .bool(tombstone)
        }
        if let timeserial {
            result[WireKey.timeserial.rawValue] = .string(timeserial)
        }
        if let serialTimestamp {
            result[WireKey.serialTimestamp.rawValue] = .number(NSNumber(value: serialTimestamp.timeIntervalSince1970 * 1000))
        }

        return result
    }
}

internal struct WireObjectData {
    internal var objectId: String? // OD2a
    internal var encoding: String? // OD2b
    internal var boolean: Bool? // OD2c
    internal var bytes: StringOrData? // OD2d
    internal var number: NSNumber? // OD2e
    internal var string: String? // OD2f
}

extension WireObjectData: WireObjectCodable {
    internal enum WireKey: String {
        case objectId
        case encoding
        case boolean
        case bytes
        case number
        case string
    }

    internal init(wireObject: [String: WireValue]) throws(InternalError) {
        objectId = try wireObject.optionalStringValueForKey(WireKey.objectId.rawValue)
        encoding = try wireObject.optionalStringValueForKey(WireKey.encoding.rawValue)
        boolean = try wireObject.optionalBoolValueForKey(WireKey.boolean.rawValue)
        bytes = try wireObject.optionalDecodableValueForKey(WireKey.bytes.rawValue)
        number = try wireObject.optionalNumberValueForKey(WireKey.number.rawValue)
        string = try wireObject.optionalStringValueForKey(WireKey.string.rawValue)
    }

    internal var toWireObject: [String: WireValue] {
        var result: [String: WireValue] = [:]

        if let objectId {
            result[WireKey.objectId.rawValue] = .string(objectId)
        }
        if let encoding {
            result[WireKey.encoding.rawValue] = .string(encoding)
        }
        if let boolean {
            result[WireKey.boolean.rawValue] = .bool(boolean)
        }
        if let bytes {
            result[WireKey.bytes.rawValue] = bytes.toWireValue
        }
        if let number {
            result[WireKey.number.rawValue] = .number(number)
        }
        if let string {
            result[WireKey.string.rawValue] = .string(string)
        }

        return result
    }
}

/// A type that can be either a string or binary data.
///
/// Used to represent the values that `WireObjectData.bytes` might hold, after being encoded per OD4 or before being decoded per OD5.
internal enum StringOrData: WireCodable {
    case string(String)
    case data(Data)

    /// An error that can occur when decoding a ``StringOrData``.
    internal enum DecodingError: Error {
        case unsupportedValue(WireValue)
    }

    internal init(wireValue: WireValue) throws(InternalError) {
        self = switch wireValue {
        case let .string(string):
            .string(string)
        case let .data(data):
            .data(data)
        default:
            throw DecodingError.unsupportedValue(wireValue).toInternalError()
        }
    }

    internal var toWireValue: WireValue {
        switch self {
        case let .string(string):
            .string(string)
        case let .data(data):
            .data(data)
        }
    }
}
