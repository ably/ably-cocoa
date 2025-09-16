import Foundation

// swift-migration: original location ARTLog.h, line 8
/// :nodoc:
public enum ARTLogLevel: UInt {
    case verbose = 0
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4
    case none = 5
}

// swift-migration: original location ARTLog.m, line 4
private func logLevelName(_ level: ARTLogLevel) -> String {
    switch level {
    case .none:
        return ""
    case .verbose:
        return "VERBOSE"
    case .debug:
        return "DEBUG"
    case .info:
        return "INFO"
    case .warn:
        return "WARN"
    case .error:
        return "ERROR"
    }
}

// swift-migration: original location ARTLog+Private.h, line 5 and ARTLog.m, line 23
internal class ARTLogLine: NSObject, NSCoding {
    
    // swift-migration: original location ARTLog+Private.h, line 7
    internal let date: Date
    // swift-migration: original location ARTLog+Private.h, line 8
    internal let level: ARTLogLevel
    // swift-migration: original location ARTLog+Private.h, line 9
    internal let message: String
    
    // swift-migration: original location ARTLog+Private.h, line 11 and ARTLog.m, line 25
    internal init(date: Date, level: ARTLogLevel, message: String) {
        self.date = date
        self.level = level
        self.message = message
        super.init()
    }
    
    // swift-migration: original location ARTLog+Private.h, line 13 and ARTLog.m, line 35
    internal func toString() -> String {
        return "\(logLevelName(self.level)): \(self.message)"
    }
    
    // swift-migration: original location ARTLog.m, line 39
    public override var description: String {
        return toString()
    }
    
    // MARK: - NSCoding
    
    // swift-migration: original location ARTLog.m, line 45
    public required init?(coder decoder: NSCoder) {
        guard let date = decoder.decodeObject(forKey: "date") as? Date,
              let levelNumber = decoder.decodeObject(forKey: "level") as? NSNumber,
              let message = decoder.decodeObject(forKey: "message") as? String else {
            return nil
        }
        self.date = date
        self.level = ARTLogLevel(rawValue: levelNumber.uintValue) ?? .error
        self.message = message
        super.init()
    }
    
    // swift-migration: original location ARTLog.m, line 56
    public func encode(with encoder: NSCoder) {
        encoder.encode(date, forKey: "date")
        encoder.encode(NSNumber(value: level.rawValue), forKey: "level")
        encoder.encode(message, forKey: "message")
    }
}

// swift-migration: original location ARTLog.h, line 18 and ARTLog.m, line 64
public class ARTLog: NSObject {
    
    // swift-migration: original location ARTLog.h, line 20
    public var logLevel: ARTLogLevel = .warn
    
    // swift-migration: original location ARTLog.m, line 65
    internal var captured: [ARTLogLine]?
    // swift-migration: original location ARTLog.m, line 66
    internal var history: [ARTLogLine]
    // swift-migration: original location ARTLog.m, line 67
    private let historyLines: Int
    // swift-migration: original location ARTLog.m, line 68
    private let queue: DispatchQueue
    
    // swift-migration: original location ARTLog.m, line 71
    public override init() {
        self.logLevel = .warn
        self.captured = []
        self.history = []
        self.historyLines = 100
        self.queue = DispatchQueue(label: "io.ably.log", qos: .utility)
        super.init()
    }
    
    // swift-migration: original location ARTLog+Private.h, line 22 and ARTLog.m, line 75
    internal init(capturingOutput capturing: Bool) {
        self.logLevel = .warn
        self.captured = capturing ? [] : nil
        self.history = []
        self.historyLines = 100
        self.queue = DispatchQueue(label: "io.ably.log", qos: .utility)
        super.init()
    }
    
    // swift-migration: original location ARTLog+Private.h, line 23 and ARTLog.m, line 79
    internal init(capturingOutput capturing: Bool, historyLines: Int) {
        self.logLevel = .warn
        self.captured = capturing ? [] : nil
        self.history = []
        self.historyLines = historyLines
        self.queue = DispatchQueue(label: "io.ably.log", qos: .utility)
        super.init()
    }
    
    // swift-migration: original location ARTLog.h, line 22 and ARTLog.m, line 93
    public func log(_ message: String, with level: ARTLogLevel) {
        queue.sync {
            let logLine = ARTLogLine(date: Date(), level: level, message: message)
            if level.rawValue >= self.logLevel.rawValue {
                NSLog("%@", logLine.toString())
                self.captured?.append(logLine)
            }
            if self.historyLines > 0 {
                self.history.insert(logLine, at: 0)
                if self.history.count > self.historyLines {
                    self.history.removeLast()
                }
            }
        }
    }
    
