internal import _AblyPluginSupportPrivate
import Ably
import Foundation

// This file contains the ObjectMessage types that we use within the codebase. We convert them to and from the corresponding wire types (e.g. `InboundWireObjectMessage`) for sending and receiving over the wire.

/// An `ObjectMessage` received in the `state` property of an `OBJECT` or `OBJECT_SYNC` `ProtocolMessage`.
internal struct InboundObjectMessage {
    internal var id: String? // OM2a
    internal var clientId: String? // OM2b
    internal var connectionId: String? // OM2c
    internal var extras: [String: JSONValue]? // OM2d
    internal var timestamp: Date? // OM2e
    internal var operation: ObjectOperation? // OM2f
    internal var object: ObjectState? // OM2g
    internal var serial: String? // OM2h
    internal var siteCode: String? // OM2i
    internal var serialTimestamp: Date? // OM2j
}

/// An `ObjectMessage` to be sent in the `state` property of an `OBJECT` `ProtocolMessage`.
///
/// - Important: When adding new fields, also update ``InboundObjectMessage/createSynthetic(from:serial:siteCode:)``.
internal struct OutboundObjectMessage: Equatable {
    internal var id: String? // OM2a
    internal var clientId: String? // OM2b
    internal var connectionId: String?
    internal var extras: [String: JSONValue]? // OM2d
    internal var timestamp: Date? // OM2e
    internal var operation: ObjectOperation? // OM2f
    internal var object: ObjectState? // OM2g
    internal var serial: String? // OM2h
    internal var siteCode: String? // OM2i
    internal var serialTimestamp: Date? // OM2j
}

internal struct ObjectOperation: Equatable {
    internal var action: WireEnum<ObjectOperationAction> // OOP3a
    internal var objectId: String // OOP3b
    internal var mapCreate: MapCreate? // OOP3j
    internal var mapSet: MapSet? // OOP3k
    internal var mapRemove: WireMapRemove? // OOP3l
    internal var counterCreate: WireCounterCreate? // OOP3m
    internal var counterInc: WireCounterInc? // OOP3n
    internal var objectDelete: WireObjectDelete? // OOP3o
    internal var mapCreateWithObjectId: MapCreateWithObjectId? // OOP3p
    internal var counterCreateWithObjectId: CounterCreateWithObjectId? // OOP3q
}

internal struct ObjectData: Equatable {
    internal var objectId: String? // OD2a
    internal var boolean: Bool? // OD2c
    internal var bytes: Data? // OD2d
    internal var number: NSNumber? // OD2e
    internal var string: String? // OD2f
    internal var json: JSONObjectOrArray? // TODO: Needs specification (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/46)
}

internal struct MapSet: Equatable {
    internal var key: String // MST2a
    internal var value: ObjectData? // MST2b
}

internal struct MapCreate: Equatable {
    internal var semantics: WireEnum<ObjectsMapSemantics> // MCR2a
    internal var entries: [String: ObjectsMapEntry]? // MCR2b
}

internal struct MapCreateWithObjectId: Equatable {
    internal var initialValue: String // MCRO2a
    internal var nonce: String // MCRO2b

    /// The source `MapCreate` from which this `MapCreateWithObjectId` was derived.
    /// For local use only (apply-on-ACK per RTLM23); must not be sent over the wire.
    /// - SeeAlso: RTO11f18
    internal var derivedFrom: MapCreate?
}

internal struct CounterCreateWithObjectId: Equatable {
    internal var initialValue: String // CCRO2a
    internal var nonce: String // CCRO2b

    /// The source `WireCounterCreate` from which this `CounterCreateWithObjectId` was derived.
    /// For local use only (apply-on-ACK per RTLC16); must not be sent over the wire.
    /// - SeeAlso: RTO12f16
    internal var derivedFrom: WireCounterCreate?
}

internal struct ObjectsMapEntry: Equatable {
    internal var tombstone: Bool? // OME2a
    internal var timeserial: String? // OME2b
    internal var data: ObjectData? // OME2c
    internal var serialTimestamp: Date? // OME2d
}

