import Ably
@testable import AblyLiveObjects
import AblyPlugin
import Testing

/// Tests for `DefaultRealtimeObjects`.
struct DefaultRealtimeObjectsTests {
    // MARK: - Test Helpers

    /// Creates a DefaultRealtimeObjects instance for testing
    static func createDefaultRealtimeObjects(channelState: ARTRealtimeChannelState = .attached) -> DefaultRealtimeObjects {
        let coreSDK = MockCoreSDK(channelState: channelState)
        let logger = TestLogger()
        return DefaultRealtimeObjects(coreSDK: coreSDK, logger: logger)
    }

    /// Tests for `DefaultRealtimeObjects.handleObjectSyncProtocolMessage`, covering RTO5 specification points.
    struct HandleObjectSyncProtocolMessageTests {
        // MARK: - RTO5a5: Single ProtocolMessage Sync Tests

        // @spec RTO5a5
        @Test
        func handlesSingleProtocolMessageSync() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
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
        @Test
        func handlesMultiProtocolMessageSync() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
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

            // Verify sync sequence is cleared and there is no SyncObjectsPool (RTO5c3, RTO5c4)
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
        @Test
        func newSequenceIdDiscardsInFlightSync() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let firstSequenceId = "seq1"
            let secondSequenceId = "seq2"

            // Start first sequence
            let firstMessages = [TestFactories.simpleMapMessage(objectId: "map:1@123")]
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: firstMessages,
                protocolMessageChannelSerial: "\(firstSequenceId):cursor1",
            )

