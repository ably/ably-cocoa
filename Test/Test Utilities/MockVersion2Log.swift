import Ably.Private

@objc(ARTMockVersion2Log) class MockVersion2Log: NSObject, Version2Log {
    var logLevel: ARTLogLevel = .none

    var lastReceivedLogMessageArguments: (message: String, level: ARTLogLevel)?
    @objc var lastReceivedLogMessageArgumentMessage: String?
    @objc var lastReceivedLogMessageArgumentLevel: ARTLogLevel = .none

    func log(_ message: String, with level: ARTLogLevel) {
        lastReceivedLogMessageArguments = (message: message, level: level)
        lastReceivedLogMessageArgumentMessage = message
        lastReceivedLogMessageArgumentLevel = level
    }
}
