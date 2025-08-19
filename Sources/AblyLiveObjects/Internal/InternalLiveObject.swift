internal import _AblyPluginSupportPrivate

/// Provides RTLO spec point functionality common to all LiveObjects.
///
/// This exists in addition to ``LiveObjectMutableState`` to enable polymorphism.
internal protocol InternalLiveObject<Update> {
    associatedtype Update: Sendable

    var liveObjectMutableState: LiveObjectMutableState<Update> { get set }

    /// Resets the LiveObject's internal data to that of a zero-value, per RTLO4e4.
    mutating func resetDataToZeroValued()
}

internal extension InternalLiveObject {
    /// Convenience method for tombstoning a `LiveObject`, as specified in RTLO4e.
    mutating func tombstone(
        objectMessageSerialTimestamp: Date?,
        logger: Logger,
        clock: SimpleClock,
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
    }

    /// Applies an `OBJECT_DELETE` operation, per RTLO5.
    mutating func applyObjectDeleteOperation(
        objectMessageSerialTimestamp: Date?,
        logger: Logger,
        clock: SimpleClock,
    ) {
        // RTLO5b
        tombstone(
            objectMessageSerialTimestamp: objectMessageSerialTimestamp,
            logger: logger,
            clock: clock,
        )
    }
}
