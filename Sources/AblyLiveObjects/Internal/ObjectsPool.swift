internal import _AblyPluginSupportPrivate

/// Maintains the list of objects present on a channel, as described by RTO3.
///
/// Note that this is a value type.
internal struct ObjectsPool {
    /// The possible `ObjectsPool` entries, as described by RTO3a.
    internal enum Entry {
        case map(InternalDefaultLiveMap)
        case counter(InternalDefaultLiveCounter)

        /// Convenience getter for accessing the map value if this entry is a map
        internal var mapValue: InternalDefaultLiveMap? {
            switch self {
            case let .map(map):
                map
            case .counter:
                nil
            }
        }

        /// Convenience getter for accessing the counter value if this entry is a counter
        internal var counterValue: InternalDefaultLiveCounter? {
            switch self {
            case .map:
                nil
            case let .counter(counter):
                counter
            }
        }

        /// Applies an operation to a LiveObject, per RTO9a2a3.
        internal func apply(
            _ operation: ObjectOperation,
            objectMessageSerial: String?,
            objectMessageSiteCode: String?,
            objectMessageSerialTimestamp: Date?,
            objectsPool: inout ObjectsPool,
        ) {
            switch self {
            case let .map(map):
                map.apply(
                    operation,
                    objectMessageSerial: objectMessageSerial,
                    objectMessageSiteCode: objectMessageSiteCode,
                    objectMessageSerialTimestamp: objectMessageSerialTimestamp,
                    objectsPool: &objectsPool,
                )
            case let .counter(counter):
                counter.apply(
                    operation,
                    objectMessageSerial: objectMessageSerial,
                    objectMessageSiteCode: objectMessageSiteCode,
                    objectMessageSerialTimestamp: objectMessageSerialTimestamp,
                    objectsPool: &objectsPool,
                )
            }
        }

        /// A LiveObject plus an update that can be emitted on this LiveObject. Can be used to store pending events while applying the `SyncObjectsPool`.
        fileprivate enum DeferredUpdate {
            case map(InternalDefaultLiveMap, LiveObjectUpdate<DefaultLiveMapUpdate>)
            case counter(InternalDefaultLiveCounter, LiveObjectUpdate<DefaultLiveCounterUpdate>)

            /// Causes the referenced `LiveObject` to emit the stored event to its subscribers.
            internal func emit() {
                switch self {
                case let .map(map, update):
                    map.emit(update)
                case let .counter(counter, update):
                    counter.emit(update)
                }
            }
        }

        /// Overrides the internal data for the object as per RTLC6, RTLM6.
        ///
        /// Returns a ``DeferredUpdate`` which contains the object plus an update that should be emitted on this object once the `SyncObjectsPool` has been applied.
        ///
        /// - Parameters:
        ///   - objectMessageSerialTimestamp: The `serialTimestamp` of the containing `ObjectMessage`. Used if we need to tombstone the object.
        fileprivate func replaceData(
            using state: ObjectState,
            objectMessageSerialTimestamp: Date?,
            objectsPool: inout ObjectsPool,
        ) -> DeferredUpdate {
            switch self {
            case let .map(map):
                .map(
                    map,
                    map.replaceData(
                        using: state,
                        objectMessageSerialTimestamp: objectMessageSerialTimestamp,
                        objectsPool: &objectsPool,
                    ),
                )
            case let .counter(counter):
                .counter(
                    counter,
                    counter.replaceData(
                        using: state,
                        objectMessageSerialTimestamp: objectMessageSerialTimestamp,
                    ),
                )
            }
        }

        /// Returns the object's RTLO3d `isTombstone` property.
        internal var isTombstone: Bool {
            switch self {
            case let .counter(counter):
                counter.isTombstone
            case let .map(map):
                map.isTombstone
            }
        }

        internal var tombstonedAt: Date? {
            switch self {
            case let .counter(counter):
                counter.tombstonedAt
            case let .map(map):
                map.tombstonedAt
            }
        }
    }

    /// Keyed by `objectId`.
    ///
    /// Per RTO3b, always contains an entry for `ObjectsPool.rootKey`, and this entry is always of type `map`.
    internal private(set) var entries: [String: Entry]

    /// The key under which the root object is stored.
    internal static let rootKey = "root"

    // MARK: - Initialization

    /// Creates an `ObjectsPool` whose root is a zero-value `LiveMap`.
    internal init(
        logger: Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
        testsOnly_otherEntries otherEntries: [String: Entry]? = nil,
    ) {
        self.init(
            logger: logger,
            userCallbackQueue: userCallbackQueue,
            clock: clock,
            otherEntries: otherEntries,
        )
    }

