import Ably
internal import AblyPlugin

/// Protocol for accessing objects from the ObjectsPool. This is used by a LiveMap when it needs to return an object given an object ID.
internal protocol LiveMapObjectPoolDelegate: AnyObject, Sendable {
    /// Fetches an object from the pool by its ID
    func getObjectFromPool(id: String) -> ObjectsPool.Entry?
}

/// This provides the implementation behind ``PublicDefaultLiveMap``, via internal versions of the ``LiveMap`` API.
internal final class InternalDefaultLiveMap: Sendable {
    // Used for synchronizing access to all of this instance's mutable state. This is a temporary solution just to allow us to implement `Sendable`, and we'll revisit it in https://github.com/ably/ably-cocoa-liveobjects-plugin/issues/3.
    private let mutex = NSLock()

    private nonisolated(unsafe) var mutableState: MutableState

    internal var testsOnly_data: [String: ObjectsMapEntry] {
        mutex.withLock {
            mutableState.data
        }
    }

    internal var testsOnly_objectID: String {
        mutex.withLock {
            mutableState.liveObject.objectID
        }
    }

    internal var testsOnly_semantics: WireEnum<ObjectsMapSemantics>? {
        mutex.withLock {
            mutableState.semantics
        }
    }

    internal var testsOnly_siteTimeserials: [String: String] {
        mutex.withLock {
            mutableState.liveObject.siteTimeserials
        }
    }

    internal var testsOnly_createOperationIsMerged: Bool {
        mutex.withLock {
            mutableState.liveObject.createOperationIsMerged
        }
    }

    private let logger: AblyPlugin.Logger

    // MARK: - Initialization

    internal convenience init(
        testsOnly_data data: [String: ObjectsMapEntry],
        objectID: String,
        testsOnly_semantics semantics: WireEnum<ObjectsMapSemantics>? = nil,
        logger: AblyPlugin.Logger
    ) {
        self.init(
            data: data,
            objectID: objectID,
            semantics: semantics,
            logger: logger,
        )
    }

    private init(
        data: [String: ObjectsMapEntry],
        objectID: String,
        semantics: WireEnum<ObjectsMapSemantics>?,
        logger: AblyPlugin.Logger
    ) {
        mutableState = .init(liveObject: .init(objectID: objectID), data: data, semantics: semantics)
        self.logger = logger
    }

    /// Creates a "zero-value LiveMap", per RTLM4.
    ///
    /// - Parameters:
    ///   - objectID: The value to use for the RTLO3a `objectID` property.
    ///   - semantics: The value to use for the "private `semantics` field" of RTO5c1b1b.
    internal static func createZeroValued(
        objectID: String,
        semantics: WireEnum<ObjectsMapSemantics>? = nil,
        logger: AblyPlugin.Logger,
    ) -> Self {
        .init(
            data: [:],
            objectID: objectID,
            semantics: semantics,
            logger: logger,
        )
    }

    // MARK: - Internal methods that back LiveMap conformance

    /// Returns the value associated with a given key, following RTLM5d specification.
    internal func get(key: String, coreSDK: CoreSDK, delegate: LiveMapObjectPoolDelegate) throws(ARTErrorInfo) -> InternalLiveMapValue? {
        // RTLM5c: If the channel is in the DETACHED or FAILED state, the library should indicate an error with code 90001
        let currentChannelState = coreSDK.channelState
        if currentChannelState == .detached || currentChannelState == .failed {
            throw LiveObjectsError.objectsOperationFailedInvalidChannelState(
                operationDescription: "LiveMap.get",
                channelState: currentChannelState,
            )
            .toARTErrorInfo()
        }

        let entry = mutex.withLock {
            mutableState.data[key]
        }

        // RTLM5d1: If no ObjectsMapEntry exists at the key, return undefined/null
        guard let entry else {
            return nil
        }

        // RTLM5d2: If a ObjectsMapEntry exists at the key, convert it using the shared logic
        return convertEntryToLiveMapValue(entry, delegate: delegate)
    }

