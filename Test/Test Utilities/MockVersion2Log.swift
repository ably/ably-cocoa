import Ably.Private

class MockVersion2Log: Version2Log {
    var logLevel: ARTLogLevel = .none

    var lastReceivedLogMessageArguments: (message: String, level: ARTLogLevel)?
    var lastReceivedLogErrorArgument: ARTErrorInfo?

    func log(_ message: String, with level: ARTLogLevel) {
        lastReceivedLogMessageArguments = (message: message, level: level)
    }

     func logWithError(_ error: ARTErrorInfo) {
        lastReceivedLogErrorArgument = error
    }
}
