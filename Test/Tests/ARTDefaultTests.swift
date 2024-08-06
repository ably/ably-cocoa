import XCTest

import Ably.ARTDefault // System under Test

class ARTDefaultTests: XCTestCase {
    
    func testVersions() {
        XCTAssertEqual(Default.apiVersion(), "2")
        XCTAssertEqual(Default.libraryVersion(), "1.2.33")
    }
}
