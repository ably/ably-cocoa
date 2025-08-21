import _AblyPluginSupportPrivate
import Ably
@testable import AblyLiveObjects
import Testing

/// Tests for `InternalDefaultRealtimeObjects`.
struct InternalDefaultRealtimeObjectsTests {
    // MARK: - Test Helpers

    /// Creates a InternalDefaultRealtimeObjects instance for testing
    static func createDefaultRealtimeObjects(clock: SimpleClock = MockSimpleClock()) -> InternalDefaultRealtimeObjects {
        let logger = TestLogger()
        return InternalDefaultRealtimeObjects(logger: logger, userCallbackQueue: .main, clock: clock)
    }

    /// Tests for `InternalDefaultRealtimeObjects.handleObjectSyncProtocolMessage`, covering RTO5 specification points.
    struct HandleObjectSyncProtocolMessageTests {
        // MARK: - RTO5a5: Single ProtocolMessage Sync Tests

        // @spec RTO5a5
        @Test
        func handlesSingleProtocolMessageSync() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let objectMessages = [
                TestFactories.simpleMapMessage(objectId: "map:1@123"),
                TestFactories.simpleMapMessage(objectId: "map:2@456"),
            ]

            // Verify no sync sequence before handling
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)

            // Call with no channelSerial (RTO5a5 case)
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: objectMessages,
                protocolMessageChannelSerial: nil,
            )

            // Verify sync was applied immediately and sequence was cleared (RTO5c3)
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)

            // Verify objects were added to pool (side effect of applySyncObjectsPool per RTO5c1b1b)
            let pool = realtimeObjects.testsOnly_objectsPool
            #expect(pool.entries["map:1@123"] != nil)
            #expect(pool.entries["map:2@456"] != nil)
        }

        // MARK: - RTO5a1, RTO5a3, RTO5a4: Multi-ProtocolMessage Sync Tests

        // @spec RTO5a1
        // @spec RTO5a3
        // @spec RTO5a4
        // @spec RTO5b
        // @spec RTO5c3
        // @spec RTO5c4
        // @spec RTO5c5
        @Test
        func handlesMultiProtocolMessageSync() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let sequenceId = "seq123"

            // First message in sequence
            let firstMessages = [TestFactories.simpleMapMessage(objectId: "map:1@123")]
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: firstMessages,
                protocolMessageChannelSerial: "\(sequenceId):cursor1",
            )

            // Verify sync sequence is active (RTO5a1, RTO5a3)
            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // Verify objects not yet applied to pool
            let poolAfterFirst = realtimeObjects.testsOnly_objectsPool
            #expect(poolAfterFirst.entries["map:1@123"] == nil)

            // Second message in sequence
            let secondMessages = [TestFactories.simpleMapMessage(objectId: "map:2@456")]
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: secondMessages,
                protocolMessageChannelSerial: "\(sequenceId):cursor2",
            )

            // Verify sync sequence still active
            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // Verify objects still not applied to pool
            let poolAfterSecond = realtimeObjects.testsOnly_objectsPool
            #expect(poolAfterSecond.entries["map:1@123"] == nil)
            #expect(poolAfterSecond.entries["map:2@456"] == nil)

            // Final message in sequence (end of sequence per RTO5a4)
            let finalMessages = [TestFactories.simpleMapMessage(objectId: "map:3@789")]
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: finalMessages,
                protocolMessageChannelSerial: "\(sequenceId):", // Empty cursor indicates end
            )

            // Verify sync sequence is cleared and there is no SyncObjectsPool or BufferedObjectOperations (RTO5c3, RTO5c4, RTO5c5)
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)

            // Verify all objects were applied to pool (side effect of applySyncObjectsPool per RTO5c1b1b)
            let finalPool = realtimeObjects.testsOnly_objectsPool
            #expect(finalPool.entries["map:1@123"] != nil)
            #expect(finalPool.entries["map:2@456"] != nil)
            #expect(finalPool.entries["map:3@789"] != nil)
        }

        // MARK: - RTO5a2: New Sync Sequence Tests

        // @spec RTO5a2
        // @spec RTO5a2a
        // @spec RTO5a2b
        @Test
        func newSequenceIdDiscardsInFlightSync() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let firstSequenceId = "seq1"
            let secondSequenceId = "seq2"

            // Start first sequence
            let firstMessages = [TestFactories.simpleMapMessage(objectId: "map:1@123")]
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: firstMessages,
                protocolMessageChannelSerial: "\(firstSequenceId):cursor1",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // Inject an OBJECT; it will get buffered per RTO8a and subsequently discarded per RTO5a2b
            realtimeObjects.handleObjectProtocolMessage(objectMessages: [
                TestFactories.mapCreateOperationMessage(objectId: "map:3@789"),
            ])

            // Start new sequence with different ID (RTO5a2)
            let secondMessages = [TestFactories.simpleMapMessage(objectId: "map:2@456")]
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: secondMessages,
                protocolMessageChannelSerial: "\(secondSequenceId):cursor1",
            )

            // Verify sync sequence is still active but with new ID
            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // Complete the new sequence
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [],
                protocolMessageChannelSerial: "\(secondSequenceId):",
            )

            // Verify only the second sequence's objects were applied (RTO5a2a - previous cleared)
            let pool = realtimeObjects.testsOnly_objectsPool
            #expect(pool.entries["map:1@123"] == nil) // From discarded first sequence
            #expect(pool.entries["map:3@789"] == nil) // Check we discarded the OBJECT that was buffered during discarded first sequence (RTO5a2b)
            #expect(pool.entries["map:2@456"] != nil) // From completed second sequence
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
        }

        // MARK: - RTO5c: Post-Sync Behavior Tests

        // A smoke test that the RTO5c post-sync behaviours get performed. They are tested in more detail in the ObjectsPool.applySyncObjectsPool tests.
        @Test
        func performsPostSyncSteps() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Perform sync with only one object (RTO5a5 case)
            let syncMessages = [TestFactories.mapObjectMessage(objectId: "map:synced@1")]
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: syncMessages,
                protocolMessageChannelSerial: nil,
            )

            // Verify root is preserved (RTO5c2a) and sync completed (RTO5c3)
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
            let finalPool = realtimeObjects.testsOnly_objectsPool
            #expect(finalPool.entries["root"] != nil) // Root preserved
            #expect(finalPool.entries["map:synced@1"] != nil) // Synced object added
        }

        // MARK: - Error Handling Tests

        /// Test handling of invalid channelSerial format
        @Test
        func handlesInvalidChannelSerialFormat() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let objectMessages = [TestFactories.mapObjectMessage(objectId: "map:1@123")]

            // Call with invalid channelSerial (missing colon)
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: objectMessages,
                protocolMessageChannelSerial: "invalid_format_no_colon",
            )

            // Verify no sync sequence was created due to parsing error
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)

            // Verify objects were not applied to pool
            let pool = realtimeObjects.testsOnly_objectsPool
            #expect(pool.entries["map:1@123"] == nil)
        }

        // MARK: - Edge Cases

        /// Test with empty sequence ID
        @Test
        func handlesEmptySequenceId() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let objectMessages = [TestFactories.mapObjectMessage(objectId: "map:1@123")]

            // Start sequence with empty sequence ID
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: objectMessages,
                protocolMessageChannelSerial: ":cursor1",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // End sequence with empty sequence ID
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [],
                protocolMessageChannelSerial: ":",
            )

            // Verify sequence completed successfully
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
            let pool = realtimeObjects.testsOnly_objectsPool
            #expect(pool.entries["map:1@123"] != nil)
        }

        /// Test mixed object types in single sync
        @Test
        func handlesMixedObjectTypesInSync() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            let mixedMessages = [
                TestFactories.mapObjectMessage(objectId: "map:1@123"),
                TestFactories.counterObjectMessage(objectId: "counter:1@456"),
                TestFactories.mapObjectMessage(objectId: "map:2@789"),
            ]

            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: mixedMessages,
                protocolMessageChannelSerial: nil, // Single message sync
            )

            // Verify all object types were processed
            let pool = realtimeObjects.testsOnly_objectsPool
            #expect(pool.entries["map:1@123"] != nil)
            #expect(pool.entries["counter:1@456"] != nil)
            #expect(pool.entries["map:2@789"] != nil)
            #expect(pool.entries.count == 4) // root + 3 objects
        }

        /// Test continuation of sync after interruption by new sequence
        @Test
        func handlesSequenceInterruptionCorrectly() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Start first sequence
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [TestFactories.mapObjectMessage(objectId: "map:old@1")],
                protocolMessageChannelSerial: "oldSeq:cursor1",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // Interrupt with new sequence
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [TestFactories.mapObjectMessage(objectId: "map:new@1")],
                protocolMessageChannelSerial: "newSeq:cursor1",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // Continue new sequence
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [TestFactories.mapObjectMessage(objectId: "map:new@2")],
                protocolMessageChannelSerial: "newSeq:cursor2",
            )

            // Complete new sequence
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [],
                protocolMessageChannelSerial: "newSeq:",
            )

            // Verify only new sequence objects were applied
            let pool = realtimeObjects.testsOnly_objectsPool
            #expect(pool.entries["map:old@1"] == nil) // From interrupted sequence
            #expect(pool.entries["map:new@1"] != nil) // From completed sequence
            #expect(pool.entries["map:new@2"] != nil) // From completed sequence
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
        }
    }

    /// Tests for `InternalDefaultRealtimeObjects.onChannelAttached`, covering RTO4 specification points.
    ///
    /// Note: These tests use `OBJECT_SYNC` messages to populate the initial state of objects pools
    /// and sync sequences. This approach is more realistic than directly manipulating internal state,
    /// as it simulates how objects actually enter pools during normal operation.
    struct OnChannelAttachedTests {
        // MARK: - RTO4a Tests

        // @spec RTO4a - Checks that when the `HAS_OBJECTS` flag is 1 (i.e. the server will shortly perform an `OBJECT_SYNC` sequence) we don't modify any internal state
        @Test
        func doesNotModifyStateWhenHasObjectsIsTrue() {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Set up initial state with additional objects by using the createZeroValueObject method
            let originalPool = realtimeObjects.testsOnly_objectsPool
            let originalRootObject = originalPool.root
            _ = realtimeObjects.testsOnly_createZeroValueLiveObject(forObjectID: "map:test@123")

            // Set up an in-progress sync sequence
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "map:sync@456"),
                ],
                protocolMessageChannelSerial: "seq1:cursor1",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // When: onChannelAttached is called with hasObjects = true
            realtimeObjects.onChannelAttached(hasObjects: true)

            // Then: Nothing should be modified
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == true)

            // Verify ObjectsPool is unchanged
            let poolAfter = realtimeObjects.testsOnly_objectsPool
            #expect(poolAfter.root as AnyObject === originalRootObject as AnyObject)
            #expect(poolAfter.entries.count == 2) // root + additional map
            #expect(poolAfter.entries["map:test@123"] != nil)

            // Verify sync sequence is still active
            #expect(realtimeObjects.testsOnly_hasSyncSequence)
        }

        // MARK: - RTO4b Tests

        // @spec RTO4b1
        // @spec RTO4b2
        // @spec RTO4b2a
        // @spec RTO4b3
        // @spec RTO4b4
        // @spec RTO4b5
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func handlesHasObjectsFalse() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Set up initial state with additional objects in the pool using sync
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "root", entries: [
                        "existingMap": TestFactories.objectReferenceMapEntry(key: "existingMap", objectId: "map:existing@123").entry,
                        "existingCounter": TestFactories.objectReferenceMapEntry(key: "existingCounter", objectId: "counter:existing@456").entry,
                    ]),
                    TestFactories.mapObjectMessage(objectId: "map:existing@123"),
                    TestFactories.counterObjectMessage(objectId: "counter:existing@456"),
                ],
                protocolMessageChannelSerial: nil, // Complete sync immediately
            )

            let originalPool = realtimeObjects.testsOnly_objectsPool
            #expect(Set(originalPool.root.testsOnly_data.keys) == ["existingMap", "existingCounter"])

            let rootSubscriber = Subscriber<DefaultLiveMapUpdate, SubscribeResponse>(callbackQueue: .main)
            let coreSDK = MockCoreSDK(channelState: .attached)
            try originalPool.root.subscribe(listener: rootSubscriber.createListener(), coreSDK: coreSDK)

            // Set up an in-progress sync sequence
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "map:sync@789"),
                ],
                protocolMessageChannelSerial: "seq1:cursor1",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)
            #expect(originalPool.entries.count == 3) // root + 2 additional objects

            // When: onChannelAttached is called with hasObjects = false
            realtimeObjects.onChannelAttached(hasObjects: false)

            // Then: Verify the expected behavior per RTO4b
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == false)

            // RTO4b1, RTO4b2: All objects except root must be removed, root must be cleared to zero-value
            let newPool = realtimeObjects.testsOnly_objectsPool
            #expect(newPool.entries.count == 1) // Only root should remain
            #expect(newPool.entries["root"] != nil)
            #expect(newPool.entries["map:existing@123"] == nil) // Should be removed
            #expect(newPool.entries["counter:existing@456"] == nil) // Should be removed
            // Verify that `removed` was emitted for root's existing keys per RTO4b2a
            let subscriberInvocations = await rootSubscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(update: ["existingMap": .removed, "existingCounter": .removed])])

            // Verify root is the same object, but with data cleared (RTO4b2)
            // TODO: this one is unclear (are we meant to replace the root or just clear its data?) https://github.com/ably/specification/pull/333/files#r2183493458. I believe that the answer is that we should just clear its data but the spec point needs to be clearer, see https://github.com/ably/specification/pull/346/files#r2201434895.
            let newRoot = newPool.root
            #expect(newRoot as AnyObject === originalPool.root as AnyObject) // Should be same instance
            #expect(newRoot.testsOnly_data.isEmpty) // Should be zero-valued (empty)

            // RTO4b3, RTO4b4, RTO4b5: SyncObjectsPool must be cleared, sync sequence cleared, BufferedObjectOperations cleared
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
        }

        // MARK: - Edge Cases and Integration Tests

        /// Test that multiple calls to onChannelAttached work correctly
        @Test
        func handlesMultipleCallsCorrectly() {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // First call with hasObjects = true (should do nothing)
            realtimeObjects.onChannelAttached(hasObjects: true)
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == true)
            let originalPool = realtimeObjects.testsOnly_objectsPool
            let originalRoot = originalPool.root

            // Second call with hasObjects = false (should reset)
            realtimeObjects.onChannelAttached(hasObjects: false)
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == false)
            let newPool = realtimeObjects.testsOnly_objectsPool
            #expect(newPool.root as AnyObject === originalRoot as AnyObject)
            #expect(newPool.entries.count == 1)

            // Third call with hasObjects = true again (should do nothing)
            realtimeObjects.onChannelAttached(hasObjects: true)
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == true)
            let finalPool = realtimeObjects.testsOnly_objectsPool
            #expect(finalPool.root as AnyObject === originalRoot as AnyObject) // Should be unchanged
        }

        /// Test that sync sequence is properly discarded even with complex sync state
        @Test
        func discardsComplexSyncSequence() {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Create a complex sync sequence using OBJECT_SYNC messages
            // (This simulates realistic multi-message sync scenarios)
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "map:sync1@123"),
                ],
                protocolMessageChannelSerial: "seq1:cursor1",
            )

            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.counterObjectMessage(objectId: "counter:sync1@456"),
                ],
                protocolMessageChannelSerial: "seq1:cursor2",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)

            // When: onChannelAttached is called with hasObjects = false
            realtimeObjects.onChannelAttached(hasObjects: false)

            // Then: All sync data should be discarded
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
            let pool = realtimeObjects.testsOnly_objectsPool
            #expect(pool.entries.count == 1) // Only root
            #expect(pool.entries["map:sync1@123"] == nil)
            #expect(pool.entries["counter:sync1@456"] == nil)
        }

        /// Test behavior when there's no sync sequence in progress
        @Test
        func handlesNoSyncSequenceCorrectly() {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Add some objects to the pool using OBJECT_SYNC messages
            // (This is the realistic way objects enter the pool, not through direct manipulation)
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "map:test@123"),
                ],
                protocolMessageChannelSerial: nil, // Complete sync immediately
            )

            let pool = realtimeObjects.testsOnly_objectsPool

            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
            #expect(pool.entries.count == 2) // root + additional map

            // When: onChannelAttached is called with hasObjects = false
            realtimeObjects.onChannelAttached(hasObjects: false)

            // Then: Should still reset the pool correctly
            let newPool = realtimeObjects.testsOnly_objectsPool
            #expect(newPool.entries.count == 1) // Only root
            #expect(newPool.entries["map:test@123"] == nil)
            #expect(!realtimeObjects.testsOnly_hasSyncSequence) // Should remain false
        }

        /// Test that the root object's delegate is correctly set after reset
        @Test
        func setsCorrectDelegateOnNewRoot() {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // When: onChannelAttached is called with hasObjects = false
            realtimeObjects.onChannelAttached(hasObjects: false)

            // Then: The new root should be properly initialized
            let newRoot = realtimeObjects.testsOnly_objectsPool.root
            #expect(newRoot.testsOnly_data.isEmpty) // Should be zero-valued (empty)
        }
    }

    /// Tests for `InternalDefaultRealtimeObjects.getRoot`, covering RTO1 specification points
    struct GetRootTests {
        // MARK: - RTO1c Tests

        // @specOneOf(1/4) RTO1c - getRoot waits for sync completion when sync completes via ATTACHED with `HAS_OBJECTS` false (RTO4b)
        @Test
        func waitsForSyncCompletionViaAttachedHasObjectsFalse() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Start getRoot call - it should wait for sync completion
            async let getRootTask = realtimeObjects.getRoot(coreSDK: coreSDK)

            // Wait for getRoot to start waiting for sync
            _ = try #require(await realtimeObjects.testsOnly_waitingForSyncEvents.first { _ in true })

            // Complete sync via ATTACHED with HAS_OBJECTS false (RTO4b)
            realtimeObjects.onChannelAttached(hasObjects: false)

            // getRoot should now complete
            _ = try await getRootTask
        }

        // @specOneOf(2/4) RTO1c - getRoot waits for sync completion when sync completes via single `OBJECT_SYNC` with no channelSerial (RTO5a5)
        @Test
        func waitsForSyncCompletionViaSingleObjectSync() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Start getRoot call - it should wait for sync completion
            async let getRootTask = realtimeObjects.getRoot(coreSDK: coreSDK)

            // Wait for getRoot to start waiting for sync
            _ = try #require(await realtimeObjects.testsOnly_waitingForSyncEvents.first { _ in true })

            // Complete sync via single OBJECT_SYNC with no channelSerial (RTO5a5)
            let (testKey, testEntry) = TestFactories.stringMapEntry(key: "testKey", value: "testValue")
            let (referencedKey, referencedEntry) = TestFactories.objectReferenceMapEntry(key: "referencedObject", objectId: "map:test@123")
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.rootObjectMessage(entries: [
                        testKey: testEntry,
                        referencedKey: referencedEntry,
                    ]),
                    TestFactories.mapObjectMessage(objectId: "map:test@123"),
                ],
                protocolMessageChannelSerial: nil, // RTO5a5 case
            )

            // getRoot should now complete
            let root = try await getRootTask

            // Verify the root object contains the expected entries from the sync
            let testValue = try root.get(key: "testKey", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue
            #expect(testValue == "testValue")

            // Verify the root object contains a reference to the other LiveObject
            let referencedObject = try root.get(key: "referencedObject", coreSDK: coreSDK, delegate: realtimeObjects)
            #expect(referencedObject != nil)
        }

        // @specOneOf(3/4) RTO1c - getRoot waits for sync completion when sync completes via multiple `OBJECT_SYNC` messages (RTO5a4)
        @Test
        func waitsForSyncCompletionViaMultipleObjectSync() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: .attached)
            let sequenceId = "seq123"

            // Start getRoot call - it should wait for sync completion
            async let getRootTask = realtimeObjects.getRoot(coreSDK: coreSDK)

            // Wait for getRoot to start waiting for sync
            _ = try #require(await realtimeObjects.testsOnly_waitingForSyncEvents.first { _ in true })

            // Start multi-message sync sequence (RTO5a1, RTO5a3)
            let (firstKey, firstEntry) = TestFactories.stringMapEntry(key: "firstKey", value: "firstValue")
            let (firstObjectKey, firstObjectEntry) = TestFactories.objectReferenceMapEntry(key: "firstObject", objectId: "map:first@123")
            let (secondObjectKey, secondObjectEntry) = TestFactories.objectReferenceMapEntry(key: "secondObject", objectId: "map:second@456")
            let (finalObjectKey, finalObjectEntry) = TestFactories.objectReferenceMapEntry(key: "finalObject", objectId: "map:final@789")
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.rootObjectMessage(entries: [
                        firstKey: firstEntry,
                        firstObjectKey: firstObjectEntry,
                        secondObjectKey: secondObjectEntry,
                        finalObjectKey: finalObjectEntry,
                    ]),
                    TestFactories.mapObjectMessage(objectId: "map:first@123"),
                ],
                protocolMessageChannelSerial: "\(sequenceId):cursor1",
            )

            // Continue sync sequence - add more objects but don't redefine root
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "map:second@456"),
                ],
                protocolMessageChannelSerial: "\(sequenceId):cursor2",
            )

            // Complete sync sequence (RTO5a4) - add final object
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "map:final@789"),
                ],
                protocolMessageChannelSerial: "\(sequenceId):", // Empty cursor indicates end
            )

            // getRoot should now complete
            let root = try await getRootTask

            // Verify the root object contains the expected entries from the sync sequence
            let firstValue = try root.get(key: "firstKey", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue
            let firstObject = try root.get(key: "firstObject", coreSDK: coreSDK, delegate: realtimeObjects)
            let secondObject = try root.get(key: "secondObject", coreSDK: coreSDK, delegate: realtimeObjects)
            let finalObject = try root.get(key: "finalObject", coreSDK: coreSDK, delegate: realtimeObjects)
            #expect(firstValue == "firstValue")
            #expect(firstObject != nil)
            #expect(secondObject != nil)
            #expect(finalObject != nil)
        }

        // @specOneOf(4/4) RTO1c - getRoot returns immediately when sync is already complete
        @Test
        func returnsImmediatelyWhenSyncAlreadyComplete() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Complete sync first
            realtimeObjects.onChannelAttached(hasObjects: false)

            // getRoot should return
            _ = try await realtimeObjects.getRoot(coreSDK: coreSDK)

            // Verify no waiting events were emitted
            realtimeObjects.testsOnly_finishAllTestHelperStreams()
            let waitingEvents: [Void] = await realtimeObjects.testsOnly_waitingForSyncEvents.reduce(into: []) { result, _ in
                result.append(())
            }
            #expect(waitingEvents.isEmpty)
        }

        // MARK: - RTO1d Tests

        // @spec RTO1d
        @Test
        func returnsRootObjectFromObjectsPool() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Complete sync first
            realtimeObjects.onChannelAttached(hasObjects: false)

            // Call getRoot
            let root = try await realtimeObjects.getRoot(coreSDK: coreSDK)

            // Verify it's the same object as the one in the pool with key "root"
            let poolRoot = realtimeObjects.testsOnly_objectsPool.entries["root"]?.mapValue
            #expect(root as AnyObject === poolRoot as AnyObject)
        }

        // MARK: - RTO1b Tests

        // @spec RTO1b
        @Test(arguments: [.detached, .failed] as [_AblyPluginSupportPrivate.RealtimeChannelState])
        func getRootThrowsIfChannelIsDetachedOrFailed(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: channelState)

            await #expect {
                _ = try await realtimeObjects.getRoot(coreSDK: coreSDK)
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }

                return errorInfo.code == 90001 && errorInfo.statusCode == 400
            }
        }
    }

    /// Tests for `InternalDefaultRealtimeObjects.handleObjectProtocolMessage`, covering RTO8 specification points.
    struct HandleObjectProtocolMessageTests {
        // Tests that when an OBJECT ProtocolMessage is received and there isn't a sync in progress, its operations are handled per RTO8b.
        struct ApplyOperationTests {
            // @specUntested RTO9a1 - There is no way to check that it was a no-op since there are no side effects that this spec point tells us not to apply
            // @specUntested RTO9a2b - There is no way to check that it was a no-op since there are no side effects that this spec point tells us not to apply

            // MARK: - RTO9a2a1 Tests

            // @spec RTO9a2a1 - Tests that if necessary it creates an object in the ObjectsPool
            @Test
            func createsObjectInObjectsPoolWhenNecessary() {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let objectId = "map:new@123"

                // Verify the object doesn't exist in the pool initially
                let initialPool = realtimeObjects.testsOnly_objectsPool
                #expect(initialPool.entries[objectId] == nil)

                // Create a MAP_SET operation message for a non-existent object
                let operationMessage = TestFactories.mapSetOperationMessage(
                    objectId: objectId,
                    key: "testKey",
                    value: "testValue",
                )

                // Handle the object protocol message
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [operationMessage])

                // Verify the object was created in the ObjectsPool (RTO9a2a1)
                let finalPool = realtimeObjects.testsOnly_objectsPool
                #expect(finalPool.entries[objectId] != nil)
            }

            // MARK: - RTO9a2a3 Tests for MAP_CREATE

            // TODO: Understand what to do with OBJECT_DELETE (https://github.com/ably/specification/pull/343#discussion_r2193126548)

            // @specOneOf(1/5) RTO9a2a3 - Tests MAP_CREATE operation application
            @Test
            func appliesMapCreateOperation() throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let objectId = "map:test@123"

                // Create a map object in the pool first
                let (entryKey, entry) = TestFactories.stringMapEntry(key: "existingKey", value: "existingValue")
                realtimeObjects.handleObjectSyncProtocolMessage(
                    objectMessages: [
                        TestFactories.mapObjectMessage(
                            objectId: objectId,
                            siteTimeserials: ["site1": "ts1"],
                            entries: [entryKey: entry],
                        ),
                    ],
                    protocolMessageChannelSerial: nil,
                )

                // Verify the object exists and has initial data
                let map = try #require(realtimeObjects.testsOnly_objectsPool.entries[objectId]?.mapValue)
                let coreSDK = MockCoreSDK(channelState: .attached)
                let initialValue = try #require(map.get(key: "existingKey", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue)
                #expect(initialValue == "existingValue")

                // Create a MAP_CREATE operation message
                let (createKey, createEntry) = TestFactories.stringMapEntry(key: "createKey", value: "createValue")
                let operationMessage = TestFactories.mapCreateOperationMessage(
                    objectId: objectId,
                    entries: [createKey: createEntry],
                    serial: "ts2", // Higher than existing "ts1"
                    siteCode: "site1",
                )

                // Handle the object protocol message
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [operationMessage])

                // Verify the operation was applied by checking for side effects
                // The full logic of applying the operation is tested in RTLM15; we just check for some of its side effects here
                let finalValue = try #require(map.get(key: "createKey", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue)
                #expect(finalValue == "createValue")
                #expect(map.testsOnly_createOperationIsMerged)
                #expect(map.testsOnly_siteTimeserials["site1"] == "ts2")
            }

            // MARK: - RTO9a2a3 Tests for MAP_SET

            // @specOneOf(2/5) RTO9a2a3 - Tests MAP_SET operation application
            @Test
            func appliesMapSetOperation() throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let objectId = "map:test@123"

                // Create a map object in the pool first
                let (entryKey, entry) = TestFactories.stringMapEntry(key: "existingKey", value: "existingValue")
                realtimeObjects.handleObjectSyncProtocolMessage(
                    objectMessages: [
                        TestFactories.mapObjectMessage(
                            objectId: objectId,
                            siteTimeserials: ["site1": "ts1"],
                            entries: [entryKey: entry],
                        ),
                    ],
                    protocolMessageChannelSerial: nil,
                )

                // Verify the object exists and has initial data
                let map = try #require(realtimeObjects.testsOnly_objectsPool.entries[objectId]?.mapValue)
                let coreSDK = MockCoreSDK(channelState: .attached)
                let initialValue = try #require(map.get(key: "existingKey", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue)
                #expect(initialValue == "existingValue")

                // Create a MAP_SET operation message
                let operationMessage = TestFactories.mapSetOperationMessage(
                    objectId: objectId,
                    key: "existingKey",
                    value: "newValue",
                    serial: "ts2", // Higher than existing "ts1"
                    siteCode: "site1",
                )

                // Handle the object protocol message
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [operationMessage])

                // Verify the operation was applied by checking for side effects
                // The full logic of applying the operation is tested in RTLM15; we just check for some of its side effects here
                let finalValue = try #require(map.get(key: "existingKey", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue)
                #expect(finalValue == "newValue")
                #expect(map.testsOnly_siteTimeserials["site1"] == "ts2")
            }

            // MARK: - RTO9a2a3 Tests for MAP_REMOVE

            // @specOneOf(3/5) RTO9a2a3 - Tests MAP_REMOVE operation application
            @Test
            func appliesMapRemoveOperation() throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let objectId = "map:test@123"

                // Create a map object in the pool first
                let (entryKey, entry) = TestFactories.stringMapEntry(key: "existingKey", value: "existingValue")
                realtimeObjects.handleObjectSyncProtocolMessage(
                    objectMessages: [
                        TestFactories.mapObjectMessage(
                            objectId: objectId,
                            siteTimeserials: ["site1": "ts1"],
                            entries: [entryKey: entry],
                        ),
                    ],
                    protocolMessageChannelSerial: nil,
                )

                // Verify the object exists and has initial data
                let map = try #require(realtimeObjects.testsOnly_objectsPool.entries[objectId]?.mapValue)
                let coreSDK = MockCoreSDK(channelState: .attached)
                let initialValue = try #require(map.get(key: "existingKey", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue)
                #expect(initialValue == "existingValue")

                // Create a MAP_REMOVE operation message
                let operationMessage = TestFactories.mapRemoveOperationMessage(
                    objectId: objectId,
                    key: "existingKey",
                    serial: "ts2", // Higher than existing "ts1"
                    siteCode: "site1",
                )

                // Handle the object protocol message
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [operationMessage])

                // Verify the operation was applied by checking for side effects
                // The full logic of applying the operation is tested in RTLM15; we just check for some of its side effects here
                let finalValue = try map.get(key: "existingKey", coreSDK: coreSDK, delegate: realtimeObjects)
                #expect(finalValue == nil) // Key should be removed/tombstoned
                #expect(map.testsOnly_siteTimeserials["site1"] == "ts2")
            }

            // MARK: - RTO9a2a3 Tests for COUNTER_CREATE

            // @specOneOf(4/5) RTO9a2a3 - Tests COUNTER_CREATE operation application
            @Test
            func appliesCounterCreateOperation() throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let objectId = "counter:test@123"

                // Create a counter object in the pool first
                realtimeObjects.handleObjectSyncProtocolMessage(
                    objectMessages: [
                        TestFactories.counterObjectMessage(
                            objectId: objectId,
                            siteTimeserials: ["site1": "ts1"],
                            count: 5,
                        ),
                    ],
                    protocolMessageChannelSerial: nil,
                )

                // Verify the object exists and has initial data
                let counter = try #require(realtimeObjects.testsOnly_objectsPool.entries[objectId]?.counterValue)
                let coreSDK = MockCoreSDK(channelState: .attached)
                let initialValue = try counter.value(coreSDK: coreSDK)
                #expect(initialValue == 5)

                // Create a COUNTER_CREATE operation message
                let operationMessage = TestFactories.counterCreateOperationMessage(
                    objectId: objectId,
                    count: 10,
                    serial: "ts2", // Higher than existing "ts1"
                    siteCode: "site1",
                )

                // Handle the object protocol message
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [operationMessage])

                // Verify the operation was applied by checking for side effects
                // The full logic of applying the operation is tested in RTLC7; we just check for some of its side effects here
                let finalValue = try counter.value(coreSDK: coreSDK)
                #expect(finalValue == 15) // 5 + 10 (initial value merged)
                #expect(counter.testsOnly_siteTimeserials["site1"] == "ts2")
            }

            // MARK: - RTO9a2a3 Tests for COUNTER_INC

            // @specOneOf(5/5) RTO9a2a3 - Tests COUNTER_INC operation application
            @Test
            func appliesCounterIncOperation() throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let objectId = "counter:test@123"

                // Create a counter object in the pool first
                realtimeObjects.handleObjectSyncProtocolMessage(
                    objectMessages: [
                        TestFactories.counterObjectMessage(
                            objectId: objectId,
                            siteTimeserials: ["site1": "ts1"],
                            count: 5,
                        ),
                    ],
                    protocolMessageChannelSerial: nil,
                )

                // Verify the object exists and has initial data
                let counter = try #require(realtimeObjects.testsOnly_objectsPool.entries[objectId]?.counterValue)
                let coreSDK = MockCoreSDK(channelState: .attached)
                let initialValue = try counter.value(coreSDK: coreSDK)
                #expect(initialValue == 5)

                // Create a COUNTER_INC operation message
                let operationMessage = TestFactories.counterIncOperationMessage(
                    objectId: objectId,
                    amount: 10,
                    serial: "ts2", // Higher than existing "ts1"
                    siteCode: "site1",
                )

                // Handle the object protocol message
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [operationMessage])

                // Verify the operation was applied by checking for side effects
                // The full logic of applying the operation is tested in RTLC7; we just check for some of its side effects here
                let finalValue = try counter.value(coreSDK: coreSDK)
                #expect(finalValue == 15) // 5 + 10
                #expect(counter.testsOnly_siteTimeserials["site1"] == "ts2")
            }
        }

        // Tests that when an OBJECT ProtocolMessage is received during a sync sequence, its operations are buffered per RTO8a and applied after sync completion per RTO5c6.
        struct BufferOperationTests {
            // @spec RTO8a
            // @spec RTO5c6
            @Test
            func buffersObjectOperationsDuringSyncAndAppliesAfterCompletion() async throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let sequenceId = "seq123"

                // Start sync sequence with first OBJECT_SYNC message
                let (entryKey, entry) = TestFactories.stringMapEntry(key: "existingKey", value: "existingValue")
                let firstSyncMessages = [
                    TestFactories.mapObjectMessage(
                        objectId: "map:1@123",
                        siteTimeserials: ["site1": "ts1"], // Explicit sync data siteCode and serial
                        entries: [entryKey: entry],
                    ),
                ]
                realtimeObjects.handleObjectSyncProtocolMessage(
                    objectMessages: firstSyncMessages,
                    protocolMessageChannelSerial: "\(sequenceId):cursor1",
                )

                // Verify sync sequence is active
                #expect(realtimeObjects.testsOnly_hasSyncSequence)

                // Inject first OBJECT ProtocolMessage during sync (RTO8a)
                let firstObjectMessage = TestFactories.mapSetOperationMessage(
                    objectId: "map:1@123",
                    key: "key1",
                    value: "value1",
                    serial: "ts3", // Higher than sync data "ts1"
                    siteCode: "site1",
                )
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [firstObjectMessage])

                // Verify the operation was buffered and not applied yet
                let poolAfterFirstObject = realtimeObjects.testsOnly_objectsPool
                #expect(poolAfterFirstObject.entries["map:1@123"] == nil) // Object not yet created from sync

                // Inject second OBJECT ProtocolMessage during sync (RTO8a)
                let secondObjectMessage = TestFactories.counterIncOperationMessage(
                    objectId: "counter:1@456",
                    amount: 10,
                    serial: "ts4", // Higher than sync data "ts2"
                    siteCode: "site1",
                )
                realtimeObjects.handleObjectProtocolMessage(objectMessages: [secondObjectMessage])

                // Verify the second operation was also buffered and not applied yet
                let poolAfterSecondObject = realtimeObjects.testsOnly_objectsPool
                #expect(poolAfterSecondObject.entries["counter:1@456"] == nil) // Object not yet created from sync

                // Complete sync sequence with final OBJECT_SYNC message
                let finalSyncMessages = [
                    TestFactories.counterObjectMessage(
                        objectId: "counter:1@456",
                        siteTimeserials: ["site1": "ts2"],
                        count: 5,
                    ),
                ]
                realtimeObjects.handleObjectSyncProtocolMessage(
                    objectMessages: finalSyncMessages,
                    protocolMessageChannelSerial: "\(sequenceId):", // Empty cursor indicates end
                )

                // Verify sync sequence is cleared
                #expect(!realtimeObjects.testsOnly_hasSyncSequence)

                // Verify all objects were applied to pool from sync
                let finalPool = realtimeObjects.testsOnly_objectsPool
                let map = try #require(finalPool.entries["map:1@123"]?.mapValue)
                let counter = try #require(finalPool.entries["counter:1@456"]?.counterValue)

                // Verify the buffered operations were applied after sync completion (RTO5c6)
                // Check that MAP_SET operation was applied to the map
                let coreSDK = MockCoreSDK(channelState: .attached)
                let mapValue = try #require(map.get(key: "key1", coreSDK: coreSDK, delegate: realtimeObjects)?.stringValue)
                #expect(mapValue == "value1")
                #expect(map.testsOnly_siteTimeserials["site1"] == "ts3")

                // Check that COUNTER_INC operation was applied to the counter
                let counterValue = try counter.value(coreSDK: coreSDK)
                #expect(counterValue == 15) // 5 (from sync) + 10 (from buffered operation)
                #expect(counter.testsOnly_siteTimeserials["site1"] == "ts4")
            }
        }
    }

    /// Tests for `InternalDefaultRealtimeObjects.createMap`, covering RTO11 specification points (these are largely a smoke test, the rest being tested in ObjectCreationHelpers tests)
    struct CreateMapTests {
        // @spec RTO11d
        @Test(arguments: [.detached, .failed, .suspended] as [_AblyPluginSupportPrivate.RealtimeChannelState])
        func throwsIfChannelIsInInvalidState(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: channelState)
            let entries: [String: InternalLiveMapValue] = ["testKey": .string("testValue")]

            await #expect {
                _ = try await realtimeObjects.createMap(entries: entries, coreSDK: coreSDK)
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }
                return errorInfo.code == 90001 && errorInfo.statusCode == 400
            }
        }

        // @spec RTO11g
        // @spec RTO11h3a
        // @spec RTO11h3b
        @Test
        func publishesObjectMessageAndCreatesMap() async throws {
            let clock = MockSimpleClock(currentTime: .init(timeIntervalSince1970: 1_754_042_434))
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects(clock: clock)
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Track published messages
            var publishedMessages: [OutboundObjectMessage] = []
            coreSDK.setPublishHandler { messages in
                publishedMessages.append(contentsOf: messages)
            }

            // Call createMap
            let returnedMap = try await realtimeObjects.createMap(
                entries: [
                    "stringKey": .string("stringValue"),
                ],
                coreSDK: coreSDK,
            )

            // Verify ObjectMessage was published (RTO11g)
            #expect(publishedMessages.count == 1)
            let publishedMessage = publishedMessages[0]

            // Sense check of ObjectMessage structure per RTO11f9-13
            #expect(publishedMessage.operation?.action == .known(.mapCreate))
            let objectID = try #require(publishedMessage.operation?.objectId)
            #expect(objectID.hasPrefix("map:"))
            // TODO: This is a stopgap; change to use server time per RTO11f5 (https://github.com/ably/ably-liveobjects-swift-plugin/issues/50)
            #expect(objectID.contains("1754042434000")) // check contains the mock clock's timestamp in milliseconds
            #expect(publishedMessage.operation?.map?.entries == [
                "stringKey": .init(data: .init(string: "stringValue")),
            ])

            // Verify initial value was merged per RTO11h3a
            #expect(returnedMap.testsOnly_data == ["stringKey": InternalObjectsMapEntry(data: ObjectData(string: "stringValue"))])

            // Verify object was added to pool per RTO11h3b
            #expect(realtimeObjects.testsOnly_objectsPool.entries[objectID]?.mapValue === returnedMap)
        }

        // @spec RTO11f4b
        @Test
        func withNoEntriesArgumentCreatesEmptyMap() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Track published messages
            var publishedMessages: [OutboundObjectMessage] = []
            coreSDK.setPublishHandler { messages in
                publishedMessages.append(contentsOf: messages)
            }

            // Call createMap with no entries
            let result = try await realtimeObjects.createMap(entries: [:], coreSDK: coreSDK)

            // Verify ObjectMessage was published
            #expect(publishedMessages.count == 1)
            let publishedMessage = publishedMessages[0]

            // Verify map operation has empty entries per RTO11f4b
            let mapOperation = publishedMessage.operation?.map
            #expect(mapOperation?.entries?.isEmpty == true)

            // Verify LiveMap has expected entries
            #expect(result.testsOnly_data.isEmpty)
        }

        // @spec RTO11h2
        @Test
        func returnsExistingObjectIfAlreadyInPool() async throws {
            let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Track published messages and the generated objectId
            var publishedMessages: [OutboundObjectMessage] = []
            var maybeGeneratedObjectID: String?
            var maybeExistingObject: AnyObject?

            coreSDK.setPublishHandler { messages in
                publishedMessages.append(contentsOf: messages)

                // Extract the generated objectId from the published message
                if let objectID = messages.first?.operation?.objectId {
                    maybeGeneratedObjectID = objectID

                    // Create an object with this exact ID in the pool
                    // This simulates the object already existing when createMap tries to get it, before the publish operation completes (e.g. because it has been populated by receipt of an OBJECT)
                    maybeExistingObject = realtimeObjects.testsOnly_createZeroValueLiveObject(forObjectID: objectID)?.mapValue
                }
            }

            // Call createMap - the publishHandler will create the object with the generated ID
            let result = try await realtimeObjects.createMap(entries: ["testKey": .string("testValue")], coreSDK: coreSDK)

            // Verify ObjectMessage was published
            #expect(publishedMessages.count == 1)

            // Extract the variables that we populated based on the generated object ID
            let generatedObjectID = try #require(maybeGeneratedObjectID)
            let existingObject = try #require(maybeExistingObject)

            // Verify the returned object is the same as the existing one
            #expect(result === existingObject)

            // Check that the existing object has not been replaced in the pool
            #expect(realtimeObjects.testsOnly_objectsPool.entries[generatedObjectID]?.mapValue === existingObject)
        }

        /// Tests for `InternalDefaultRealtimeObjects.createCounter`, covering RTO12 specification points (these are largely a smoke test, the rest being tested in ObjectCreationHelpers tests)
        struct CreateCounterTests {
            // @spec RTO12d
            @Test(arguments: [.detached, .failed, .suspended] as [_AblyPluginSupportPrivate.RealtimeChannelState])
            func throwsIfChannelIsInInvalidState(channelState: _AblyPluginSupportPrivate.RealtimeChannelState) async throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let coreSDK = MockCoreSDK(channelState: channelState)

                await #expect {
                    _ = try await realtimeObjects.createCounter(count: 10.5, coreSDK: coreSDK)
                } throws: { error in
                    guard let errorInfo = error as? ARTErrorInfo else {
                        return false
                    }
                    return errorInfo.code == 90001 && errorInfo.statusCode == 400
                }
            }

            // @spec RTO12g
            // @spec RTO12h3a
            // @spec RTO12h3b
            @Test
            func publishesObjectMessageAndCreatesCounter() async throws {
                let clock = MockSimpleClock(currentTime: .init(timeIntervalSince1970: 1_754_042_434))
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects(clock: clock)
                let coreSDK = MockCoreSDK(channelState: .attached)

                // Track published messages
                var publishedMessages: [OutboundObjectMessage] = []
                coreSDK.setPublishHandler { messages in
                    publishedMessages.append(contentsOf: messages)
                }

                // Call createCounter
                let returnedCounter = try await realtimeObjects.createCounter(count: 10.5, coreSDK: coreSDK)

                // Verify ObjectMessage was published (RTO12g)
                #expect(publishedMessages.count == 1)
                let publishedMessage = publishedMessages[0]

                // Sense check of ObjectMessage structure per RTO12f7-11
                #expect(publishedMessage.operation?.action == .known(.counterCreate))
                let objectID = try #require(publishedMessage.operation?.objectId)
                #expect(objectID.hasPrefix("counter:"))
                // TODO: This is a stopgap; change to use server time per RTO11f5 (https://github.com/ably/ably-liveobjects-swift-plugin/issues/50)
                #expect(objectID.contains("1754042434000")) // check contains the mock clock's timestamp in milliseconds
                #expect(publishedMessage.operation?.counter?.count == 10.5)

                // Verify initial value was merged per RTO12h3a
                #expect(try returnedCounter.value(coreSDK: coreSDK) == 10.5)

                // Verify object was added to pool per RTO12h3b
                #expect(realtimeObjects.testsOnly_objectsPool.entries[objectID]?.counterValue === returnedCounter)
            }

            // @spec RTO12f2a
            @Test
            func withNoEntriesArgumentCreatesWithZeroValue() async throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let coreSDK = MockCoreSDK(channelState: .attached)

                // Track published messages
                var publishedMessages: [OutboundObjectMessage] = []
                coreSDK.setPublishHandler { messages in
                    publishedMessages.append(contentsOf: messages)
                }

                // Call createCounter with no count
                let result = try await realtimeObjects.createCounter(coreSDK: coreSDK)

                // Verify ObjectMessage was published
                #expect(publishedMessages.count == 1)
                let publishedMessage = publishedMessages[0]

                // Verify counter operation has zero count per RTO12f2a
                let counterOperation = publishedMessage.operation?.counter
                // swiftlint:disable:next empty_count
                #expect(counterOperation?.count == 0)

                // Verify LiveCounter has zero value
                #expect(try result.value(coreSDK: coreSDK) == 0)
            }

            // @spec RTO12h2
            @Test
            func returnsExistingObjectIfAlreadyInPool() async throws {
                let realtimeObjects = InternalDefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
                let coreSDK = MockCoreSDK(channelState: .attached)

                // Track published messages and the generated objectId
                var publishedMessages: [OutboundObjectMessage] = []
                var maybeGeneratedObjectID: String?
                var maybeExistingObject: AnyObject?

                coreSDK.setPublishHandler { messages in
                    publishedMessages.append(contentsOf: messages)

                    // Extract the generated objectId from the published message
                    if let objectID = messages.first?.operation?.objectId {
                        maybeGeneratedObjectID = objectID

                        // Create an object with this exact ID in the pool
                        // This simulates the object already existing when createMap tries to get it, before the publish operation completes (e.g. because it has been populated by receipt of an OBJECT)
                        maybeExistingObject = realtimeObjects.testsOnly_createZeroValueLiveObject(forObjectID: objectID)?.counterValue
                    }
                }

                // Call createCounter - the publishHandler will create the object with the generated ID
                let result = try await realtimeObjects.createCounter(count: 10.5, coreSDK: coreSDK)

                // Verify ObjectMessage was published
                #expect(publishedMessages.count == 1)

                // Extract the variables that we populated based on the generated object ID
                let generatedObjectID = try #require(maybeGeneratedObjectID)
                let existingObject = try #require(maybeExistingObject)

                // Verify the returned object is the same as the existing one
                #expect(result === existingObject)

                // Check that the existing object has not been replaced in the pool
                #expect(realtimeObjects.testsOnly_objectsPool.entries[generatedObjectID]?.counterValue === existingObject)
            }
        }
    }
}
