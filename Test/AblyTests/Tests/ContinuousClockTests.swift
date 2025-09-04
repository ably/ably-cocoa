import XCTest
import Ably.Private

class ContinuousClockTests: XCTestCase {
    func test_isAfter() {
        let clock = ARTContinuousClock()

        let preSleepNow = clock.now()
        // Sleep for 0.25s
        usleep(UInt32(0.25 * Double(USEC_PER_SEC)))
        let postSleepNow = clock.now()

        XCTAssertTrue(postSleepNow.isAfter(preSleepNow))
    }

    func test_advancedBy() {
        let clock = ARTContinuousClock()

        let preSleepNow = clock.now()
        let advancedByQuarterSecond = clock.addingDuration(0.25, to: preSleepNow)
        let advancedByOneSecond = clock.addingDuration(1, to: preSleepNow)

        // Sleep for 0.5s
        usleep(UInt32(0.5 * Double(USEC_PER_SEC)))

        let postSleepNow = clock.now()
        XCTAssertFalse(advancedByQuarterSecond.isAfter(postSleepNow))
        XCTAssertTrue(advancedByOneSecond.isAfter(postSleepNow))
    }
}
