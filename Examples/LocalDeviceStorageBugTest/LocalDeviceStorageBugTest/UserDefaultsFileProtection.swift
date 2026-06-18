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

/// Returns the entire contents of `UserDefaults.standard` as a JSON string.
///
/// Values that are not directly JSON-serialisable (e.g. `Data`) are
/// converted to a string representation.
func userDefaultsContentsSanitisedJSON() -> String {
    let dict = UserDefaults.standard.dictionaryRepresentation()
    let sanitised = dict.mapValues { makeJSONSafe($0) }
    guard let data = try? JSONSerialization.data(withJSONObject: sanitised, options: [.sortedKeys]),
          let json = String(data: data, encoding: .utf8) else {
        return "{}"
    }
    return json
}

private func makeJSONSafe(_ value: Any) -> Any {
    switch value {
    case let data as Data:
        return "<Data: \(data.count) bytes>"
    case let date as Date:
        return date.description
    case let array as [Any]:
        return array.map { makeJSONSafe($0) }
    case let dict as [String: Any]:
        return dict.mapValues { makeJSONSafe($0) }
    case is String, is Bool, is Int, is Double, is Float:
        return value
    case let number as NSNumber:
        return number
    default:
        return String(describing: value)
    }
}