internal struct ObjectsMap: Equatable {
    internal var semantics: WireEnum<ObjectsMapSemantics> // OMP3a
    internal var entries: [String: ObjectsMapEntry]? // OMP3b
}

internal struct ObjectState: Equatable {
    internal var objectId: String // OST2a
    internal var siteTimeserials: [String: String] // OST2b
    internal var tombstone: Bool // OST2c
    internal var createOp: ObjectOperation? // OST2d
    internal var map: ObjectsMap? // OST2e
    internal var counter: WireObjectsCounter? // OST2f
}

internal extension InboundObjectMessage {
    /// Initializes an `InboundObjectMessage` from an `InboundWireObjectMessage`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `ARTErrorInfo` if JSON or Base64 decoding fails.
    init(
        wireObjectMessage: InboundWireObjectMessage,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        id = wireObjectMessage.id
        clientId = wireObjectMessage.clientId
        connectionId = wireObjectMessage.connectionId
        extras = wireObjectMessage.extras
        timestamp = wireObjectMessage.timestamp
        operation = try wireObjectMessage.operation.map { wireObjectOperation throws(ARTErrorInfo) in
            try .init(wireObjectOperation: wireObjectOperation, format: format)
        }
        object = try wireObjectMessage.object.map { wireObjectState throws(ARTErrorInfo) in
            try .init(wireObjectState: wireObjectState, format: format)
        }
        serial = wireObjectMessage.serial
        siteCode = wireObjectMessage.siteCode
        serialTimestamp = wireObjectMessage.serialTimestamp
    }
}

internal extension OutboundObjectMessage {
    /// Converts this `OutboundObjectMessage` to an `OutboundWireObjectMessage`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> OutboundWireObjectMessage {
        .init(
            id: id,
            clientId: clientId,
            connectionId: connectionId,
            extras: extras,
            timestamp: timestamp,
            operation: operation?.toWire(format: format),
            object: object?.toWire(format: format),
            serial: serial,
            siteCode: siteCode,
            serialTimestamp: serialTimestamp,
        )
    }
}

internal extension ObjectOperation {
    /// Initializes an `ObjectOperation` from a `WireObjectOperation`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `ARTErrorInfo` if JSON or Base64 decoding fails.
    init(
        wireObjectOperation: WireObjectOperation,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        action = wireObjectOperation.action
        objectId = wireObjectOperation.objectId

        mapCreate = try wireObjectOperation.mapCreate.map { wireMapCreate throws(ARTErrorInfo) in
            try .init(wireMapCreate: wireMapCreate, format: format)
        }
        mapSet = try wireObjectOperation.mapSet.map { wireMapSet throws(ARTErrorInfo) in
            try .init(wireMapSet: wireMapSet, format: format)
        }
        mapRemove = wireObjectOperation.mapRemove
        counterCreate = wireObjectOperation.counterCreate
        counterInc = wireObjectOperation.counterInc
        objectDelete = wireObjectOperation.objectDelete
        // Outbound-only — do not access on inbound data
        mapCreateWithObjectId = nil
        counterCreateWithObjectId = nil
    }

    /// Converts this `ObjectOperation` to a `WireObjectOperation`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> WireObjectOperation {
        .init(
            action: action,
            objectId: objectId,
            mapCreate: mapCreate?.toWire(format: format),
            mapSet: mapSet?.toWire(format: format),
            mapRemove: mapRemove,
            counterCreate: counterCreate,
            counterInc: counterInc,
            objectDelete: objectDelete,
            mapCreateWithObjectId: mapCreateWithObjectId?.toWire(),
            counterCreateWithObjectId: counterCreateWithObjectId?.toWire(),
        )
    }
}

