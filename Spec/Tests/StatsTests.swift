import Ably
import Foundation
import Nimble
import XCTest

private let encoder = ARTJsonLikeEncoder()
private let subject: ARTStatsConnectionTypes? = {
    let data: [[String: Any]] = [
        ["connections": ["tls": ["opened": 5], "all": ["peak": 10]]],
    ]
    let rawData = try! JSONUtility.serialize(data)
    let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
    return stats?.connections
}()

private let channelsTestsSubject: ARTStatsResourceCount? = {
    let data: [[String: Any]] = [
        ["channels": ["opened": 5, "peak": 10]],
    ]
    let rawData = try! JSONUtility.serialize(data)
    let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
    return stats?.channels
}()

private let pushTestsSubject: ARTStatsPushCount? = {
    let data: [[String: Any]] = [
        ["push":
            [
                "messages": 10,
                "notifications": [
                    "invalid": 1,
                    "attempted": 2,
                    "successful": 3,
                    "failed": 4,
                ],
                "directPublishes": 5,
            ] as [String : Any]],
    ]
    let rawData = try! JSONUtility.serialize(data)
    let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
    return stats?.pushes
}()

private let inProgressTestsStats: ARTStats? = {
    let data: [[String: Any]] = [
        ["inProgress": "2004-02-01:05:06"],
    ]
    let rawData = try! JSONUtility.serialize(data)
    return try! encoder.decodeStats(rawData)[0] as? ARTStats
}()

private let countTestStats: ARTStats? = {
    let data: [[String: Any]] = [
        ["count": 55],
    ]
    let rawData = try! JSONUtility.serialize(data)
    return try! encoder.decodeStats(rawData)[0] as? ARTStats
}()

class StatsTests: XCTestCase {
    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = encoder
        _ = subject
        _ = channelsTestsSubject
        _ = pushTestsSubject
        _ = inProgressTestsStats
        _ = countTestStats