    internal func size(coreSDK: CoreSDK) throws(ARTErrorInfo) -> Int {
        // RTLM10c: If the channel is in the DETACHED or FAILED state, the library should throw an ErrorInfo error with statusCode 400 and code 90001
        let currentChannelState = coreSDK.channelState
        if currentChannelState == .detached || currentChannelState == .failed {
            throw LiveObjectsError.objectsOperationFailedInvalidChannelState(
                operationDescription: "LiveMap.size",
                channelState: currentChannelState,
            )
            .toARTErrorInfo()
        }

        return mutex.withLock {
            // RTLM10d: Returns the number of non-tombstoned entries (per RTLM14) in the internal data map
            mutableState.data.values.count { entry in
                // RTLM14a: The method returns true if ObjectsMapEntry.tombstone is true
                // RTLM14b: Otherwise, it returns false
                entry.tombstone != true
            }
        }
    }

    internal func entries(coreSDK: CoreSDK, delegate: LiveMapObjectPoolDelegate) throws(ARTErrorInfo) -> [(key: String, value: InternalLiveMapValue)] {
        // RTLM11c: If the channel is in the DETACHED or FAILED state, the library should throw an ErrorInfo error with statusCode 400 and code 90001
        let currentChannelState = coreSDK.channelState
        if currentChannelState == .detached || currentChannelState == .failed {
            throw LiveObjectsError.objectsOperationFailedInvalidChannelState(
                operationDescription: "LiveMap.entries",
                channelState: currentChannelState,
            )
            .toARTErrorInfo()
        }

        return mutex.withLock {
            // RTLM11d: Returns key-value pairs from the internal data map
            // RTLM11d1: Pairs with tombstoned entries (per RTLM14) are not returned
            var result: [(key: String, value: InternalLiveMapValue)] = []

            for (key, entry) in mutableState.data {
                // Convert entry to LiveMapValue using the same logic as get(key:)
                if let value = convertEntryToLiveMapValue(entry, delegate: delegate) {
                    result.append((key: key, value: value))
                }
            }

            return result
        }
    }

    internal func keys(coreSDK: CoreSDK, delegate: LiveMapObjectPoolDelegate) throws(ARTErrorInfo) -> [String] {
        // RTLM12b: Identical to LiveMap#entries, except that it returns only the keys from the internal data map
        try entries(coreSDK: coreSDK, delegate: delegate).map(\.key)
    }

    internal func values(coreSDK: CoreSDK, delegate: LiveMapObjectPoolDelegate) throws(ARTErrorInfo) -> [InternalLiveMapValue] {
        // RTLM13b: Identical to LiveMap#entries, except that it returns only the values from the internal data map
        try entries(coreSDK: coreSDK, delegate: delegate).map(\.value)
    }

    internal func set(key _: String, value _: LiveMapValue) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    internal func remove(key _: String) async throws(ARTErrorInfo) {
        notYetImplemented()
    }

    internal func subscribe(listener _: LiveObjectUpdateCallback<LiveMapUpdate>) -> any SubscribeResponse {
        notYetImplemented()
    }

    internal func unsubscribeAll() {
        notYetImplemented()
    }

    internal func on(event _: LiveObjectLifecycleEvent, callback _: LiveObjectLifecycleEventCallback) -> any OnLiveObjectLifecycleEventResponse {
        notYetImplemented()
    }

    internal func offAll() {
        notYetImplemented()
    }

    // MARK: - Data manipulation

    /// Replaces the internal data of this map with the provided ObjectState, per RTLM6.
    ///
    /// - Parameters:
    ///   - objectsPool: The pool into which should be inserted any objects created by a `MAP_SET` operation.
    internal func replaceData(using state: ObjectState, objectsPool: inout ObjectsPool) {
        mutex.withLock {
            mutableState.replaceData(
                using: state,
                objectsPool: &objectsPool,
                logger: logger,
            )
        }
    }

