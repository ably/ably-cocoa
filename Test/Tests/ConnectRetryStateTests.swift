import XCTest
import Ably.Private

class ConnectRetryStateTests: XCTestCase {
    func test_addRetryAttempt() {
        // Given: an ConnectRetryState initialized with a delay calculator that returns arbitrary values from its `delay(forRetryNumber:)` method...
        let delays: [TimeInterval] = [0.1, 0.3, 0.9]
        let calculator = MockRetryDelayCalculator(delays: delays)

        let retryState = ConnectRetryState(retryDelayCalculator: calculator,
                                          logger: .init(core: MockInternalLogCore()),
                                          logMessagePrefix: "")

        // When: addRetryAttempt is called an arbitrarily-chosen number n ( = 3) times on the connect retry state...
        let firstRetryAttempt = retryState.addRetryAttempt()
        let secondRetryAttempt = retryState.addRetryAttempt()
        let thirdRetryAttempt = retryState.addRetryAttempt()

        // Then: the list of `delay` properties of the returned RetryAttempt objects matches those returned by the calculator’s `delay(forRetryNumber: x)` method for x = 1, ... , n.
        XCTAssertEqual(firstRetryAttempt.delay, delays[0])
        XCTAssertEqual(secondRetryAttempt.delay, delays[1])
        XCTAssertEqual(thirdRetryAttempt.delay, delays[2])
    }
}
