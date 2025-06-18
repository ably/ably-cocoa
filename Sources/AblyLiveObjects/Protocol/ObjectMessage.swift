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
    // TODO: Not yet clear how to encode / decode this property; I assume it will be properly specified later. Do in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/12
    internal var initialValue: Data? // OOP3h
    internal var initialValueEncoding: String? // OOP3i
}

internal struct ObjectData {
    internal var objectId: String? // OD2a
    internal var encoding: String? // OD2b
    internal var boolean: Bool? // OD2c
    // TODO: Not yet clear how to encode / decode this property; I assume it will be properly specified later. Do in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/12
    internal var bytes: Data? // OD2d
    internal var number: NSNumber? // OD2e
    internal var string: String? // OD2f
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
    /// Initializes an `InboundObjectMessage` from an `InboundWireObjectMessage`.
    init(wireObjectMessage: InboundWireObjectMessage) {
        id = wireObjectMessage.id
        clientId = wireObjectMessage.clientId
        connectionId = wireObjectMessage.connectionId
        extras = wireObjectMessage.extras
        timestamp = wireObjectMessage.timestamp
        operation = wireObjectMessage.operation.map { .init(wireObjectOperation: $0) }
        object = wireObjectMessage.object.map { .init(wireObjectState: $0) }
        serial = wireObjectMessage.serial
        siteCode = wireObjectMessage.siteCode
    }
}

internal extension OutboundObjectMessage {
    /// Converts this `OutboundObjectMessage` to an `OutboundWireObjectMessage`.
    func toWire() -> OutboundWireObjectMessage {
        .init(
            id: id,
            clientId: clientId,
            connectionId: connectionId,
            extras: extras,
            timestamp: timestamp,
            operation: operation?.toWire(),
            object: object?.toWire(),
            serial: serial,
            siteCode: siteCode,
        )
    }
}

internal extension ObjectOperation {
    /// Initializes an `ObjectOperation` from a `WireObjectOperation`.
    init(wireObjectOperation: WireObjectOperation) {
        action = wireObjectOperation.action
        objectId = wireObjectOperation.objectId
        mapOp = wireObjectOperation.mapOp.map { .init(wireMapOp: $0) }
        counterOp = wireObjectOperation.counterOp
        map = wireObjectOperation.map.map { .init(wireMap: $0) }
        counter = wireObjectOperation.counter
        nonce = wireObjectOperation.nonce
        initialValue = wireObjectOperation.initialValue
        initialValueEncoding = wireObjectOperation.initialValueEncoding
    }

    /// Converts this `ObjectOperation` to a `WireObjectOperation`.
    func toWire() -> WireObjectOperation {
        .init(
            action: action,
            objectId: objectId,
            mapOp: mapOp?.toWire(),
            counterOp: counterOp,
            map: map?.toWire(),
            counter: counter,
            nonce: nonce,
            initialValue: initialValue,
            initialValueEncoding: initialValueEncoding,
        )
    }
}

internal extension ObjectData {
    /// Initializes an `ObjectData` from a `WireObjectData`.
    init(wireObjectData: WireObjectData) {
        objectId = wireObjectData.objectId
        encoding = wireObjectData.encoding
        boolean = wireObjectData.boolean
        bytes = wireObjectData.bytes
        number = wireObjectData.number
        string = wireObjectData.string
    }

    /// Converts this `ObjectData` to a `WireObjectData`.
    func toWire() -> WireObjectData {
        .init(
            objectId: objectId,
            encoding: encoding,
            boolean: boolean,
            bytes: bytes,
            number: number,
            string: string,
        )
    }
}

internal extension MapOp {
    /// Initializes a `MapOp` from a `WireMapOp`.
    init(wireMapOp: WireMapOp) {
        key = wireMapOp.key
        data = wireMapOp.data.map { .init(wireObjectData: $0) }
    }

    /// Converts this `MapOp` to a `WireMapOp`.
    func toWire() -> WireMapOp {
        .init(
            key: key,
            data: data?.toWire(),
        )
    }
}

internal extension MapEntry {
    /// Initializes a `MapEntry` from a `WireMapEntry`.
    init(wireMapEntry: WireMapEntry) {
        tombstone = wireMapEntry.tombstone
        timeserial = wireMapEntry.timeserial
        data = .init(wireObjectData: wireMapEntry.data)
    }

    /// Converts this `MapEntry` to a `WireMapEntry`.
    func toWire() -> WireMapEntry {
        .init(
            tombstone: tombstone,
            timeserial: timeserial,
            data: data.toWire(),
        )
    }
}

internal extension Map {
    /// Initializes a `Map` from a `WireMap`.
    init(wireMap: WireMap) {
        semantics = wireMap.semantics
        entries = wireMap.entries?.mapValues { .init(wireMapEntry: $0) }
    }

    /// Converts this `Map` to a `WireMap`.
    func toWire() -> WireMap {
        .init(
            semantics: semantics,
            entries: entries?.mapValues { $0.toWire() },
        )
    }
}

internal extension ObjectState {
    /// Initializes an `ObjectState` from a `WireObjectState`.
    init(wireObjectState: WireObjectState) {
        objectId = wireObjectState.objectId
        siteTimeserials = wireObjectState.siteTimeserials
        tombstone = wireObjectState.tombstone
        createOp = wireObjectState.createOp.map { .init(wireObjectOperation: $0) }
        map = wireObjectState.map.map { .init(wireMap: $0) }
        counter = wireObjectState.counter
    }

    /// Converts this `ObjectState` to a `WireObjectState`.
    func toWire() -> WireObjectState {
        .init(
            objectId: objectId,
            siteTimeserials: siteTimeserials,
            tombstone: tombstone,
            createOp: createOp?.toWire(),
            map: map?.toWire(),
            counter: counter,
        )
    }
}
