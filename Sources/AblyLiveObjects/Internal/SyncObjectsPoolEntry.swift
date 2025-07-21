import Foundation

/// The contents of the spec's `SyncObjectsPool` that is built during an `OBJECT_SYNC` sync sequence.
internal struct SyncObjectsPoolEntry {
    internal var state: ObjectState
}
