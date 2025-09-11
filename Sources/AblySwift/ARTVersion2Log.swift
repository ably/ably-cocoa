import Foundation

/**
 The `ARTVersion2Log` protocol represents a logger object that handles data emitted by the SDK's logging system. It will be renamed `ARTLog` in the next major release of the SDK (replacing the existing class), at which point users of the SDK will need to provide an implementation of this protocol if they wish to replace the SDK's default logger.

 The initial interface of `ARTVersion2Log` is based on that of the `ARTLog` class. However, its design will evolve as we gather further information about the following things:

 1. Requirements for the information logged by the SDK — see issues #1623 and #1624.

 2. Requirements for the data emitted by the SDK's logging system — see issues #1618 and #1625.
 */
// swift-migration: original location ARTVersion2Log.h, line 16
public protocol ARTVersion2Log: NSObjectProtocol {
    
    // swift-migration: original location ARTVersion2Log.h, line 18
    var logLevel: ARTLogLevel { get set }
    
    /**
     - Parameters:
       - fileName: The base name (e.g. given an absolute path `/foo/bar/baz`, its base name is `baz`) of the file from which the log message was emitted.
     */
    // swift-migration: original location ARTVersion2Log.h, line 24
    func log(_ message: String, withLevel level: ARTLogLevel, file fileName: String, line: Int)
}