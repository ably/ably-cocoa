import XCTest
import Ably.Private

class LogAdapterTests: XCTestCase {
    class MockARTLog: ARTLog {
        var lastReceivedLogMessageArguments: (message: String, level: ARTLogLevel)?
        var lastReceivedLogErrorArgument: ARTErrorInfo?

        override func log(_ message: String, with level: ARTLogLevel) {
            lastReceivedLogMessageArguments = (message: message, level: level)
        }

        override func logWithError(_ error: ARTErrorInfo) {
            lastReceivedLogErrorArgument = error
        }
    }

    func test_logMessage() {
        let underlyingLogger = MockARTLog()
        let logger = LogAdapter(logger: underlyingLogger)

        let logLevels: [ARTLogLevel] = [.verbose, .debug, .info, .warn, .error, .none]
        for (index, level) in logLevels.enumerated() {
            let message = "Message \(index)"
            logger.log(message, with: level)

            let logged = underlyingLogger.lastReceivedLogMessageArguments!
            XCTAssertEqual(logged.level, level)
            XCTAssertEqual(logged.message, message)
        }
    }

    func test_logError() {
        let underlyingLogger = MockARTLog()
        let logger = LogAdapter(logger: underlyingLogger)

        let error = ARTErrorInfo.createUnknownError()
        logger.logWithError(error)

        let logged = underlyingLogger.lastReceivedLogErrorArgument!
        XCTAssertEqual(logged, error)
    }

    func test_logLevel() {
        let underlyingLogger = ARTLog()
        underlyingLogger.logLevel = .info
        let logger = LogAdapter(logger: underlyingLogger)

        XCTAssertEqual(logger.logLevel, .info)
    }

    func test_setLogLevel() {
        let underlyingLogger = ARTLog()
        underlyingLogger.logLevel = .info
        let logger = LogAdapter(logger: underlyingLogger)

        logger.logLevel = .debug
        XCTAssertEqual(underlyingLogger.logLevel, .debug)
    }
}
