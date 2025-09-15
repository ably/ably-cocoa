import Foundation
import _AblyPluginSupportPrivate

// swift-migration: Implement the logging macro functionality as Swift functions
// swift-migration: Using default arguments to inject #fileID and #line values

public func ARTLogVerbose(_ logger: ARTInternalLog, _ format: String, _ args: CVarArg..., fileID: String = #fileID, line: Int = #line) {
    let message = String(format: format, arguments: args)
    logger.log(message, withLevel: .verbose, file: fileID, line: line)
}

public func ARTLogDebug(_ logger: ARTInternalLog, _ format: String, _ args: CVarArg..., fileID: String = #fileID, line: Int = #line) {
    let message = String(format: format, arguments: args)
    logger.log(message, withLevel: .debug, file: fileID, line: line)
}

public func ARTLogInfo(_ logger: ARTInternalLog, _ format: String, _ args: CVarArg..., fileID: String = #fileID, line: Int = #line) {
    let message = String(format: format, arguments: args)
    logger.log(message, withLevel: .info, file: fileID, line: line)
}

public func ARTLogWarn(_ logger: ARTInternalLog, _ format: String, _ args: CVarArg..., fileID: String = #fileID, line: Int = #line) {
    let message = String(format: format, arguments: args)
    logger.log(message, withLevel: .warn, file: fileID, line: line)
}

public func ARTLogError(_ logger: ARTInternalLog, _ format: String, _ args: CVarArg..., fileID: String = #fileID, line: Int = #line) {
    let message = String(format: format, arguments: args)
    logger.log(message, withLevel: .error, file: fileID, line: line)
}

public func ARTPrint(_ logger: ARTInternalLog, _ format: String, _ args: CVarArg..., fileID: String = #fileID, line: Int = #line) {
    let message = String(format: format, arguments: args)
    logger.log(message, withLevel: .none, file: fileID, line: line)
}

// swift-migration: original location ARTInternalLog.h, line 37 and ARTInternalLog.m, line 7
/**
 `ARTInternalLog` is the logging class used internally by the SDK. It provides a thin wrapper over `ARTInternalLogCore`, providing variadic versions of that protocol's methods.

 - Note: It would be great if we could make `ARTInternalLog` a protocol (with a default implementation) instead of a class, since this would make it easier to test the logging behaviour of the SDK. However, since its interface currently makes heavy use of variadic Objective-C methods, which cannot be represented in Swift, we would be unable to write mocks for this protocol in our Swift test suite. As the `ARTInternalLog` interface evolves we may end up removing these variadic methods, in which case we can reconsider.
 */
public class ARTInternalLog: NSObject, _AblyPluginSupportPrivate.Logger {

    // swift-migration: original location ARTInternalLog+Testing.h, line 9
    public var core: any ARTInternalLogCore
    
    // swift-migration: original location ARTInternalLog.h, line 48 and ARTInternalLog.m, line 9
    /**
     Provides a shared logger to be used by all public class methods meeting the following criteria:

     - they wish to perform logging
     - they do not have access to any more appropriate logger
     - their signature is already locked since they are part of the public API of the library

     Currently, this returns a logger that will not actually output any log messages, but I've created https://github.com/ably/ably-cocoa/issues/1652 for us to revisit this.
     */
    public static var sharedClassMethodLogger_readDocumentationBeforeUsing: ARTInternalLog = {
        let artLog = ARTLog()
        artLog.logLevel = .none
        let version2Log: any Version2Log = LogAdapter(logger: artLog)
        let core: any ARTInternalLogCore = DefaultInternalLogCore(logger: version2Log)
        return ARTInternalLog(core: core)
    }()
    
    // swift-migration: original location ARTInternalLog.h, line 53 and ARTInternalLog.m, line 23
    /**
     Creates a logger which forwards its generated messages to the given core object.
     */
    public init(core: any ARTInternalLogCore) {
        self.core = core
        super.init()
    }
    
    // swift-migration: original location ARTInternalLog.h, line 58 and ARTInternalLog.m, line 31
    /**
     A convenience initializer which creates a logger whose core is an instance of `ARTDefaultInternalLogCore` wrapping the given logger.
     */
    public convenience init(logger: any Version2Log) {
        let core: any ARTInternalLogCore = DefaultInternalLogCore(logger: logger)
        self.init(core: core)
    }
    
    // swift-migration: original location ARTInternalLog.h, line 62 and ARTInternalLog.m, line 36
    /**
     A convenience initializer which creates a logger whose core is an instance of `ARTDefaultInternalLogCore` initialized with that class's `initWithClientOptions:` initializer.
     */
    public convenience init(clientOptions: ARTClientOptions) {
        let core: any ARTInternalLogCore = DefaultInternalLogCore(clientOptions: clientOptions)
        self.init(core: core)
    }
    
    // MARK: Logging
    
    // swift-migration: original location ARTInternalLog.h, line 73 and ARTInternalLog.m, line 43
    /**
     Passes the arguments through to the logger's core object.

     It is not directly used by the internals of the `Ably` library, but it is used by:

     - some of our Swift tests (which can't access the variadic method below), which want to be able to call a logging method on an instance of `ARTInternalLog`
     - `ARTPluginAPI`, to implement its conformance to the `APPluginAPIProtocol` protocol, which is used by plugins written in Swift
    */
    public func log(_ message: String, withLevel level: ARTLogLevel, file fileName: String, line: Int) {
        core.log(message, withLevel: level, file: fileName, line: line)
    }
    
    // swift-migration: original location ARTInternalLog.h, line 76 and ARTInternalLog.m, line 47
    // This method should not be called directly — it is for use by the ARTLog* macros. It is tested via the tests of the macros.
    public func log(withLevel level: ARTLogLevel, file fileName: String, line: UInt, format: String, _ args: CVarArg...) {
        if self.logLevel.rawValue <= level.rawValue {
            let message = String(format: format, arguments: args)
            log(message, withLevel: level, file: fileName, line: Int(line))
        }
    }
    
    // MARK: Log level
    
    // swift-migration: original location ARTInternalLog.h, line 78 and ARTInternalLog.m, line 59
    public var logLevel: ARTLogLevel {
        get {
            return core.logLevel
        }
        set {
            core.logLevel = newValue
        }
    }
}