internal extension ObjectData {
    /// Initializes an `ObjectData` from a `WireObjectData`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `ARTErrorInfo` if JSON or Base64 decoding fails.
    init(
        wireObjectData: WireObjectData,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        objectId = wireObjectData.objectId
        boolean = wireObjectData.boolean
        number = wireObjectData.number
        string = wireObjectData.string

        // OD5: Decode data based on format
        switch format {
        case .messagePack:
            // OD5a: When the MessagePack protocol is used
            // OD5a1: The payloads in (…) ObjectData.bytes (…) are decoded as their corresponding MessagePack types
            if let wireBytes = wireObjectData.bytes {
                switch wireBytes {
                case let .data(data):
                    bytes = data
                case .string:
                    // Not very clear what we're meant to do if `bytes` contains a string; let's ignore it. I think it's a bit moot - shouldn't happen. The only reason I'm considering it here is because of our slightly weird WireObjectData.bytes type which is typed as a string or data; might be good to at some point figure out how to rule out the string case earlier when using MessagePack, but it's not a big issue
                    bytes = nil
                }
            } else {
                bytes = nil
            }
        case .json:
            // OD5b: When the JSON protocol is used
            // OD5b2: The ObjectData.bytes payload is Base64-decoded into a binary value
            if let wireBytes = wireObjectData.bytes {
                switch wireBytes {
                case let .string(base64String):
                    bytes = try Data.fromBase64Throwing(base64String)
                case .data:
                    // This is an error in our logic, not a malformed wire value
                    preconditionFailure("Should not receive Data for JSON encoding format")
                }
            } else {
                bytes = nil
            }
        }

        // TODO: Needs specification (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/46)
        if let wireJson = wireObjectData.json {
            let jsonValue = try JSONObjectOrArray(jsonString: wireJson)
            json = jsonValue
        } else {
            json = nil
        }
    }

    /// Converts this `ObjectData` to a `WireObjectData`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> WireObjectData {
        // OD4: Encode data based on format
        let wireBytes: StringOrData? = if let bytes {
            switch format {
            case .messagePack:
                // OD4c: When the MessagePack protocol is used
                // OD4c2: A binary payload is encoded as a MessagePack binary type, and the result is set on the ObjectData.bytes attribute
                .data(bytes)
            case .json:
                // OD4d: When the JSON protocol is used
                // OD4d2: A binary payload is Base64-encoded and represented as a JSON string; the result is set on the ObjectData.bytes attribute
                .string(bytes.base64EncodedString())
            }
        } else {
            nil
        }

        let wireNumber: NSNumber? = if let number {
            switch format {
            case .json:
                number
            case .messagePack:
                // OD4c: When the MessagePack protocol is used
                // OD4c3 A number payload is encoded as a MessagePack float64 type, and the result is set on the ObjectData.number attribute
                .init(value: number.doubleValue)
            }
        } else {
            nil
        }

        return .init(
            objectId: objectId,
            boolean: boolean,
            bytes: wireBytes,
            number: wireNumber,
            // OD4c4: A string payload is encoded as a MessagePack string type, and the result is set on the ObjectData.string attribute
            // OD4d4: A string payload is represented as a JSON string and set on the ObjectData.string attribute
            string: string,
            // TODO: Needs specification (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/46)
            json: json?.toJSONString,
        )
    }
}

internal extension MapSet {
    init(
        wireMapSet: WireMapSet,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        key = wireMapSet.key
        value = try wireMapSet.value.map { wireObjectData throws(ARTErrorInfo) in
            try .init(wireObjectData: wireObjectData, format: format)
        }
    }

    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> WireMapSet {
        .init(
            key: key,
            value: value?.toWire(format: format),
        )
    }
}

internal extension MapCreate {
    init(
        wireMapCreate: WireMapCreate,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        semantics = wireMapCreate.semantics
        entries = try wireMapCreate.entries?.ablyLiveObjects_mapValuesWithTypedThrow { wireMapEntry throws(ARTErrorInfo) in
            try .init(wireObjectsMapEntry: wireMapEntry, format: format)
        }
    }

    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> WireMapCreate {
        .init(
            semantics: semantics,
            entries: entries?.mapValues { $0.toWire(format: format) },
        )
    }
}

