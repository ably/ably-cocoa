internal import AblyPlugin
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
}

/// An `ObjectMessage` to be sent in the `state` property of an `OBJECT` `ProtocolMessage`.
internal struct OutboundObjectMessage {
    internal var id: String? // OM2a
    internal var clientId: String? // OM2b
    internal var connectionId: String?
    internal var extras: [String: JSONValue]? // OM2d
    internal var timestamp: Date? // OM2e
    internal var operation: ObjectOperation? // OM2f
    internal var object: ObjectState? // OM2g
    internal var serial: String? // OM2h
    internal var siteCode: String? // OM2i
}

internal struct ObjectOperation {
    internal var action: WireEnum<ObjectOperationAction> // OOP3a
    internal var objectId: String // OOP3b
    internal var mapOp: MapOp? // OOP3c
    internal var counterOp: WireCounterOp? // OOP3d
    internal var map: Map? // OOP3e
    internal var counter: WireCounter? // OOP3f
    internal var nonce: String? // OOP3g
    internal var initialValue: Data? // OOP3h
    internal var initialValueEncoding: String? // OOP3i
}

internal struct ObjectData {
    /// The values that the `string` property might hold, before being encoded per OD4 or after being decoded per OD5.
    internal enum StringPropertyContent {
        case string(String)
        case json(JSONObjectOrArray)
    }

    internal var objectId: String? // OD2a
    internal var encoding: String? // OD2b
    internal var boolean: Bool? // OD2c
    internal var bytes: Data? // OD2d
    internal var number: NSNumber? // OD2e
    internal var string: StringPropertyContent? // OD2f
}

internal struct MapOp {
    internal var key: String // MOP2a
    internal var data: ObjectData? // MOP2b
}

internal struct MapEntry {
    internal var tombstone: Bool? // ME2a
    internal var timeserial: String? // ME2b
    internal var data: ObjectData // ME2c
}

internal struct Map {
    internal var semantics: WireEnum<MapSemantics> // MAP3a
    internal var entries: [String: MapEntry]? // MAP3b
}

internal struct ObjectState {
    internal var objectId: String // OST2a
    internal var siteTimeserials: [String: String] // OST2b
    internal var tombstone: Bool // OST2c
    internal var createOp: ObjectOperation? // OST2d
    internal var map: Map? // OST2e
    internal var counter: WireCounter? // OST2f
}

internal extension InboundObjectMessage {
    /// Initializes an `InboundObjectMessage` from an `InboundWireObjectMessage`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireObjectMessage: InboundWireObjectMessage,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        id = wireObjectMessage.id
        clientId = wireObjectMessage.clientId
        connectionId = wireObjectMessage.connectionId
        extras = wireObjectMessage.extras
        timestamp = wireObjectMessage.timestamp
        operation = try wireObjectMessage.operation.map { wireObjectOperation throws(InternalError) in
            try .init(wireObjectOperation: wireObjectOperation, format: format)
        }
        object = try wireObjectMessage.object.map { wireObjectState throws(InternalError) in
            try .init(wireObjectState: wireObjectState, format: format)
        }
        serial = wireObjectMessage.serial
        siteCode = wireObjectMessage.siteCode
    }
}

internal extension OutboundObjectMessage {
    /// Converts this `OutboundObjectMessage` to an `OutboundWireObjectMessage`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> OutboundWireObjectMessage {
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
        )
    }
}

internal extension ObjectOperation {
    /// Initializes an `ObjectOperation` from a `WireObjectOperation`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireObjectOperation: WireObjectOperation,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        action = wireObjectOperation.action
        objectId = wireObjectOperation.objectId
        mapOp = try wireObjectOperation.mapOp.map { wireMapOp throws(InternalError) in
            try .init(wireMapOp: wireMapOp, format: format)
        }
        counterOp = wireObjectOperation.counterOp
        map = try wireObjectOperation.map.map { wireMap throws(InternalError) in
            try .init(wireMap: wireMap, format: format)
        }
        counter = wireObjectOperation.counter

