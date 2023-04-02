import XCTest
import Ably.Private

class ConstantRetryDelayCalculatorTests: XCTestCase {
    func test_returnsConstantDelay() {
        let constantDelay: TimeInterval = 2
        let calculator = ConstantRetryDelayCalculator(constantDelay: constantDelay)

        XCTAssertEqual(calculator.delay(forRetryNumber: 1), constantDelay)
        XCTAssertEqual(calculator.delay(forRetryNumber: 100), constantDelay)
    }
}
