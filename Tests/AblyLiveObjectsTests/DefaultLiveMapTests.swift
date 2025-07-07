@testable import AblyLiveObjects
import AblyPlugin
import Foundation
import Testing

struct DefaultLiveMapTests {
    /// Tests for the `get` method, covering RTLM5 specification points
    struct GetTests {
        // @spec RTLM5c
        @Test(arguments: [.detached, .failed] as [ARTRealtimeChannelState])
        func getThrowsIfChannelIsDetachedOrFailed(channelState: ARTRealtimeChannelState) async throws {
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: MockLiveMapObjectPoolDelegate(), coreSDK: MockCoreSDK(channelState: channelState))

            #expect {
                _ = try map.get(key: "test")
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }

                return errorInfo.code == 90001 && errorInfo.statusCode == 400
            }
        }

        // MARK: - RTLM5d Tests

        // @spec RTLM5d1
        @Test
        func returnsNilWhenNoEntryExists() throws {
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: MockLiveMapObjectPoolDelegate(), coreSDK: coreSDK)
            #expect(try map.get(key: "nonexistent") == nil)
        }

        // @spec RTLM5d2a
        @Test
        func returnsNilWhenEntryIsTombstoned() throws {
            let entry = TestFactories.mapEntry(
                tombstone: true,
                data: ObjectData(boolean: true), // Value doesn't matter as it's tombstoned
            )
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: nil, coreSDK: coreSDK)
            #expect(try map.get(key: "key") == nil)
        }

        // @spec RTLM5d2b
        @Test
        func returnsBooleanValue() throws {
            let entry = TestFactories.mapEntry(data: ObjectData(boolean: true))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: nil, coreSDK: coreSDK)
            let result = try map.get(key: "key")
            #expect(result?.boolValue == true)
        }

        // @spec RTLM5d2c
        @Test
        func returnsBytesValue() throws {
            let bytes = Data([0x01, 0x02, 0x03])
            let entry = TestFactories.mapEntry(data: ObjectData(bytes: bytes))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: nil, coreSDK: coreSDK)
            let result = try map.get(key: "key")
            #expect(result?.dataValue == bytes)
        }

        // @spec RTLM5d2d
        @Test
        func returnsNumberValue() throws {
            let entry = TestFactories.mapEntry(data: ObjectData(number: NSNumber(value: 123.456)))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: nil, coreSDK: coreSDK)
            let result = try map.get(key: "key")
            #expect(result?.numberValue == 123.456)
        }

        // @spec RTLM5d2e
        @Test
        func returnsStringValue() throws {
            let entry = TestFactories.mapEntry(data: ObjectData(string: .string("test")))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: nil, coreSDK: coreSDK)
            let result = try map.get(key: "key")
            #expect(result?.stringValue == "test")
        }

        // @spec RTLM5d2f1
        @Test
        func returnsNilWhenReferencedObjectDoesNotExist() throws {
            let entry = TestFactories.mapEntry(data: ObjectData(objectId: "missing"))
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            #expect(try map.get(key: "key") == nil)
        }

        // @specOneOf(1/2) RTLM5d2f2 - Returns referenced map when it exists in pool
        @Test
        func returnsReferencedMap() throws {
            let objectId = "map1"
            let entry = TestFactories.mapEntry(data: ObjectData(objectId: objectId))
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let referencedMap = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            delegate.objects[objectId] = .map(referencedMap)

            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            let result = try map.get(key: "key")
            let returnedMap = result?.liveMapValue
            #expect(returnedMap as AnyObject === referencedMap as AnyObject)
        }

        // @specOneOf(2/2) RTLM5d2f2 - Returns referenced counter when it exists in pool
        @Test
        func returnsReferencedCounter() throws {
            let objectId = "counter1"
            let entry = TestFactories.mapEntry(data: ObjectData(objectId: objectId))
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let referencedCounter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: coreSDK)
            delegate.objects[objectId] = .counter(referencedCounter)
            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            let result = try map.get(key: "key")
            let returnedCounter = result?.liveCounterValue
            #expect(returnedCounter as AnyObject === referencedCounter as AnyObject)
        }

        // @spec RTLM5d2g
        @Test
        func returnsNullOtherwise() throws {
            let entry = TestFactories.mapEntry(data: ObjectData())
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)

            let map = DefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            #expect(try map.get(key: "key") == nil)
        }
    }

    /// Tests for the `replaceData` method, covering RTLM6 specification points
    struct ReplaceDataTests {
        // @spec RTLM6a
        @Test
        func replacesSiteTimeserials() {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            let state = TestFactories.objectState(
                objectId: "arbitrary-id",
                siteTimeserials: ["site1": "ts1", "site2": "ts2"],
            )
            var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)
            map.replaceData(using: state, objectsPool: &pool)
            #expect(map.testsOnly_siteTimeserials == ["site1": "ts1", "site2": "ts2"])
        }

        // @spec RTLM6b
        @Test
        func setsCreateOperationIsMergedToFalseWhenCreateOpAbsent() {
            // Given:
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)
            let map = {
                let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)

                // Test setup: Manipulate map so that its createOperationIsMerged gets set to true (we need to do this since we want to later assert that it gets set to false, but the default is false).
                let state = TestFactories.objectState(
                    createOp: TestFactories.mapCreateOperation(objectId: "arbitrary-id"),
                )
                map.replaceData(using: state, objectsPool: &pool)
                #expect(map.testsOnly_createOperationIsMerged)

                return map
            }()

            // When:
            let state = TestFactories.objectState(objectId: "arbitrary-id", createOp: nil)
            map.replaceData(using: state, objectsPool: &pool)

            // Then:
            #expect(!map.testsOnly_createOperationIsMerged)
        }

        // @specOneOf(1/2) RTLM6c
        @Test
        func setsDataToMapEntries() throws {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            let (key, entry) = TestFactories.stringMapEntry(key: "key1", value: "test")
            let state = TestFactories.mapObjectState(
                objectId: "arbitrary-id",
                entries: [key: entry],
            )
            var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)
            map.replaceData(using: state, objectsPool: &pool)
            let newData = map.testsOnly_data
            #expect(newData.count == 1)
            #expect(Set(newData.keys) == ["key1"])
            #expect(try map.get(key: "key1")?.stringValue == "test")
        }

        // @specOneOf(2/2) RTLM6c - Tests that the map entries get combined with the createOp
        // @spec RTLM6d1a
        @Test
        func appliesMapSetOperationFromCreateOp() throws {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            let state = TestFactories.objectState(
                objectId: "arbitrary-id",
                createOp: TestFactories.mapCreateOperation(
                    objectId: "arbitrary-id",
                    entries: [
                        "keyFromCreateOp": TestFactories.stringMapEntry(key: "keyFromCreateOp", value: "valueFromCreateOp").entry,
                    ],
                ),
                map: ObjectsMap(
                    semantics: .known(.lww),
                    entries: [
                        "keyFromMapEntries": TestFactories.stringMapEntry(key: "keyFromMapEntries", value: "valueFromMapEntries").entry,
                    ],
                ),
            )
            var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)
            map.replaceData(using: state, objectsPool: &pool)
            // Note that we just check for some basic expected side effects of applying MAP_SET; RTLM7 is tested in more detail elsewhere
            // Check that it contains the data from the entries (per RTLM6c) and also the createOp (per RTLM6d1a)
            #expect(try map.get(key: "keyFromMapEntries")?.stringValue == "valueFromMapEntries")
            #expect(try map.get(key: "keyFromCreateOp")?.stringValue == "valueFromCreateOp")
        }

        // @spec RTLM6d1b
        @Test
        func appliesMapRemoveOperationFromCreateOp() throws {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(
                testsOnly_data: ["key1": TestFactories.stringMapEntry().entry],
                objectID: "arbitrary",
                delegate: delegate,
                coreSDK: coreSDK,
            )
            // Confirm that the initial data is there
            #expect(try map.get(key: "key1") != nil)

            let entry = TestFactories.mapEntry(
                tombstone: true,
                data: ObjectData(),
            )
            let state = TestFactories.objectState(
                objectId: "arbitrary-id",
                createOp: TestFactories.mapCreateOperation(
                    objectId: "arbitrary-id",
                    entries: ["key1": entry],
                ),
            )
            var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)
            map.replaceData(using: state, objectsPool: &pool)
            // Note that we just check for some basic expected side effects of applying MAP_REMOVE; RTLM8 is tested in more detail elsewhere
            // Check that MAP_REMOVE removed the initial data
            #expect(try map.get(key: "key1") == nil)
        }

        // @spec RTLM6d2
        @Test
        func setsCreateOperationIsMergedToTrueWhenCreateOpPresent() {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            let state = TestFactories.objectState(
                objectId: "arbitrary-id",
                createOp: TestFactories.mapCreateOperation(objectId: "arbitrary-id"),
            )
            var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)
            map.replaceData(using: state, objectsPool: &pool)
            #expect(map.testsOnly_createOperationIsMerged)
        }
    }

    /// Tests for the `size`, `entries`, `keys`, and `values` properties, covering RTLM10, RTLM11, RTLM12, and RTLM13 specification points
    struct AccessPropertiesTests {
        // MARK: - Error Throwing Tests (RTLM10c, RTLM11c, RTLM12b, RTLM13b)

        // @spec RTLM10c
        // @spec RTLM11c
        // @spec RTLM12b
        // @spec RTLM13b
        @Test(arguments: [.detached, .failed] as [ARTRealtimeChannelState])
        func allPropertiesThrowIfChannelIsDetachedOrFailed(channelState: ARTRealtimeChannelState) async throws {
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: MockLiveMapObjectPoolDelegate(), coreSDK: MockCoreSDK(channelState: channelState))

            // Define actions to test
            let actions: [(String, () throws -> Any)] = [
                ("size", { try map.size }),
                ("entries", { try map.entries }),
                ("keys", { try map.keys }),
                ("values", { try map.values }),
            ]

            // Test each property throws the expected error
            for (propertyName, action) in actions {
                #expect("\(propertyName) should throw") {
                    _ = try action()
                } throws: { error in
                    guard let errorInfo = error as? ARTErrorInfo else {
                        return false
                    }
                    return errorInfo.code == 90001 && errorInfo.statusCode == 400
                }
            }
        }

        // MARK: - Tombstone Filtering Tests (RTLM10d, RTLM11d1, RTLM12b, RTLM13b)

        // @specOneOf(1/2) RTLM10d - Tests the "non-tombstoned" part of spec point
        // @spec RTLM11d1
        // @specOneOf(1/2) RTLM12b - Tests the "non-tombstoned" part of RTLM10d
        // @specOneOf(1/2) RTLM13b - Tests the "non-tombstoned" part of RTLM10d
        // @spec RTLM14
        @Test
        func allPropertiesFilterOutTombstonedEntries() throws {
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(
                testsOnly_data: [
                    // tombstone is nil, so not considered tombstoned
                    "active1": TestFactories.mapEntry(data: ObjectData(string: .string("value1"))),
                    // tombstone is false, so not considered tombstoned[
                    "active2": TestFactories.mapEntry(tombstone: false, data: ObjectData(string: .string("value2"))),
                    "tombstoned": TestFactories.mapEntry(tombstone: true, data: ObjectData(string: .string("tombstoned"))),
                    "tombstoned2": TestFactories.mapEntry(tombstone: true, data: ObjectData(string: .string("tombstoned2"))),
                ],
                objectID: "arbitrary",
                delegate: nil,
                coreSDK: coreSDK,
            )

            // Test size - should only count non-tombstoned entries
            let size = try map.size
            #expect(size == 2)

            // Test entries - should only return non-tombstoned entries
            let entries = try map.entries
            #expect(entries.count == 2)
            #expect(Set(entries.map(\.key)) == ["active1", "active2"])
            #expect(entries.first { $0.key == "active1" }?.value.stringValue == "value1")
            #expect(entries.first { $0.key == "active2" }?.value.stringValue == "value2")

            // Test keys - should only return keys from non-tombstoned entries
            let keys = try map.keys
            #expect(keys.count == 2)
            #expect(Set(keys) == ["active1", "active2"])

            // Test values - should only return values from non-tombstoned entries
            let values = try map.values
            #expect(values.count == 2)
            #expect(Set(values.compactMap(\.stringValue)) == Set(["value1", "value2"]))
        }

        // MARK: - Consistency Tests

        // @specOneOf(2/2) RTLM10d
        // @specOneOf(2/2) RTLM12b
        // @specOneOf(2/2) RTLM13b
        @Test
        func allAccessPropertiesReturnExpectedValuesAndAreConsistentWithEachOther() throws {
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(
                testsOnly_data: [
                    "key1": TestFactories.mapEntry(data: ObjectData(string: .string("value1"))),
                    "key2": TestFactories.mapEntry(data: ObjectData(string: .string("value2"))),
                    "key3": TestFactories.mapEntry(data: ObjectData(string: .string("value3"))),
                ],
                objectID: "arbitrary",
                delegate: nil,
                coreSDK: coreSDK,
            )

            let size = try map.size
            let entries = try map.entries
            let keys = try map.keys
            let values = try map.values

            // All properties should return the same count
            #expect(size == 3)
            #expect(entries.count == 3)
            #expect(keys.count == 3)
            #expect(values.count == 3)

            // Keys should match the keys from entries
            #expect(Set(keys) == Set(entries.map(\.key)))

            // Values should match the values from entries
            #expect(Set(values.compactMap(\.stringValue)) == Set(entries.compactMap(\.value.stringValue)))
        }

        // MARK: - `entries` handling of different value types, per RTLM5d2

        // @spec RTLM11d
        @Test
        func entriesHandlesAllValueTypes() throws {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Create referenced objects for testing
            let referencedMap = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
            let referencedCounter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: coreSDK)
            delegate.objects["map:ref@123"] = .map(referencedMap)
            delegate.objects["counter:ref@456"] = .counter(referencedCounter)

            let map = DefaultLiveMap(
                testsOnly_data: [
                    "boolean": TestFactories.mapEntry(data: ObjectData(boolean: true)), // RTLM5d2b
                    "bytes": TestFactories.mapEntry(data: ObjectData(bytes: Data([0x01, 0x02, 0x03]))), // RTLM5d2c
                    "number": TestFactories.mapEntry(data: ObjectData(number: NSNumber(value: 42))), // RTLM5d2d
                    "string": TestFactories.mapEntry(data: ObjectData(string: .string("hello"))), // RTLM5d2e
                    "mapRef": TestFactories.mapEntry(data: ObjectData(objectId: "map:ref@123")), // RTLM5d2f2
                    "counterRef": TestFactories.mapEntry(data: ObjectData(objectId: "counter:ref@456")), // RTLM5d2f2
                ],
                objectID: "arbitrary",
                delegate: delegate,
                coreSDK: coreSDK,
            )

            let size = try map.size
            let entries = try map.entries
            let keys = try map.keys
            let values = try map.values

            #expect(size == 6)
            #expect(entries.count == 6)
            #expect(keys.count == 6)
            #expect(values.count == 6)

            // Verify the correct values are returned by `entries`
            let booleanEntry = entries.first { $0.key == "boolean" } // RTLM5d2b
            let bytesEntry = entries.first { $0.key == "bytes" } // RTLM5d2c
            let numberEntry = entries.first { $0.key == "number" } // RTLM5d2d
            let stringEntry = entries.first { $0.key == "string" } // RTLM5d2e
            let mapRefEntry = entries.first { $0.key == "mapRef" } // RTLM5d2f2
            let counterRefEntry = entries.first { $0.key == "counterRef" } // RTLM5d2f2

            #expect(booleanEntry?.value.boolValue == true) // RTLM5d2b
            #expect(bytesEntry?.value.dataValue == Data([0x01, 0x02, 0x03])) // RTLM5d2c
            #expect(numberEntry?.value.numberValue == 42) // RTLM5d2d
            #expect(stringEntry?.value.stringValue == "hello") // RTLM5d2e
            #expect(mapRefEntry?.value.liveMapValue as AnyObject === referencedMap as AnyObject) // RTLM5d2f2
            #expect(counterRefEntry?.value.liveCounterValue as AnyObject === referencedCounter as AnyObject) // RTLM5d2f2
        }
    }

    /// Tests for `MAP_SET` operations, covering RTLM7 specification points
    struct MapSetOperationTests {
        // MARK: - RTLM7a Tests (Existing Entry)

        struct ExistingEntryTests {
            // @spec RTLM7a1
            @Test
            func discardsOperationWhenCannotBeApplied() throws {
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = DefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.mapEntry(timeserial: "ts2", data: ObjectData(string: .string("existing")))],
                    objectID: "arbitrary",
                    delegate: delegate,
                    coreSDK: coreSDK,
                )
                var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)

                // Try to apply operation with lower timeserial (ts1 < ts2)
                map.testsOnly_applyMapSetOperation(
                    key: "key1",
                    operationTimeserial: "ts1",
                    operationData: ObjectData(objectId: "new"),
                    objectsPool: &pool,
                )

                // Verify the operation was discarded - existing data unchanged
                #expect(try map.get(key: "key1")?.stringValue == "existing")
                // Verify that RTLM7c1 didn't happen (i.e. that we didn't create a zero-value object in the pool for object ID "new")
                #expect(Set(pool.entries.keys) == ["root"])
            }

            // @spec RTLM7a2
            // @specOneOf(1/2) RTLM7c1
            @Test(arguments: [
                // Case 1: ObjectData refers to a number value (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(number: NSNumber(value: 42)), expectedCreatedObjectID: nil),
                // Case 2: ObjectData refers to an object value but the object ID is an empty string (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(objectId: ""), expectedCreatedObjectID: nil),
                // Case 3: ObjectData refers to an object value (should modify the ObjectPool per RTLM7c and RTLM7c1)
                (operationData: ObjectData(objectId: "map:referenced@123"), expectedCreatedObjectID: "map:referenced@123"),
            ] as [(operationData: ObjectData, expectedCreatedObjectID: String?)])
            func appliesOperationWhenCanBeApplied(operationData: ObjectData, expectedCreatedObjectID: String?) throws {
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = DefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.mapEntry(tombstone: true, timeserial: "ts1", data: ObjectData(string: .string("existing")))],
                    objectID: "arbitrary",
                    delegate: delegate,
                    coreSDK: coreSDK,
                )
                var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)

                map.testsOnly_applyMapSetOperation(
                    key: "key1",
                    operationTimeserial: "ts2",
                    operationData: operationData,
                    objectsPool: &pool,
                )

                // Update the delegate's pool to include any objects created by the MAP_SET operation (so that when we verify RTLM7b1 using map.get it can return a referenced object)
                if let expectedCreatedObjectID {
                    delegate.objects[expectedCreatedObjectID] = pool.entries[expectedCreatedObjectID]
                }

                // Verify the operation was applied
                let result = try map.get(key: "key1")
                if let numberValue = operationData.number {
                    #expect(result?.numberValue == numberValue.doubleValue)
                } else if expectedCreatedObjectID != nil {
                    #expect(result?.liveMapValue != nil)
                }

                // RTLM7a2a: Set ObjectsMapEntry.data to the ObjectData from the operation
                #expect(map.testsOnly_data["key1"]?.data.number == operationData.number)
                #expect(map.testsOnly_data["key1"]?.data.objectId == operationData.objectId)

                // RTLM7a2b: Set ObjectsMapEntry.timeserial to the operation's serial
                #expect(map.testsOnly_data["key1"]?.timeserial == "ts2")

                // RTLM7a2c: Set ObjectsMapEntry.tombstone to false
                #expect(map.testsOnly_data["key1"]?.tombstone == false)

                // RTLM7c/RTLM7c1: Check if zero-value object was created in pool
                if let expectedCreatedObjectID {
                    let createdObject = pool.entries[expectedCreatedObjectID]
                    #expect(createdObject != nil)
                    #expect(createdObject?.mapValue != nil)
                } else {
                    // For number values, no object should be created
                    #expect(Set(pool.entries.keys) == ["root"])
                }
            }
        }

        // MARK: - RTLM7b Tests (No Existing Entry)

        struct NoExistingEntryTests {
            // @spec RTLM7b1
            // @spec RTLM7b2
            // @specOneOf(2/2) RTLM7c1
            @Test(arguments: [
                // Case 1: ObjectData refers to a number value (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(number: NSNumber(value: 42)), expectedCreatedObjectID: nil),
                // Case 2: ObjectData refers to an object value but the object ID is an empty string (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(objectId: ""), expectedCreatedObjectID: nil),
                // Case 3: ObjectData refers to an object value (should modify the ObjectPool per RTLM7c and RTLM7c1)
                (operationData: ObjectData(objectId: "map:referenced@123"), expectedCreatedObjectID: "map:referenced@123"),
            ] as [(operationData: ObjectData, expectedCreatedObjectID: String?)])
            func createsNewEntryWhenNoExistingEntry(operationData: ObjectData, expectedCreatedObjectID: String?) throws {
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)
                var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)

                map.testsOnly_applyMapSetOperation(
                    key: "newKey",
                    operationTimeserial: "ts1",
                    operationData: operationData,
                    objectsPool: &pool,
                )

                // Update the delegate's pool to include any objects created by the MAP_SET operation (so that when we verify RTLM7b1 using map.get it can return a referenced object)
                if let expectedCreatedObjectID {
                    delegate.objects[expectedCreatedObjectID] = pool.entries[expectedCreatedObjectID]
                }

                // Verify new entry was created
                // RTLM7b1
                let result = try map.get(key: "newKey")
                if let numberValue = operationData.number {
                    #expect(result?.numberValue == numberValue.doubleValue)
                } else if expectedCreatedObjectID != nil {
                    #expect(result?.liveMapValue != nil)
                }
                let entry = try #require(map.testsOnly_data["newKey"])
                #expect(entry.timeserial == "ts1")
                // RTLM7b2
                #expect(entry.tombstone == false)

                // RTLM7c/RTLM7c1: Check if zero-value object was created in pool
                if let expectedCreatedObjectID {
                    let createdObject = try #require(pool.entries[expectedCreatedObjectID])
                    #expect(createdObject.mapValue != nil)
                } else {
                    // For number values, no object should be created
                    #expect(Set(pool.entries.keys) == ["root"])
                }
            }
        }

        // MARK: - RTLM7c1 Standalone Test (RTO6a Integration)

        // This is a sense check to convince ourselves that when applying a MAP_SET operation that references an object, then, because of RTO6a, if the referenced object already exists in the pool it is not replaced when RTLM7c1 is applied.
        @Test
        func doesNotReplaceExistingObjectWhenReferencedByMapSet() throws {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)

            // Create an existing object in the pool with some data
            let existingObjectId = "map:existing@123"
            let existingObject = DefaultLiveMap(
                testsOnly_data: [:],
                objectID: "arbitrary",
                delegate: delegate,
                coreSDK: coreSDK,
            )
            var pool = ObjectsPool(
                rootDelegate: delegate,
                rootCoreSDK: coreSDK,
                testsOnly_otherEntries: [existingObjectId: .map(existingObject)],
            )
            // Populate the delegate so that when we "verify the MAP_SET operation was applied correctly" using map.get below it returns the referenced object
            delegate.objects[existingObjectId] = pool.entries[existingObjectId]

            // Apply MAP_SET operation that references the existing object
            map.testsOnly_applyMapSetOperation(
                key: "referenceKey",
                operationTimeserial: "ts1",
                operationData: ObjectData(objectId: existingObjectId),
                objectsPool: &pool,
            )

            // RTO6a: Verify that the existing object was NOT replaced
            let objectAfterMapSetValue = try #require(pool.entries[existingObjectId]?.mapValue)
            #expect(objectAfterMapSetValue as AnyObject === existingObject as AnyObject)

            // Verify the MAP_SET operation was applied correctly (creates reference in the map)
            let referenceValue = try map.get(key: "referenceKey")
            #expect(referenceValue?.liveMapValue != nil)
        }
    }

    /// Tests for `MAP_REMOVE` operations, covering RTLM8 specification points
    struct MapRemoveOperationTests {
        // MARK: - RTLM8a Tests (Existing Entry)

        struct ExistingEntryTests {
            // @spec RTLM8a1
            @Test
            func discardsOperationWhenCannotBeApplied() throws {
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = DefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.mapEntry(timeserial: "ts2", data: ObjectData(string: .string("existing")))],
                    objectID: "arbitrary",
                    delegate: delegate,
                    coreSDK: coreSDK,
                )

                // Try to apply operation with lower timeserial (ts1 < ts2), cannot be applied per RTLM9
                map.testsOnly_applyMapRemoveOperation(key: "key1", operationTimeserial: "ts1")

                // Verify the operation was discarded - existing data unchanged
                #expect(try map.get(key: "key1")?.stringValue == "existing")
            }

            // @spec RTLM8a2a
            // @spec RTLM8a2b
            // @spec RTLM8a2c
            @Test
            func appliesOperationWhenCanBeApplied() throws {
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = DefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.mapEntry(tombstone: false, timeserial: "ts1", data: ObjectData(string: .string("existing")))],
                    objectID: "arbitrary",
                    delegate: delegate,
                    coreSDK: coreSDK,
                )

                // Apply operation with higher timeserial (ts2 > ts1), so can be applied per RTLM9
                map.testsOnly_applyMapRemoveOperation(key: "key1", operationTimeserial: "ts2")

                // Verify the operation was applied
                #expect(try map.get(key: "key1") == nil)

                // RTLM8a2a: Set ObjectsMapEntry.data to undefined/null
                let entry = map.testsOnly_data["key1"]
                #expect(entry?.data.string == nil)
                #expect(entry?.data.number == nil)
                #expect(entry?.data.boolean == nil)
                #expect(entry?.data.bytes == nil)
                #expect(entry?.data.objectId == nil)

                // RTLM8a2b: Set ObjectsMapEntry.timeserial to the operation's serial
                #expect(map.testsOnly_data["key1"]?.timeserial == "ts2")

                // RTLM8a2c: Set ObjectsMapEntry.tombstone to true
                #expect(map.testsOnly_data["key1"]?.tombstone == true)
            }
        }

        // MARK: - RTLM8b Tests (No Existing Entry)

        struct NoExistingEntryTests {
            // @spec RTLM8b1 - Create new entry with ObjectsMapEntry.data set to undefined/null and operation's serial
            @Test
            func createsNewEntryWhenNoExistingEntry() throws {
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)

                map.testsOnly_applyMapRemoveOperation(key: "newKey", operationTimeserial: "ts1")

                // Verify new entry was created
                let entry = map.testsOnly_data["newKey"]
                #expect(entry != nil)
                #expect(entry?.timeserial == "ts1")
                #expect(entry?.data.string == nil)
                #expect(entry?.data.number == nil)
                #expect(entry?.data.boolean == nil)
                #expect(entry?.data.bytes == nil)
                #expect(entry?.data.objectId == nil)
            }

            // @spec RTLM8b2 - Set ObjectsMapEntry.tombstone for new entry to true
            @Test
            func setsNewEntryTombstoneToTrue() throws {
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = DefaultLiveMap.createZeroValued(objectID: "arbitrary", delegate: delegate, coreSDK: coreSDK)

                map.testsOnly_applyMapRemoveOperation(key: "newKey", operationTimeserial: "ts1")

                // Verify tombstone is true for new entry
                #expect(map.testsOnly_data["newKey"]?.tombstone == true)
            }
        }
    }

    /// Tests for map operation applicability, covering RTLM9 specification points
    struct MapOperationApplicabilityTests {
        // @spec RTLM9a
        // @spec RTLM9b
        // @spec RTLM9c
        // @spec RTLM9d
        // @spec RTLM9e
        @Test(arguments: [
            // RTLM9a, RTLM9e: LWW lexicographical comparison - operation can be applied
            // Standard case: ts2 > ts1
            (entrySerial: "ts1", operationSerial: "ts2", shouldApply: true),
            // Simple lexicographical: b > a
            (entrySerial: "a", operationSerial: "b", shouldApply: true),
            // Numeric strings: 2 > 1
            (entrySerial: "1", operationSerial: "2", shouldApply: true),
            // Longer string comparison: ts10 > ts1
            (entrySerial: "ts1", operationSerial: "ts10", shouldApply: true),

            // RTLM9a, RTLM9e: LWW lexicographical comparison - operation cannot be applied
            // Standard case: ts1 < ts2
            (entrySerial: "ts2", operationSerial: "ts1", shouldApply: false),
            // Simple lexicographical: a < b
            (entrySerial: "b", operationSerial: "a", shouldApply: false),
            // Numeric strings: 1 < 2
            (entrySerial: "2", operationSerial: "1", shouldApply: false),
            // Longer string comparison: ts1 < ts10
            (entrySerial: "ts10", operationSerial: "ts1", shouldApply: false),
            // Equal case: ts1 == ts1
            (entrySerial: "ts1", operationSerial: "ts1", shouldApply: false),

            // RTLM9b: Both serials null or empty - operation cannot be applied
            // Both null
            (entrySerial: nil, operationSerial: nil, shouldApply: false),
            // Both empty strings
            (entrySerial: "", operationSerial: "", shouldApply: false),

            // RTLM9c: Only entry serial exists - operation cannot be applied
            // Entry has serial, operation doesn't
            (entrySerial: "ts1", operationSerial: nil, shouldApply: false),
            // Entry has serial, operation empty
            (entrySerial: "ts1", operationSerial: "", shouldApply: false),

            // RTLM9d: Only operation serial exists - operation can be applied
            // Entry no serial, operation has serial
            (entrySerial: nil, operationSerial: "ts1", shouldApply: true),
            // Entry empty, operation has serial
            (entrySerial: "", operationSerial: "ts1", shouldApply: true),
        ] as [(entrySerial: String?, operationSerial: String?, shouldApply: Bool)])
        func mapOperationApplicability(entrySerial: String?, operationSerial: String?, shouldApply: Bool) throws {
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = DefaultLiveMap(
                testsOnly_data: ["key1": TestFactories.mapEntry(timeserial: entrySerial, data: ObjectData(string: .string("existing")))],
                objectID: "arbitrary",
                delegate: delegate,
                coreSDK: coreSDK,
            )
            var pool = ObjectsPool(rootDelegate: delegate, rootCoreSDK: coreSDK)

            map.testsOnly_applyMapSetOperation(
                key: "key1",
                operationTimeserial: operationSerial,
                operationData: ObjectData(string: .string("new")),
                objectsPool: &pool,
            )

            // We check whether the side effects of the MAP_SET operation have occurred or not as our proxy for checking that the appropriate applicability rules were applied.

            if shouldApply {
                // Verify operation was applied
                #expect(try map.get(key: "key1")?.stringValue == "new")
            } else {
                // Verify operation was discarded
                #expect(try map.get(key: "key1")?.stringValue == "existing")
            }
        }
    }
}
