import AblyPlugin
import os

/// An implementation of `AblyPlugin.Logger` to use when testing internal components of the LiveObjects plugin.
final class TestLogger: NSObject, AblyPlugin.Logger {
    // By default, we don’t log in tests to keep the test logs easy to read. You can set this property to `true` to temporarily turn logging on if you want to debug a test.
    static let loggingEnabled = false

    private let underlyingLogger = os.Logger()

    func log(_ message: String, with level: ARTLogLevel, file fileName: UnsafePointer<CChar>, line: Int) {
        guard Self.loggingEnabled else {
            return
        }

        underlyingLogger.log(level: level.toOSLogType, "(\(String(cString: fileName)):\(line)): \(message)")
    }
}

private extension ARTLogLevel {
    var toOSLogType: OSLogType {
        // Not much thought has gone into this conversion
        switch self {
        case .verbose:
            .debug
        case .debug:
            .debug
        case .info:
            .info
        case .warn:
            .error
        case .error:
            .error
        case .none:
            .debug
        @unknown default:
            .debug
        }
    }
}
