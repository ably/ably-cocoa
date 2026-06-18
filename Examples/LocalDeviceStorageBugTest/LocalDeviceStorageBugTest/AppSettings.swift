import Foundation

/// Persistent settings for the app, stored in a file with no data protection
/// so that they are readable even when the device is locked (i.e. before first
/// unlock).
struct AppSettings: Codable {
    /// Whether to automatically call `push.activate()` on app launch.
    var autoActivatePush: Bool = false

    /// Whether to automatically subscribe to the push channel on app launch
    /// (after activation completes, if auto-activate is also enabled).
    var autoSubscribeToPushChannel: Bool = false
}

/// Reads and writes ``AppSettings`` to a JSON file with
/// `FileProtectionType.none`.
class AppSettingsStore {
    static let shared = AppSettingsStore()

    private let fileURL: URL

    private init() {
        let documentsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        fileURL = documentsDir.appendingPathComponent("settings.json")
    }

    func load() -> AppSettings {
        guard let data = try? Data(contentsOf: fileURL) else {
            return AppSettings()
        }
        return (try? JSONDecoder().decode(AppSettings.self, from: data)) ?? AppSettings()
    }

    func save(_ settings: AppSettings) {
        let data = try! JSONEncoder().encode(settings)
        try! data.write(to: fileURL, options: .noFileProtection)
    }
}