    // swift-migration: original location ARTLog.h, line 25 and ARTLog.m, line 111
    public func log(withError error: ARTErrorInfo) {
        log(error.message, with: .error)
    }
    
    // swift-migration: original location ARTLog+Private.h, line 20 and ARTLog.m, line 115
    internal var logHistory: [ARTLogLine] {
        return history
    }
    
    // swift-migration: original location ARTLog+Private.h, line 19 and ARTLog.m, line 119
    internal var logCaptured: [ARTLogLine] {
        guard let captured = captured else {
            fatalError("tried to get captured output in non-capturing instance; use init(capturingOutput: true) if you want captured output.")
        }
        return captured
    }
    
    // swift-migration: original location ARTLog.h, line 27 and ARTLog.m, line 126
    @discardableResult
    public func verboseMode() -> ARTLog {
        self.logLevel = .verbose
        return self
    }
    
    // swift-migration: original location ARTLog.h, line 28 and ARTLog.m, line 131
    @discardableResult
    public func debugMode() -> ARTLog {
        self.logLevel = .debug
        return self
    }
    
    // swift-migration: original location ARTLog.h, line 30 and ARTLog.m, line 136
    @discardableResult
    public func warnMode() -> ARTLog {
        self.logLevel = .warn
        return self
    }
    
    // swift-migration: original location ARTLog.h, line 29 and ARTLog.m, line 141
    @discardableResult
    public func infoMode() -> ARTLog {
        self.logLevel = .info
        return self
    }
    
    // swift-migration: original location ARTLog.h, line 31 and ARTLog.m, line 146
    @discardableResult
    public func errorMode() -> ARTLog {
        self.logLevel = .error
        return self
    }
    
    // swift-migration: original location ARTLog.h, line 40 and ARTLog.m, line 151
    public func verbose(_ format: String, _ arguments: CVarArg...) {
        if self.logLevel.rawValue <= ARTLogLevel.verbose.rawValue {
            let message = String(format: format, arguments: arguments)
            log(message, with: .verbose)
        }
    }
    
    // swift-migration: original location ARTLog.h, line 41 and ARTLog.m, line 162
    public func verbose(_ fileName: String, line: Int, message: String, _ arguments: CVarArg...) {
        if self.logLevel.rawValue <= ARTLogLevel.verbose.rawValue {
            let formattedMessage = String(format: message, arguments: arguments)
            let fileBasename = URL(fileURLWithPath: fileName).lastPathComponent
            let fullMessage = "(\(fileBasename):\(line)) \(formattedMessage)"
            log(fullMessage, with: .verbose)
        }
    }
    
    // swift-migration: original location ARTLog.h, line 42 and ARTLog.m, line 172
    public func debug(_ format: String, _ arguments: CVarArg...) {
        if self.logLevel.rawValue <= ARTLogLevel.debug.rawValue {
            let message = String(format: format, arguments: arguments)
            log(message, with: .debug)
        }
    }
    
    // swift-migration: original location ARTLog.h, line 43 and ARTLog.m, line 182
    public func debug(_ fileName: String, line: Int, message: String, _ arguments: CVarArg...) {
        if self.logLevel.rawValue <= ARTLogLevel.debug.rawValue {
            let formattedMessage = String(format: message, arguments: arguments)
            let fileBasename = URL(fileURLWithPath: fileName).lastPathComponent
            let fullMessage = "(\(fileBasename):\(line)) \(formattedMessage)"
            log(fullMessage, with: .debug)
        }
    }
    
    // swift-migration: original location ARTLog.h, line 44 and ARTLog.m, line 192
    public func info(_ format: String, _ arguments: CVarArg...) {
        if self.logLevel.rawValue <= ARTLogLevel.info.rawValue {
            let message = String(format: format, arguments: arguments)
            log(message, with: .info)
        }
    }
    
    // swift-migration: original location ARTLog.h, line 45 and ARTLog.m, line 202
    public func warn(_ format: String, _ arguments: CVarArg...) {
        if self.logLevel.rawValue <= ARTLogLevel.warn.rawValue {
            let message = String(format: format, arguments: arguments)
            log(message, with: .warn)
        }
    }
    
    // swift-migration: original location ARTLog.h, line 46 and ARTLog.m, line 212
    public func error(_ format: String, _ arguments: CVarArg...) {
        if self.logLevel.rawValue <= ARTLogLevel.error.rawValue {
            let message = String(format: format, arguments: arguments)
            log(message, with: .error)
        }
    }
}
