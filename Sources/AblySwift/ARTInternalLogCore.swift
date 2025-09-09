import Foundation

// swift-migration: original location ARTInternalLogCore.h, line 19 and ARTInternalLogCore.m, line 7
/// `ARTInternalLogCore` is the type underlying `ARTInternalLog`, and defines the logging functionality available to components of the SDK.
///
/// It's responsible for receiving log messages from SDK components, performing additional processing on these messages, and forwarding the result to an object conforming to the `ARTVersion2Log` protocol.
///
/// This protocol exists to give internal SDK components access to a rich and useful logging interface, whilst minimising the complexity (and hence the implementation burden for users of the SDK) of the `ARTVersion2Log` protocol. It also allows us to evolve the logging interface used internally without introducing breaking changes for users of the SDK.
///
/// The initial interface of `ARTInternalLogCore` more or less mirrors that of the `ARTLog` class, for compatibility with existing internal SDK code. However, it will evolve as we gather requirements for the information logged by the SDK — see issues #1623 and #1624.
public protocol ARTInternalLogCore {
    /// - Parameters:
    ///   - fileName: The absolute path of the file from which the log message was emitted (for example, as returned by the `__FILE__` macro).
    // swift-migration: original location ARTInternalLogCore.h, line 25
    func log(_ message: String, withLevel level: ARTLogLevel, file fileName: UnsafePointer<CChar>, line: Int)
    
    // swift-migration: original location ARTInternalLogCore.h, line 27
    var logLevel: ARTLogLevel { get set }
}

// swift-migration: original location ARTInternalLogCore.h, line 35 and ARTInternalLogCore.m, line 7
/// The implementation of `ARTInternalLogCore` that should be used in non-test code.
public class ARTDefaultInternalLogCore: NSObject, ARTInternalLogCore {
    
    // swift-migration: original location ARTInternalLogCore+Testing.h, line 9
    /// Exposed to test suite so that it can make assertions about how the convenience initializers populate it.
    public private(set) var logger: ARTVersion2Log
    
    // swift-migration: original location ARTInternalLogCore.h, line 40 and ARTInternalLogCore.m, line 9
    /// Creates a logger which forwards its generated messages to the given logger.
    public init(logger: ARTVersion2Log) {
        self.logger = logger
        super.init()
    }
    
    // swift-migration: original location ARTInternalLogCore.h, line 46 and ARTInternalLogCore.m, line 17
    /// A convenience initializer which creates a logger initialized with an instance of `ARTLogAdapter` which wraps the given client options' `logHandler`.
    ///
    /// Also, if the client options' `logLevel` is anything other than `ARTLogLevelNone`, this initializer will set the client options' `logHandler`'s `logLevel` such that it matches the client options' `logLevel`. (We offer no judgement here on whether this is the right thing to do or the right place to do it; this is pre-existing behaviour simply moved from elsewhere in the codebase.)
    public convenience init(clientOptions: ARTClientOptions) {
        if clientOptions.logLevel != .none {
            clientOptions.logHandler.logLevel = clientOptions.logLevel
        }
        
        let logger = ARTLogAdapter(logger: clientOptions.logHandler)
        self.init(logger: logger)
    }
    
    // MARK: Logging
    
    // swift-migration: original location ARTInternalLogCore.h, line 25 and ARTInternalLogCore.m, line 28
    public func log(_ message: String, withLevel level: ARTLogLevel, file fileName: UnsafePointer<CChar>, line: Int) {
        let fileNameNSString = String(cString: fileName)
        let lastPathComponent = (fileNameNSString as NSString).lastPathComponent
        logger.log(message, withLevel: level, file: lastPathComponent, line: line)
    }
    
    // MARK: Log level
    
    // swift-migration: original location ARTInternalLogCore.h, line 27 and ARTInternalLogCore.m, line 36
    public var logLevel: ARTLogLevel {
        get {
            return logger.logLevel
        }
        set {
            logger.logLevel = newValue
        }
    }
}