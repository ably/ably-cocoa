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
    internal var serialTimestamp: Date? // OM2j
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
    internal var serialTimestamp: Date? // OM2j
}

/// A partial version of `ObjectOperation` that excludes the `objectId` property. Used for encoding initial values where the `objectId` is not yet known.
///
/// `ObjectOperation` delegates its encoding and decoding to `PartialObjectOperation`.
internal struct PartialObjectOperation {
    internal var action: WireEnum<ObjectOperationAction> // OOP3a
    internal var mapOp: ObjectsMapOp? // OOP3c
    internal var counterOp: WireObjectsCounterOp? // OOP3d
    internal var map: ObjectsMap? // OOP3e
    internal var counter: WireObjectsCounter? // OOP3f
    internal var nonce: String? // OOP3g
    internal var initialValue: String? // OOP3h
}

internal struct ObjectOperation {
    internal var action: WireEnum<ObjectOperationAction> // OOP3a
    internal var objectId: String // OOP3b
    internal var mapOp: ObjectsMapOp? // OOP3c
    internal var counterOp: WireObjectsCounterOp? // OOP3d
    internal var map: ObjectsMap? // OOP3e
    internal var counter: WireObjectsCounter? // OOP3f
    internal var nonce: String? // OOP3g
    internal var initialValue: String? // OOP3h
}

internal struct ObjectData {
    internal var objectId: String? // OD2a
    internal var boolean: Bool? // OD2c
    internal var bytes: Data? // OD2d
    internal var number: NSNumber? // OD2e
    internal var string: String? // OD2f
    internal var json: JSONObjectOrArray? // TODO: Needs specification (see https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/46)
}

internal struct ObjectsMapOp {
    internal var key: String // OMO2a
    internal var data: ObjectData? // OMO2b
}

internal struct ObjectsMapEntry {
    internal var tombstone: Bool? // OME2a
    internal var timeserial: String? // OME2b
    internal var data: ObjectData // OME2c
    internal var serialTimestamp: Date? // OME2d
}

internal struct ObjectsMap {
    internal var semantics: WireEnum<ObjectsMapSemantics> // OMP3a
    internal var entries: [String: ObjectsMapEntry]? // OMP3b
}

internal struct ObjectState {
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
        serialTimestamp = wireObjectMessage.serialTimestamp
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
            serialTimestamp: serialTimestamp,
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
        // Decode the objectId first since it's not part of PartialObjectOperation
        objectId = wireObjectOperation.objectId

        // Delegate to PartialObjectOperation for decoding
        let partialOperation = try PartialObjectOperation(
            partialWireObjectOperation: PartialWireObjectOperation(
                action: wireObjectOperation.action,
                mapOp: wireObjectOperation.mapOp,
                counterOp: wireObjectOperation.counterOp,
                map: wireObjectOperation.map,
                counter: wireObjectOperation.counter,
                nonce: wireObjectOperation.nonce,
                initialValue: wireObjectOperation.initialValue,
            ),
            format: format,
        )

        // Copy the decoded values
        action = partialOperation.action
        mapOp = partialOperation.mapOp
        counterOp = partialOperation.counterOp
        map = partialOperation.map
        counter = partialOperation.counter
        nonce = partialOperation.nonce
        initialValue = partialOperation.initialValue
    }

    /// Converts this `ObjectOperation` to a `WireObjectOperation`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireObjectOperation {
        let partialWireOperation = PartialObjectOperation(
            action: action,
            mapOp: mapOp,
            counterOp: counterOp,
            map: map,
            counter: counter,
            nonce: nonce,
            initialValue: initialValue,
        ).toWire(format: format)

        // Create WireObjectOperation from PartialWireObjectOperation and add objectId
        return WireObjectOperation(
            action: partialWireOperation.action,
            objectId: objectId,
            mapOp: partialWireOperation.mapOp,
            counterOp: partialWireOperation.counterOp,
            map: partialWireOperation.map,
            counter: partialWireOperation.counter,
            nonce: partialWireOperation.nonce,
            initialValue: partialWireOperation.initialValue,
        )
    }
}

