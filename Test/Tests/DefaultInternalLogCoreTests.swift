import XCTest
import Ably.Private

class DefaultInternalLogCoreTests: XCTestCase {
    func test_logMessage() {
        let mock = MockVersion2Log()
        let core = DefaultInternalLogCore(logger: mock)

        let logLevels: [ARTLogLevel] = [.verbose, .debug, .info, .warn, .error, .none]
        for (index, level) in logLevels.enumerated() {
            let message = "Message \(index)"
            core.log(message, with: level, file: "/foo/bar/myFile.m", line: 123)

            let logged = mock.lastReceivedLogMessageArguments!
            XCTAssertEqual(logged.level, level)
            XCTAssertEqual(logged.message, message)
            XCTAssertEqual(logged.fileName, "myFile.m")
            XCTAssertEqual(logged.line, 123)
        }
    }

    func test_logLevel() {
        let mock = MockVersion2Log()
        mock.logLevel = .info
        let core = DefaultInternalLogCore(logger: mock)

        XCTAssertEqual(core.logLevel, .info)
    }

    func test_setLogLevel() {
        let mock = MockVersion2Log()
        mock.logLevel = .info
        let core = DefaultInternalLogCore(logger: mock)

        core.logLevel = .debug
        XCTAssertEqual(mock.logLevel, .debug)
    }
}
