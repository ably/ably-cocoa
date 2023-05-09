/**
 Represents an execution of a test case method.
 */
struct Test {
    var id = UUID()
    private var function: StaticString

    init(function: StaticString = #function) {
        self.function = function
        NSLog("Created test \(id) for function \(function)")
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
