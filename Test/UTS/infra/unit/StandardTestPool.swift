import Ably
import Foundation
@testable import AblyLiveObjects

/// Shared fixtures, protocol-message builders, and canonical constants for the LiveObjects UTS
/// tests. Derived from `uts/objects/helpers/standard_test_pool.md`.
///
/// The pool objects are built directly as internal ``ProtocolTypes/InboundObjectMessage`` values
/// (reachable via `@testable`) and delivered through the mock as an `OBJECT_SYNC` protocol message;
/// this mirrors what ably-cocoa's wire decoder produces (see ``ProtocolMessage``).
enum StandardTestPool {
    // MARK: - Canonical Constants

    /// The harness `ConnectionDetails.siteCode`.
    static let siteCode = "test-site"

    /// The timeserial every standard-pool entry and object is seeded with.
    static let poolSerial = "t:0"

    /// The serial the harness assigns to a locally-published operation applied on its ACK; sorts
    /// after ``poolSerial``. `ackSerial(0, 0) == "t:1:0"`.
    static func ackSerial(_ msgSerial: Int, _ index: Int) -> String {
        "t:\(msgSerial + 1):\(index)"
    }

    /// A REMOTE inbound "winning" serial on an existing pool entry; sorts after ``poolSerial``.
    /// `remoteSerial(0) == "t:1"`.
    static func remoteSerial(_ index: Int) -> String {
        "t:\(index + 1)"
    }

    /// A serial that is not an ack-serial (escapes RTO9a3 dedup) yet sorts below the first
    /// ack-serial, while still after ``poolSerial``. `belowAckSerial(9) == "t:0:9"`.
    static func belowAckSerial(_ index: Int) -> String {
        "t:0:\(index)"
    }

    // MARK: - Standard Pool Objects

    /// The fixed LiveObjects tree used across test files, as `OBJECT_SYNC` state. See the tree
    /// diagram in `standard_test_pool.md`.
    static var objects: [ProtocolTypes.InboundObjectMessage] {
        [
            objectStateMessage(
                objectId: "root",
                map: objectsMap(
                    semantics: .lww,
                    entries: mapEntries([
                        "name": data(string: "Alice"),
                        "age": data(number: 30),
                        "active": data(boolean: true),
                        "score": data(objectId: "counter:score@1000"),
                        "profile": data(objectId: "map:profile@1000"),
                        "data": data(json: ["tags": ["a", "b"]]),
                        "avatar": data(bytes: Data([1, 2, 3])),
                    ]),
                ),
                createOp: mapCreateOp(objectId: "root"),
            ),
            objectStateMessage(
                objectId: "counter:score@1000",
                // count = 0 post-create; createOp carries the initial 100 -> materialises to 100.
                counter: WireObjectsCounter(count: NSNumber(value: 0)),
                createOp: counterCreateOp(objectId: "counter:score@1000", count: 100),
            ),
            objectStateMessage(
                objectId: "map:profile@1000",
                map: objectsMap(
                    semantics: .lww,
                    entries: mapEntries([
                        "email": data(string: "alice@example.com"),
                        "nested_counter": data(objectId: "counter:nested@1000"),
                        "prefs": data(objectId: "map:prefs@1000"),
                    ]),
                ),
                createOp: mapCreateOp(objectId: "map:profile@1000"),
            ),
            objectStateMessage(
                objectId: "counter:nested@1000",
                counter: WireObjectsCounter(count: NSNumber(value: 0)),
                createOp: counterCreateOp(objectId: "counter:nested@1000", count: 5),
            ),
            objectStateMessage(
                objectId: "map:prefs@1000",
                map: objectsMap(
                    semantics: .lww,
                    entries: mapEntries([
                        "theme": data(string: "dark"),
                    ]),
                ),
                createOp: mapCreateOp(objectId: "map:prefs@1000"),
            ),
        ]
    }

    // MARK: - ObjectData builders

    static func data(objectId: String? = nil, boolean: Bool? = nil, bytes: Data? = nil, number: Double? = nil, string: String? = nil, json: JSONObjectOrArray? = nil) -> ProtocolTypes.ObjectData {
        ProtocolTypes.ObjectData(
            objectId: objectId,
            boolean: boolean,
            bytes: bytes,
            number: number.map { NSNumber(value: $0) },
            string: string,
            json: json,
        )
    }

    // MARK: - ObjectState builders

    /// Builds a map of ``ProtocolTypes/ObjectsMapEntry`` from key -> data, all seeded with
    /// ``poolSerial`` and `tombstone: false`.
    static func mapEntries(_ entries: [String: ProtocolTypes.ObjectData]) -> [String: ProtocolTypes.ObjectsMapEntry] {
        entries.mapValues { data in
            ProtocolTypes.ObjectsMapEntry(tombstone: false, timeserial: poolSerial, data: data, serialTimestamp: nil)
        }
    }

