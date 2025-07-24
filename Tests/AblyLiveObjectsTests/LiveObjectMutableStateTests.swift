import Ably
@testable import AblyLiveObjects
import AblyPlugin
import Testing

/// Tests for `LiveObjectMutableState`.
struct LiveObjectMutableStateTests {
    /// Tests for `LiveObjectMutableState.canApplyOperation`, covering RTLO4 specification points.
    struct CanApplyOperationTests {
        /// Test case data for canApplyOperation tests
        struct TestCase {
            let description: String
            let objectMessageSerial: String?
            let objectMessageSiteCode: String?
            let siteTimeserials: [String: String]
            let expectedResult: LiveObjectMutableState.ApplicableOperation?
        }

        // @spec RTLO4a3
        // @spec RTLO4a4
        // @spec RTLO4a5
        // @spec RTLO4a6
        @Test(arguments: [
            // RTLO4a3: Both ObjectMessage.serial and ObjectMessage.siteCode must be non-empty strings
            TestCase(
                description: "serial is nil, siteCode is valid - should return nil",
                objectMessageSerial: nil,
                objectMessageSiteCode: "site1",
                siteTimeserials: [:],
                expectedResult: nil,
            ),
            TestCase(
                description: "serial is empty string, siteCode is valid - should return nil",
                objectMessageSerial: "",
                objectMessageSiteCode: "site1",
                siteTimeserials: [:],
                expectedResult: nil,
            ),
            TestCase(
                description: "serial is valid, siteCode is nil - should return nil",
                objectMessageSerial: "serial1",
                objectMessageSiteCode: nil,
                siteTimeserials: [:],
                expectedResult: nil,
            ),
            TestCase(
                description: "serial is valid, siteCode is empty string - should return nil",
                objectMessageSerial: "serial1",
                objectMessageSiteCode: "",
                siteTimeserials: [:],
                expectedResult: nil,
            ),
            TestCase(
                description: "both serial and siteCode are invalid - should return nil",
                objectMessageSerial: nil,
                objectMessageSiteCode: "",
                siteTimeserials: [:],
                expectedResult: nil,
            ),

            // RTLO4a5: If the siteSerial for this LiveObject is null or an empty string, return ApplicableOperation
            TestCase(
                description: "siteSerial is nil (siteCode doesn't exist) - should return ApplicableOperation",
                objectMessageSerial: "serial2",
                objectMessageSiteCode: "site1",
                siteTimeserials: ["site2": "serial1"], // i.e. only has an entry for a different siteCode
                expectedResult: LiveObjectMutableState.ApplicableOperation(objectMessageSerial: "serial2", objectMessageSiteCode: "site1"),
            ),
            TestCase(
                description: "siteSerial is empty string - should return ApplicableOperation",
                objectMessageSerial: "serial2",
                objectMessageSiteCode: "site1",
                siteTimeserials: ["site1": "", "site2": "serial1"],
                expectedResult: LiveObjectMutableState.ApplicableOperation(objectMessageSerial: "serial2", objectMessageSiteCode: "site1"),
            ),

            // RTLO4a6: If the siteSerial for this LiveObject is not an empty string, return ApplicableOperation if ObjectMessage.serial is greater than siteSerial when compared lexicographically
            TestCase(
                description: "serial is greater than siteSerial lexicographically - should return ApplicableOperation",
                objectMessageSerial: "serial2",
                objectMessageSiteCode: "site1",
                siteTimeserials: ["site1": "serial1"],
                expectedResult: LiveObjectMutableState.ApplicableOperation(objectMessageSerial: "serial2", objectMessageSiteCode: "site1"),
            ),
            TestCase(
                description: "serial is less than siteSerial lexicographically - should return nil",
                objectMessageSerial: "serial1",
                objectMessageSiteCode: "site1",
                siteTimeserials: ["site1": "serial2"],
                expectedResult: nil,
            ),
            TestCase(
                description: "serial equals siteSerial - should return nil",
                objectMessageSerial: "serial1",
                objectMessageSiteCode: "site1",
                siteTimeserials: ["site1": "serial1"],
                expectedResult: nil,
            ),
        ])
        func canApplyOperation(testCase: TestCase) {
            let state = LiveObjectMutableState(
                objectID: "test:object@123",
                siteTimeserials: testCase.siteTimeserials,
            )
            let logger = TestLogger()

            let result = state.canApplyOperation(
                objectMessageSerial: testCase.objectMessageSerial,
                objectMessageSiteCode: testCase.objectMessageSiteCode,
                logger: logger,
            )

            #expect(result == testCase.expectedResult, "Expected \(String(describing: testCase.expectedResult)) for case: \(testCase.description)")
        }
    }
}
