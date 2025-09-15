@testable import AblySwift
import Foundation

public class MockInternalLogCore: NSObject, InternalLogCore {
    public var logLevel: ARTLogLevel = .none

    var lastReceivedLogMessageArguments: (message: String, level: ARTLogLevel, fileName: UnsafePointer<CChar>, line: Int)?
    public var lastReceivedLogMessageArgumentMessage: String?
    public var lastReceivedLogMessageArgumentLevel: ARTLogLevel = .none
    public var lastReceivedLogMessageArgumentFileName: UnsafePointer<CChar>?
    public var lastReceivedLogMessageArgumentLine: Int = -1

    public func log(_ message: String, with level: ARTLogLevel, file fileName: UnsafePointer<CChar>, line: Int) {
        lastReceivedLogMessageArguments = (message: message, level: level, fileName: fileName, line: line)
        lastReceivedLogMessageArgumentMessage = message
        lastReceivedLogMessageArgumentLevel = level
        lastReceivedLogMessageArgumentFileName = fileName
        lastReceivedLogMessageArgumentLine = line
    }
}
