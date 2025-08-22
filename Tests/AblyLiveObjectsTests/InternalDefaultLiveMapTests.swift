import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Foundation
import Testing

struct InternalDefaultLiveMapTests {
    /// Tests for the `get` method, covering RTLM5 specification points
    struct GetTests {
        // @spec RTLM5c
        @Test(arguments: [.detached, .failed] as [_AblyPluginSupportPrivate.RealtimeChannelState])
        func getThrowsIfChannelIsDetachedOrFailed(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            #expect {
                _ = try map.get(key: "test", coreSDK: MockCoreSDK(channelState: channelState), delegate: MockLiveMapObjectPoolDelegate())
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
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            #expect(try map.get(key: "nonexistent", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate()) == nil)
        }

        // @spec RTLM5d2a
        @Test
        func returnsNilWhenEntryIsTombstoned() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(
                tombstonedAt: Date(),
                data: ObjectData(boolean: true), // Value doesn't matter as it's tombstoned
            )
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            #expect(try map.get(key: "key", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate()) == nil)
        }

        // @spec RTLM5d2b
        @Test
        func returnsBooleanValue() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(data: ObjectData(boolean: true))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate())
            #expect(result?.boolValue == true)
        }

        // @spec RTLM5d2c
        @Test
        func returnsBytesValue() throws {
            let logger = TestLogger()
            let bytes = Data([0x01, 0x02, 0x03])
            let entry = TestFactories.internalMapEntry(data: ObjectData(bytes: bytes))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate())
            #expect(result?.dataValue == bytes)
        }

        // @spec RTLM5d2d
        @Test
        func returnsNumberValue() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(data: ObjectData(number: NSNumber(value: 123.456)))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate())
            #expect(result?.numberValue == 123.456)
        }

        // @spec RTLM5d2e
        @Test
        func returnsStringValue() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(data: ObjectData(string: "test"))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate())
            #expect(result?.stringValue == "test")
        }

        // TODO: Needs specification (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/46)
        // Tests when `json` is a JSON array
        @Test
        func returnsJSONArrayValue() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(data: ObjectData(json: .array(["foo"])))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate())
            #expect(result?.jsonArrayValue == ["foo"])
        }

        // TODO: Needs specification (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/46)
        // Tests when `json` is a JSON object
        @Test
        func returnsJSONObjectValue() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(data: ObjectData(json: .object(["foo": "bar"])))
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: MockLiveMapObjectPoolDelegate())
            #expect(result?.jsonObjectValue == ["foo": "bar"])
        }

        // @spec RTLM5d2f1
        @Test
        func returnsNilWhenReferencedObjectDoesNotExist() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(data: ObjectData(objectId: "missing"))
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            #expect(try map.get(key: "key", coreSDK: coreSDK, delegate: delegate) == nil)
        }

        // @specOneOf(1/2) RTLM5d2f2 - Returns referenced map when it exists in pool
        @Test
        func returnsReferencedMap() throws {
            let logger = TestLogger()
            let objectId = "map1"
            let entry = TestFactories.internalMapEntry(data: ObjectData(objectId: objectId))
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let referencedMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            delegate.objects[objectId] = .map(referencedMap)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: delegate)
            let returnedMap = result?.liveMapValue
            #expect(returnedMap as AnyObject === referencedMap as AnyObject)
        }

        // @specOneOf(2/2) RTLM5d2f2 - Returns referenced counter when it exists in pool
        @Test
        func returnsReferencedCounter() throws {
            let logger = TestLogger()
            let objectId = "counter1"
            let entry = TestFactories.internalMapEntry(data: ObjectData(objectId: objectId))
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let referencedCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            delegate.objects[objectId] = .counter(referencedCounter)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let result = try map.get(key: "key", coreSDK: coreSDK, delegate: delegate)
            let returnedCounter = result?.liveCounterValue
            #expect(returnedCounter as AnyObject === referencedCounter as AnyObject)
        }

        // @spec RTLM5d2g
        @Test
        func returnsNullOtherwise() throws {
            let logger = TestLogger()
            let entry = TestFactories.internalMapEntry(data: ObjectData())
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(testsOnly_data: ["key": entry], objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            #expect(try map.get(key: "key", coreSDK: coreSDK, delegate: delegate) == nil)
        }
    }

    /// Tests for the `replaceData` method, covering RTLM6 specification points
    struct ReplaceDataTests {
        // @spec RTLM6a
        @Test
        func replacesSiteTimeserials() {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let state = TestFactories.objectState(
                objectId: "arbitrary-id",
                siteTimeserials: ["site1": "ts1", "site2": "ts2"],
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            _ = map.replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
            #expect(map.testsOnly_siteTimeserials == ["site1": "ts1", "site2": "ts2"])
        }

        // @spec RTLM6b
        @Test
        func setsCreateOperationIsMergedToFalseWhenCreateOpAbsent() {
            // Given:
            let logger = TestLogger()
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let map = {
                let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

                // Test setup: Manipulate map so that its createOperationIsMerged gets set to true (we need to do this since we want to later assert that it gets set to false, but the default is false).
                let state = TestFactories.objectState(
                    createOp: TestFactories.mapCreateOperation(objectId: "arbitrary-id"),
                )
                _ = map.replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
                #expect(map.testsOnly_createOperationIsMerged)

                return map
            }()

            // When:
            let state = TestFactories.objectState(objectId: "arbitrary-id", createOp: nil)
            _ = map.replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)

            // Then:
            #expect(!map.testsOnly_createOperationIsMerged)
        }

        // @specOneOf(1/2) RTLM6c
        @Test
        func setsDataToMapEntries() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let (key, entry) = TestFactories.stringMapEntry(key: "key1", value: "test")
            let state = TestFactories.mapObjectState(
                objectId: "arbitrary-id",
                entries: [key: entry],
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            _ = map.replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
            let newData = map.testsOnly_data
            #expect(newData.count == 1)
            #expect(Set(newData.keys) == ["key1"])
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "test")
        }

        // @specOneOf(2/2) RTLM6c - Tests that the map entries get combined with the createOp
        // @spec RTLM6d
        @Test
        func mergesInitialValueWhenCreateOpPresent() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
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
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            _ = map.replaceData(using: state, objectMessageSerialTimestamp: nil, objectsPool: &pool)
            // Note that we just check for some basic expected side effects of merging the initial value; RTLM17 is tested in more detail elsewhere
            // Check that it contains the data from the entries (per RTLM6c) and also the createOp (per RTLM6d)
            #expect(try map.get(key: "keyFromMapEntries", coreSDK: coreSDK, delegate: delegate)?.stringValue == "valueFromMapEntries")
            #expect(try map.get(key: "keyFromCreateOp", coreSDK: coreSDK, delegate: delegate)?.stringValue == "valueFromCreateOp")
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
        @Test(arguments: [.detached, .failed] as [_AblyPluginSupportPrivate.RealtimeChannelState])
        func allPropertiesThrowIfChannelIsDetachedOrFailed(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: channelState)
            let delegate = MockLiveMapObjectPoolDelegate()

            // Define actions to test
            let actions: [(String, () throws -> Any)] = [
                ("size", { try map.size(coreSDK: coreSDK, delegate: delegate) }),
                ("entries", { try map.entries(coreSDK: coreSDK, delegate: delegate) }),
                ("keys", { try map.keys(coreSDK: coreSDK, delegate: delegate) }),
                ("values", { try map.values(coreSDK: coreSDK, delegate: delegate) }),
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
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let delegate = MockLiveMapObjectPoolDelegate()
            let map = InternalDefaultLiveMap(
                testsOnly_data: [
                    // tombstonedAt is nil, so not considered tombstoned
                    "active1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
                    // tombstonedAt is false, so not considered tombstoned
                    "tombstoned": TestFactories.internalMapEntry(tombstonedAt: Date(), data: ObjectData(string: "tombstoned")),
                    "tombstoned2": TestFactories.internalMapEntry(tombstonedAt: Date(), data: ObjectData(string: "tombstoned2")),
                ],
                objectID: "arbitrary",
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )

            // Test size - should only count non-tombstoned entries
            let size = try map.size(coreSDK: coreSDK, delegate: delegate)
            #expect(size == 1)

            // Test entries - should only return non-tombstoned entries
            let entries = try map.entries(coreSDK: coreSDK, delegate: delegate)
            #expect(entries.count == 1)
            #expect(Set(entries.map(\.key)) == ["active1"])
            #expect(entries.first { $0.key == "active1" }?.value.stringValue == "value1")

            // Test keys - should only return keys from non-tombstoned entries
            let keys = try map.keys(coreSDK: coreSDK, delegate: delegate)
            #expect(keys.count == 1)
            #expect(Set(keys) == ["active1"])

            // Test values - should only return values from non-tombstoned entries
            let values = try map.values(coreSDK: coreSDK, delegate: delegate)
            #expect(values.count == 1)
            #expect(Set(values.compactMap(\.stringValue)) == Set(["value1"]))
        }

        // MARK: - Consistency Tests

        // @specOneOf(2/2) RTLM10d
        // @specOneOf(2/2) RTLM12b
        // @specOneOf(2/2) RTLM13b
        @Test
        func allAccessPropertiesReturnExpectedValuesAndAreConsistentWithEachOther() throws {
            let logger = TestLogger()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let delegate = MockLiveMapObjectPoolDelegate()
            let map = InternalDefaultLiveMap(
                testsOnly_data: [
                    "key1": TestFactories.internalMapEntry(data: ObjectData(string: "value1")),
                    "key2": TestFactories.internalMapEntry(data: ObjectData(string: "value2")),
                    "key3": TestFactories.internalMapEntry(data: ObjectData(string: "value3")),
                ],
                objectID: "arbitrary",
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )

            let size = try map.size(coreSDK: coreSDK, delegate: delegate)
            let entries = try map.entries(coreSDK: coreSDK, delegate: delegate)
            let keys = try map.keys(coreSDK: coreSDK, delegate: delegate)
            let values = try map.values(coreSDK: coreSDK, delegate: delegate)

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
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Create referenced objects for testing
            let referencedMap = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let referencedCounter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            delegate.objects["map:ref@123"] = .map(referencedMap)
            delegate.objects["counter:ref@456"] = .counter(referencedCounter)

            let map = InternalDefaultLiveMap(
                testsOnly_data: [
                    "boolean": TestFactories.internalMapEntry(data: ObjectData(boolean: true)), // RTLM5d2b
                    "bytes": TestFactories.internalMapEntry(data: ObjectData(bytes: Data([0x01, 0x02, 0x03]))), // RTLM5d2c
                    "number": TestFactories.internalMapEntry(data: ObjectData(number: NSNumber(value: 42))), // RTLM5d2d
                    "string": TestFactories.internalMapEntry(data: ObjectData(string: "hello")), // RTLM5d2e
                    "jsonArray": TestFactories.internalMapEntry(data: ObjectData(json: .array(["foo"]))), // TODO: Needs specification (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/46)
                    "jsonObject": TestFactories.internalMapEntry(data: ObjectData(json: .object(["foo": "bar"]))), // TODO: Needs specification (see https://github.com/ably/ably-liveobjects-swift-plugin/issues/46)
                    "mapRef": TestFactories.internalMapEntry(data: ObjectData(objectId: "map:ref@123")), // RTLM5d2f2
                    "counterRef": TestFactories.internalMapEntry(data: ObjectData(objectId: "counter:ref@456")), // RTLM5d2f2
                ],
                objectID: "arbitrary",
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )

            let size = try map.size(coreSDK: coreSDK, delegate: delegate)
            let entries = try map.entries(coreSDK: coreSDK, delegate: delegate)
            let keys = try map.keys(coreSDK: coreSDK, delegate: delegate)
            let values = try map.values(coreSDK: coreSDK, delegate: delegate)

            #expect(size == 8)
            #expect(entries.count == 8)
            #expect(keys.count == 8)
            #expect(values.count == 8)

            // Verify the correct values are returned by `entries`
            let booleanEntry = entries.first { $0.key == "boolean" } // RTLM5d2b
            let bytesEntry = entries.first { $0.key == "bytes" } // RTLM5d2c
            let numberEntry = entries.first { $0.key == "number" } // RTLM5d2d
            let stringEntry = entries.first { $0.key == "string" } // RTLM5d2e
            let jsonArrayEntry = entries.first { $0.key == "jsonArray" } // RTLM5d2e
            let jsonObjectEntry = entries.first { $0.key == "jsonObject" } // RTLM5d2e
            let mapRefEntry = entries.first { $0.key == "mapRef" } // RTLM5d2f2
            let counterRefEntry = entries.first { $0.key == "counterRef" } // RTLM5d2f2

            #expect(booleanEntry?.value.boolValue == true) // RTLM5d2b
            #expect(bytesEntry?.value.dataValue == Data([0x01, 0x02, 0x03])) // RTLM5d2c
            #expect(numberEntry?.value.numberValue == 42) // RTLM5d2d
            #expect(stringEntry?.value.stringValue == "hello") // RTLM5d2e
            #expect(jsonArrayEntry?.value.jsonArrayValue == ["foo"]) // RTLM5d2e
            #expect(jsonObjectEntry?.value.jsonObjectValue == ["foo": "bar"]) // RTLM5d2e
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
                let logger = TestLogger()
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = InternalDefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.internalMapEntry(timeserial: "ts2", data: ObjectData(string: "existing"))],
                    objectID: "arbitrary",
                    logger: logger,
                    userCallbackQueue: .main,
                    clock: MockSimpleClock(),
                )
                var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

                // Try to apply operation with lower timeserial (ts1 < ts2)
                let update = map.testsOnly_applyMapSetOperation(
                    key: "key1",
                    operationTimeserial: "ts1",
                    operationData: ObjectData(objectId: "new"),
                    objectsPool: &pool,
                )

                // Verify the operation was discarded - existing data unchanged
                #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "existing")
                // Verify that RTLM7c1 didn't happen (i.e. that we didn't create a zero-value object in the pool for object ID "new")
                #expect(Set(pool.entries.keys) == ["root"])
                // Verify return value
                #expect(update.isNoop)
            }

            // @spec RTLM7a2
            // @specOneOf(1/2) RTLM7c1
            // @specOneOf(1/2) RTLM7f
            @Test(arguments: [
                // Case 1: ObjectData refers to a number value (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(number: NSNumber(value: 42)), expectedCreatedObjectID: nil),
                // Case 2: ObjectData refers to an object value but the object ID is an empty string (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(objectId: ""), expectedCreatedObjectID: nil),
                // Case 3: ObjectData refers to an object value (should modify the ObjectPool per RTLM7c and RTLM7c1)
                (operationData: ObjectData(objectId: "map:referenced@123"), expectedCreatedObjectID: "map:referenced@123"),
            ] as [(operationData: ObjectData, expectedCreatedObjectID: String?)])
            func appliesOperationWhenCanBeApplied(operationData: ObjectData, expectedCreatedObjectID: String?) throws {
                let logger = TestLogger()
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = InternalDefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.internalMapEntry(tombstonedAt: Date(), timeserial: "ts1", data: ObjectData(string: "existing"))],
                    objectID: "arbitrary",
                    logger: logger,
                    userCallbackQueue: .main,
                    clock: MockSimpleClock(),
                )
                var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

                let update = map.testsOnly_applyMapSetOperation(
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
                let result = try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)
                if let numberValue = operationData.number {
                    #expect(result?.numberValue == numberValue.doubleValue)
                } else if expectedCreatedObjectID != nil {
                    #expect(result?.liveMapValue != nil)
                }

                // RTLM7a2a: Set ObjectsMapEntry.data to the ObjectData from the operation
                #expect(map.testsOnly_data["key1"]?.data?.number == operationData.number)
                #expect(map.testsOnly_data["key1"]?.data?.objectId == operationData.objectId)

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

                // RTLM7f: Check return value
                #expect(try #require(update.update).update == ["key1": .updated])
            }
        }

        // MARK: - RTLM7b Tests (No Existing Entry)

        struct NoExistingEntryTests {
            // @spec RTLM7b1
            // @spec RTLM7b2
            // @specOneOf(2/2) RTLM7c1
            // @specOneOf(2/2) RTLM7f
            @Test(arguments: [
                // Case 1: ObjectData refers to a number value (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(number: NSNumber(value: 42)), expectedCreatedObjectID: nil),
                // Case 2: ObjectData refers to an object value but the object ID is an empty string (shouldn't modify the ObjectPool per RTLM7c)
                (operationData: ObjectData(objectId: ""), expectedCreatedObjectID: nil),
                // Case 3: ObjectData refers to an object value (should modify the ObjectPool per RTLM7c and RTLM7c1)
                (operationData: ObjectData(objectId: "map:referenced@123"), expectedCreatedObjectID: "map:referenced@123"),
            ] as [(operationData: ObjectData, expectedCreatedObjectID: String?)])
            func createsNewEntryWhenNoExistingEntry(operationData: ObjectData, expectedCreatedObjectID: String?) throws {
                let logger = TestLogger()
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
                var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

                let update = map.testsOnly_applyMapSetOperation(
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
                let result = try map.get(key: "newKey", coreSDK: coreSDK, delegate: delegate)
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

                // RTLM7f: Check return value
                #expect(try #require(update.update).update == ["newKey": .updated])
            }
        }

        // MARK: - RTLM7c1 Standalone Test (RTO6a Integration)

        // This is a sense check to convince ourselves that when applying a MAP_SET operation that references an object, then, because of RTO6a, if the referenced object already exists in the pool it is not replaced when RTLM7c1 is applied.
        @Test
        func doesNotReplaceExistingObjectWhenReferencedByMapSet() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Create an existing object in the pool with some data
            let existingObjectId = "map:existing@123"
            let existingObject = InternalDefaultLiveMap(
                testsOnly_data: [:],
                objectID: "arbitrary",
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
            var pool = ObjectsPool(
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
                testsOnly_otherEntries: [existingObjectId: .map(existingObject)],
            )
            // Populate the delegate so that when we "verify the MAP_SET operation was applied correctly" using map.get below it returns the referenced object
            delegate.objects[existingObjectId] = pool.entries[existingObjectId]

            // Apply MAP_SET operation that references the existing object
            _ = map.testsOnly_applyMapSetOperation(
                key: "referenceKey",
                operationTimeserial: "ts1",
                operationData: ObjectData(objectId: existingObjectId),
                objectsPool: &pool,
            )

            // RTO6a: Verify that the existing object was NOT replaced
            let objectAfterMapSetValue = try #require(pool.entries[existingObjectId]?.mapValue)
            #expect(objectAfterMapSetValue as AnyObject === existingObject as AnyObject)

            // Verify the MAP_SET operation was applied correctly (creates reference in the map)
            let referenceValue = try map.get(key: "referenceKey", coreSDK: coreSDK, delegate: delegate)
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
                let logger = TestLogger()
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = InternalDefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.internalMapEntry(timeserial: "ts2", data: ObjectData(string: "existing"))],
                    objectID: "arbitrary",
                    logger: logger,
                    userCallbackQueue: .main,
                    clock: MockSimpleClock(),
                )

                // Try to apply operation with lower timeserial (ts1 < ts2), cannot be applied per RTLM9
                let update = map.testsOnly_applyMapRemoveOperation(key: "key1", operationTimeserial: "ts1", operationSerialTimestamp: nil)

                // Verify the operation was discarded - existing data unchanged
                #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "existing")
                // Verify return value
                #expect(update.isNoop)
            }

            // @spec RTLM8a2a
            // @spec RTLM8a2b
            // @spec RTLM8a2c
            // @specOneOf(1/2) RTLM8e
            @Test
            func appliesOperationWhenCanBeApplied() throws {
                let logger = TestLogger()
                let delegate = MockLiveMapObjectPoolDelegate()
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let map = InternalDefaultLiveMap(
                    testsOnly_data: ["key1": TestFactories.internalMapEntry(tombstonedAt: nil, timeserial: "ts1", data: ObjectData(string: "existing"))],
                    objectID: "arbitrary",
                    logger: logger,
                    userCallbackQueue: .main,
                    clock: MockSimpleClock(),
                )

                // Apply operation with higher timeserial (ts2 > ts1), so can be applied per RTLM9
                let update = map.testsOnly_applyMapRemoveOperation(key: "key1", operationTimeserial: "ts2", operationSerialTimestamp: nil)

                // Verify the operation was applied
                #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate) == nil)

                // RTLM8a2a: Set ObjectsMapEntry.data to undefined/null
                #expect(map.testsOnly_data["key1"]?.data == nil)

                // RTLM8a2b: Set ObjectsMapEntry.timeserial to the operation's serial
                #expect(map.testsOnly_data["key1"]?.timeserial == "ts2")

                // RTLM8a2c: Set ObjectsMapEntry.tombstone to true
                #expect(map.testsOnly_data["key1"]?.tombstone == true)

                // RTLM8e: Check return value
                #expect(try #require(update.update).update == ["key1": .removed])
            }
        }

        // MARK: - RTLM8b Tests (No Existing Entry)

        struct NoExistingEntryTests {
            // @spec RTLM8b1 - Create new entry with ObjectsMapEntry.data set to undefined/null and operation's serial
            // @specOneOf(1/2) RTLM8e
            @Test
            func createsNewEntryWhenNoExistingEntry() throws {
                let logger = TestLogger()
                let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

                let update = map.testsOnly_applyMapRemoveOperation(key: "newKey", operationTimeserial: "ts1", operationSerialTimestamp: nil)

                // Verify new entry was created
                let entry = map.testsOnly_data["newKey"]
                #expect(entry != nil)
                #expect(entry?.timeserial == "ts1")
                #expect(entry?.data == nil)

                // RTLM8e: Check return value
                #expect(try #require(update.update).update == ["newKey": .removed])
            }

            // @spec RTLM8b2 - Set ObjectsMapEntry.tombstone for new entry to true
            @Test
            func setsNewEntryTombstoneToTrue() throws {
                let logger = TestLogger()
                let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

                _ = map.testsOnly_applyMapRemoveOperation(key: "newKey", operationTimeserial: "ts1", operationSerialTimestamp: nil)

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
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(
                testsOnly_data: ["key1": TestFactories.internalMapEntry(timeserial: entrySerial, data: ObjectData(string: "existing"))],
                objectID: "arbitrary",
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            _ = map.testsOnly_applyMapSetOperation(
                key: "key1",
                operationTimeserial: operationSerial,
                operationData: ObjectData(string: "new"),
                objectsPool: &pool,
            )

            // We check whether the side effects of the MAP_SET operation have occurred or not as our proxy for checking that the appropriate applicability rules were applied.

            if shouldApply {
                // Verify operation was applied
                #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "new")
            } else {
                // Verify operation was discarded
                #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "existing")
            }
        }
    }

    /// Tests for the `mergeInitialValue` method, covering RTLM17 specification points
    struct MergeInitialValueTests {
        // @spec RTLM17a1
        @Test
        func appliesMapSetOperationsFromOperation() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply merge operation with MAP_SET entries
            let operation = TestFactories.mapCreateOperation(
                objectId: "arbitrary-id",
                entries: [
                    "keyFromCreateOp": TestFactories.stringMapEntry(key: "keyFromCreateOp", value: "valueFromCreateOp").entry,
                ],
            )
            _ = map.mergeInitialValue(from: operation, objectsPool: &pool)

            // Note that we just check for some basic expected side effects of applying MAP_SET; RTLM7 is tested in more detail elsewhere
            // Check that it contains the data from the operation (per RTLM17a1)
            #expect(try map.get(key: "keyFromCreateOp", coreSDK: coreSDK, delegate: delegate)?.stringValue == "valueFromCreateOp")
        }

        // @spec RTLM17a2
        @Test
        func appliesMapRemoveOperationsFromOperation() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap(
                testsOnly_data: ["key1": TestFactories.internalStringMapEntry().entry],
                objectID: "arbitrary",
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Confirm that the initial data is there
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate) != nil)

            // Apply merge operation with MAP_REMOVE entry
            let entry = TestFactories.mapEntry(
                tombstone: true,
                timeserial: "ts2", // Must be greater than existing entry's timeserial "ts1"
                data: ObjectData(),
            )
            let operation = TestFactories.mapCreateOperation(
                objectId: "arbitrary-id",
                entries: ["key1": entry],
            )
            _ = map.mergeInitialValue(from: operation, objectsPool: &pool)

            // Verify the MAP_REMOVE operation was applied
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate) == nil)
        }

        // @spec RTLM17c
        @Test
        func returnedUpdateMergesOperationUpdates() throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap(
                testsOnly_data: [
                    "keyThatWillBeRemoved": TestFactories.internalStringMapEntry(timeserial: "ts1").entry,
                    "keyThatWillNotBeRemoved": TestFactories.internalStringMapEntry(timeserial: "ts1").entry,
                ],
                objectID: "arbitrary",
                logger: logger,
                userCallbackQueue: .main,
                clock: MockSimpleClock(),
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply merge operation with MAP_CREATE and MAP_REMOVE entries (copied from RTLM17a1 and RTLM17a2 test cases)
            let operation = TestFactories.mapCreateOperation(
                objectId: "arbitrary-id",
                entries: [
                    "keyThatWillBeRemoved": TestFactories.mapEntry(
                        tombstone: true,
                        timeserial: "ts2", // Must be greater than existing entry's timeserial "ts1"
                        data: ObjectData(),
                    ),
                    "keyThatWillNotBeRemoved": TestFactories.mapEntry(
                        tombstone: true,
                        timeserial: "ts0", // Less than existing entry's timeserial "ts1" so MAP_REMOVE will be a no-op (this lets us test that no-ops are excluded from return value per RTLM17c)
                        data: ObjectData(),
                    ),
                    "keyFromCreateOp": TestFactories.stringMapEntry(key: "keyFromCreateOp", value: "valueFromCreateOp").entry,
                ],
            )
            let update = map.mergeInitialValue(from: operation, objectsPool: &pool)

            // Verify merged return value per RTLM17c
            #expect(try #require(update.update).update == ["keyThatWillBeRemoved": .removed, "keyFromCreateOp": .updated])
        }

        // @spec RTLM17b
        @Test
        func setsCreateOperationIsMergedToTrue() {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply merge operation
            let operation = TestFactories.mapCreateOperation(objectId: "arbitrary-id")
            _ = map.mergeInitialValue(from: operation, objectsPool: &pool)

            #expect(map.testsOnly_createOperationIsMerged)
        }
    }

    /// Tests for `MAP_CREATE` operations, covering RTLM16 specification points
    struct MapCreateOperationTests {
        // @spec RTLM16b
        @Test
        func discardsOperationWhenCreateOperationIsMerged() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Set initial data and mark create operation as merged
            _ = map.replaceData(using: TestFactories.mapObjectState(entries: ["key1": TestFactories.stringMapEntry().entry]), objectMessageSerialTimestamp: nil, objectsPool: &pool)
            _ = map.mergeInitialValue(from: TestFactories.mapCreateOperation(entries: ["key2": TestFactories.stringMapEntry(key: "key2", value: "value2").entry]), objectsPool: &pool)
            #expect(map.testsOnly_createOperationIsMerged)

            // Try to apply another MAP_CREATE operation
            let operation = TestFactories.mapCreateOperation(entries: ["key3": TestFactories.stringMapEntry(key: "key3", value: "value3").entry])
            let update = map.testsOnly_applyMapCreateOperation(operation, objectsPool: &pool)

            // Verify the operation was discarded - data unchanged
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "testValue") // Original data
            #expect(try map.get(key: "key2", coreSDK: coreSDK, delegate: delegate)?.stringValue == "value2") // From first merge
            #expect(try map.get(key: "key3", coreSDK: coreSDK, delegate: delegate) == nil) // Not added by second operation

            // Verify the return value
            #expect(update.isNoop)
        }

        // @spec RTLM16d
        // @spec RTLM16f
        @Test
        func mergesInitialValue() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Set initial data but don't mark create operation as merged
            _ = map.replaceData(using: TestFactories.mapObjectState(entries: ["key1": TestFactories.stringMapEntry().entry]), objectMessageSerialTimestamp: nil, objectsPool: &pool)
            #expect(!map.testsOnly_createOperationIsMerged)

            // Apply MAP_CREATE operation
            let operation = TestFactories.mapCreateOperation(entries: ["key2": TestFactories.stringMapEntry(key: "key2", value: "value2").entry])
            let update = map.testsOnly_applyMapCreateOperation(operation, objectsPool: &pool)

            // Verify the operation was applied - initial value merged. (The full logic of RTLM17 is tested elsewhere; we just check for some of its side effects here.)
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "testValue") // Original data
            #expect(try map.get(key: "key2", coreSDK: coreSDK, delegate: delegate)?.stringValue == "value2") // From merge
            #expect(map.testsOnly_createOperationIsMerged)

            // Verify return value per RTLM16f
            #expect(try #require(update.update).update == ["key2": .updated])
        }
    }

    /// Tests for the `apply(_ operation:, …)` method, covering RTLM15 specification points
    struct ApplyOperationTests {
        // @spec RTLM15b - Tests that an operation does not get applied when canApplyOperation returns nil
        @Test
        func discardsOperationWhenCannotBeApplied() throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Set up the map with an existing site timeserial that will cause the operation to be discarded
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let (key1, entry1) = TestFactories.stringMapEntry(key: "key1", value: "existing", timeserial: nil)
            _ = map.replaceData(
                using: TestFactories.mapObjectState(
                    siteTimeserials: ["site1": "ts2"], // Existing serial "ts2"
                    entries: [key1: entry1],
                ),
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            let operation = TestFactories.objectOperation(
                action: .known(.mapSet),
                mapOp: ObjectsMapOp(key: "key1", data: ObjectData(string: "new")),
            )

            // Apply operation with serial "ts1" which is lexicographically less than existing "ts2" and thus will be applied per RTLO4a (this is a non-pathological case of RTOL4a, that spec point being fully tested elsewhere)
            map.apply(
                operation,
                objectMessageSerial: "ts1", // Less than existing "ts2"
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Check that the MAP_SET side-effects didn't happen:
            // Verify the operation was discarded - data unchanged (should still be "existing" from creation)
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "existing")
            // Verify site timeserials unchanged
            #expect(map.testsOnly_siteTimeserials == ["site1": "ts2"])
        }

        // @specOneOf(1/3) RTLM15c - We test this spec point for each possible operation
        // @spec RTLM15d1 - Tests MAP_CREATE operation application
        // @spec RTLM15d1a
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func appliesMapCreateOperation() async throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let subscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
            try map.subscribe(listener: subscriber.createListener(), coreSDK: coreSDK)

            let operation = TestFactories.mapCreateOperation(
                entries: ["key1": TestFactories.stringMapEntry(key: "key1", value: "value1").entry],
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply MAP_CREATE operation
            map.apply(
                operation,
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Verify the operation was applied - initial value merged (the full logic of RTLM16 is tested elsewhere; we just check for some of its side effects here)
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "value1")
            #expect(map.testsOnly_createOperationIsMerged)
            // Verify RTLM15c side-effect: site timeserial was updated
            #expect(map.testsOnly_siteTimeserials == ["site1": "ts1"])

            // Verify update was emitted per RTLM15d1a
            let subscriberInvocations = await subscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(update: ["key1": .updated])])
        }

        // @specOneOf(2/3) RTLM15c - We test this spec point for each possible operation
        // @spec RTLM15d2 - Tests MAP_SET operation application
        // @spec RTLM15d2a
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func appliesMapSetOperation() async throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let subscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
            try map.subscribe(listener: subscriber.createListener(), coreSDK: coreSDK)

            // Set initial data
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let (key1, entry1) = TestFactories.stringMapEntry(key: "key1", value: "existing", timeserial: nil)
            _ = map.replaceData(
                using: TestFactories.mapObjectState(
                    siteTimeserials: [:],
                    entries: [key1: entry1],
                ),
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "existing")

            let operation = TestFactories.objectOperation(
                action: .known(.mapSet),
                mapOp: ObjectsMapOp(key: "key1", data: ObjectData(string: "new")),
            )

            // Apply MAP_SET operation
            map.apply(
                operation,
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Verify the operation was applied - value updated (the full logic of RTLM7 is tested elsewhere; we just check for some of its side effects here)
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "new")
            // Verify RTLM15c side-effect: site timeserial was updated
            #expect(map.testsOnly_siteTimeserials == ["site1": "ts1"])

            // Verify update was emitted per RTLM15d2a
            let subscriberInvocations = await subscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(update: ["key1": .updated])])
        }

        // @specOneOf(3/3) RTLM15c - We test this spec point for each possible operation
        // @spec RTLM15d3 - Tests MAP_REMOVE operation application
        // @spec RTLM15d3a
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func appliesMapRemoveOperation() async throws {
            let logger = TestLogger()
            let delegate = MockLiveMapObjectPoolDelegate()
            let coreSDK = MockCoreSDK(channelState: .attaching)
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            let subscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
            try map.subscribe(listener: subscriber.createListener(), coreSDK: coreSDK)

            // Set initial data
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let (key1, entry1) = TestFactories.stringMapEntry(key: "key1", value: "existing", timeserial: nil)
            _ = map.replaceData(
                using: TestFactories.mapObjectState(
                    siteTimeserials: [:],
                    entries: [key1: entry1],
                ),
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate)?.stringValue == "existing")

            let operation = TestFactories.objectOperation(
                action: .known(.mapRemove),
                mapOp: ObjectsMapOp(key: "key1", data: ObjectData()),
            )

            // Apply MAP_REMOVE operation
            map.apply(
                operation,
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Verify the operation was applied - key removed (the full logic of RTLM8 is tested elsewhere; we just check for some of its side effects here)
            #expect(try map.get(key: "key1", coreSDK: coreSDK, delegate: delegate) == nil)
            // Verify RTLM15c side-effect: site timeserial was updated
            #expect(map.testsOnly_siteTimeserials == ["site1": "ts1"])

            // Verify update was emitted per RTLM15d3a
            let subscriberInvocations = await subscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(update: ["key1": .removed])])
        }

        // @spec RTLM15d4
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func noOpForOtherOperation() async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            let subscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
            try map.subscribe(listener: subscriber.createListener(), coreSDK: coreSDK)

            // Try to apply a COUNTER_CREATE to the map (not supported)
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            map.apply(
                TestFactories.counterCreateOperation(),
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Check no update was emitted
            let subscriberInvocations = await subscriber.getInvocations()
            #expect(subscriberInvocations.isEmpty)
        }
    }

    /// Tests for the `set` method, covering RTLM20 specification points
    struct SetTests {
        // @spec RTLM20c
        @Test(arguments: [.detached, .failed, .suspended] as [_AblyPluginSupportPrivate.RealtimeChannelState])
        func throwsErrorForInvalidChannelState(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: channelState)

            await #expect {
                try await map.set(key: "test", value: .string("value"), coreSDK: coreSDK)
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }

                return errorInfo.code == 90001 && errorInfo.statusCode == 400
            }
        }

        // @spec RTLM20e
        // @specUntested RTLM20e1 - Not needed with Swift's type system
        // @spec RTLM20e2
        // @spec RTLM20e3
        // @spec RTLM20e4
        // @spec RTLM20e5a
        // @spec RTLM20e5b
        // @spec RTLM20e5c
        // @spec RTLM20e5d
        // @spec RTLM20e5e
        // @spec RTLM20e5f
        // @spec RTLM20f
        @Test(arguments: [
            // RTLM20e5a
            (value: .liveMap(.createZeroValued(objectID: "map:test@123", logger: TestLogger(), userCallbackQueue: .main, clock: MockSimpleClock())), expectedData: .init(objectId: "map:test@123")),
            (value: .liveCounter(.createZeroValued(objectID: "map:test@123", logger: TestLogger(), userCallbackQueue: .main, clock: MockSimpleClock())), expectedData: .init(objectId: "map:test@123")),
            // RTLM20e5b
            (value: .jsonArray(["test"]), expectedData: .init(json: .array(["test"]))),
            (value: .jsonObject(["foo": "bar"]), expectedData: .init(json: .object(["foo": "bar"]))),
            // RTLM20e5c
            (value: .string("test"), expectedData: .init(string: "test")),
            // RTLM20e5d
            (value: .number(42.5), expectedData: .init(number: NSNumber(value: 42.5))),
            // RTLM20e5e
            (value: .bool(true), expectedData: .init(boolean: true)),
            // RTLM20e5f
            (value: .data(Data([0x01, 0x02])), expectedData: .init(bytes: Data([0x01, 0x02]))),
        ] as [(value: InternalLiveMapValue, expectedData: ObjectData)])
        func publishesCorrectObjectMessageForDifferentValueTypes(value: InternalLiveMapValue, expectedData: ObjectData) async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "map:test@123", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attached)

            var publishedMessage: OutboundObjectMessage?
            coreSDK.setPublishHandler { messages in
                publishedMessage = messages.first
            }

            try await map.set(key: "testKey", value: value, coreSDK: coreSDK)

            let expectedMessage = OutboundObjectMessage(
                operation: ObjectOperation(
                    // RTLM20e2
                    action: .known(.mapSet),
                    // RTLM20e3
                    objectId: "map:test@123",
                    mapOp: ObjectsMapOp(
                        // RTLM20e4
                        key: "testKey",
                        // RTLM20e5
                        data: expectedData,
                    ),
                ),
            )
            // RTLM20f
            let message = try #require(publishedMessage)
            #expect(message == expectedMessage)
        }

        @Test
        func throwsErrorWhenPublishFails() async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "map:test@123", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attached)

            coreSDK.setPublishHandler { _ throws(InternalError) in
                throw NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Publish failed"]).toInternalError()
            }

            await #expect {
                try await map.set(key: "testKey", value: .string("testValue"), coreSDK: coreSDK)
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }
                return errorInfo.message.contains("Publish failed")
            }
        }
    }

    /// Tests for the `remove` method, covering RTLM21 specification points
    struct RemoveTests {
        // @spec RTLM21c
        @Test(arguments: [.detached, .failed, .suspended] as [_AblyPluginSupportPrivate.RealtimeChannelState])
        func throwsErrorForInvalidChannelState(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: channelState)

            await #expect {
                try await map.remove(key: "test", coreSDK: coreSDK)
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }

                return errorInfo.code == 90001 && errorInfo.statusCode == 400
            }
        }

        // @specUntested RTLM21e
        // @specUntested RTLM21e1 - Not needed with Swift's type system
        // @spec RTLM21e2
        // @spec RTLM21e3
        // @spec RTLM21e4
        // @spec RTLM21f
        func publishesCorrectObjectMessage() async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "map:test@123", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attached)

            var publishedMessages: [OutboundObjectMessage] = []
            coreSDK.setPublishHandler { messages in
                publishedMessages.append(contentsOf: messages)
            }

            try await map.remove(key: "testKey", coreSDK: coreSDK)

            let expectedMessage = OutboundObjectMessage(
                operation: ObjectOperation(
                    // RTLM21e2
                    action: .known(.mapRemove),
                    // RTLM21e3
                    objectId: "map:test@123",
                    mapOp: ObjectsMapOp(
                        // RTLM21e4
                        key: "testKey",
                        data: nil,
                    ),
                ),
            )
            // RTLM21f
            #expect(publishedMessages.count == 1)
            #expect(publishedMessages[0] == expectedMessage)
        }

        @Test
        func throwsErrorWhenPublishFails() async throws {
            let logger = TestLogger()
            let map = InternalDefaultLiveMap.createZeroValued(objectID: "map:test@123", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attached)

            coreSDK.setPublishHandler { _ throws(InternalError) in
                throw NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Publish failed"]).toInternalError()
            }

            await #expect {
                try await map.remove(key: "testKey", coreSDK: coreSDK)
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }
                return errorInfo.message.contains("Publish failed")
            }
        }
    }
}
