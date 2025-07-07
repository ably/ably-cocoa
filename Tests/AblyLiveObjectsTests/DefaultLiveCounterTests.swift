@testable import AblyLiveObjects
import AblyPlugin
import Foundation
import Testing

struct DefaultLiveCounterTests {
    /// Tests for the `value` property, covering RTLC5 specification points
    struct ValueTests {
        // @spec RTLC5b
        @Test(arguments: [.detached, .failed] as [ARTRealtimeChannelState])
        func valueThrowsIfChannelIsDetachedOrFailed(channelState: ARTRealtimeChannelState) async throws {
            let logger = TestLogger()
            let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: channelState), logger: logger)

            #expect {
                _ = try counter.value
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
            let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attached), logger: logger)

            // Set some test data
            counter.replaceData(using: TestFactories.counterObjectState(count: 42))

            #expect(try counter.value == 42)
        }
    }

    /// Tests for the `replaceData` method, covering RTLC6 specification points
    struct ReplaceDataTests {
        // @spec RTLC6a
        @Test
        func replacesSiteTimeserials() {
            let logger = TestLogger()
            let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attaching), logger: logger)
            let state = TestFactories.counterObjectState(
                siteTimeserials: ["site1": "ts1"], // Test value
            )
            counter.replaceData(using: state)
            #expect(counter.testsOnly_siteTimeserials == ["site1": "ts1"])
        }

        /// Tests for the case where createOp is not present
        struct WithoutCreateOpTests {
            // @spec RTLC6b - Tests the case without createOp, as RTLC6d2 takes precedence when createOp exists
            @Test
            func setsCreateOperationIsMergedToFalse() {
                // Given: A counter whose createOperationIsMerged is true
                let logger = TestLogger()
                let counter = {
                    let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attaching), logger: logger)
                    // Test setup: Manipulate counter so that its createOperationIsMerged gets set to true (we need to do this since we want to later assert that it gets set to false, but the default is false).
                    let state = TestFactories.counterObjectState(
                        createOp: TestFactories.objectOperation(
                            action: .known(.counterCreate),
                        ),
                    )
                    counter.replaceData(using: state)
                    #expect(counter.testsOnly_createOperationIsMerged)

                    return counter
                }()

                // When:
                let state = TestFactories.counterObjectState(
                    createOp: nil, // Test value - must be nil to test RTLC6b
                )
                counter.replaceData(using: state)

                // Then:
                #expect(!counter.testsOnly_createOperationIsMerged)
            }

            // @specOneOf(1/4) RTLC6c - count but no createOp
            @Test
            func setsDataToCounterCount() throws {
                let logger = TestLogger()
                let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attaching), logger: logger)
                let state = TestFactories.counterObjectState(
                    count: 42, // Test value
                )
                counter.replaceData(using: state)
                #expect(try counter.value == 42)
            }

            // @specOneOf(2/4) RTLC6c - no count, no createOp
            @Test
            func setsDataToZeroWhenCounterCountDoesNotExist() throws {
                let logger = TestLogger()
                let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attaching), logger: logger)
                counter.replaceData(using: TestFactories.counterObjectState(
                    count: nil, // Test value - must be nil
                ))
                #expect(try counter.value == 0)
            }
        }

        /// Tests for RTLC6d (with createOp present)
        struct WithCreateOpTests {
            // @specOneOf(1/2) RTLC6d1 - with count
            // @specOneOf(3/4) RTLC6c - count and createOp
            @Test
            func setsDataToCounterCountThenAddsCreateOpCounterCount() throws {
                let logger = TestLogger()
                let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attaching), logger: logger)
                let state = TestFactories.counterObjectState(
                    createOp: TestFactories.counterCreateOperation(count: 10), // Test value - must exist
                    count: 5, // Test value - must exist
                )
                counter.replaceData(using: state)
                #expect(try counter.value == 15) // First sets to 5 (RTLC6c) then adds 10 (RTLC6d1)
            }

            // @specOneOf(2/2) RTLC6d1 - no count
            // @specOneOf(4/4) RTLC6c - no count but createOp
            @Test
            func doesNotModifyDataWhenCreateOpCounterCountDoesNotExist() throws {
                let logger = TestLogger()
                let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attaching), logger: logger)
                let state = TestFactories.counterObjectState(
                    createOp: TestFactories.objectOperation(
                        action: .known(.counterCreate),
                        counter: nil, // Test value - must be nil
                    ),
                    count: 5, // Test value
                )
                counter.replaceData(using: state)
                #expect(try counter.value == 5) // Only the base counter.count value
            }

            // @spec RTLC6d2
            @Test
            func setsCreateOperationIsMergedToTrue() {
                let logger = TestLogger()
                let counter = DefaultLiveCounter.createZeroValued(objectID: "arbitrary", coreSDK: MockCoreSDK(channelState: .attaching), logger: logger)
                let state = TestFactories.counterObjectState(
                    createOp: TestFactories.objectOperation( // Test value - must be non-nil
                        action: .known(.counterCreate),
                    ),
                )
                counter.replaceData(using: state)
                #expect(counter.testsOnly_createOperationIsMerged)
            }
        }
    }
}