    /// Test-only method to merge initial value from an ObjectOperation, per RTLM17.
    internal func testsOnly_mergeInitialValue(from operation: ObjectOperation, objectsPool: inout ObjectsPool) {
        mutex.withLock {
            mutableState.mergeInitialValue(
                from: operation,
                objectsPool: &objectsPool,
                logger: logger,
            )
        }
    }

    /// Test-only method to apply a MAP_CREATE operation, per RTLM16.
    internal func testsOnly_applyMapCreateOperation(_ operation: ObjectOperation, objectsPool: inout ObjectsPool) {
        mutex.withLock {
            mutableState.applyMapCreateOperation(
                operation,
                objectsPool: &objectsPool,
                logger: logger,
            )
        }
    }

    /// Attempts to apply an operation from an inbound `ObjectMessage`, per RTLM15.
    internal func apply(
        _ operation: ObjectOperation,
        objectMessageSerial: String?,
        objectMessageSiteCode: String?,
        objectsPool: inout ObjectsPool,
    ) {
        mutex.withLock {
            mutableState.apply(
                operation,
                objectMessageSerial: objectMessageSerial,
                objectMessageSiteCode: objectMessageSiteCode,
                objectsPool: &objectsPool,
                logger: logger,
            )
        }
    }

    /// Applies a `MAP_SET` operation to a key, per RTLM7.
    ///
    /// This is currently exposed just so that the tests can test RTLM7 without having to go through a convoluted replaceData(…) call, but I _think_ that it's going to be used in further contexts when we introduce the handling of incoming object operations in a future spec PR.
    internal func testsOnly_applyMapSetOperation(
        key: String,
        operationTimeserial: String?,
        operationData: ObjectData,
        objectsPool: inout ObjectsPool,
    ) {
        mutex.withLock {
            mutableState.applyMapSetOperation(
                key: key,
                operationTimeserial: operationTimeserial,
                operationData: operationData,
                objectsPool: &objectsPool,
                logger: logger,
            )
        }
    }

    /// Applies a `MAP_REMOVE` operation to a key, per RTLM8.
    ///
    /// This is currently exposed just so that the tests can test RTLM8 without having to go through a convoluted replaceData(…) call, but I _think_ that it's going to be used in further contexts when we introduce the handling of incoming object operations in a future spec PR.
    internal func testsOnly_applyMapRemoveOperation(key: String, operationTimeserial: String?) {
        mutex.withLock {
            mutableState.applyMapRemoveOperation(
                key: key,
                operationTimeserial: operationTimeserial,
            )
        }
    }

    // MARK: - Mutable state and the operations that affect it

    private struct MutableState {
        /// The mutable state common to all LiveObjects.
        internal var liveObject: LiveObjectMutableState

        /// The internal data that this map holds, per RTLM3.
        internal var data: [String: ObjectsMapEntry]

        /// The "private `semantics` field" of RTO5c1b1b.
        internal var semantics: WireEnum<ObjectsMapSemantics>?

        /// Replaces the internal data of this map with the provided ObjectState, per RTLM6.
        ///
        /// - Parameters:
        ///   - objectsPool: The pool into which should be inserted any objects created by a `MAP_SET` operation.
        internal mutating func replaceData(
            using state: ObjectState,
            objectsPool: inout ObjectsPool,
            logger: AblyPlugin.Logger,
        ) {
            // RTLM6a: Replace the private siteTimeserials with the value from ObjectState.siteTimeserials
            liveObject.siteTimeserials = state.siteTimeserials

            // RTLM6b: Set the private flag createOperationIsMerged to false
            liveObject.createOperationIsMerged = false

            // RTLM6c: Set data to ObjectState.map.entries, or to an empty map if it does not exist
            data = state.map?.entries ?? [:]

            // RTLM6d: If ObjectState.createOp is present, merge the initial value into the LiveMap as described in RTLM17
            if let createOp = state.createOp {
                mergeInitialValue(
                    from: createOp,
                    objectsPool: &objectsPool,
                    logger: logger,
                )
            }
        }

