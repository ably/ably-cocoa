import Foundation
import Ably
import Ably.Private
import XCTest

class ARTFilteredMessageCallbackFactoryTests: XCTestCase {

    func test_returnedInstanceCallsMessageHandlerIfFilterPasses()
    {
        let filter = ARTMessageFilter();
        filter.clientId = "clientId";

        var functionCalled = false;
        let filteredHandler = ARTFilteredMessageCallbackFactory.createFilteredCallback(
            { (message: ARTMessage) in
                functionCalled = true
            },
            filter: filter);

        let message = ARTMessage(name: "name", data: "abc", clientId: "clientId");
        filteredHandler(message)

        XCTAssertTrue(functionCalled);
    }

    func test_returnedInstanceDoesntCallMessageHandlerIfFilterPasses()
    {
        let filter = ARTMessageFilter();
        filter.clientId = "clientId";

        var functionCalled = false;
        let filteredHandler = ARTFilteredMessageCallbackFactory.createFilteredCallback(
            { (message: ARTMessage) in
                functionCalled = true
            },
            filter: filter);

        let message = ARTMessage(name: "name", data: "abc", clientId: "clientId2");
        filteredHandler(message)

        XCTAssertFalse(functionCalled);
    }
}