        // Do not access on inbound data, per OOP3g
        nonce = nil
        // Do not access on inbound data, per OOP3h
        initialValue = nil
        // Do not access on inbound data, per OOP3i
        initialValueEncoding = nil
    }

    /// Converts this `ObjectOperation` to a `WireObjectOperation`, applying the data encoding rules of OD4 and OOP5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4 and OOP5.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireObjectOperation {
        // OOP5: Encode initialValue based on format
        let wireInitialValue: StringOrData?
        let wireInitialValueEncoding: String?

        if let initialValue {
            switch format {
            case .messagePack:
                // OOP5a: When the MessagePack protocol is used
                // OOP5a1: A binary ObjectOperation.initialValue is encoded as a MessagePack binary type
                wireInitialValue = .data(initialValue)
                // OOP5a2: Set ObjectOperation.initialValueEncoding to msgpack
                wireInitialValueEncoding = "msgpack"

            case .json:
                // OOP5b: When the JSON protocol is used
                // OOP5b1: A binary ObjectOperation.initialValue is Base64-encoded and represented as a JSON string
                wireInitialValue = .string(initialValue.base64EncodedString())
                // OOP5b2: Set ObjectOperation.initialValueEncoding to json
                wireInitialValueEncoding = "json"
            }
        } else {
            wireInitialValue = nil
            wireInitialValueEncoding = nil
        }

        return .init(
            action: action,
            objectId: objectId,
            mapOp: mapOp?.toWire(format: format),
            counterOp: counterOp,
            map: map?.toWire(format: format),
            counter: counter,
            nonce: nonce,
            initialValue: wireInitialValue,
            initialValueEncoding: wireInitialValueEncoding,
        )
    }
}

internal extension ObjectData {
    /// Initializes an `ObjectData` from a `WireObjectData`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireObjectData: WireObjectData,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        objectId = wireObjectData.objectId
        encoding = wireObjectData.encoding
        boolean = wireObjectData.boolean
        number = wireObjectData.number

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

        if let wireString = wireObjectData.string {
            // OD5a2, OD5b3: If ObjectData.encoding is set to "json", the ObjectData.string content is decoded by parsing the string as JSON
            if wireObjectData.encoding == "json" {
                let jsonValue = try JSONObjectOrArray(jsonString: wireString)
                string = .json(jsonValue)
            } else {
                string = .string(wireString)
            }
        } else {
            string = nil
        }
    }

    /// Converts this `ObjectData` to a `WireObjectData`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireObjectData {
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

        // OD4c4: A string payload is encoded as a MessagePack string type, and the result is set on the ObjectData.string attribute
        // OD4d4: A string payload is represented as a JSON string and set on the ObjectData.string attribute
        let (wireString, wireEncoding): (String?, String?) = if let stringContent = string {
            switch stringContent {
            case let .string(str):
                (str, nil)
            case let .json(jsonValue):
                // OD4c5, OD4d5: A payload consisting of a JSON-encodable object or array is stringified as a JSON object or array, represented as a JSON string and the result is set on the ObjectData.string attribute. The ObjectData.encoding attribute is then set to "json"
                (jsonValue.toJSONString, "json")
            }
        } else {
            (nil, nil)
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
            encoding: wireEncoding,
            boolean: boolean,
            bytes: wireBytes,
            number: wireNumber,
            string: wireString,
        )
    }
}

internal extension MapOp {
    /// Initializes a `MapOp` from a `WireMapOp`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireMapOp: WireMapOp,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        key = wireMapOp.key
        data = try wireMapOp.data.map { wireObjectData throws(InternalError) in
            try .init(wireObjectData: wireObjectData, format: format)
        }
    }

    /// Converts this `MapOp` to a `WireMapOp`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireMapOp {
        .init(
            key: key,
            data: data?.toWire(format: format),
        )
    }
}

internal extension MapEntry {
    /// Initializes a `MapEntry` from a `WireMapEntry`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireMapEntry: WireMapEntry,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        tombstone = wireMapEntry.tombstone
        timeserial = wireMapEntry.timeserial
        data = try .init(wireObjectData: wireMapEntry.data, format: format)
    }

    /// Converts this `MapEntry` to a `WireMapEntry`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireMapEntry {
        .init(
            tombstone: tombstone,
            timeserial: timeserial,
            data: data.toWire(format: format),
        )
    }
}

internal extension Map {
    /// Initializes a `Map` from a `WireMap`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireMap: WireMap,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        semantics = wireMap.semantics
        entries = try wireMap.entries?.ablyLiveObjects_mapValuesWithTypedThrow { wireMapEntry throws(InternalError) in
            try .init(wireMapEntry: wireMapEntry, format: format)
        }
    }

    /// Converts this `Map` to a `WireMap`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireMap {
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
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireObjectState: WireObjectState,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        objectId = wireObjectState.objectId
        siteTimeserials = wireObjectState.siteTimeserials
        tombstone = wireObjectState.tombstone
        createOp = try wireObjectState.createOp.map { wireObjectOperation throws(InternalError) in
            try .init(wireObjectOperation: wireObjectOperation, format: format)
        }
        map = try wireObjectState.map.map { wireMap throws(InternalError) in
            try .init(wireMap: wireMap, format: format)
        }
        counter = wireObjectState.counter
    }

    /// Converts this `ObjectState` to a `WireObjectState`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireObjectState {
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