        /// Merges the initial value from an ObjectOperation into this LiveMap, per RTLM17.
        internal mutating func mergeInitialValue(
            from operation: ObjectOperation,
            objectsPool: inout ObjectsPool,
            logger: AblyPlugin.Logger,
        ) {
            // RTLM17a: For each key–ObjectsMapEntry pair in ObjectOperation.map.entries
            if let entries = operation.map?.entries {
                for (key, entry) in entries {
                    if entry.tombstone == true {
                        // RTLM17a2: If ObjectsMapEntry.tombstone is true, apply the MAP_REMOVE operation
                        // as described in RTLM8, passing in the current key as ObjectsMapOp, and ObjectsMapEntry.timeserial as the operation's serial
                        applyMapRemoveOperation(
                            key: key,
                            operationTimeserial: entry.timeserial,
                        )
                    } else {
                        // RTLM17a1: If ObjectsMapEntry.tombstone is false, apply the MAP_SET operation
                        // as described in RTLM7, passing in ObjectsMapEntry.data and the current key as ObjectsMapOp, and ObjectsMapEntry.timeserial as the operation's serial
                        applyMapSetOperation(
                            key: key,
                            operationTimeserial: entry.timeserial,
                            operationData: entry.data,
                            objectsPool: &objectsPool,
                            logger: logger,
                        )
                    }
                }
            }
            // RTLM17b: Set the private flag createOperationIsMerged to true
            liveObject.createOperationIsMerged = true
        }

        /// Attempts to apply an operation from an inbound `ObjectMessage`, per RTLM15.
        internal mutating func apply(
            _ operation: ObjectOperation,
            objectMessageSerial: String?,
            objectMessageSiteCode: String?,
            objectsPool: inout ObjectsPool,
            logger: Logger,
        ) {
            guard let applicableOperation = liveObject.canApplyOperation(objectMessageSerial: objectMessageSerial, objectMessageSiteCode: objectMessageSiteCode, logger: logger) else {
                // RTLM15b
                logger.log("Operation \(operation) (serial: \(String(describing: objectMessageSerial)), siteCode: \(String(describing: objectMessageSiteCode))) should not be applied; discarding", level: .debug)
                return
            }

            // RTLM15c
            liveObject.siteTimeserials[applicableOperation.objectMessageSiteCode] = applicableOperation.objectMessageSerial

            switch operation.action {
            case .known(.mapCreate):
                // RTLM15d1
                applyMapCreateOperation(
                    operation,
                    objectsPool: &objectsPool,
                    logger: logger,
                )
            case .known(.mapSet):
                guard let mapOp = operation.mapOp else {
                    logger.log("Could not apply MAP_SET since operation.mapOp is missing", level: .warn)
                    return
                }
                guard let data = mapOp.data else {
                    logger.log("Could not apply MAP_SET since operation.data is missing", level: .warn)
                    return
                }

                // RTLM15d2
                applyMapSetOperation(
                    key: mapOp.key,
                    operationTimeserial: applicableOperation.objectMessageSerial,
                    operationData: data,
                    objectsPool: &objectsPool,
                    logger: logger,
                )
            case .known(.mapRemove):
                guard let mapOp = operation.mapOp else {
                    return
                }

                // RTLM15d3
                applyMapRemoveOperation(
                    key: mapOp.key,
                    operationTimeserial: applicableOperation.objectMessageSerial,
                )
            default:
                // RTLM15d4
                logger.log("Operation \(operation) has unsupported action for LiveMap; discarding", level: .warn)
            }
        }

