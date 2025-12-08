import Foundation

/// The contents of the spec's `SyncObjectsPool` that is built during an `OBJECT_SYNC` sync sequence.
internal struct SyncObjectsPoolEntry {
    internal var state: ObjectState
    /// The `serialTimestamp` of the `ObjectMessage` that generated this entry.
    internal var objectMessageSerialTimestamp: Date?

    // We replace the default memberwise initializer because we don't want a default argument for objectMessageSerialTimestamp (want to make sure we don't forget to set it whenever we create an entry).
    // swiftlint:disable:next unneeded_synthesized_initializer
    internal init(state: ObjectState, objectMessageSerialTimestamp: Date?) {
        self.state = state
        self.objectMessageSerialTimestamp = objectMessageSerialTimestamp
    }
}