    private init(
        logger: Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
        otherEntries: [String: Entry]?
    ) {
        entries = otherEntries ?? [:]
        // TODO: What initial root entry to use? https://github.com/ably/specification/pull/333/files#r2152312933
        entries[Self.rootKey] = .map(.createZeroValued(objectID: Self.rootKey, logger: logger, userCallbackQueue: userCallbackQueue, clock: clock))
    }

    // MARK: - Typed root

    /// Fetches the root object.
    internal var root: InternalDefaultLiveMap {
        guard let rootEntry = entries[Self.rootKey] else {
            preconditionFailure("ObjectsPool should always contain a root object")
        }

        switch rootEntry {
        case let .map(map):
            return map
        case .counter:
            preconditionFailure("The ObjectsPool root object must always be a map")
        }
    }

    // MARK: - Data manipulation

    /// Creates a zero-value object if it does not exist in the pool, per RTO6. This is used when applying a `MAP_SET` operation that contains a reference to another object.
    ///
    /// - Parameters:
    ///   - objectID: The ID of the object to create
    ///   - logger: The logger to use for any created LiveObject
    ///   - userCallbackQueue: The callback queue to use for any created LiveObject
    ///   - clock: The clock to use for any created LiveObject
    /// - Returns: The existing or newly created object
    internal mutating func createZeroValueObject(forObjectID objectID: String, logger: Logger, userCallbackQueue: DispatchQueue, clock: SimpleClock) -> Entry? {
        // RTO6a: If an object with objectId exists in ObjectsPool, do not create a new object
        if let existingEntry = entries[objectID] {
            return existingEntry
        }

        // RTO6b: The expected type of the object can be inferred from the provided objectId
        // RTO6b1: Split the objectId (formatted as type:hash@timestamp) on the separator : and parse the first part as the type string
        let components = objectID.split(separator: ":")
        guard let typeString = components.first else {
            return nil
        }

        // RTO6b2: If the parsed type is map, create a zero-value LiveMap per RTLM4 in the ObjectsPool
        // RTO6b3: If the parsed type is counter, create a zero-value LiveCounter per RTLC4 in the ObjectsPool
        let entry: Entry
        switch typeString {
        case "map":
            entry = .map(.createZeroValued(objectID: objectID, logger: logger, userCallbackQueue: userCallbackQueue, clock: clock))
        case "counter":
            entry = .counter(.createZeroValued(objectID: objectID, logger: logger, userCallbackQueue: userCallbackQueue, clock: clock))
        default:
            return nil
        }

        // Note that already know that the key is not "root" per the above check so there's no risk of breaking the RTO3b invariant that the root object is always a map
        entries[objectID] = entry
        return entry
    }

