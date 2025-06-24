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
            let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: channelState))

            #expect {
                _ = try counter.value
            } throws: { error in
                guard let errorInfo = error as? ARTErrorInfo else {
                    return false
                }

                return errorInfo.code == 90001
            }
        }

        // @spec RTLC5c
        @Test
        func valueReturnsCurrentDataWhenChannelIsValid() throws {
            let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attached))

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
            let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attaching))
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
                let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attaching))
                let state = TestFactories.counterObjectState(
                    createOp: nil, // Test value - must be nil to test RTLC6b
                )
                counter.replaceData(using: state)
                #expect(counter.testsOnly_createOperationIsMerged == false)
            }

            // @specOneOf(1/4) RTLC6c - count but no createOp
            @Test
            func setsDataToCounterCount() throws {
                let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attaching))
                let state = TestFactories.counterObjectState(
                    count: 42, // Test value
                )
                counter.replaceData(using: state)
                #expect(try counter.value == 42)
            }

            // @specOneOf(2/4) RTLC6c - no count, no createOp
            @Test
            func setsDataToZeroWhenCounterCountDoesNotExist() throws {
                let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attaching))
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
                let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attaching))
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
                let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attaching))
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
                let counter = DefaultLiveCounter.createZeroValued(coreSDK: MockCoreSDK(channelState: .attaching))
                let state = TestFactories.counterObjectState(
                    createOp: TestFactories.objectOperation( // Test value - must be non-nil
                        action: .known(.counterCreate),
                    ),
                )
                counter.replaceData(using: state)
                #expect(counter.testsOnly_createOperationIsMerged == true)
            }
        }
    }
}
