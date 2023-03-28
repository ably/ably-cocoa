import Ably.Private

class MockVersion2Log: Version2Log {
    var logLevel: ARTLogLevel = .none

    func log(_ message: String, with level: ARTLogLevel) {
        // TODO
    }
}
