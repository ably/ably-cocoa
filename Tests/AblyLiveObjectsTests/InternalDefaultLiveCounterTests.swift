@testable import AblyLiveObjects
import AblyPlugin
import Foundation
import Testing

struct InternalDefaultLiveCounterTests {
    /// Tests for the `value` property, covering RTLC5 specification points
    struct ValueTests {
        // @spec RTLC5b
        @Test(arguments: [.detached, .failed] as [ARTRealtimeChannelState])
        func valueThrowsIfChannelIsDetachedOrFailed(channelState: ARTRealtimeChannelState) async throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: channelState)

            #expect {
                _ = try counter.value(coreSDK: coreSDK)
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }

                return errorInfo.code == 90001 && errorInfo.statusCode == 400
            }
        }

        // @spec RTLC5c
        @Test
        func valueReturnsCurrentDataWhenChannelIsValid() throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attached)

            // Set some test data
            _ = counter.replaceData(using: TestFactories.counterObjectState(count: 42), objectMessageSerialTimestamp: nil)

            #expect(try counter.value(coreSDK: coreSDK) == 42)
        }
    }

    /// Tests for the `replaceData` method, covering RTLC6 specification points
    struct ReplaceDataTests {
        // @spec RTLC6a
        @Test
        func replacesSiteTimeserials() {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let state = TestFactories.counterObjectState(
                siteTimeserials: ["site1": "ts1"], // Test value
            )
            _ = counter.replaceData(using: state, objectMessageSerialTimestamp: nil)
            #expect(counter.testsOnly_siteTimeserials == ["site1": "ts1"])
        }

        /// Tests for the case where createOp is not present
        struct WithoutCreateOpTests {
            // @spec RTLC6b - Tests the case without createOp, as RTLC10b takes precedence when createOp exists
            @Test
            func setsCreateOperationIsMergedToFalse() {
                // Given: A counter whose createOperationIsMerged is true
                let logger = TestLogger()
                let counter = {
                    let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
                    // Test setup: Manipulate counter so that its createOperationIsMerged gets set to true (we need to do this since we want to later assert that it gets set to false, but the default is false).
                    let state = TestFactories.counterObjectState(
                        createOp: TestFactories.objectOperation(
                            action: .known(.counterCreate),
                        ),
                    )
                    _ = counter.replaceData(using: state, objectMessageSerialTimestamp: nil)
                    #expect(counter.testsOnly_createOperationIsMerged)

                    return counter
                }()

                // When:
                let state = TestFactories.counterObjectState(
                    createOp: nil, // Test value - must be nil to test RTLC6b
                )
                _ = counter.replaceData(using: state, objectMessageSerialTimestamp: nil)

                // Then:
                #expect(!counter.testsOnly_createOperationIsMerged)
            }

            // @specOneOf(1/4) RTLC6c - count but no createOp
            @Test
            func setsDataToCounterCount() throws {
                let logger = TestLogger()
                let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let state = TestFactories.counterObjectState(
                    count: 42, // Test value
                )
                _ = counter.replaceData(using: state, objectMessageSerialTimestamp: nil)
                #expect(try counter.value(coreSDK: coreSDK) == 42)
            }

            // @specOneOf(2/4) RTLC6c - no count, no createOp
            @Test
            func setsDataToZeroWhenCounterCountDoesNotExist() throws {
                let logger = TestLogger()
                let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
                let coreSDK = MockCoreSDK(channelState: .attaching)
                _ = counter.replaceData(using: TestFactories.counterObjectState(
                    count: nil, // Test value - must be nil
                ), objectMessageSerialTimestamp: nil)

                #expect(try counter.value(coreSDK: coreSDK) == 0)
            }
        }

        /// Tests for RTLC10 (merge initial value from createOp)
        struct WithCreateOpTests {
            // @spec RTLC10 - Tests that replaceData merges initial value when createOp is present
            @Test
            func mergesInitialValueWhenCreateOpPresent() throws {
                let logger = TestLogger()
                let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
                let coreSDK = MockCoreSDK(channelState: .attaching)
                let state = TestFactories.counterObjectState(
                    createOp: TestFactories.counterCreateOperation(count: 10), // Test value - must exist
                    count: 5, // Test value - must exist
                )
                _ = counter.replaceData(using: state, objectMessageSerialTimestamp: nil)
                #expect(try counter.value(coreSDK: coreSDK) == 15) // First sets to 5 (RTLC6c) then adds 10 (RTLC10a)
                #expect(counter.testsOnly_createOperationIsMerged)
            }
        }
    }

    /// Tests for the `mergeInitialValue` method, covering RTLC10 specification points
    struct MergeInitialValueTests {
        // @specOneOf(1/2) RTLC10a - with count
        // @spec RTLC10c
        @Test
        func addsCounterCountToData() throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Set initial data
            _ = counter.replaceData(using: TestFactories.counterObjectState(count: 5), objectMessageSerialTimestamp: nil)
            #expect(try counter.value(coreSDK: coreSDK) == 5)

            // Apply merge operation
            let operation = TestFactories.counterCreateOperation(count: 10) // Test value - must exist
            let update = counter.mergeInitialValue(from: operation)

            #expect(try counter.value(coreSDK: coreSDK) == 15) // 5 + 10

            // Check return value
            #expect(try #require(update.update).amount == 10)
        }

        // @specOneOf(2/2) RTLC10a - no count
        // @spec RTLC10d
        @Test
        func doesNotModifyDataWhenCounterCountDoesNotExist() throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Set initial data
            _ = counter.replaceData(using: TestFactories.counterObjectState(count: 5), objectMessageSerialTimestamp: nil)
            #expect(try counter.value(coreSDK: coreSDK) == 5)

            // Apply merge operation with no count
            let operation = TestFactories.objectOperation(
                action: .known(.counterCreate),
                counter: nil, // Test value - must be nil
            )
            let update = counter.mergeInitialValue(from: operation)

            #expect(try counter.value(coreSDK: coreSDK) == 5) // Unchanged

            // Check return value
            #expect(update.isNoop)
        }

        // @spec RTLC10b
        @Test
        func setsCreateOperationIsMergedToTrue() {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply merge operation
            let operation = TestFactories.counterCreateOperation(count: 10) // Test value - must exist
            _ = counter.mergeInitialValue(from: operation)

            #expect(counter.testsOnly_createOperationIsMerged)
        }
    }

    /// Tests for `COUNTER_CREATE` operations, covering RTLC8 specification points
    struct CounterCreateOperationTests {
        // @spec RTLC8b
        @Test
        func discardsOperationWhenCreateOperationIsMerged() throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Set initial data and mark create operation as merged
            _ = counter.replaceData(using: TestFactories.counterObjectState(count: 5), objectMessageSerialTimestamp: nil)
            _ = counter.mergeInitialValue(from: TestFactories.counterCreateOperation(count: 10))
            #expect(counter.testsOnly_createOperationIsMerged)

            // Try to apply another COUNTER_CREATE operation
            let operation = TestFactories.counterCreateOperation(count: 20)
            let update = counter.testsOnly_applyCounterCreateOperation(operation)

            // Verify the operation was discarded - data unchanged
            #expect(try counter.value(coreSDK: coreSDK) == 15) // 5 + 10, not 5 + 10 + 20

            // Verify return value
            #expect(update.isNoop)
        }

        // @spec RTLC8c
        // @spec RTLC8e
        @Test
        func mergesInitialValue() throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Set initial data but don't mark create operation as merged
            _ = counter.replaceData(using: TestFactories.counterObjectState(count: 5), objectMessageSerialTimestamp: nil)
            #expect(!counter.testsOnly_createOperationIsMerged)

            // Apply COUNTER_CREATE operation
            let operation = TestFactories.counterCreateOperation(count: 10)
            let update = counter.testsOnly_applyCounterCreateOperation(operation)

            // Verify the operation was applied - initial value merged. (The full logic of RTLC10 is tested elsewhere; we just check for some of its side effects here.)
            #expect(try counter.value(coreSDK: coreSDK) == 15) // 5 + 10
            #expect(counter.testsOnly_createOperationIsMerged)

            // Verify return value per RTLC8e
            #expect(try #require(update.update).amount == 10)
        }
    }

    /// Tests for `COUNTER_INC` operations, covering RTLC9 specification points
    struct CounterIncOperationTests {
        // @spec RTLC9b
        // @spec RTLC9d
        // @spec RTLC9e
        @Test(
            arguments: [
                (
                    operation: TestFactories.counterOp(amount: 10),
                    expectedValue: 15.0, // 5 + 10
                    expectedUpdate: .update(.init(amount: 10)) // RTLC9d
                ),
                (
                    operation: nil as WireObjectsCounterOp?,
                    expectedValue: 5.0, // unchanged
                    expectedUpdate: .noop // RTLC9e
                ),
            ] as [(operation: WireObjectsCounterOp?, expectedValue: Double, expectedUpdate: LiveObjectUpdate<DefaultLiveCounterUpdate>)],
        )
        func addsAmountToData(operation: WireObjectsCounterOp?, expectedValue: Double, expectedUpdate: LiveObjectUpdate<DefaultLiveCounterUpdate>) throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Set initial data
            _ = counter.replaceData(using: TestFactories.counterObjectState(count: 5), objectMessageSerialTimestamp: nil)
            #expect(try counter.value(coreSDK: coreSDK) == 5)

            // Apply COUNTER_INC operation
            let update = counter.testsOnly_applyCounterIncOperation(operation)

            // Verify the operation was applied correctly
            #expect(try counter.value(coreSDK: coreSDK) == expectedValue)

            // Verify return value
            #expect(update == expectedUpdate)
        }
    }

    /// Tests for the `apply(_ operation:, …)` method, covering RTLC7 specification points
    struct ApplyOperationTests {
        // @spec RTLC7b - Tests that an operation does not get applied when canApplyOperation returns nil
        @Test
        func discardsOperationWhenCannotBeApplied() throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            // Set up the counter with an existing site timeserial that will cause the operation to be discarded
            _ = counter.replaceData(using: TestFactories.counterObjectState(
                siteTimeserials: ["site1": "ts2"], // Existing serial "ts2"
                count: 5,
            ), objectMessageSerialTimestamp: nil)

            let operation = TestFactories.objectOperation(
                action: .known(.counterInc),
                counterOp: TestFactories.counterOp(amount: 10),
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply operation with serial "ts1" which is lexicographically less than existing "ts2" and thus will be applied per RTLO4a (this is a non-pathological case of RTOL4a, that spec point being fully tested elsewhere)
            counter.apply(
                operation,
                objectMessageSerial: "ts1", // Less than existing "ts2"
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Check that the COUNTER_INC side-effects didn't happen:
            // Verify the operation was discarded - data unchanged (should still be 5 from creation)
            #expect(try counter.value(coreSDK: coreSDK) == 5)
            // Verify site timeserials unchanged
            #expect(counter.testsOnly_siteTimeserials == ["site1": "ts2"])
        }

        // @specOneOf(1/2) RTLC7c - We test this spec point for each possible operation
        // @spec RTLC7d1 - Tests COUNTER_CREATE operation application
        // @spec RTLC7d1a
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func appliesCounterCreateOperation() async throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            let subscriber = Subscriber<DefaultLiveCounterUpdate, SubscribeResponse>(callbackQueue: .main)
            try counter.subscribe(listener: subscriber.createListener(), coreSDK: coreSDK)

            let operation = TestFactories.counterCreateOperation(count: 15)
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply COUNTER_CREATE operation
            counter.apply(
                operation,
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Verify the operation was applied - initial value merged (the full logic of RTLC8 is tested elsewhere; we just check for some of its side effects here)
            #expect(try counter.value(coreSDK: coreSDK) == 15)
            #expect(counter.testsOnly_createOperationIsMerged)
            // Verify RTLC7c side-effect: site timeserial was updated
            #expect(counter.testsOnly_siteTimeserials == ["site1": "ts1"])

            // Verify update was emitted per RTLC7d1a
            let subscriberInvocations = await subscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(amount: 15)])
        }

        // @specOneOf(2/2) RTLC7c - We test this spec point for each possible operation
        // @spec RTLC7d2 - Tests COUNTER_INC operation application
        // @spec RTLC7d2a
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func appliesCounterIncOperation() async throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            let subscriber = Subscriber<DefaultLiveCounterUpdate, SubscribeResponse>(callbackQueue: .main)
            try counter.subscribe(listener: subscriber.createListener(), coreSDK: coreSDK)

            // Set initial data
            _ = counter.replaceData(using: TestFactories.counterObjectState(siteTimeserials: [:], count: 5), objectMessageSerialTimestamp: nil)
            #expect(try counter.value(coreSDK: coreSDK) == 5)

            let operation = TestFactories.objectOperation(
                action: .known(.counterInc),
                counterOp: TestFactories.counterOp(amount: 10),
            )
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())

            // Apply COUNTER_INC operation
            counter.apply(
                operation,
                objectMessageSerial: "ts1",
                objectMessageSiteCode: "site1",
                objectMessageSerialTimestamp: nil,
                objectsPool: &pool,
            )

            // Verify the operation was applied - amount added to data (the full logic of RTLC9 is tested elsewhere; we just check for some of its side effects here)
            #expect(try counter.value(coreSDK: coreSDK) == 15) // 5 + 10
            // Verify RTLC7c side-effect: site timeserial was updated
            #expect(counter.testsOnly_siteTimeserials == ["site1": "ts1"])

            // Verify update was emitted per RTLC7d2a
            let subscriberInvocations = await subscriber.getInvocations()
            #expect(subscriberInvocations.map(\.0) == [.init(amount: 10)])
        }

        // @spec RTLC7d3
        @available(iOS 17.0.0, tvOS 17.0.0, *)
        @Test
        func noOpForOtherOperation() async throws {
            let logger = TestLogger()
            let counter = InternalDefaultLiveCounter.createZeroValued(objectID: "arbitrary", logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            let coreSDK = MockCoreSDK(channelState: .attaching)

            let subscriber = Subscriber<DefaultLiveCounterUpdate, SubscribeResponse>(callbackQueue: .main)
            try counter.subscribe(listener: subscriber.createListener(), coreSDK: coreSDK)

            // Try to apply a MAP_CREATE to the counter (not supported)
            var pool = ObjectsPool(logger: logger, userCallbackQueue: .main, clock: MockSimpleClock())
            counter.apply(
                TestFactories.mapCreateOperation(),
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
}
