@testable import AblyLiveObjects
import AblyPlugin
import Testing

struct ObjectsPoolTests {
    /// Tests for the `createZeroValueObject` method, covering RTO6 specification points
    struct CreateZeroValueObjectTests {
        // @spec RTO6a
        @Test
        func returnsExistingObject() throws {
            let logger = TestLogger()
            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger)
            var pool = ObjectsPool(logger: logger, testsOnly_otherEntries: ["map:123@456": .map(existingMap)])

            let result = pool.createZeroValueObject(forObjectID: "map:123@456", logger: logger)
            let map = try #require(result?.mapValue)
            #expect(map as AnyObject === existingMap as AnyObject)
        }

        // @spec RTO6b2
        @Test
        func createsZeroValueMap() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger)

            let result = pool.createZeroValueObject(forObjectID: "map:123@456", logger: logger)
            let map = try #require(result?.mapValue)

            // Verify it was added to the pool
            #expect(pool.entries["map:123@456"]?.mapValue != nil)

            // Verify the objectID is correctly set
            #expect(map.testsOnly_objectID == "map:123@456")
        }

        // @spec RTO6b3
        @Test
        func createsZeroValueCounter() throws {
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            var pool = ObjectsPool(logger: logger)

            let result = pool.createZeroValueObject(forObjectID: "counter:123@456", logger: logger)
            let counter = try #require(result?.counterValue)
            #expect(try counter.value(coreSDK: coreSDK) == 0)

            // Verify it was added to the pool
            #expect(pool.entries["counter:123@456"]?.counterValue != nil)
            // Verify the objectID is correctly set
            #expect(counter.testsOnly_objectID == "counter:123@456")
        }

        // Sense check to see how it behaves when given an object ID not in the format of RTO6b1 (spec isn't prescriptive here)
        @Test
        func returnsNilForInvalidObjectId() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger)

            let result = pool.createZeroValueObject(forObjectID: "invalid", logger: logger)
            #expect(result == nil)
        }

        // Sense check to see how it behaves when given an object ID not covered by RTO6b2 or RTO6b3
        @Test
        func returnsNilForUnknownType() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger)

            let result = pool.createZeroValueObject(forObjectID: "unknown:123@456", logger: logger)
            #expect(result == nil)
            #expect(pool.entries["unknown:123@456"] == nil)
        }
    }

    /// Tests for the `applySyncObjectsPool` method, covering RTO5c1 and RTO5c2 specification points
    struct ApplySyncObjectsPoolTests {
        // MARK: - RTO5c1 Tests

        // @specOneOf(1/2) RTO5c1a1 - Override the internal data for existing map objects
        @Test
        func updatesExistingMapObject() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger)
            var pool = ObjectsPool(logger: logger, testsOnly_otherEntries: ["map:hash@123": .map(existingMap)])

            let (key, entry) = TestFactories.stringMapEntry(key: "key1", value: "updated_value")
            let objectState = TestFactories.mapObjectState(
                objectId: "map:hash@123",
                siteTimeserials: ["site1": "ts1"],
                entries: [key: entry],
            )

            pool.applySyncObjectsPool([objectState], logger: logger)

            // Verify the existing map was updated by checking side effects of InternalDefaultLiveMap.replaceData(using:)
            let updatedMap = try #require(pool.entries["map:hash@123"]?.mapValue)
            #expect(updatedMap === existingMap)
            // Checking map data to verify replaceData was called successfully
            #expect(try updatedMap.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "updated_value")
            // Checking site timeserials to verify they were updated by replaceData
            #expect(updatedMap.testsOnly_siteTimeserials == ["site1": "ts1"])
        }

        // @specOneOf(2/2) RTO5c1a1 - Override the internal data for existing counter objects
        @Test
        func updatesExistingCounterObject() throws {
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let existingCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger)
            var pool = ObjectsPool(logger: logger, testsOnly_otherEntries: ["counter:hash@123": .counter(existingCounter)])

            let objectState = TestFactories.counterObjectState(
                objectId: "counter:hash@123",
                siteTimeserials: ["site1": "ts1"],
                count: 42,
            )

            pool.applySyncObjectsPool([objectState], logger: logger)

            // Verify the existing counter was updated by checking side effects of InternalDefaultLiveCounter.replaceData(using:)
            let updatedCounter = try #require(pool.entries["counter:hash@123"]?.counterValue)
            #expect(updatedCounter === existingCounter)
            // Checking counter value to verify replaceData was called successfully
            #expect(try updatedCounter.value(coreSDK: coreSDK) == 42)
            // Checking site timeserials to verify they were updated by replaceData
            #expect(updatedCounter.testsOnly_siteTimeserials == ["site1": "ts1"])
        }

        // @spec RTO5c1b1a
        @Test
        func createsNewCounterObject() throws {
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            var pool = ObjectsPool(logger: logger)

            let objectState = TestFactories.counterObjectState(
                objectId: "counter:hash@456",
                siteTimeserials: ["site2": "ts2"],
                count: 100,
            )

            pool.applySyncObjectsPool([objectState], logger: logger)

            // Verify a new counter was created and data was set by checking side effects of InternalDefaultLiveCounter.replaceData(using:)
            let newCounter = try #require(pool.entries["counter:hash@456"]?.counterValue)
            // Checking counter value to verify the new counter was created and replaceData was called
            #expect(try newCounter.value(coreSDK: coreSDK) == 100)
            // Checking site timeserials to verify they were set by replaceData
            #expect(newCounter.testsOnly_siteTimeserials == ["site2": "ts2"])
            // Verify the objectID is correctly set per RTO5c1b1a
            #expect(newCounter.testsOnly_objectID == "counter:hash@456")
        }

        // @spec RTO5c1b1b
        @Test
        func createsNewMapObject() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)

            var pool = ObjectsPool(logger: logger)

            let (key, entry) = TestFactories.stringMapEntry(key: "key2", value: "new_value")
            let objectState = TestFactories.mapObjectState(
                objectId: "map:hash@789",
                siteTimeserials: ["site3": "ts3"],
                entries: [key: entry],
            )

            pool.applySyncObjectsPool([objectState], logger: logger)

            // Verify a new map was created and data was set by checking side effects of InternalDefaultLiveMap.replaceData(using:)
            let newMap = try #require(pool.entries["map:hash@789"]?.mapValue)
            // Checking map data to verify the new map was created and replaceData was called
            #expect(try newMap.get(key: "key2", coreSDK: coreSDK, delegate: delegate)?.stringValue == "new_value")
            // Checking site timeserials to verify they were set by replaceData
            #expect(newMap.testsOnly_siteTimeserials == ["site3": "ts3"])
            // Verify the objectID and semantics are correctly set per RTO5c1b1b
            #expect(newMap.testsOnly_objectID == "map:hash@789")
            #expect(newMap.testsOnly_semantics == .known(.lww))
        }

        // @spec RTO5c1b1c
        @Test
        func ignoresNonMapOrCounterObject() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger)

            let validObjectState = TestFactories.counterObjectState(
                objectId: "counter:hash@456",
                siteTimeserials: ["site2": "ts2"],
                count: 100,
            )

            let invalidObjectState = TestFactories.objectState(objectId: "invalid")

            pool.applySyncObjectsPool([invalidObjectState, validObjectState], logger: logger)

            // Check that there's no entry for the key that we don't know how to handle, and that it didn't interfere with the insertion of the we one that we do know how to handle
            #expect(Set(pool.entries.keys) == ["root", "counter:hash@456"])
        }

        // MARK: - RTO5c2 Tests

        // @spec(RTO5c2) Remove objects not received during sync
        @Test
        func removesObjectsNotInSync() throws {
            let logger = TestLogger()
            let existingMap1 = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger)
            let existingMap2 = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger)
            let existingCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger)

            var pool = ObjectsPool(logger: logger, testsOnly_otherEntries: [
                "map:hash@1": .map(existingMap1),
                "map:hash@2": .map(existingMap2),
                "counter:hash@1": .counter(existingCounter),
            ])

            // Only sync one of the existing objects
            let objectState = TestFactories.mapObjectState(objectId: "map:hash@1")

            pool.applySyncObjectsPool([objectState], logger: logger)

            // Verify only synced object and root remain
            #expect(pool.entries.count == 2) // root + map:hash@1
            #expect(pool.entries["root"] != nil)
            #expect(pool.entries["map:hash@1"] != nil)
            #expect(pool.entries["map:hash@2"] == nil) // Should be removed
            #expect(pool.entries["counter:hash@1"] == nil) // Should be removed
        }

        // @spec(RTO5c2a) Root object must not be removed
        @Test
        func doesNotRemoveRootObject() throws {
            let logger = TestLogger()
            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger)
            var pool = ObjectsPool(logger: logger, testsOnly_otherEntries: ["map:hash@1": .map(existingMap)])

            // Sync with empty list (no objects)
            pool.applySyncObjectsPool([], logger: logger)

            // Verify root is preserved but other objects are removed
            #expect(pool.entries.count == 1) // Only root
            #expect(pool.entries["root"] != nil)
            #expect(pool.entries["map:hash@1"] == nil) // Should be removed
        }

        // @spec(RTO5c1, RTO5c2) Complete sync scenario with mixed operations
        @Test
        func handlesComplexSyncScenario() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)

            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger)
            let existingCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger)
            let toBeRemovedMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger)

            var pool = ObjectsPool(logger: logger, testsOnly_otherEntries: [
                "map:existing@1": .map(existingMap),
                "counter:existing@1": .counter(existingCounter),
                "map:toremove@1": .map(toBeRemovedMap),
            ])

            let syncObjects = [
                // Update existing map
                TestFactories.mapObjectState(
                    objectId: "map:existing@1",
                    siteTimeserials: ["site1": "ts1"],
                    entries: ["updated": TestFactories.mapEntry(data: ObjectData(string: .string("updated")))],
                ),
                // Update existing counter
                TestFactories.counterObjectState(
                    objectId: "counter:existing@1",
                    siteTimeserials: ["site2": "ts2"],
                    count: 100,
                ),
                // Create new map
                TestFactories.mapObjectState(
                    objectId: "map:new@1",
                    siteTimeserials: ["site3": "ts3"],
                    entries: ["new": TestFactories.mapEntry(data: ObjectData(string: .string("new")))],
                ),
                // Create new counter
                TestFactories.counterObjectState(
                    objectId: "counter:new@1",
                    siteTimeserials: ["site4": "ts4"],
                    count: 50,
                ),
                // Note: "map:toremove@1" is not in sync, so it should be removed
            ]

            pool.applySyncObjectsPool(syncObjects, logger: logger)

            // Verify final state
            #expect(pool.entries.count == 5) // root + 4 synced objects

            // Root should remain
            #expect(pool.entries["root"] != nil)

            // Updated existing objects - verify by checking side effects of replaceData calls
            let updatedMap = try #require(pool.entries["map:existing@1"]?.mapValue)
            // Checking map data to verify replaceData was called successfully
            #expect(try updatedMap.get(key: "updated", coreSDK: coreSDK, delegate: delegate)?.stringValue == "updated")

            let updatedCounter = try #require(pool.entries["counter:existing@1"]?.counterValue)
            // Checking counter value to verify replaceData was called successfully
            #expect(try updatedCounter.value(coreSDK: coreSDK) == 100)

            // New objects - verify by checking side effects of replaceData calls
            let newMap = try #require(pool.entries["map:new@1"]?.mapValue)
            // Checking map data to verify the new map was created and replaceData was called
            #expect(try newMap.get(key: "new", coreSDK: coreSDK, delegate: delegate)?.stringValue == "new")
            // Verify the objectID and semantics are correctly set per RTO5c1b1b
            #expect(newMap.testsOnly_objectID == "map:new@1")
            #expect(newMap.testsOnly_semantics == .known(.lww))

            let newCounter = try #require(pool.entries["counter:new@1"]?.counterValue)
            // Checking counter value to verify the new counter was created and replaceData was called
            #expect(try newCounter.value(coreSDK: coreSDK) == 50)
            // Verify the objectID is correctly set per RTO5c1b1a
            #expect(newCounter.testsOnly_objectID == "counter:new@1")

            // Removed object
            #expect(pool.entries["map:toremove@1"] == nil)
        }
    }
}
