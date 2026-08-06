import _AblyPluginSupportPrivate
@testable import AblyLiveObjects
import Foundation

// Mirrors the shared UTS helper `uts/objects/helpers/standard_test_pool.md` for the
// AblyLiveObjectsTests target: the canonical constants/serial helpers plus the
// `build_object_delete` operation-message builder that `TestFactories` did not yet cover.
//
// Name mapping (UTS pseudocode -> Swift):
// - `SITE_CODE`            -> `UTSTestPool.utsSiteCode`
// - `POOL_SERIAL`          -> `UTSTestPool.utsPoolSerial`
// - `ack_serial(m, i)`     -> `UTSTestPool.utsAckSerial(msgSerial:_:)`
// - `remote_serial(i)`     -> `UTSTestPool.utsRemoteSerial(_:)`
// - `below_ack_serial(i)`  -> `UTSTestPool.utsBelowAckSerial(_:)`
// - `build_object_delete`  -> `TestFactories.objectDeleteOperationMessage(...)`
//
// The other `build_*` operation builders from the helper are already covered by
// `TestFactories`: `build_counter_inc` (counterIncOperationMessage), `build_map_set`
// (mapSetOperationMessage), `build_map_remove` (mapRemoveOperationMessage), `build_map_clear`
// (mapClearOperationMessage), `build_map_create` (mapCreateOperationMessage),
// `build_counter_create` (counterCreateOperationMessage); and the state builders
// `build_object_state` variants via mapObjectState/counterObjectState/objectState.

/// Canonical constants and serial helpers from the UTS standard test pool.
///
/// See `uts/objects/helpers/standard_test_pool.md` -> "Canonical Constants". All serials are
/// compared lexicographically as strings (RTLM9e) and are defined relative to the pool baseline
/// `utsPoolSerial`.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
enum UTSTestPool {
    /// `SITE_CODE` — the harness ConnectionDetails siteCode (the connection's own site).
    static let utsSiteCode = "test-site"

    /// `POOL_SERIAL` — the timeserial every standard-pool entry and object is seeded with.
    static let utsPoolSerial = "t:0"

    /// `ack_serial(msgSerial, i)` — the serial the harness assigns to a locally-published
    /// operation when it is applied on its ACK. First publish's first op = `utsAckSerial(0, 0)`
    /// == `"t:1:0"`. Sorts AFTER `utsPoolSerial`.
    static func utsAckSerial(msgSerial: Int, _ i: Int) -> String {
        "t:\(msgSerial + 1):\(i)"
    }

    /// `remote_serial(i)` — a remote inbound "winning" serial for a MAP_SET / MAP_REMOVE on an
    /// existing pool entry. 0-based: `utsRemoteSerial(0)` == `"t:1"`. Sorts AFTER `utsPoolSerial`.
    static func utsRemoteSerial(_ i: Int) -> String {
        "t:\(i + 1)"
    }

    /// `below_ack_serial(i)` — a serial that is NOT an ack_serial (escapes the RTO9a3 apply-on-ACK
    /// echo dedup) yet sorts BELOW the first ack_serial (`utsAckSerial(0, 0)` == `"t:1:0"`), while
    /// still after `utsPoolSerial`. 0-based: `utsBelowAckSerial(9)` == `"t:0:9"`.
    static func utsBelowAckSerial(_ i: Int) -> String {
        "t:0:\(i)"
    }
}

// MARK: - SyncObjectsPool construction

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension SyncObjectsPool {
    /// Test-only convenience to create a `SyncObjectsPool` from an array of `(state, serialTimestamp)` pairs,
    /// wrapping each in an `InboundObjectMessage` and calling `accumulate`.
    static func testsOnly_fromStates(
        _ states: [(state: ProtocolTypes.ObjectState, serialTimestamp: Date?)],
        logger: AblyLiveObjects.Logger = TestLogger(),
    ) -> SyncObjectsPool {
        var pool = SyncObjectsPool()
        let messages = states.map { pair in
            TestFactories.inboundObjectMessage(
                object: pair.state,
                serialTimestamp: pair.serialTimestamp,
            )
        }
        pool.accumulate(messages, logger: logger)
        return pool
    }
}

// MARK: - build_object_delete (audit D-3)

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension TestFactories {
    /// Creates an InboundObjectMessage with an OBJECT_DELETE operation.
    ///
    /// Mirrors the UTS `build_object_delete` builder from
    /// `uts/objects/helpers/standard_test_pool.md`. Takes `serial` / `siteCode` /
    /// `serialTimestamp` as parameters, matching the other `*OperationMessage` builders.
    static func objectDeleteOperationMessage(
        objectId: String = "test:object@123",
        serial: String = "ts1",
        siteCode: String = "site1",
        serialTimestamp: Date? = nil,
    ) -> ProtocolTypes.InboundObjectMessage {
        inboundObjectMessage(
            operation: objectOperation(
                action: .known(.objectDelete),
                objectId: objectId,
                objectDelete: WireObjectDelete(),
            ),
            serial: serial,
            siteCode: siteCode,
            serialTimestamp: serialTimestamp,
        )
    }

    /// Creates an InboundObjectMessage with a MAP_SET operation carrying an arbitrary `ObjectData`
    /// value (the `value:`-based `TestFactories.mapSetOperationMessage` only supports a `String`).
    /// Used by the UTS map ports for `{ objectId: … }` / `{ number: … }` MapSet values.
    static func mapSetOperationMessage(
        objectId: String,
        key: String,
        data: ProtocolTypes.ObjectData,
        serial: String,
        siteCode: String,
    ) -> ProtocolTypes.InboundObjectMessage {
        inboundObjectMessage(
            operation: objectOperation(
                action: .known(.mapSet),
                objectId: objectId,
                mapSet: ProtocolTypes.MapSet(key: key, value: data),
            ),
            serial: serial,
            siteCode: siteCode,
        )
    }

    /// Creates an InboundObjectMessage with a MAP_REMOVE operation that also carries a
    /// `serialTimestamp` (the base `TestFactories.mapRemoveOperationMessage` does not), needed to
    /// exercise the RTLM8f `tombstonedAt` derivation.
    static func mapRemoveOperationMessage(
        objectId: String,
        key: String,
        serial: String,
        siteCode: String,
        serialTimestamp: Date?,
    ) -> ProtocolTypes.InboundObjectMessage {
        inboundObjectMessage(
            operation: objectOperation(
                action: .known(.mapRemove),
                objectId: objectId,
                mapRemove: WireMapRemove(key: key),
            ),
            serial: serial,
            siteCode: siteCode,
            serialTimestamp: serialTimestamp,
        )
    }
}
