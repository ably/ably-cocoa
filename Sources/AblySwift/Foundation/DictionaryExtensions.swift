import Foundation

// MARK: - Dictionary Extensions

extension Dictionary where Key == String, Value == Any {
    /// Safely extracts a String value for the given key
    func artString(_ key: String) -> String? {
        return artTyped(String.self, key: key)
    }
    
    /// Safely extracts a NSNumber value for the given key
    func artNumber(_ key: String) -> NSNumber? {
        return artTyped(NSNumber.self, key: key)
    }
    
    /// Safely extracts a Date value from timestamp (milliseconds) for the given key
    func artTimestamp(_ key: String) -> Date? {
        if let number = artNumber(key) {
            return Date.artDate(fromNumberMs: number)
        }
        if let string = artString(key) {
            return Date.artDate(fromIntegerMs: Int64(string) ?? 0)
        }
        return nil
    }
    
    /// Safely extracts an Array value for the given key
    func artArray(_ key: String) -> [Any]? {
        return artTyped(Array<Any>.self, key: key)
    }
    
    /// Safely extracts a Dictionary value for the given key
    func artDictionary(_ key: String) -> [String: Any]? {
        return artTyped(Dictionary<String, Any>.self, key: key)
    }
    
    /// Generic method to safely extract a typed value for the given key
    func artTyped<T>(_ type: T.Type, key: String) -> T? {
        guard let obj = self[key] else { return nil }
        return obj as? T
    }
    
    /// Safely extracts an Integer value for the given key
    func artInteger(_ key: String) -> Int {
        if let number = artNumber(key) {
            return number.intValue
        }
        if let string = artString(key) {
            return Int(string) ?? 0
        }
        return 0
    }
    
    /// Safely extracts a Boolean value for the given key
    func artBoolean(_ key: String) -> Bool {
        return artInteger(key) != 0
    }
}

// MARK: - NSMutableDictionary Extensions

extension NSMutableDictionary {
    /// Adds a value as URLQueryItem for the given key
    func addValueAsURLQueryItem(_ value: String, forKey key: String) {
        self[key] = URLQueryItem(name: key, value: value)
    }
}