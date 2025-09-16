import XCTest

@testable import AblySwift // System under Test

class ARTDefaultTests: XCTestCase {
    
    func testVersions() {
        XCTAssertEqual(ARTDefault.apiVersion(), "2")
        XCTAssertEqual(ARTDefault.libraryVersion(), "1.2.44")
    }
}
