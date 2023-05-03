/**
 Represents an execution of a test case method.
 */
struct Test: CustomStringConvertible {
    var id = UUID()
    var fileID: String
    var function: String

    init(fileID: String = #fileID, function: String = #function) {
        self.fileID = fileID
        self.function = function
        NSLog("Created test \(id) for function \(function) in file \(fileID)")
    }

    var description: String {
        return "Test(id: \(id), fileID: \(fileID), function: \(function))"
    }

    func uniqueChannelName(prefix: String = "",
                           timestamp: TimeInterval = Date.timeIntervalSinceReferenceDate) -> String {
        let platform: String
    #if targetEnvironment(macCatalyst)
        platform = "macCatalyst"
    #elseif os(OSX)
        platform = "OSX"
    #elseif os(iOS)
        platform = "iOS"
    #elseif os(tvOS)
        platform = "tvOS"
    #elseif os(watchOS)
        platform = "watchOS"
    #else
        platform = "Unknown"
    #endif
        return "\(prefix)-\(platform)-\(id)-\(timestamp)-\(NSUUID().uuidString)"
    }
}
