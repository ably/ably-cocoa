import XCTest

import Ably.ARTDefault // System under Test

class ARTDefaultTests: XCTestCase {
    func testVersions() {
        XCTAssertEqual(ARTDefault.version(), "1.2")
    }
}
