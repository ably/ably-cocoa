import XCTest

import Ably.ARTClientOptions

class ClientOptionsTests: XCTestCase {
    
    func testAgentLibraryIdentifier() {
        let options = ARTClientOptions()
        
        let agents = [
            "demolib": "0.0.1",
            "morelib": ARTClientOptionsAgentNotVersioned
        ]
        options.agents = agents
        
        let expectedIdentifier = "\(ARTDefault.libraryAgent()) demolib/0.0.1 morelib \(ARTDefault.platformAgent())"
        XCTAssertEqual(options.agentLibraryIdentifier(), expectedIdentifier)
    }
}
