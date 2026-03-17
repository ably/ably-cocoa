import XCTest

import Ably.ARTDefault // System under Test

class ARTDefaultTests: XCTestCase {

    func testVersions() {
        XCTAssertEqual(ARTDefault.apiVersion(), "6")
        XCTAssertEqual(ARTDefault.libraryVersion(), "1.2.60")
    }
}
