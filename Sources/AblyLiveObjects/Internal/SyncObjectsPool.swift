import Foundation

/// The RTO5b collection of objects gathered during an `OBJECT_SYNC` sequence, ready to be applied to the `ObjectsPool`.
internal struct SyncObjectsPool: Collection {
    /// The contents of the spec's `SyncObjectsPool` that is built during an `OBJECT_SYNC` sync sequence.
    internal struct Entry {
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

    private var entries: [Entry]

    /// Creates an empty pool.
    internal init() {
        entries = []
    }

    /// Creates a pool from the given entries.
    internal init(entries: [Entry]) {
        self.entries = entries
    }

    /// Accumulates entries from a sync message per RTO5b.
    internal mutating func append(contentsOf newEntries: [Entry]) {
        entries.append(contentsOf: newEntries)
    }

    // MARK: - Collection conformance

    internal var startIndex: Int { entries.startIndex }
    internal var endIndex: Int { entries.endIndex }
    internal func index(after i: Int) -> Int { entries.index(after: i) }
    internal subscript(position: Int) -> Entry { entries[position] }
}
