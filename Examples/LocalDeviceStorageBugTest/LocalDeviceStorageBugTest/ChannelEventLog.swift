import Foundation

/// Appends a line per published channel event to `ARTRealtimeChannel.log` in
/// the documents directory, using `FileProtectionType.none` so the log stays
/// readable even when the device is locked (i.e. before first unlock).
///
/// Mirrors ``AppSettingsStore``, but appends rather than overwriting.
final class ChannelEventLog {
    static let shared = ChannelEventLog()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "io.ably.example.ChannelEventLog")
    private let dateFormatter = ISO8601DateFormatter()

    private init() {
        let documentsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        fileURL = documentsDir.appendingPathComponent("ARTRealtimeChannel.log")
        print("Event log created: \(fileURL)")
    }

    /// Appends `message`, prefixed with an ISO 8601 timestamp, as a new line.
    func append(_ message: String) {
        let line = "\(dateFormatter.string(from: Date())) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        queue.sync {
            do {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } catch {
                // The file doesn't exist yet (or couldn't be opened): create it
                // with no data protection so it stays readable while locked.
                try? data.write(to: fileURL, options: .noFileProtection)
            }
        }
    }
}
