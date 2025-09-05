import Foundation

// MARK: - String Extensions

extension String {
    /// Converts nil or empty strings to empty string
    static func nilToEmpty(_ aString: String?) -> String {
        if let string = aString, !string.isEmpty {
            return string
        }
        return ""
    }
    
    /// Returns true if string is empty or contains only whitespace
    var isEmptyString: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns true if string is not empty and contains non-whitespace characters
    var isNotEmptyString: Bool {
        return !isEmptyString
    }
}