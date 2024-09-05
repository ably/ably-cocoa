import Ably.Private

@objc(ARTMockInternalLogCore)
class MockInternalLogCore: NSObject, InternalLogCore {
    var logLevel: LogLevel = .none

    var lastReceivedLogMessageArguments: (message: String, level: LogLevel, fileName: UnsafePointer<CChar>, line: Int)?
    @objc var lastReceivedLogMessageArgumentMessage: String?
    @objc var lastReceivedLogMessageArgumentLevel: LogLevel = .none
    @objc var lastReceivedLogMessageArgumentFileName: UnsafePointer<CChar>?
    @objc var lastReceivedLogMessageArgumentLine: Int = -1

    func log(_ message: String, with level: LogLevel, file fileName: UnsafePointer<CChar>, line: Int) {
        lastReceivedLogMessageArguments = (message: message, level: level, fileName: fileName, line: line)
        lastReceivedLogMessageArgumentMessage = message
        lastReceivedLogMessageArgumentLevel = level
        lastReceivedLogMessageArgumentFileName = fileName
        lastReceivedLogMessageArgumentLine = line
    }
}