        /// Applies a `MAP_SET` operation to a key, per RTLM7.
        internal mutating func applyMapSetOperation(
            key: String,
            operationTimeserial: String?,
            operationData: ObjectData,
            objectsPool: inout ObjectsPool,
            logger: AblyPlugin.Logger,
        ) {
            // RTLM7a: If an entry exists in the private data for the specified key
            if let existingEntry = data[key] {
                // RTLM7a1: If the operation cannot be applied as per RTLM9, discard the operation
                if !Self.canApplyMapOperation(entryTimeserial: existingEntry.timeserial, operationTimeserial: operationTimeserial) {
                    return
                }
                // RTLM7a2: Otherwise, apply the operation
                // RTLM7a2a: Set ObjectsMapEntry.data to the ObjectData from the operation
                // RTLM7a2b: Set ObjectsMapEntry.timeserial to the operation's serial
                // RTLM7a2c: Set ObjectsMapEntry.tombstone to false
                var updatedEntry = existingEntry
                updatedEntry.data = operationData
                updatedEntry.timeserial = operationTimeserial
                updatedEntry.tombstone = false
                data[key] = updatedEntry
            } else {
                // RTLM7b: If an entry does not exist in the private data for the specified key
                // RTLM7b1: Create a new entry in data for the specified key with the provided ObjectData and the operation's serial
                // RTLM7b2: Set ObjectsMapEntry.tombstone for the new entry to false
                data[key] = ObjectsMapEntry(tombstone: false, timeserial: operationTimeserial, data: operationData)
            }

            // RTLM7c: If the operation has a non-empty ObjectData.objectId attribute
            if let objectId = operationData.objectId, !objectId.isEmpty {
                // RTLM7c1: Create a zero-value LiveObject in the internal ObjectsPool per RTO6
                _ = objectsPool.createZeroValueObject(forObjectID: objectId, logger: logger)
            }
        }

        /// Applies a `MAP_REMOVE` operation to a key, per RTLM8.
        internal mutating func applyMapRemoveOperation(key: String, operationTimeserial: String?) {
            // (Note that, where the spec tells us to set ObjectsMapEntry.data to nil, we actually set it to an empty ObjectData, which is equivalent, since it contains no data)

            // RTLM8a: If an entry exists in the private data for the specified key
            if let existingEntry = data[key] {
                // RTLM8a1: If the operation cannot be applied as per RTLM9, discard the operation
                if !Self.canApplyMapOperation(entryTimeserial: existingEntry.timeserial, operationTimeserial: operationTimeserial) {
                    return
                }
                // RTLM8a2: Otherwise, apply the operation
                // RTLM8a2a: Set ObjectsMapEntry.data to undefined/null
                // RTLM8a2b: Set ObjectsMapEntry.timeserial to the operation's serial
                // RTLM8a2c: Set ObjectsMapEntry.tombstone to true
                var updatedEntry = existingEntry
                updatedEntry.data = ObjectData()
                updatedEntry.timeserial = operationTimeserial
                updatedEntry.tombstone = true
                data[key] = updatedEntry
            } else {
                // RTLM8b: If an entry does not exist in the private data for the specified key
                // RTLM8b1: Create a new entry in data for the specified key, with ObjectsMapEntry.data set to undefined/null and the operation's serial
                // RTLM8b2: Set ObjectsMapEntry.tombstone for the new entry to true
                data[key] = ObjectsMapEntry(tombstone: true, timeserial: operationTimeserial, data: ObjectData())
            }
        }