    /// Applies the objects gathered during an `OBJECT_SYNC` to this `ObjectsPool`, per RTO5c1 and RTO5c2.
    internal mutating func applySyncObjectsPool(
        _ syncObjectsPool: [SyncObjectsPoolEntry],
        logger: Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
    ) {
        logger.log("applySyncObjectsPool called with \(syncObjectsPool.count) objects", level: .debug)

        // Keep track of object IDs that were received during sync for RTO5c2
        var receivedObjectIds = Set<String>()

        // Keep track of updates to existing objects during sync for RTO5c1a2
        var updatesToExistingObjects: [ObjectsPool.Entry.DeferredUpdate] = []

        // RTO5c1: For each ObjectState member in the SyncObjectsPool list
        for syncObjectsPoolEntry in syncObjectsPool {
            receivedObjectIds.insert(syncObjectsPoolEntry.state.objectId)

            // RTO5c1a: If an object with ObjectState.objectId exists in the internal ObjectsPool
            if let existingEntry = entries[syncObjectsPoolEntry.state.objectId] {
                logger.log("Updating existing object with ID: \(syncObjectsPoolEntry.state.objectId)", level: .debug)

                // RTO5c1a1: Override the internal data for the object as per RTLC6, RTLM6
                let deferredUpdate = existingEntry.replaceData(
                    using: syncObjectsPoolEntry.state,
                    objectMessageSerialTimestamp: syncObjectsPoolEntry.objectMessageSerialTimestamp,
                    objectsPool: &self,
                )
                // RTO5c1a2: Store this update to emit at end
                updatesToExistingObjects.append(deferredUpdate)
            } else {
                // RTO5c1b: If an object with ObjectState.objectId does not exist in the internal ObjectsPool
                logger.log("Creating new object with ID: \(syncObjectsPoolEntry.state.objectId)", level: .debug)

                // RTO5c1b1: Create a new LiveObject using the data from ObjectState and add it to the internal ObjectsPool:
                let newEntry: Entry?

                if syncObjectsPoolEntry.state.counter != nil {
                    // RTO5c1b1a: If ObjectState.counter is present, create a zero-value LiveCounter,
                    // set its private objectId equal to ObjectState.objectId and override its internal data per RTLC6
                    let counter = InternalDefaultLiveCounter.createZeroValued(objectID: syncObjectsPoolEntry.state.objectId, logger: logger, userCallbackQueue: userCallbackQueue, clock: clock)
                    _ = counter.replaceData(
                        using: syncObjectsPoolEntry.state,
                        objectMessageSerialTimestamp: syncObjectsPoolEntry.objectMessageSerialTimestamp,
                    )
                    newEntry = .counter(counter)
                } else if let objectsMap = syncObjectsPoolEntry.state.map {
                    // RTO5c1b1b: If ObjectState.map is present, create a zero-value LiveMap,
                    // set its private objectId equal to ObjectState.objectId, set its private semantics
                    // equal to ObjectState.map.semantics and override its internal data per RTLM6
                    let map = InternalDefaultLiveMap.createZeroValued(objectID: syncObjectsPoolEntry.state.objectId, semantics: objectsMap.semantics, logger: logger, userCallbackQueue: userCallbackQueue, clock: clock)
                    _ = map.replaceData(
                        using: syncObjectsPoolEntry.state,
                        objectMessageSerialTimestamp: syncObjectsPoolEntry.objectMessageSerialTimestamp,
                        objectsPool: &self,
                    )
                    newEntry = .map(map)
                } else {
                    // RTO5c1b1c: Otherwise, log a warning that an unsupported object state message has been received, and discard the current ObjectState without taking any action
                    logger.log("Unsupported object state message received for objectId: \(syncObjectsPoolEntry.state.objectId)", level: .warn)
                    newEntry = nil
                }

                if let newEntry {
                    // Note that we will never replace the root object here, and thus never break the RTO3b invariant that the root object is always a map. This is because the pool always contains a root object and thus we always go through the RTO5c1a branch of the `if` above.
                    entries[syncObjectsPoolEntry.state.objectId] = newEntry
                }
            }
        }

        // RTO5c2: Remove any objects from the internal ObjectsPool for which objectIds were not received during the sync sequence
        // RTO5c2a: The object with ID "root" must not be removed from ObjectsPool, as per RTO3b
        let objectIdsToRemove = Set(entries.keys).subtracting(receivedObjectIds + [Self.rootKey])
        if !objectIdsToRemove.isEmpty {
            logger.log("Removing objects with IDs: \(objectIdsToRemove) as they were not in sync", level: .debug)
            for objectId in objectIdsToRemove {
                entries.removeValue(forKey: objectId)
            }
        }

        // RTO5c7: Emit the updates to existing objects
        for deferredUpdate in updatesToExistingObjects {
            deferredUpdate.emit()
        }

        logger.log("applySyncObjectsPool completed. Pool now contains \(entries.count) objects", level: .debug)
    }

    /// Gets or creates a counter object in the pool, implementing the "find or create zero-value" behavior of RTO12h1.
    ///
    /// - Parameters:
    ///   - creationOperation: The CounterCreationOperation containing the object ID and operation to merge
    ///   - logger: The logger to use for any created LiveObject
    ///   - userCallbackQueue: The callback queue to use for any created LiveObject
    ///   - clock: The clock to use for any created LiveObject
    /// - Returns: The existing or newly created counter object
    internal mutating func getOrCreateCounter(
        creationOperation: ObjectCreationHelpers.CounterCreationOperation,
        logger: Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
    ) -> InternalDefaultLiveCounter {
        // RTO12h2: If an object with the ObjectMessage.operation.objectId exists in the internal ObjectsPool, return it
        if let existingEntry = entries[creationOperation.objectID] {
            switch existingEntry {
            case let .counter(counter):
                return counter
            case .map:
                // TODO: Add the ability to statically reason about the type of pool entries in https://github.com/ably/ably-liveobjects-swift-plugin/issues/36
                preconditionFailure("Expected counter object with ID \(creationOperation.objectID) but found map object")
            }
        }

        // RTO12h3: Otherwise, if the object does not exist in the internal ObjectsPool:
        // RTO12h3a: Create a zero-value LiveCounter, set its objectId to ObjectMessage.operation.objectId, and merge the initial value
        let counter = InternalDefaultLiveCounter.createZeroValued(
            objectID: creationOperation.objectID,
            logger: logger,
            userCallbackQueue: userCallbackQueue,
            clock: clock,
        )

        // Merge the initial value from the creation operation
        _ = counter.mergeInitialValue(from: creationOperation.operation)

        // RTO12h3b: Add the created LiveCounter instance to the internal ObjectsPool
        entries[creationOperation.objectID] = .counter(counter)

        // RTO12h3c: Return the created LiveCounter instance
        return counter
    }

