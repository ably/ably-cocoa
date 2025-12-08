import Foundation

/// The entries stored in a `LiveMap`'s data. Same as an `ObjectsMapEntry` but with an additional `tombstonedAt` property, per RTLM3a.
@available(macOS 11, iOS 14, tvOS 14, *)
internal struct InternalObjectsMapEntry: Equatable {
    internal var tombstonedAt: Date? // RTLM3a
    internal var tombstone: Bool {
        // TODO: Confirm that we don't need to store this (https://github.com/ably/specification/pull/350/files#r2213895661)
        tombstonedAt != nil
    }

    internal var timeserial: String? // OME2b
    internal var data: ObjectData? // OME2c
}

@available(macOS 11, iOS 14, tvOS 14, *)
internal extension InternalObjectsMapEntry {
    init(objectsMapEntry: ObjectsMapEntry, tombstonedAt: Date?) {
        self.tombstonedAt = tombstonedAt
        timeserial = objectsMapEntry.timeserial
        data = objectsMapEntry.data
    }
}
