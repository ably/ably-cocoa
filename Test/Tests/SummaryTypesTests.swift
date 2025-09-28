import XCTest
@testable import Ably

class SummaryTypesTests: XCTestCase {
    
    // MARK: - ARTSummaryClientIdList Tests (TM7c1)
    
    func test__summaryClientIdList__parses_from_dictionary() {
        let dictionary: [String: Any] = [
            "total": 3,
            "clientIds": ["client1", "client2", "client3"]
        ]
        
        let summary = ARTSummaryClientIdList.create(from: dictionary)
        
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.total, 3)
        XCTAssertEqual(summary?.clientIds, ["client1", "client2", "client3"])
    }
    
    func test__summaryClientIdList__returns_nil_for_invalid_dictionary() {
        let invalidDictionary: [String: Any] = [
            "total": 3,
            "clientIds": [123, 456] // Invalid - should be strings
        ]
        
        let summary = ARTSummaryClientIdList.create(from: invalidDictionary)
        
        XCTAssertNil(summary)
    }
    
    func test__summaryClientIdList__writes_to_dictionary() {
        let summary = ARTSummaryClientIdList(total: 2, clientIds: ["user1", "user2"])
        let dictionary = NSMutableDictionary()
        
        summary.write(to: dictionary)
        
        XCTAssertEqual(dictionary["total"] as? NSNumber, NSNumber(value: 2))
        XCTAssertEqual(dictionary["clientIds"] as? [String], ["user1", "user2"])
    }
    
    // MARK: - ARTSummaryClientIdCounts Tests (TM7d1)
    
    func test__summaryClientIdCounts__parses_from_dictionary() {
        let dictionary: [String: Any] = [
            "total": 10,
            "clientIds": [
                "client1": 5,
                "client2": 3,
                "client3": 2
            ]
        ]
        
        let summary = ARTSummaryClientIdCounts.create(from: dictionary)
        
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.total, 10)
        XCTAssertEqual(summary?.clientIds["client1"], NSNumber(value: 5))
        XCTAssertEqual(summary?.clientIds["client2"], NSNumber(value: 3))
        XCTAssertEqual(summary?.clientIds["client3"], NSNumber(value: 2))
    }
    
    func test__summaryClientIdCounts__parses_string_numbers_from_dictionary() {
        let dictionary: [String: Any] = [
            "total": 8,
            "clientIds": [
                "client1": "5", // String number should be converted
                "client2": 3    // Regular number should work
            ]
        ]
        
        let summary = ARTSummaryClientIdCounts.create(from: dictionary)
        
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.total, 8)
        XCTAssertEqual(summary?.clientIds["client1"], NSNumber(value: 5))
        XCTAssertEqual(summary?.clientIds["client2"], NSNumber(value: 3))
    }
    
    func test__summaryClientIdCounts__returns_nil_for_invalid_values() {
        let invalidDictionary: [String: Any] = [
            "total": 5,
            "clientIds": [
                "client1": 3,
                "client2": "invalid_number" // Invalid string that can't be converted
            ]
        ]
        
        let summary = ARTSummaryClientIdCounts.create(from: invalidDictionary)
        
        XCTAssertNil(summary)
    }
    
    func test__summaryClientIdCounts__writes_to_dictionary() {
        let clientIds = ["user1": NSNumber(value: 4), "user2": NSNumber(value: 6)]
        let summary = ARTSummaryClientIdCounts(total: 10, clientIds: clientIds)
        let dictionary = NSMutableDictionary()
        
        summary.write(to: dictionary)
        
        XCTAssertEqual(dictionary["total"] as? NSNumber, NSNumber(value: 10))
        let writtenClientIds = dictionary["clientIds"] as? [String: NSNumber]
        XCTAssertEqual(writtenClientIds?["user1"], NSNumber(value: 4))
        XCTAssertEqual(writtenClientIds?["user2"], NSNumber(value: 6))
    }
    
    // MARK: - ARTSummaryTotal Tests (TM7e1)
    
    func test__summaryTotal__parses_from_dictionary() {
        let dictionary: [String: Any] = [
            "total": 42
        ]
        
        let summary = ARTSummaryTotal.create(from: dictionary)
        
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.total, 42)
    }
    
    func test__summaryTotal__parses_string_number_from_dictionary() {
        let dictionary: [String: Any] = [
            "total": "123" // String number should be converted to integer
        ]
        
        let summary = ARTSummaryTotal.create(from: dictionary)
        
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.total, 123)
    }
    
    func test__summaryTotal__writes_to_dictionary() {
        let summary = ARTSummaryTotal(total: 99)
        let dictionary = NSMutableDictionary()
        
        summary.write(to: dictionary)
        
        XCTAssertEqual(dictionary["total"] as? NSNumber, NSNumber(value: 99))
    }
    
    func test__summaryClientIdList__with_additional_properties() {
        let dictionary: [String: Any] = [
            "total": 5,
            "clientIds": ["client1", "client2"],
            "clipped": true
        ]
        
        let summary = ARTSummaryClientIdList.create(from: dictionary)
        
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.total, 5)
        XCTAssertEqual(summary?.clientIds, ["client1", "client2"])
        XCTAssertEqual(summary?.clipped, true)
    }
    
    func test__summaryClientIdCounts__with_additional_properties() {
        let dictionary: [String: Any] = [
            "total": 8,
            "clientIds": ["client1": 3, "client2": 2],
            "clipped": false,
            "totalUnidentified": 1,
            "totalClientIds": 5
        ]
        
        let summary = ARTSummaryClientIdCounts.create(from: dictionary)
        
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.total, 8)
        XCTAssertEqual(summary?.clientIds["client1"], NSNumber(value: 3))
        XCTAssertEqual(summary?.clientIds["client2"], NSNumber(value: 2))
        XCTAssertEqual(summary?.clipped, false)
        XCTAssertEqual(summary?.totalUnidentified, 1)
        XCTAssertEqual(summary?.totalClientIds, 5)
    }
    
    // MARK: - ARTMessageAnnotations Extension Tests
    
    func test__messageAnnotations__extension_methods() {
        let annotations = ARTMessageAnnotations()
        annotations.summary = [
            "reaction:unique.v1": [
                "like": ["total": 2, "clientIds": ["userOne", "userTwo"]],
                "love": ["total": 1, "clientIds": ["userThree"]],
            ],
            "reaction:distinct.v1": [
                "like": ["total": 2, "clientIds": ["userOne", "userTwo"]],
                "love": ["total": 1, "clientIds": ["userOne"]],
            ],
            "reaction:multiple.v1": [
                "like": ["total": 5, "clientIds": ["userOne": 3, "userTwo": 2]],
                "love": ["total": 10, "clientIds": ["userOne": 10]],
            ],
        ]
        
        let uniqueSummary = annotations.summaryUniqueV1()
        XCTAssertNotNil(uniqueSummary)
        XCTAssertEqual(uniqueSummary?["like"]?.total, 2)
        XCTAssertEqual(uniqueSummary?["love"]?.total, 1)
        XCTAssertEqual(uniqueSummary?["like"]?.clientIds.count, 2)
        XCTAssertEqual(uniqueSummary?["love"]?.clientIds.count, 1)
        XCTAssertTrue(uniqueSummary?["like"]?.clientIds.contains("userOne") ?? false)
        XCTAssertTrue(uniqueSummary?["like"]?.clientIds.contains("userTwo") ?? false)
        XCTAssertTrue(uniqueSummary?["love"]?.clientIds.contains("userThree") ?? false)
        
        let distinctSummary = annotations.summaryDistinctV1()
        XCTAssertNotNil(distinctSummary)
        XCTAssertEqual(distinctSummary?["like"]?.total, 2)
        XCTAssertEqual(distinctSummary?["love"]?.total, 1)
        XCTAssertEqual(distinctSummary?["like"]?.clientIds.count, 2)
        XCTAssertEqual(distinctSummary?["love"]?.clientIds.count, 1)
        XCTAssertTrue(distinctSummary?["like"]?.clientIds.contains("userOne") ?? false)
        XCTAssertTrue(distinctSummary?["like"]?.clientIds.contains("userTwo") ?? false)
        XCTAssertTrue(distinctSummary?["love"]?.clientIds.contains("userOne") ?? false)
        
        let multipleSummary = annotations.summaryMultipleV1()
        XCTAssertNotNil(multipleSummary)
        XCTAssertEqual(multipleSummary?["like"]?.total, 5)
        XCTAssertEqual(multipleSummary?["love"]?.total, 10)
        XCTAssertEqual(multipleSummary?["like"]?.clientIds.count, 2)
        XCTAssertEqual(multipleSummary?["love"]?.clientIds.count, 1)
        XCTAssertEqual(multipleSummary?["like"]?.clientIds["userOne"], NSNumber(value: 3))
        XCTAssertEqual(multipleSummary?["like"]?.clientIds["userTwo"], NSNumber(value: 2))
        XCTAssertEqual(multipleSummary?["love"]?.clientIds["userOne"], NSNumber(value: 10))
    }
}
