import XCTest

import Ably.ARTClientOptions

class ClientOptionsTests: XCTestCase {
    
    func testAgentLibraryIdentifier() {
        let agents = [
            "demolib": "0.0.1",
            "morelib": "1.0.3"
        ]
        
        let options = ARTClientOptions()
        options.agents = agents
        
        let expectedIdentifier = "\(ARTDefault.libraryAgent()) demolib/0.0.1 morelib/1.0.3 \(ARTDefault.platformAgent())"
        XCTAssertEqual(options.agentLibraryIdentifier(), expectedIdentifier)
    }
}
