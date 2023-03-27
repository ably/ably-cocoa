import XCTest
import Ably.Private

class InternalLogTests: XCTestCase {
    func test_logMessage() {
        let mock = MockVersion2Log()
        let internalLog = InternalLog(logger: mock)

        let logLevels: [ARTLogLevel] = [.verbose, .debug, .info, .warn, .error, .none]
        for (index, level) in logLevels.enumerated() {
            let message = "Message \(index)"
            internalLog.log(message, with: level)

            let logged = mock.lastReceivedLogMessageArguments!
            XCTAssertEqual(logged.level, level)
            XCTAssertEqual(logged.message, message)
        }
    }

    func test_logError() {
        let mock = MockVersion2Log()
        let internalLog = InternalLog(logger: mock)

        let error = ARTErrorInfo.createUnknownError()
        internalLog.logWithError(error)

        let logged = mock.lastReceivedLogErrorArgument!
        XCTAssertEqual(logged, error)
    }

    func test_logLevel() {
        let mock = MockVersion2Log()
        mock.logLevel = .info
        let internalLog = InternalLog(logger: mock)

        XCTAssertEqual(internalLog.logLevel, .info)
    }

    func test_setLogLevel() {
        let mock = MockVersion2Log()
        mock.logLevel = .info
        let internalLog = InternalLog(logger: mock)

        internalLog.logLevel = .debug
        XCTAssertEqual(mock.logLevel, .debug)
    }
}