    /// Builds an ``ProtocolTypes/ObjectsMap`` — the `{ semantics, entries }` object of the spec's
    /// `build_object_state`. `clearTimeserial` is omitted unless the spec shows one.
    static func objectsMap(
        semantics: ProtocolTypes.ObjectsMapSemantics,
        entries: [String: ProtocolTypes.ObjectsMapEntry],
        clearTimeserial: String? = nil,
    ) -> ProtocolTypes.ObjectsMap {
        ProtocolTypes.ObjectsMap(semantics: .known(semantics), entries: entries, clearTimeserial: clearTimeserial)
    }

    /// A MAP_CREATE createOp with empty entries (RTLM16 no-op merge; entries already present in map).
    static func mapCreateOp(objectId: String) -> ProtocolTypes.ObjectOperation {
        ProtocolTypes.ObjectOperation(
            action: .known(.mapCreate),
            objectId: objectId,
            mapCreate: ProtocolTypes.MapCreate(semantics: .known(.lww), entries: [:]),
        )
    }

    /// A COUNTER_CREATE createOp carrying the initial `count`.
    static func counterCreateOp(objectId: String, count: Double) -> ProtocolTypes.ObjectOperation {
        ProtocolTypes.ObjectOperation(
            action: .known(.counterCreate),
            objectId: objectId,
            counterCreate: WireCounterCreate(count: NSNumber(value: count)),
        )
    }

    /// Builds an inbound `ObjectMessage` carrying an ``ProtocolTypes/ObjectState`` (UTS
    /// `build_object_state` composed with `build_object_message_with_state`).
    static func objectStateMessage(
        objectId: String,
        siteTimeserials: [String: String] = ["aaa": poolSerial],
        tombstone: Bool = false,
        map: ProtocolTypes.ObjectsMap? = nil,
        counter: WireObjectsCounter? = nil,
        createOp: ProtocolTypes.ObjectOperation? = nil,
    ) -> ProtocolTypes.InboundObjectMessage {
        ProtocolTypes.InboundObjectMessage(object: ProtocolTypes.ObjectState(
            objectId: objectId,
            siteTimeserials: siteTimeserials,
            tombstone: tombstone,
            createOp: createOp,
            map: map,
            counter: counter,
        ))
    }

    // MARK: - Operation ObjectMessage builders

    static func counterInc(objectId: String, number: Double, serial: String, siteCode: String) -> ProtocolTypes.InboundObjectMessage {
        operationMessage(serial: serial, siteCode: siteCode, operation: ProtocolTypes.ObjectOperation(
            action: .known(.counterInc),
            objectId: objectId,
            counterInc: WireCounterInc(number: NSNumber(value: number)),
        ))
    }

    static func mapSet(objectId: String, key: String, value: ProtocolTypes.ObjectData, serial: String, siteCode: String) -> ProtocolTypes.InboundObjectMessage {
        operationMessage(serial: serial, siteCode: siteCode, operation: ProtocolTypes.ObjectOperation(
            action: .known(.mapSet),
            objectId: objectId,
            mapSet: ProtocolTypes.MapSet(key: key, value: value),
        ))
    }

    static func mapRemove(objectId: String, key: String, serial: String, siteCode: String, serialTimestamp: Date? = nil) -> ProtocolTypes.InboundObjectMessage {
        operationMessage(serial: serial, siteCode: siteCode, serialTimestamp: serialTimestamp, operation: ProtocolTypes.ObjectOperation(
            action: .known(.mapRemove),
            objectId: objectId,
            mapRemove: WireMapRemove(key: key),
        ))
    }

    static func mapClear(objectId: String, serial: String, siteCode: String) -> ProtocolTypes.InboundObjectMessage {
        operationMessage(serial: serial, siteCode: siteCode, operation: ProtocolTypes.ObjectOperation(
            action: .known(.mapClear),
            objectId: objectId,
            mapClear: WireMapClear(),
        ))
    }

    static func objectDelete(objectId: String, serial: String, siteCode: String, serialTimestamp: Date? = nil) -> ProtocolTypes.InboundObjectMessage {
        operationMessage(serial: serial, siteCode: siteCode, serialTimestamp: serialTimestamp, operation: ProtocolTypes.ObjectOperation(
            action: .known(.objectDelete),
            objectId: objectId,
            objectDelete: WireObjectDelete(),
        ))
    }

    private static func operationMessage(serial: String, siteCode: String, serialTimestamp: Date? = nil, operation: ProtocolTypes.ObjectOperation) -> ProtocolTypes.InboundObjectMessage {
        ProtocolTypes.InboundObjectMessage(
            operation: operation,
            serial: serial,
            siteCode: siteCode,
            serialTimestamp: serialTimestamp,
        )
    }
}
