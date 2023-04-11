import Ably.Private

@objc(ARTMockInternalLogBackend)
class MockInternalLogBackend: NSObject, InternalLogBackend {
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