internal extension PartialObjectOperation {
    /// Initializes a `PartialObjectOperation` from a `PartialWireObjectOperation`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        partialWireObjectOperation: PartialWireObjectOperation,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        action = partialWireObjectOperation.action
        mapOp = try partialWireObjectOperation.mapOp.map { wireObjectsMapOp throws(InternalError) in
            try .init(wireObjectsMapOp: wireObjectsMapOp, format: format)
        }
        counterOp = partialWireObjectOperation.counterOp
        map = try partialWireObjectOperation.map.map { wireMap throws(InternalError) in
            try .init(wireObjectsMap: wireMap, format: format)
        }
        counter = partialWireObjectOperation.counter

        // Do not access on inbound data, per OOP3g
        nonce = nil
        // Do not access on inbound data, per OOP3h
        initialValue = nil
    }

    /// Converts this `PartialObjectOperation` to a `PartialWireObjectOperation`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> PartialWireObjectOperation {
        .init(
            action: action,
            mapOp: mapOp?.toWire(format: format),
            counterOp: counterOp,
            map: map?.toWire(format: format),
            counter: counter,
            nonce: nonce,
            initialValue: initialValue,
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

        // TODO: Needs specification (see https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/46)
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
            // TODO: Needs specification (see https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/46)
            json: json?.toJSONString,
        )
    }
}

internal extension ObjectsMapOp {
    /// Initializes a `ObjectsMapOp` from a `WireObjectsMapOp`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireObjectsMapOp: WireObjectsMapOp,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        key = wireObjectsMapOp.key
        data = try wireObjectsMapOp.data.map { wireObjectData throws(InternalError) in
            try .init(wireObjectData: wireObjectData, format: format)
        }
    }

    /// Converts this `ObjectsMapOp` to a `WireObjectsMapOp`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireObjectsMapOp {
        .init(
            key: key,
            data: data?.toWire(format: format),
        )
    }
}

internal extension ObjectsMapEntry {
    /// Initializes an `ObjectsMapEntry` from a `WireObjectsMapEntry`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireObjectsMapEntry: WireObjectsMapEntry,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        tombstone = wireObjectsMapEntry.tombstone
        timeserial = wireObjectsMapEntry.timeserial
        data = try .init(wireObjectData: wireObjectsMapEntry.data, format: format)
        serialTimestamp = wireObjectsMapEntry.serialTimestamp
    }

    /// Converts this `ObjectsMapEntry` to a `WireObjectsMapEntry`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireObjectsMapEntry {
        .init(
            tombstone: tombstone,
            timeserial: timeserial,
            data: data.toWire(format: format),
        )
    }
}

internal extension ObjectsMap {
    /// Initializes an `ObjectsMap` from a `WireObjectsMap`, applying the data decoding rules of OD5.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the decoding rules of OD5.
    /// - Throws: `InternalError` if JSON or Base64 decoding fails.
    init(
        wireObjectsMap: WireObjectsMap,
        format: AblyPlugin.EncodingFormat
    ) throws(InternalError) {
        semantics = wireObjectsMap.semantics
        entries = try wireObjectsMap.entries?.ablyLiveObjects_mapValuesWithTypedThrow { wireMapEntry throws(InternalError) in
            try .init(wireObjectsMapEntry: wireMapEntry, format: format)
        }
    }

    /// Converts this `ObjectsMap` to a `WireObjectsMap`, applying the data encoding rules of OD4.
    ///
    /// - Parameters:
    ///   - format: The format to use when applying the encoding rules of OD4.
    func toWire(format: AblyPlugin.EncodingFormat) -> WireObjectsMap {
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
        map = try wireObjectState.map.map { wireObjectsMap throws(InternalError) in
            try .init(wireObjectsMap: wireObjectsMap, format: format)
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
