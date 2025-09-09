import Foundation

// swift-migration: original location ARTLogAdapter.h, line 15 and ARTLogAdapter.m, line 5
internal class ARTLogAdapter: NSObject, ARTVersion2Log {
    
    // swift-migration: original location ARTLogAdapter+Testing.h, line 9 and ARTLogAdapter.m, line 9
    internal let logger: ARTLog
    
    // swift-migration: original location ARTLogAdapter.h, line 17
    private override init() {
        fatalError("init() is not available")
    }
    
    // swift-migration: original location ARTLogAdapter.h, line 25 and ARTLogAdapter.m, line 7
    internal init(logger: ARTLog) {
        self.logger = logger
        super.init()
    }
    
    // swift-migration: original location ARTLogAdapter.m, line 15
    func log(_ message: String, withLevel level: ARTLogLevel, file fileName: String, line: Int) {
        let augmentedMessage = "(\(fileName):\(line)) \(message)"
        logger.log(augmentedMessage, withLevel: level)
    }
    
    // swift-migration: original location ARTLogAdapter.h, line 30 and ARTLogAdapter.m, line 20
    var logLevel: ARTLogLevel {
        get {
            return logger.logLevel
        }
        set {
            logger.logLevel = newValue
        }
    }
}