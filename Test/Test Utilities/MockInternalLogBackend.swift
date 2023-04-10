import Ably.Private

@objc(ARTMockInternalLogBackend)
class MockInternalLogBackend: NSObject, InternalLogBackend {
    var logLevel: ARTLogLevel = .none

    var lastReceivedLogMessageArguments: (message: String, level: ARTLogLevel, fileName: UnsafePointer<CChar>?, line: Int?)?
    @objc var lastReceivedLogMessageArgumentMessage: String?
    @objc var lastReceivedLogMessageArgumentLevel: ARTLogLevel = .none
    @objc var lastReceivedLogMessageArgumentFileName: UnsafePointer<CChar>?
    @objc var lastReceivedLogMessageArgumentLine: Int = -1

    func log(_ message: String, with level: ARTLogLevel) {
        lastReceivedLogMessageArguments = (message: message, level: level, fileName: nil, line: nil)
        lastReceivedLogMessageArgumentMessage = message
        lastReceivedLogMessageArgumentLevel = level
        lastReceivedLogMessageArgumentFileName = nil
        lastReceivedLogMessageArgumentLine = -1
    }

    func log(_ message: String, with level: ARTLogLevel, file fileName: UnsafePointer<CChar>, line: Int) {
        lastReceivedLogMessageArguments = (message: message, level: level, fileName: fileName, line: line)
        lastReceivedLogMessageArgumentMessage = message
        lastReceivedLogMessageArgumentLevel = level
        lastReceivedLogMessageArgumentFileName = fileName
        lastReceivedLogMessageArgumentLine = line
    }
}
