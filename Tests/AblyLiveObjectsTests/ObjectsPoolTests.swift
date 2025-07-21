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
            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock(), testsOnly_otherEntries: ["map:123@456": .map(existingMap)])

            let result = pool.createZeroValueObject(forObjectID: "map:123@456", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let map = try #require(result?.mapValue)
            #expect(map as AnyObject === existingMap as AnyObject)
        }

        // @spec RTO6b2
        @Test
        func createsZeroValueMap() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let result = pool.createZeroValueObject(forObjectID: "map:123@456", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let map = try #require(result?.mapValue)

            // Verify it was added to the pool
            #expect(pool.entries["map:123@456"]?.mapValue != nil)

            // Verify the objectID is correctly set
            #expect(map.objectID == "map:123@456")
        }

        // @spec RTO6b3
        @Test
        func createsZeroValueCounter() throws {
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let result = pool.createZeroValueObject(forObjectID: "counter:123@456", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let counter = try #require(result?.counterValue)
            #expect(try counter.value(coreSDK: coreSDK) == 0)

            // Verify it was added to the pool
            #expect(pool.entries["counter:123@456"]?.counterValue != nil)
            // Verify the objectID is correctly set
            #expect(counter.objectID == "counter:123@456")
        }

        // Sense check to see how it behaves when given an object ID not in the format of RTO6b1 (spec isn't prescriptive here)
        @Test
        func returnsNilForInvalidObjectId() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let result = pool.createZeroValueObject(forObjectID: "invalid", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            #expect(result == nil)
        }

        // Sense check to see how it behaves when given an object ID not covered by RTO6b2 or RTO6b3
        @Test
        func returnsNilForUnknownType() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let result = pool.createZeroValueObject(forObjectID: "unknown:123@456", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            #expect(result == nil)
            #expect(pool.entries["unknown:123@456"] == nil)
        }
    }

    /// Tests for the `applySyncObjectsPool` method, covering RTO5c1 and RTO5c2 specification points
    struct ApplySyncObjectsPoolTests {
        // MARK: - RTO5c1 Tests

        // @specOneOf(1/2) RTO5c1a1 - Override the internal data for existing map objects
        // @specOneOf(1/2) RTO5c1a2 - Check we store the update for existing map objects
        // @specOneOf(1/2) RTO5c7 - Check we emit the update for existing map objects
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func updatesExistingMapObject() async throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let existingMapSubscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
            try existingMap.subscribe(listener: existingMapSubscriber.createListener(), coreSDK: coreSDK)
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock(), testsOnly_otherEntries: ["map:hash@123": .map(existingMap)])

            let (key, entry) = TestFactories.stringMapEntry(key: "key1", value: "updated_value")
            let objectState = TestFactories.mapObjectState(
                objectId: "map:hash@123",
                siteTimeserials: ["site1": "ts1"],
                createOp: TestFactories.mapCreateOperation(objectId: "map:hash@123", entries: [
                    "createOpKey": TestFactories.stringMapEntry(value: "bar").entry,
                ]),
                entries: [key: entry],
            )

            pool.applySyncObjectsPool([.init(state: objectState)], logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Verify the existing map was updated by checking side effects of InternalDefaultLiveMap.replaceData(using:)
            let updatedMap = try #require(pool.entries["map:hash@123"]?.mapValue)
            #expect(updatedMap === existingMap)
            // Checking map data to verify replaceData was called successfully
            #expect(try updatedMap.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "updated_value")
            // Checking site timeserials to verify they were updated by replaceData
            #expect(updatedMap.testsOnly_siteTimeserials == ["site1": "ts1"])

            // Check that the update was stored and emitted per RTO5c1a2 and RTO5c7
            let subscriberInvocations = await existingMapSubscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(update: ["createOpKey": .updated])])
        }

        // @specOneOf(2/2) RTO5c1a1 - Override the internal data for existing counter objects
        // @specOneOf(2/2) RTO5c1a2 - Check we store the update for existing counter objects
        // @specOneOf(2/2) RTO5c7 - Check we emit the update for existing counter objects
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func updatesExistingCounterObject() async throws {
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let existingCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let existingCounterSubscriber = Subscriber<DefaultLiveCounterUpdate, SubscribeResponse>(callbackQueue: .main)
            try existingCounter.subscribe(listener: existingCounterSubscriber.createListener(), coreSDK: coreSDK)
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock(), testsOnly_otherEntries: ["counter:hash@123": .counter(existingCounter)])

            let objectState = TestFactories.counterObjectState(
                objectId: "counter:hash@123",
                siteTimeserials: ["site1": "ts1"],
                createOp: TestFactories.counterCreateOperation(objectId: "counter:hash@123", count: 5),
                count: 10,
            )

            pool.applySyncObjectsPool([.init(state: objectState)], logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Verify the existing counter was updated by checking side effects of InternalDefaultLiveCounter.replaceData(using:)
            let updatedCounter = try #require(pool.entries["counter:hash@123"]?.counterValue)
            #expect(updatedCounter === existingCounter)
            // Checking counter value to verify replaceData was called successfully
            #expect(try updatedCounter.value(coreSDK: coreSDK) == 15) // 10 (state) + 5 (createOp)
            // Checking site timeserials to verify they were updated by replaceData
            #expect(updatedCounter.testsOnly_siteTimeserials == ["site1": "ts1"])

            // Check that the update was stored and emitted per RTO5c1a2 and RTO5c7
            let subscriberInvocations = await existingCounterSubscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(amount: 5)]) // From createOp
        }

        // @spec RTO5c1b1a
        @Test
        func createsNewCounterObject() throws {
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let objectState = TestFactories.counterObjectState(
                objectId: "counter:hash@456",
                siteTimeserials: ["site2": "ts2"],
                count: 100,
            )

            pool.applySyncObjectsPool([.init(state: objectState)], logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Verify a new counter was created and data was set by checking side effects of InternalDefaultLiveCounter.replaceData(using:)
            let newCounter = try #require(pool.entries["counter:hash@456"]?.counterValue)
            // Checking counter value to verify the new counter was created and replaceData was called
            #expect(try newCounter.value(coreSDK: coreSDK) == 100)
            // Checking site timeserials to verify they were set by replaceData
            #expect(newCounter.testsOnly_siteTimeserials == ["site2": "ts2"])
            // Verify the objectID is correctly set per RTO5c1b1a
            #expect(newCounter.objectID == "counter:hash@456")
        }

        // @spec RTO5c1b1b
        @Test
        func createsNewMapObject() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)

            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let (key, entry) = TestFactories.stringMapEntry(key: "key2", value: "new_value")
            let objectState = TestFactories.mapObjectState(
                objectId: "map:hash@789",
                siteTimeserials: ["site3": "ts3"],
                entries: [key: entry],
            )

            pool.applySyncObjectsPool([.init(state: objectState)], logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Verify a new map was created and data was set by checking side effects of InternalDefaultLiveMap.replaceData(using:)
            let newMap = try #require(pool.entries["map:hash@789"]?.mapValue)
            // Checking map data to verify the new map was created and replaceData was called
            #expect(try newMap.get(key: "key2", coreSDK: coreSDK, delegate: delegate)?.stringValue == "new_value")
            // Checking site timeserials to verify they were set by replaceData
            #expect(newMap.testsOnly_siteTimeserials == ["site3": "ts3"])
            // Verify the objectID and semantics are correctly set per RTO5c1b1b
            #expect(newMap.objectID == "map:hash@789")
            #expect(newMap.testsOnly_semantics == .known(.lww))
        }

        // @spec RTO5c1b1c
        @Test
        func ignoresNonMapOrCounterObject() throws {
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let validObjectState = TestFactories.counterObjectState(
                objectId: "counter:hash@456",
                siteTimeserials: ["site2": "ts2"],
                count: 100,
            )

            let invalidObjectState = TestFactories.objectState(objectId: "invalid")

            pool.applySyncObjectsPool([invalidObjectState, validObjectState].map { .init(state: $0) }, logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Check that there's no entry for the key that we don't know how to handle, and that it didn't interfere with the insertion of the we one that we do know how to handle
            #expect(Set(pool.entries.keys) == ["root", "counter:hash@456"])
        }

        // MARK: - RTO5c2 Tests

        // @spec RTO5c2
        @Test
        func removesObjectsNotInSync() throws {
            let logger = TestLogger()
            let existingMap1 = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let existingMap2 = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let existingCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock(), testsOnly_otherEntries: [
                "map:hash@1": .map(existingMap1),
                "map:hash@2": .map(existingMap2),
                "counter:hash@1": .counter(existingCounter),
            ])

            // Only sync one of the existing objects
            let objectState = TestFactories.mapObjectState(objectId: "map:hash@1")

            pool.applySyncObjectsPool([.init(state: objectState)], logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Verify only synced object and root remain
            #expect(pool.entries.count == 2) // root + map:hash@1
            #expect(pool.entries["root"] != nil)
            #expect(pool.entries["map:hash@1"] != nil)
            #expect(pool.entries["map:hash@2"] == nil) // Should be removed
            #expect(pool.entries["counter:hash@1"] == nil) // Should be removed
        }

        // @spec RTO5c2a
        @Test
        func doesNotRemoveRootObject() throws {
            let logger = TestLogger()
            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock(), testsOnly_otherEntries: ["map:hash@1": .map(existingMap)])

            // Sync with empty list (no objects)
            pool.applySyncObjectsPool([], logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Verify root is preserved but other objects are removed
            #expect(pool.entries.count == 1) // Only root
            #expect(pool.entries["root"] != nil)
            #expect(pool.entries["map:hash@1"] == nil) // Should be removed
        }

        // A more complete example of the behaviours described in RTO5c1, RTO5c2, and RTO5c7.
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func handlesComplexSyncScenario() async throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)

            let existingMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let existingCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let toBeRemovedMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let existingMapSubscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
            try existingMap.subscribe(listener: existingMapSubscriber.createListener(), coreSDK: coreSDK)
            let existingCounterSubscriber = Subscriber<DefaultLiveCounterUpdate, SubscribeResponse>(callbackQueue: .main)
            try existingCounter.subscribe(listener: existingCounterSubscriber.createListener(), coreSDK: coreSDK)

            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock(), testsOnly_otherEntries: [
                "map:existing@1": .map(existingMap),
                "counter:existing@1": .counter(existingCounter),
                "map:toremove@1": .map(toBeRemovedMap),
            ])

            let syncObjects = [
                // Update existing map
                TestFactories.mapObjectState(
                    objectId: "map:existing@1",
                    siteTimeserials: ["site1": "ts1"],
                    createOp: TestFactories.mapCreateOperation(objectId: "map:existing@1", entries: [
                        "createOpKey": TestFactories.stringMapEntry(value: "bar").entry,
                    ]),
                    entries: ["updated": TestFactories.mapEntry(data: ObjectData(string: .string("updated")))],
                ),
                // Update existing counter
                TestFactories.counterObjectState(
                    objectId: "counter:existing@1",
                    siteTimeserials: ["site2": "ts2"],
                    createOp: TestFactories.counterCreateOperation(objectId: "counter:existing@1", count: 5),
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

            pool.applySyncObjectsPool(syncObjects.map { .init(state: $0) }, logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Verify final state
            #expect(pool.entries.count == 5) // root + 4 synced objects

            // Root should remain
            #expect(pool.entries["root"] != nil)

            // Updated existing objects - verify by checking side effects of replaceData calls
            let updatedMap = try #require(pool.entries["map:existing@1"]?.mapValue)
            // Checking map data to verify replaceData was called successfully
            #expect(try updatedMap.get(key: "updated", coreSDK: coreSDK, delegate: delegate)?.stringValue == "updated")

            // Check update emitted by existing map per RTO5c7
            let existingMapSubscriberInvocations = await existingMapSubscriber.getInvocations()
            #expect(existingMapSubscriberInvocations.map(\.0) == [.init(update: ["createOpKey": .updated])])

            let updatedCounter = try #require(pool.entries["counter:existing@1"]?.counterValue)
            // Checking counter value to verify replaceData was called successfully
            #expect(try updatedCounter.value(coreSDK: coreSDK) == 105)

            // Check update emitted by existing counter per RTO5c7
            let existingCounterInvocations = await existingCounterSubscriber.getInvocations()
            #expect(existingCounterInvocations.map(\.0) == [.init(amount: 5)])

            // New objects - verify by checking side effects of replaceData calls
            let newMap = try #require(pool.entries["map:new@1"]?.mapValue)
            // Checking map data to verify the new map was created and replaceData was called
            #expect(try newMap.get(key: "new", coreSDK: coreSDK, delegate: delegate)?.stringValue == "new")
            // Verify the objectID and semantics are correctly set per RTO5c1b1b
            #expect(newMap.objectID == "map:new@1")
            #expect(newMap.testsOnly_semantics == .known(.lww))

            let newCounter = try #require(pool.entries["counter:new@1"]?.counterValue)
            // Checking counter value to verify the new counter was created and replaceData was called
            #expect(try newCounter.value(coreSDK: coreSDK) == 50)
            // Verify the objectID is correctly set per RTO5c1b1a
            #expect(newCounter.objectID == "counter:new@1")

            // Removed object
            #expect(pool.entries["map:toremove@1"] == nil)
        }
    }
}
