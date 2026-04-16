import Foundation

/// Returns the file protection level of the UserDefaults plist file.
///
/// The plist path (`Library/Preferences/<bundle-id>.plist`) is an
/// implementation detail of `NSUserDefaults` and not guaranteed by Apple.
/// The file may not exist on a fresh install before any defaults have been
/// written; in that case this returns an error string.
func userDefaultsFileProtection() -> String {
    let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
    let prefsDir = FileManager.default
        .urls(for: .libraryDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Preferences")
    let plistURL = prefsDir.appendingPathComponent("\(bundleId).plist")

    do {
        let attrs = try FileManager.default.attributesOfItem(atPath: plistURL.path)
        if let protection = attrs[.protectionKey] as? FileProtectionType {
            return protection.rawValue
        }
        return "unknown (attribute not present)"
    } catch {
        return "error: \(error.localizedDescription)"
    }
}