    /// Gets or creates a map object in the pool, implementing the "find or create zero-value" behavior of RTO11h1.
    ///
    /// - Parameters:
    ///   - creationOperation: The MapCreationOperation containing the object ID and operation to merge
    ///   - logger: The logger to use for any created LiveObject
    ///   - userCallbackQueue: The callback queue to use for any created LiveObject
    ///   - clock: The clock to use for any created LiveObject
    /// - Returns: The existing or newly created map object
    internal mutating func getOrCreateMap(
        creationOperation: ObjectCreationHelpers.MapCreationOperation,
        logger: Logger,
        userCallbackQueue: DispatchQueue,
        clock: SimpleClock,
    ) -> InternalDefaultLiveMap {
        // RTO11h2: If an object with the ObjectMessage.operation.objectId exists in the internal ObjectsPool, return it
        if let existingEntry = entries[creationOperation.objectID] {
            switch existingEntry {
            case let .map(map):
                return map
            case .counter:
                // TODO: Add the ability to statically reason about the type of pool entries in https://github.com/ably/ably-liveobjects-swift-plugin/issues/36
                preconditionFailure("Expected map object with ID \(creationOperation.objectID) but found counter object")
            }
        }

        // RTO11h3: Otherwise, if the object does not exist in the internal ObjectsPool:
        // RTO11h3a: Create a zero-value LiveMap, set its objectId to ObjectMessage.operation.objectId, set its semantics to ObjectMessage.operation.map.semantics, and merge the initial value
        let map = InternalDefaultLiveMap.createZeroValued(
            objectID: creationOperation.objectID,
            semantics: .known(creationOperation.semantics),
            logger: logger,
            userCallbackQueue: userCallbackQueue,
            clock: clock,
        )

        // Merge the initial value from the creation operation
        _ = map.mergeInitialValue(from: creationOperation.operation, objectsPool: &self)

        // RTO11h3b: Add the created LiveMap instance to the internal ObjectsPool
        entries[creationOperation.objectID] = .map(map)

        // RTO11h3c: Return the created LiveMap instance
        return map
    }

    /// Removes all entries except the root, and clears the root's data. This is to be used when an `ATTACHED` ProtocolMessage indicates that the only object in a channel is an empty root map, per RTO4b.
    internal mutating func reset() {
        let root = root

        // RTO4b1
        entries = [Self.rootKey: .map(root)]

        // RTO4b2
        // TODO: this one is unclear (are we meant to replace the root or just clear its data?) https://github.com/ably/specification/pull/333/files#r2183493458. I believe that the answer is that we should just clear its data but the spec point needs to be clearer, see https://github.com/ably/specification/pull/346/files#r2201434895.
        root.resetData()
    }

    /// Performs garbage collection of tombstoned objects and map entries, per RTO10c.
    internal mutating func performGarbageCollection(
        gracePeriod: TimeInterval,
        clock: SimpleClock,
        logger: Logger,
        eventsContinuation: AsyncStream<Void>.Continuation,
    ) {
        logger.log("Performing garbage collection, grace period \(gracePeriod)s", level: .debug)

        let now = clock.now

        entries = entries.filter { key, entry in
            if case let .map(map) = entry {
                // RTO10c1a
                map.releaseTombstonedEntries(gracePeriod: gracePeriod, clock: clock)
            }

            // RTO10c1b
            let shouldRelease = {
                guard let tombstonedAt = entry.tombstonedAt else {
                    return false
                }

                return now.timeIntervalSince(tombstonedAt) >= gracePeriod
            }()

            if shouldRelease {
                logger.log("Releasing tombstoned entry \(entry) for key \(key)", level: .debug)
            }
            return !shouldRelease
        }

        eventsContinuation.yield()
    }
}
