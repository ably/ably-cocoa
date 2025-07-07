internal import AblyPlugin

/// Maintains the list of objects present on a channel, as described by RTO3.
///
/// Note that this is a value type.
internal struct ObjectsPool {
    /// The possible `ObjectsPool` entries, as described by RTO3a.
    internal enum Entry {
        case map(DefaultLiveMap)
        case counter(DefaultLiveCounter)

        /// Convenience getter for accessing the map value if this entry is a map
        internal var mapValue: DefaultLiveMap? {
            switch self {
            case let .map(map):
                map
            case .counter:
                nil
            }
        }

        /// Convenience getter for accessing the counter value if this entry is a counter
        internal var counterValue: DefaultLiveCounter? {
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
            objectsPool: inout ObjectsPool,
        ) {
            switch self {
            case let .map(map):
                map.apply(
                    operation,
                    objectMessageSerial: objectMessageSerial,
                    objectMessageSiteCode: objectMessageSiteCode,
                    objectsPool: &objectsPool,
                )
            case let .counter(counter):
                counter.apply(
                    operation,
                    objectMessageSerial: objectMessageSerial,
                    objectMessageSiteCode: objectMessageSiteCode,
                    objectsPool: &objectsPool,
                )
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
        rootDelegate: LiveMapObjectPoolDelegate?,
        rootCoreSDK: CoreSDK,
        logger: AblyPlugin.Logger,
        testsOnly_otherEntries otherEntries: [String: Entry]? = nil,
    ) {
        self.init(
            rootDelegate: rootDelegate,
            rootCoreSDK: rootCoreSDK,
            logger: logger,
            otherEntries: otherEntries,
        )
    }

    private init(
        rootDelegate: LiveMapObjectPoolDelegate?,
        rootCoreSDK: CoreSDK,
        logger: AblyPlugin.Logger,
        otherEntries: [String: Entry]?
    ) {
        entries = otherEntries ?? [:]
        // TODO: What initial root entry to use? https://github.com/ably/specification/pull/333/files#r2152312933
        entries[Self.rootKey] = .map(.createZeroValued(objectID: Self.rootKey, delegate: rootDelegate, coreSDK: rootCoreSDK, logger: logger))
    }

    // MARK: - Typed root

    /// Fetches the root object.
    internal var root: DefaultLiveMap {
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
    ///   - mapDelegate: The delegate to use for any created LiveMap
    ///   - coreSDK: The CoreSDK to use for any created LiveObject
    ///   - logger: The logger to use for any created LiveObject
    /// - Returns: The existing or newly created object
    internal mutating func createZeroValueObject(forObjectID objectID: String, mapDelegate: LiveMapObjectPoolDelegate?, coreSDK: CoreSDK, logger: AblyPlugin.Logger) -> Entry? {
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
            entry = .map(.createZeroValued(objectID: objectID, delegate: mapDelegate, coreSDK: coreSDK, logger: logger))
        case "counter":
            entry = .counter(.createZeroValued(objectID: objectID, coreSDK: coreSDK, logger: logger))
        default:
            return nil
        }

        // Note that already know that the key is not "root" per the above check so there's no risk of breaking the RTO3b invariant that the root object is always a map
        entries[objectID] = entry
        return entry
    }

    /// Applies the objects gathered during an `OBJECT_SYNC` to this `ObjectsPool`, per RTO5c1.
    ///
    /// - Parameters:
    ///   - mapDelegate: The delegate to use for any created LiveMap
    ///   - coreSDK: The CoreSDK to use for any created LiveObject
    internal mutating func applySyncObjectsPool(
        _ syncObjectsPool: [ObjectState],
        mapDelegate: LiveMapObjectPoolDelegate,
        coreSDK: CoreSDK,
        logger: AblyPlugin.Logger,
    ) {
        logger.log("applySyncObjectsPool called with \(syncObjectsPool.count) objects", level: .debug)

        // Keep track of object IDs that were received during sync for RTO5c2
        var receivedObjectIds = Set<String>()

        // RTO5c1: For each ObjectState member in the SyncObjectsPool list
        for objectState in syncObjectsPool {
            receivedObjectIds.insert(objectState.objectId)

            // RTO5c1a: If an object with ObjectState.objectId exists in the internal ObjectsPool
            if let existingEntry = entries[objectState.objectId] {
                logger.log("Updating existing object with ID: \(objectState.objectId)", level: .debug)

                // RTO5c1a1: Override the internal data for the object as per RTLC6, RTLM6
                switch existingEntry {
                case let .map(map):
                    map.replaceData(using: objectState, objectsPool: &self)
                case let .counter(counter):
                    counter.replaceData(using: objectState)
                }
            } else {
                // RTO5c1b: If an object with ObjectState.objectId does not exist in the internal ObjectsPool
                logger.log("Creating new object with ID: \(objectState.objectId)", level: .debug)

                // RTO5c1b1: Create a new LiveObject using the data from ObjectState and add it to the internal ObjectsPool:
                let newEntry: Entry?

                if objectState.counter != nil {
                    // RTO5c1b1a: If ObjectState.counter is present, create a zero-value LiveCounter,
                    // set its private objectId equal to ObjectState.objectId and override its internal data per RTLC6
                    let counter = DefaultLiveCounter.createZeroValued(objectID: objectState.objectId, coreSDK: coreSDK, logger: logger)
                    counter.replaceData(using: objectState)
                    newEntry = .counter(counter)
                } else if let objectsMap = objectState.map {
                    // RTO5c1b1b: If ObjectState.map is present, create a zero-value LiveMap,
                    // set its private objectId equal to ObjectState.objectId, set its private semantics
                    // equal to ObjectState.map.semantics and override its internal data per RTLM6
                    let map = DefaultLiveMap.createZeroValued(objectID: objectState.objectId, semantics: objectsMap.semantics, delegate: mapDelegate, coreSDK: coreSDK, logger: logger)
                    map.replaceData(using: objectState, objectsPool: &self)
                    newEntry = .map(map)
                } else {
                    // RTO5c1b1c: Otherwise, log a warning that an unsupported object state message has been received, and discard the current ObjectState without taking any action
                    logger.log("Unsupported object state message received for objectId: \(objectState.objectId)", level: .warn)
                    newEntry = nil
                }

                if let newEntry {
                    // Note that we will never replace the root object here, and thus never break the RTO3b invariant that the root object is always a map. This is because the pool always contains a root object and thus we always go through the RTO5c1a branch of the `if` above.
                    entries[objectState.objectId] = newEntry
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

        logger.log("applySyncObjectsPool completed. Pool now contains \(entries.count) objects", level: .debug)
    }
}
