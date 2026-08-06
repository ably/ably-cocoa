internal import _AblyPluginSupportPrivate

/// Provides RTLO spec point functionality common to all LiveObjects.
///
/// This exists in addition to ``LiveObjectMutableState`` to enable polymorphism.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal protocol InternalLiveObject<Update> {
    associatedtype Update: Sendable

    var liveObjectMutableState: LiveObjectMutableState<Update> { get set }

    /// Resets the LiveObject's internal data to that of a zero-value, per RTLO4e4.
    mutating func resetDataToZeroValued()
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal extension InternalLiveObject {
    /// Convenience method for tombstoning a `LiveObject`, as specified in RTLO4e.
    mutating func tombstone(
        objectMessageSerialTimestamp: Date?,
        logger: Logger,
        clock: SimpleClock,
        userCallbackQueue: DispatchQueue,
    ) {
        // RTLO4e2, RTLO4e3
        if let objectMessageSerialTimestamp {
            // RTLO4e3a
            liveObjectMutableState.tombstonedAt = objectMessageSerialTimestamp
        } else {
            // RTLO4e3b1
            logger.log("serialTimestamp not found in ObjectMessage, using local clock for tombstone timestamp", level: .debug)
            // RTLO4e3b
            liveObjectMutableState.tombstonedAt = clock.now
        }

        // RTLO4e4
        resetDataToZeroValued()

        // Emit the deleted lifecycle event
        // Taken from https://github.com/ably/ably-js/blob/e280bff11a4a7627362c5185e764b7ebd0490570/src/plugins/objects/liveobject.ts#L168
        // TODO: Bring in line with spec once it exists (https://github.com/ably/ably-liveobjects-swift-plugin/issues/77)
        liveObjectMutableState.emitLifecycleEvent(.deleted, on: userCallbackQueue)
    }

    /// Stamps the source public object message onto `rawUpdate`, emits the enriched update to this
    /// object's subscribers (RTLO4b4c3a), and — if the update tombstones the object —
    /// deregisters all of this object's subscriptions afterwards (RTLO4b4c3c teardown).
    ///
    /// - Parameter sourceObjectMessage: the PAOM3-converted public message (op-bearing paths), or
    ///   `nil` for sync-originated updates (RTO4b2a).
    /// - Returns: the enriched update, so the apply return carries the enrichment too.
    mutating func nosync_emitAndTearDown(
        _ rawUpdate: LiveObjectUpdate<Update>,
        sourceObjectMessage: ObjectMessage?,
        userCallbackQueue: DispatchQueue,
    ) -> LiveObjectUpdate<Update> where Update: LiveObjectUpdatePayload {
        // RTLO4b4d: stamp the source public message onto the update
        let enriched = rawUpdate.nosync_stampingObjectMessage(sourceObjectMessage)
        // RTLO4b4c3a: emit to instance listeners (noops are dropped in emit)
        liveObjectMutableState.emit(enriched, on: userCallbackQueue)
        // RTLO4b4c3c: tombstone teardown — deregister this object's subscriptions after emitting
        if enriched.tombstone {
            liveObjectMutableState.unsubscribeAll()
        }
        return enriched
    }

    /// Applies an `OBJECT_DELETE` operation, per RTLO5.
    mutating func applyObjectDeleteOperation(
        objectMessageSerialTimestamp: Date?,
        logger: Logger,
        clock: SimpleClock,
        userCallbackQueue: DispatchQueue,
    ) {
        // RTLO5b
        tombstone(
            objectMessageSerialTimestamp: objectMessageSerialTimestamp,
            logger: logger,
            clock: clock,
            userCallbackQueue: userCallbackQueue,
        )
    }

    // MARK: - Parent-reference graph (RTLO3f, RTLO4f, RTLO4g, RTLO4h)

    /// Records that the map identified by `parentObjectID` references this object at `key`, per RTLO4g.
    mutating func nosync_addParentReference(parentObjectID: String, key: String) {
        // RTLO4g1, RTLO4g2: insert a new entry if absent, otherwise add the key to the existing set
        liveObjectMutableState.parentReferences[parentObjectID, default: []].insert(key)
    }

    /// Removes the recorded reference from the map identified by `parentObjectID` at `key`, per RTLO4h.
    mutating func nosync_removeParentReference(parentObjectID: String, key: String) {
        // RTLO4h1: no entry for this parent — do nothing
        guard var keys = liveObjectMutableState.parentReferences[parentObjectID] else {
            return
        }
        // RTLO4h2: remove the key from the entry's set
        keys.remove(key)
        if keys.isEmpty {
            // RTLO4h3: if the entry's set is now empty, remove the entry entirely
            liveObjectMutableState.parentReferences.removeValue(forKey: parentObjectID)
        } else {
            liveObjectMutableState.parentReferences[parentObjectID] = keys
        }
    }

    /// Resets `parentReferences` to its initial value (an empty map), per RTO5c10a.
    mutating func nosync_clearParentReferences() {
        liveObjectMutableState.parentReferences = [:]
    }

    // Note (RTLO4f `getFullPaths`): the cycle-safe DFS lives on `ObjectsPool`
    // (`nosync_getFullPaths(forObjectID:)`) rather than here. It must read each object's
    // `parentReferences` through a brief, self-contained access and must never hold any single
    // object's queue-mutex open across the traversal — doing so re-enters that mutex when the walk
    // revisits the object, tripping Swift's exclusive-access checker. Placing it on the pool (which
    // owns the graph) keeps every `nosync_parentReferences` read independent; the per-object
    // `nosync_getFullPaths(objectsPool:)` forwarders delegate to it.
}
