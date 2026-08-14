import _AblyPluginSupportPrivate
@testable import AblyLiveObjects
import Foundation

// Shared object-pool construction and operation-message builders consumed by both
// AblyLiveObjectsTests and the UTS objects tier: the `SyncObjectsPool` factory plus the
// `build_object_delete` / arbitrary-value MAP_SET / timestamped MAP_REMOVE builders that
// `TestFactories` did not yet cover.
//
// The other `build_*` operation builders from the shared UTS helper are already covered by
// `TestFactories`: `build_counter_inc` (counterIncOperationMessage), `build_map_set`
// (mapSetOperationMessage), `build_map_remove` (mapRemoveOperationMessage), `build_map_clear`
// (mapClearOperationMessage), `build_map_create` (mapCreateOperationMessage),
// `build_counter_create` (counterCreateOperationMessage); and the state builders
// `build_object_state` variants via mapObjectState/counterObjectState/objectState.

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
    /// exercise the RTLO6 `tombstonedAt` derivation.
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