internal extension MapCreateWithObjectId {
    init(wireMapCreateWithObjectId: WireMapCreateWithObjectId) {
        nonce = wireMapCreateWithObjectId.nonce
        initialValue = wireMapCreateWithObjectId.initialValue
    }

    func toWire() -> WireMapCreateWithObjectId {
        .init(initialValue: initialValue, nonce: nonce)
    }
}

internal extension CounterCreateWithObjectId {
    init(wireCounterCreateWithObjectId: WireCounterCreateWithObjectId) {
        nonce = wireCounterCreateWithObjectId.nonce
        initialValue = wireCounterCreateWithObjectId.initialValue
    }

    func toWire() -> WireCounterCreateWithObjectId {
        .init(initialValue: initialValue, nonce: nonce)
    }
}

internal extension ObjectsMapEntry {
    /// Initializes an `ObjectsMapEntry` from a `WireObjectsMapEntry`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `ARTErrorInfo` if JSON or Base64 decoding fails.
    init(
        wireObjectsMapEntry: WireObjectsMapEntry,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        tombstone = wireObjectsMapEntry.tombstone
        timeserial = wireObjectsMapEntry.timeserial
        data = if let wireObjectData = wireObjectsMapEntry.data {
            try .init(wireObjectData: wireObjectData, format: format)
        } else {
            nil
        }
        serialTimestamp = wireObjectsMapEntry.serialTimestamp
    }

    /// Converts this `ObjectsMapEntry` to a `WireObjectsMapEntry`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> WireObjectsMapEntry {
        .init(
            tombstone: tombstone,
            timeserial: timeserial,
            data: data?.toWire(format: format),
        )
    }
}

internal extension ObjectsMap {
    /// Initializes an `ObjectsMap` from a `WireObjectsMap`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `ARTErrorInfo` if JSON or Base64 decoding fails.
    init(
        wireObjectsMap: WireObjectsMap,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        semantics = wireObjectsMap.semantics
        entries = try wireObjectsMap.entries?.ablyLiveObjects_mapValuesWithTypedThrow { wireMapEntry throws(ARTErrorInfo) in
            try .init(wireObjectsMapEntry: wireMapEntry, format: format)
        }
    }

    /// Converts this `ObjectsMap` to a `WireObjectsMap`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> WireObjectsMap {
        .init(
            semantics: semantics,
            entries: entries?.mapValues { $0.toWire(format: format) },
        )
    }
}

internal extension ObjectState {
    /// Initializes an `ObjectState` from a `WireObjectState`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `ARTErrorInfo` if JSON or Base64 decoding fails.
    init(
        wireObjectState: WireObjectState,
        format: _AblyPluginSupportPrivate.EncodingFormat
    ) throws(ARTErrorInfo) {
        objectId = wireObjectState.objectId
        siteTimeserials = wireObjectState.siteTimeserials
        tombstone = wireObjectState.tombstone
        createOp = try wireObjectState.createOp.map { wireObjectOperation throws(ARTErrorInfo) in
            try .init(wireObjectOperation: wireObjectOperation, format: format)
        }
        map = try wireObjectState.map.map { wireObjectsMap throws(ARTErrorInfo) in
            try .init(wireObjectsMap: wireObjectsMap, format: format)
        }
        counter = wireObjectState.counter
    }

    /// Converts this `ObjectState` to a `WireObjectState`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: _AblyPluginSupportPrivate.EncodingFormat) -> WireObjectState {
        .init(
            objectId: objectId,
            siteTimeserials: siteTimeserials,
            tombstone: tombstone,
            createOp: createOp?.toWire(format: format),
            map: map?.toWire(format: format),
            counter: counter,
        )
    }
}

// MARK: - CustomDebugStringConvertible