        return super.defaultTestSuite
    }

    enum TestCase_ReusableTestsTestAttribute {
        case should_return_a_MessagesTypes_object
        case should_return_value_for_message_counts
        case should_return_value_for_all_data_transferred
        case should_return_zero_for_empty_values
    }

    // TS6
    func reusableTestsTestAttribute(_ attribute: String, testCase: TestCase_ReusableTestsTestAttribute, beforeEach contextBeforeEach: (() -> Void)? = nil, afterEach contextAfterEach: (() -> Void)? = nil) {
        let data: [[String: Any]] = [
            [attribute: ["messages": ["count": 5], "all": ["data": 10]]],
        ]
        let rawData = try! JSONUtility.serialize(data)
        let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
        let subject = stats?.value(forKey: attribute) as? ARTStatsMessageTypes

        func test__should_return_a_MessagesTypes_object() {
            contextBeforeEach?()

            expect(subject).to(beAnInstanceOf(ARTStatsMessageTypes.self))

            contextAfterEach?()
        }

        // TS5
        func test__should_return_value_for_message_counts() {
            contextBeforeEach?()

            expect(subject?.messages.count).to(equal(5))

            contextAfterEach?()
        }

        // TS5
        func test__should_return_value_for_all_data_transferred() {
            contextBeforeEach?()

            expect(subject?.all.data).to(equal(10))

            contextAfterEach?()
        }

        // TS2
        func test__should_return_zero_for_empty_values() {
            contextBeforeEach?()

            expect(subject?.presence.count).to(equal(0))

            contextAfterEach?()
        }

        switch testCase {
        case .should_return_a_MessagesTypes_object:
            test__should_return_a_MessagesTypes_object()
        case .should_return_value_for_message_counts:
            test__should_return_value_for_message_counts()
        case .should_return_value_for_all_data_transferred:
            test__should_return_value_for_all_data_transferred()
        case .should_return_zero_for_empty_values:
            test__should_return_zero_for_empty_values()
        }
    }

    func reusableTestsWrapper__Stats__all__reusableTestsTestAttribute(testCase: TestCase_ReusableTestsTestAttribute) {
        reusableTestsTestAttribute("all", testCase: testCase)
    }

    func test__001__Stats__all__should_return_a_MessagesTypes_object() {
        reusableTestsWrapper__Stats__all__reusableTestsTestAttribute(testCase: .should_return_a_MessagesTypes_object)
    }

    func test__002__Stats__all__should_return_value_for_message_counts() {
        reusableTestsWrapper__Stats__all__reusableTestsTestAttribute(testCase: .should_return_value_for_message_counts)
    }

    func test__003__Stats__all__should_return_value_for_all_data_transferred() {
        reusableTestsWrapper__Stats__all__reusableTestsTestAttribute(testCase: .should_return_value_for_all_data_transferred)
    }

    func test__004__Stats__all__should_return_zero_for_empty_values() {
        reusableTestsWrapper__Stats__all__reusableTestsTestAttribute(testCase: .should_return_zero_for_empty_values)
    }

    func reusableTestsWrapper__Stats__persisted__reusableTestsTestAttribute(testCase: TestCase_ReusableTestsTestAttribute) {
        reusableTestsTestAttribute("persisted", testCase: testCase)
    }

    func test__005__Stats__persisted__should_return_a_MessagesTypes_object() {
        reusableTestsWrapper__Stats__persisted__reusableTestsTestAttribute(testCase: .should_return_a_MessagesTypes_object)
    }

    func test__006__Stats__persisted__should_return_value_for_message_counts() {
        reusableTestsWrapper__Stats__persisted__reusableTestsTestAttribute(testCase: .should_return_value_for_message_counts)
    }

    func test__007__Stats__persisted__should_return_value_for_all_data_transferred() {
        reusableTestsWrapper__Stats__persisted__reusableTestsTestAttribute(testCase: .should_return_value_for_all_data_transferred)
    }

    func test__008__Stats__persisted__should_return_zero_for_empty_values() {
        reusableTestsWrapper__Stats__persisted__reusableTestsTestAttribute(testCase: .should_return_zero_for_empty_values)
    }

    enum TestCase_ReusableTestsTestDirection {
        case should_return_a_MessageTraffic_object
        case should_return_value_for_realtime_message_counts
        case should_return_value_for_all_presence_data
    }

    // TS7
    func reusableTestsTestDirection(_ direction: String, testCase: TestCase_ReusableTestsTestDirection, beforeEach contextBeforeEach: (() -> Void)? = nil, afterEach contextAfterEach: (() -> Void)? = nil) {
        let data: [[String: Any]] = [
            [direction: [
                "realtime": ["messages": ["count": 5]],
                "all": ["messages": ["count": 25], "presence": ["data": 210]],
            ]],
        ]
        let rawData = try! JSONUtility.serialize(data)
        let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
        let subject = stats?.value(forKey: direction) as? ARTStatsMessageTraffic

        func test__should_return_a_MessageTraffic_object() {
            contextBeforeEach?()

            expect(subject).to(beAnInstanceOf(ARTStatsMessageTraffic.self))

            contextAfterEach?()
        }

        // TS5
        func test__should_return_value_for_realtime_message_counts() {
            contextBeforeEach?()

            expect(subject?.realtime.messages.count).to(equal(5))

            contextAfterEach?()
        }

        // TS5
        func test__should_return_value_for_all_presence_data() {
            contextBeforeEach?()

            expect(subject?.all.presence.data).to(equal(210))

            contextAfterEach?()
        }

        switch testCase {
        case .should_return_a_MessageTraffic_object:
            test__should_return_a_MessageTraffic_object()
        case .should_return_value_for_realtime_message_counts:
            test__should_return_value_for_realtime_message_counts()
        case .should_return_value_for_all_presence_data:
            test__should_return_value_for_all_presence_data()
        }
    }

    func reusableTestsWrapper__Stats__inbound__reusableTestsTestDirection(testCase: TestCase_ReusableTestsTestDirection) {
        reusableTestsTestDirection("inbound", testCase: testCase)
    }

    func test__009__Stats__inbound__should_return_a_MessageTraffic_object() {
        reusableTestsWrapper__Stats__inbound__reusableTestsTestDirection(testCase: .should_return_a_MessageTraffic_object)
    }

    func test__010__Stats__inbound__should_return_value_for_realtime_message_counts() {
        reusableTestsWrapper__Stats__inbound__reusableTestsTestDirection(testCase: .should_return_value_for_realtime_message_counts)
    }

    func test__011__Stats__inbound__should_return_value_for_all_presence_data() {
        reusableTestsWrapper__Stats__inbound__reusableTestsTestDirection(testCase: .should_return_value_for_all_presence_data)
    }

    func reusableTestsWrapper__Stats__outbound__reusableTestsTestDirection(testCase: TestCase_ReusableTestsTestDirection) {
        reusableTestsTestDirection("outbound", testCase: testCase)
    }

    func test__012__Stats__outbound__should_return_a_MessageTraffic_object() {
        reusableTestsWrapper__Stats__outbound__reusableTestsTestDirection(testCase: .should_return_a_MessageTraffic_object)
    }

    func test__013__Stats__outbound__should_return_value_for_realtime_message_counts() {
        reusableTestsWrapper__Stats__outbound__reusableTestsTestDirection(testCase: .should_return_value_for_realtime_message_counts)
    }

    func test__014__Stats__outbound__should_return_value_for_all_presence_data() {
        reusableTestsWrapper__Stats__outbound__reusableTestsTestDirection(testCase: .should_return_value_for_all_presence_data)
    }

    // TS4

    func test__015__Stats__connections__should_return_a_ConnectionTypes_object() {
        expect(subject).to(beAnInstanceOf(ARTStatsConnectionTypes.self))
    }

    func test__016__Stats__connections__should_return_value_for_tls_opened_counts() {
        expect(subject?.tls.opened).to(equal(5))
    }

    func test__017__Stats__connections__should_return_value_for_all_peak_connections() {
        expect(subject?.all.peak).to(equal(10))
    }

    // TS2
    func test__018__Stats__connections__should_return_zero_for_empty_values() {
        expect(subject?.all.refused).to(equal(0))
    }

    // TS9

    func test__019__Stats__channels__should_return_a_ResourceCount_object() {
        expect(channelsTestsSubject).to(beAnInstanceOf(ARTStatsResourceCount.self))
    }

    func test__020__Stats__channels__should_return_value_for_opened_counts() {
        expect(channelsTestsSubject?.opened).to(equal(5))
    }

    func test__021__Stats__channels__should_return_value_for_peak_channels() {
        expect(channelsTestsSubject?.peak).to(equal(10))
    }

    // TS2
    func test__022__Stats__channels__should_return_zero_for_empty_values() {
        expect(channelsTestsSubject?.refused).to(equal(0))
    }

    enum TestCase_ReusableTestsTestRequestType {
        case should_return_a_RequestCount_object
        case should_return_value_for_succeeded
        case should_return_value_for_failed
    }

    // TS8
    func reusableTestsTestRequestType(_ requestType: String, testCase: TestCase_ReusableTestsTestRequestType, beforeEach contextBeforeEach: (() -> Void)? = nil, afterEach contextAfterEach: (() -> Void)? = nil) {
        let data: [[String: Any]] = [
            [requestType: ["succeeded": 5, "failed": 10]],
        ]
        let rawData = try! JSONUtility.serialize(data)
        let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
        let subject = stats?.value(forKey: requestType) as? ARTStatsRequestCount

        func test__should_return_a_RequestCount_object() {
            contextBeforeEach?()

            expect(subject).to(beAnInstanceOf(ARTStatsRequestCount.self))

            contextAfterEach?()
        }

        func test__should_return_value_for_succeeded() {
            contextBeforeEach?()

            expect(subject?.succeeded).to(equal(5))

            contextAfterEach?()
        }

        func test__should_return_value_for_failed() {
            contextBeforeEach?()

            expect(subject?.failed).to(equal(10))

            contextAfterEach?()
        }

        switch testCase {
        case .should_return_a_RequestCount_object:
            test__should_return_a_RequestCount_object()
        case .should_return_value_for_succeeded:
            test__should_return_value_for_succeeded()
        case .should_return_value_for_failed:
            test__should_return_value_for_failed()
        }
    }

    func reusableTestsWrapper__Stats__apiRequests__reusableTestsTestRequestType(testCase: TestCase_ReusableTestsTestRequestType) {
        reusableTestsTestRequestType("apiRequests", testCase: testCase)
    }

    func test__023__Stats__apiRequests__should_return_a_RequestCount_object() {
        reusableTestsWrapper__Stats__apiRequests__reusableTestsTestRequestType(testCase: .should_return_a_RequestCount_object)
    }

    func test__024__Stats__apiRequests__should_return_value_for_succeeded() {
        reusableTestsWrapper__Stats__apiRequests__reusableTestsTestRequestType(testCase: .should_return_value_for_succeeded)
    }

    func test__025__Stats__apiRequests__should_return_value_for_failed() {
        reusableTestsWrapper__Stats__apiRequests__reusableTestsTestRequestType(testCase: .should_return_value_for_failed)
    }

    func reusableTestsWrapper__Stats__tokenRequests__reusableTestsTestRequestType(testCase: TestCase_ReusableTestsTestRequestType) {
        reusableTestsTestRequestType("tokenRequests", testCase: testCase)
    }

    func test__026__Stats__tokenRequests__should_return_a_RequestCount_object() {
        reusableTestsWrapper__Stats__tokenRequests__reusableTestsTestRequestType(testCase: .should_return_a_RequestCount_object)
    }

    func test__027__Stats__tokenRequests__should_return_value_for_succeeded() {
        reusableTestsWrapper__Stats__tokenRequests__reusableTestsTestRequestType(testCase: .should_return_value_for_succeeded)
    }

    func test__028__Stats__tokenRequests__should_return_value_for_failed() {
        reusableTestsWrapper__Stats__tokenRequests__reusableTestsTestRequestType(testCase: .should_return_value_for_failed)
    }

    func test__029__Stats__interval__should_return_a_Date_object_representing_the_start_of_the_interval() {
        let data: [[String: Any]] = [
            ["intervalId": "2004-02-01:05:06"],
        ]
        let rawData = try! JSONUtility.serialize(data)
        let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats

        let dateComponents = NSDateComponents()
        dateComponents.year = 2004
        dateComponents.month = 2
        dateComponents.day = 1
        dateComponents.hour = 5
        dateComponents.minute = 6
        dateComponents.timeZone = NSTimeZone(name: "UTC") as TimeZone?

        let expected = NSCalendar(identifier: NSCalendar.Identifier.gregorian)?.date(from: dateComponents as DateComponents)

        expect(stats?.intervalTime()).to(equal(expected))
    }

    func test__030__Stats__push__should_return_a_ARTStatsPushCount_object() {
        expect(pushTestsSubject).to(beAnInstanceOf(ARTStatsPushCount.self))
    }

    func test__031__Stats__push__should_return_value_for_messages_count() {
        expect(pushTestsSubject?.messages).to(equal(10))
    }

    func test__032__Stats__push__should_return_value_for_invalid_notifications() {
        expect(pushTestsSubject?.invalid).to(equal(1))
    }

    func test__033__Stats__push__should_return_value_for_attempted_notifications() {
        expect(pushTestsSubject?.attempted).to(equal(2))
    }

    func test__034__Stats__push__should_return_value_for_successful_notifications() {
        expect(pushTestsSubject?.succeeded).to(equal(3))
    }

    func test__035__Stats__push__should_return_value_for_failed_notifications() {
        expect(pushTestsSubject?.failed).to(equal(4))
    }

    func test__036__Stats__push__should_return_value_for_directPublishes() {
        expect(pushTestsSubject?.direct).to(equal(5))
    }

    func test__037__Stats__inProgress__should_return_a_Date_object_representing_the_last_sub_interval_included_in_this_statistic() {
        let dateComponents = NSDateComponents()
        dateComponents.year = 2004
        dateComponents.month = 2
        dateComponents.day = 1
        dateComponents.hour = 5
        dateComponents.minute = 6
        dateComponents.timeZone = NSTimeZone(name: "UTC") as TimeZone?

        let expected = NSCalendar(identifier: NSCalendar.Identifier.gregorian)?.date(from: dateComponents as DateComponents)

        expect(inProgressTestsStats?.dateFromInProgress()).to(equal(expected))
    }

    func test__038__Stats__count__should_return_value_for_number_of_lower_level_stats() {
        expect(countTestStats?.count).to(equal(55))
    }
}