        /// Determines whether a map operation can be applied to a map entry, per RTLM9.
        private static func canApplyMapOperation(entryTimeserial: String?, operationTimeserial: String?) -> Bool {
            // I am going to treat "exists" and "is non-empty" as equivalent here, because the spec mentions "null or empty" in some places and is vague in others.
            func normalize(timeserial: String?) -> String? {
                // swiftlint:disable:next empty_string
                timeserial == "" ? nil : timeserial
            }

            let (
                normalizedEntryTimeserial,
                normalizedOperationTimeserial
            ) = (
                normalize(timeserial: entryTimeserial),
                normalize(timeserial: operationTimeserial),
            )

            return switch (normalizedEntryTimeserial, normalizedOperationTimeserial) {
            case let (.some(normalizedEntryTimeserial), .some(normalizedOperationTimeserial)):
                // RTLM9a: For a LiveMap using LWW (Last-Write-Wins) CRDT semantics, the operation must
                // only be applied if its serial is strictly greater ("after") than the entry's serial
                // when compared lexicographically
                // RTLM9e: If both serials exist, compare them lexicographically and allow operation
                // to be applied only if the operation's serial is greater than the entry's serial
                normalizedOperationTimeserial > normalizedEntryTimeserial
            case (nil, .some):
                // RTLM9d: If only the operation serial exists, it is considered greater than the missing
                // entry serial, so the operation can be applied
                true
            case (.some, nil):
                // RTLM9c: If only the entry serial exists, the missing operation serial is considered lower
                // than the existing entry serial, so the operation must not be applied
                false
            case (nil, nil):
                // RTLM9b: If both the entry serial and the operation serial are null or empty strings,
                // they are treated as the "earliest possible" serials and considered "equal",
                // so the operation must not be applied
                false
            }
        }

        /// Applies a `MAP_CREATE` operation, per RTLM16.
        internal mutating func applyMapCreateOperation(
            _ operation: ObjectOperation,
            objectsPool: inout ObjectsPool,
            logger: AblyPlugin.Logger,
        ) {
            if liveObject.createOperationIsMerged {
                // RTLM16b
                logger.log("Not applying MAP_CREATE because a MAP_CREATE has already been applied", level: .warn)
                return
            }

            // TODO: RTLM16c `semantics` comparison; outstanding question in https://github.com/ably/specification/pull/343/files#r2192784482

            // RTLM16d
            mergeInitialValue(
                from: operation,
                objectsPool: &objectsPool,
                logger: logger,
            )
        }
    }

    // MARK: - Helper Methods

    /// Converts an ObjectsMapEntry to LiveMapValue using the same logic as get(key:)
    /// This is used by entries to ensure consistent value conversion
    private func convertEntryToLiveMapValue(_ entry: ObjectsMapEntry, delegate: LiveMapObjectPoolDelegate) -> InternalLiveMapValue? {
        // RTLM5d2a: If ObjectsMapEntry.tombstone is true, return undefined/null
        // This is also equivalent to the RTLM14 check
        if entry.tombstone == true {
            return nil
        }

        // Handle primitive values in the order specified by RTLM5d2b through RTLM5d2e

        // RTLM5d2b: If ObjectsMapEntry.data.boolean exists, return it
        if let boolean = entry.data.boolean {
            return .primitive(.bool(boolean))
        }

        // RTLM5d2c: If ObjectsMapEntry.data.bytes exists, return it
        if let bytes = entry.data.bytes {
            return .primitive(.data(bytes))
        }

        // RTLM5d2d: If ObjectsMapEntry.data.number exists, return it
        if let number = entry.data.number {
            return .primitive(.number(number.doubleValue))
        }

        // RTLM5d2e: If ObjectsMapEntry.data.string exists, return it
        if let string = entry.data.string {
            switch string {
            case let .string(string):
                return .primitive(.string(string))
            case .json:
                // TODO: Understand how to handle JSON values (https://github.com/ably/specification/pull/333/files#r2164561055)
                notYetImplemented()
            }
        }

        // RTLM5d2f: If ObjectsMapEntry.data.objectId exists, get the object stored at that objectId from the internal ObjectsPool
        if let objectId = entry.data.objectId {
            // RTLM5d2f1: If an object with id objectId does not exist, return undefined/null
            guard let poolEntry = delegate.getObjectFromPool(id: objectId) else {
                return nil
            }

            // RTLM5d2f2: If an object with id objectId exists, return it
            switch poolEntry {
            case let .map(map):
                return .liveMap(map)
            case let .counter(counter):
                return .liveCounter(counter)
            }
        }

        // RTLM5d2g: Otherwise, return undefined/null
        return nil
    }
}
