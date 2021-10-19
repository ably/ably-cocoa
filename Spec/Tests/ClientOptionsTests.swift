import XCTest

import Ably.ARTClientOptions

class ClientOptionsTests: XCTestCase {
    
    func testAddAgent() {
        let options = ARTClientOptions()
        options.addAgent("demolib", version: "0.0.1")
        options.addAgent("morelib", version: nil)
        let agents = "\(ARTDefault.libraryAgent()) demolib/0.0.1 morelib \(ARTDefault.platformAgent())"
        XCTAssertEqual(options.agents(), agents)
    }
}