            #expect(realtimeObjects.testsOnly_hasSyncSequence)

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
            #expect(pool.entries["map:2@456"] != nil) // From completed second sequence
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
        }

        // MARK: - RTO5c: Post-Sync Behavior Tests

        // @spec(RTO5c2, RTO5c2a) Objects not in sync are removed, except root
        @Test
        func removesObjectsNotInSyncButPreservesRoot() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

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

            // Note: We rely on applySyncObjectsPool being tested separately for RTO5c2 removal behavior
            // as the side effect of removing pre-existing objects is tested in ObjectsPoolTests
        }

        // MARK: - Error Handling Tests

        /// Test handling of invalid channelSerial format
        @Test
        func handlesInvalidChannelSerialFormat() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
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
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
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
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

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
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

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

    /// Tests for `DefaultRealtimeObjects.onChannelAttached`, covering RTO4 specification points.
    ///
    /// Note: These tests use `OBJECT_SYNC` messages to populate the initial state of objects pools
    /// and sync sequences. This approach is more realistic than directly manipulating internal state,
    /// as it simulates how objects actually enter pools during normal operation.
    struct OnChannelAttachedTests {
        // MARK: - RTO4a Tests

        // @spec RTO4a - Checks that when the `HAS_OBJECTS` flag is 1 (i.e. the server will shortly perform an `OBJECT_SYNC` sequence) we don't modify any internal state
        @Test
        func doesNotModifyStateWhenHasObjectsIsTrue() {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Set up initial state with additional objects by using the createZeroValueObject method
            let originalPool = realtimeObjects.testsOnly_objectsPool
            let originalRootObject = originalPool.root
            _ = realtimeObjects.testsOnly_createZeroValueLiveObject(forObjectID: "map:test@123", coreSDK: MockCoreSDK(channelState: .attaching))

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
        // @spec RTO4b3
        // @spec RTO4b4
        @Test
        func handlesHasObjectsFalse() {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Set up initial state with additional objects in the pool using sync
            realtimeObjects.handleObjectSyncProtocolMessage(
                objectMessages: [
                    TestFactories.mapObjectMessage(objectId: "map:existing@123"),
                    TestFactories.counterObjectMessage(objectId: "counter:existing@456"),
                ],
                protocolMessageChannelSerial: nil, // Complete sync immediately
            )

            let originalPool = realtimeObjects.testsOnly_objectsPool

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

            // Verify root is a new zero-valued map (RTO4b2)
            // TODO: this one is unclear (are we meant to replace the root or just clear its data?) https://github.com/ably/specification/pull/333/files#r2183493458
            let newRoot = newPool.root
            #expect(newRoot as AnyObject !== originalPool.root as AnyObject) // Should be a new instance
            #expect(newRoot.testsOnly_data.isEmpty) // Should be zero-valued (empty)

            // RTO4b3, RTO4b4: SyncObjectsPool must be cleared, sync sequence cleared
            #expect(!realtimeObjects.testsOnly_hasSyncSequence)
        }

        // MARK: - Edge Cases and Integration Tests

        /// Test that multiple calls to onChannelAttached work correctly
        @Test
        func handlesMultipleCallsCorrectly() {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // First call with hasObjects = true (should do nothing)
            realtimeObjects.onChannelAttached(hasObjects: true)
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == true)
            let originalPool = realtimeObjects.testsOnly_objectsPool
            let originalRoot = originalPool.root

            // Second call with hasObjects = false (should reset)
            realtimeObjects.onChannelAttached(hasObjects: false)
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == false)
            let newPool = realtimeObjects.testsOnly_objectsPool
            #expect(newPool.root as AnyObject !== originalRoot as AnyObject)
            #expect(newPool.entries.count == 1)

            // Third call with hasObjects = true again (should do nothing)
            let secondResetRoot = newPool.root
            realtimeObjects.onChannelAttached(hasObjects: true)
            #expect(realtimeObjects.testsOnly_onChannelAttachedHasObjects == true)
            let finalPool = realtimeObjects.testsOnly_objectsPool
            #expect(finalPool.root as AnyObject === secondResetRoot as AnyObject) // Should be unchanged
        }

        /// Test that sync sequence is properly discarded even with complex sync state
        @Test
        func discardsComplexSyncSequence() {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

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
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

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
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // When: onChannelAttached is called with hasObjects = false
            realtimeObjects.onChannelAttached(hasObjects: false)

            // Then: The new root should have the correct delegate
            let newRoot = realtimeObjects.testsOnly_objectsPool.root
            #expect(newRoot.testsOnly_delegate as AnyObject === realtimeObjects as AnyObject)
        }
    }

    /// Tests for `DefaultRealtimeObjects.getRoot`, covering RTO1 specification points
    struct GetRootTests {
        // MARK: - RTO1c Tests

        // @specOneOf(1/4) RTO1c - getRoot waits for sync completion when sync completes via ATTACHED with `HAS_OBJECTS` false (RTO4b)
        @Test
        func waitsForSyncCompletionViaAttachedHasObjectsFalse() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Start getRoot call - it should wait for sync completion
            async let getRootTask = realtimeObjects.getRoot()

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
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Start getRoot call - it should wait for sync completion
            async let getRootTask = realtimeObjects.getRoot()

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
            let testValue = try root.get(key: "testKey")?.stringValue
            #expect(testValue == "testValue")

            // Verify the root object contains a reference to the other LiveObject
            let referencedObject = try root.get(key: "referencedObject")
            #expect(referencedObject != nil)
        }

        // @specOneOf(3/4) RTO1c - getRoot waits for sync completion when sync completes via multiple `OBJECT_SYNC` messages (RTO5a4)
        @Test
        func waitsForSyncCompletionViaMultipleObjectSync() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()
            let sequenceId = "seq123"

            // Start getRoot call - it should wait for sync completion
            async let getRootTask = realtimeObjects.getRoot()

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
            let firstValue = try root.get(key: "firstKey")?.stringValue
            let firstObject = try root.get(key: "firstObject")
            let secondObject = try root.get(key: "secondObject")
            let finalObject = try root.get(key: "finalObject")
            #expect(firstValue == "firstValue")
            #expect(firstObject != nil)
            #expect(secondObject != nil)
            #expect(finalObject != nil)
        }

        // @specOneOf(4/4) RTO1c - getRoot returns immediately when sync is already complete
        @Test
        func returnsImmediatelyWhenSyncAlreadyComplete() async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Complete sync first
            realtimeObjects.onChannelAttached(hasObjects: false)

            // getRoot should return
            _ = try await realtimeObjects.getRoot()

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
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects()

            // Complete sync first
            realtimeObjects.onChannelAttached(hasObjects: false)

            // Call getRoot
            let root = try await realtimeObjects.getRoot()

            // Verify it's the same object as the one in the pool with key "root"
            let poolRoot = realtimeObjects.testsOnly_objectsPool.entries["root"]?.mapValue
            #expect(root as AnyObject === poolRoot as AnyObject)
        }

        // MARK: - RTO1b Tests

        // @spec RTO1b
        @Test(arguments: [.detached, .failed] as [ARTRealtimeChannelState])
        func getRootThrowsIfChannelIsDetachedOrFailed(channelState: ARTRealtimeChannelState) async throws {
            let realtimeObjects = DefaultRealtimeObjectsTests.createDefaultRealtimeObjects(channelState: channelState)

            await #expect {
                _ = try await realtimeObjects.getRoot()
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }

                return errorInfo.code == 90001 && errorInfo.statusCode == 400
            }
        }
    }
}