extension InboundObjectMessage: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        if let id { parts.append("id: \(id)") }
        if let clientId { parts.append("clientId: \(clientId)") }
        if let connectionId { parts.append("connectionId: \(connectionId)") }
        if let extras { parts.append("extras: \(extras)") }
        if let timestamp { parts.append("timestamp: \(timestamp)") }
        if let operation { parts.append("operation: \(operation)") }
        if let object { parts.append("object: \(object)") }
        if let serial { parts.append("serial: \(serial)") }
        if let siteCode { parts.append("siteCode: \(siteCode)") }
        if let serialTimestamp { parts.append("serialTimestamp: \(serialTimestamp)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension OutboundObjectMessage: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        if let id { parts.append("id: \(id)") }
        if let clientId { parts.append("clientId: \(clientId)") }
        if let connectionId { parts.append("connectionId: \(connectionId)") }
        if let extras { parts.append("extras: \(extras)") }
        if let timestamp { parts.append("timestamp: \(timestamp)") }
        if let operation { parts.append("operation: \(operation)") }
        if let object { parts.append("object: \(object)") }
        if let serial { parts.append("serial: \(serial)") }
        if let siteCode { parts.append("siteCode: \(siteCode)") }
        if let serialTimestamp { parts.append("serialTimestamp: \(serialTimestamp)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension ObjectOperation: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        parts.append("action: \(action)")
        parts.append("objectId: \(objectId)")
        if let mapCreate { parts.append("mapCreate: \(mapCreate)") }
        if let mapSet { parts.append("mapSet: \(mapSet)") }
        if let mapRemove { parts.append("mapRemove: \(mapRemove)") }
        if let counterCreate { parts.append("counterCreate: \(counterCreate)") }
        if let counterInc { parts.append("counterInc: \(counterInc)") }
        if let objectDelete { parts.append("objectDelete: \(objectDelete)") }
        if let mapCreateWithObjectId { parts.append("mapCreateWithObjectId: \(mapCreateWithObjectId)") }
        if let counterCreateWithObjectId { parts.append("counterCreateWithObjectId: \(counterCreateWithObjectId)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension ObjectState: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        parts.append("objectId: \(objectId)")
        parts.append("siteTimeserials: \(siteTimeserials)")
        parts.append("tombstone: \(tombstone)")
        if let createOp { parts.append("createOp: \(createOp)") }
        if let map { parts.append("map: \(map)") }
        if let counter { parts.append("counter: \(counter)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension ObjectsMap: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        parts.append("semantics: \(semantics)")
        if let entries {
            let formattedEntries = entries
                .map { key, entry in
                    "\(key): \(entry)"
                }
                .joined(separator: ", ")
            parts.append("entries: { \(formattedEntries) }")
        }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension ObjectsMapEntry: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        if let tombstone { parts.append("tombstone: \(tombstone)") }
        if let timeserial { parts.append("timeserial: \(timeserial)") }
        if let data { parts.append("data: \(data)") }
        if let serialTimestamp { parts.append("serialTimestamp: \(serialTimestamp)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension ObjectData: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        if let objectId { parts.append("objectId: \(objectId)") }
        if let boolean { parts.append("boolean: \(boolean)") }
        if let bytes { parts.append("bytes: \(bytes.count) bytes") }
        if let number { parts.append("number: \(number)") }
        if let string { parts.append("string: \(string)") }
        if let json { parts.append("json: \(json)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension MapSet: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        parts.append("key: \(key)")
        if let value { parts.append("value: \(value)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension MapCreate: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        parts.append("semantics: \(semantics)")
        if let entries {
            let formattedEntries = entries
                .map { key, entry in
                    "\(key): \(entry)"
                }
                .joined(separator: ", ")
            parts.append("entries: { \(formattedEntries) }")
        }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension MapCreateWithObjectId: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        parts.append("initialValue: \(initialValue)")
        parts.append("nonce: \(nonce)")
        if let derivedFrom { parts.append("derivedFrom: \(derivedFrom)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}

extension CounterCreateWithObjectId: CustomDebugStringConvertible {
    internal var debugDescription: String {
        var parts: [String] = []

        parts.append("initialValue: \(initialValue)")
        parts.append("nonce: \(nonce)")
        if let derivedFrom { parts.append("derivedFrom: \(derivedFrom)") }

        return "{ " + parts.joined(separator: ", ") + " }"
    }
}
