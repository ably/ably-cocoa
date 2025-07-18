/// The entries stored in a `LiveMap`'s data. Same as an `ObjectsMapEntry` but with an additional `tombstonedAt` property, per RTLM3a. (This property will be added in an upcoming commit.)
internal struct InternalObjectsMapEntry {
    internal var tombstone: Bool? // OME2a
    internal var timeserial: String? // OME2b
    internal var data: ObjectData // OME2c
}

internal extension InternalObjectsMapEntry {
    init(objectsMapEntry: ObjectsMapEntry) {
        tombstone = objectsMapEntry.tombstone
        timeserial = objectsMapEntry.timeserial
        data = objectsMapEntry.data
    }
}
