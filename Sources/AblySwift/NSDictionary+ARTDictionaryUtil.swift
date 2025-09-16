import Foundation

// swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 3 and NSDictionary+ARTDictionaryUtil.m, line 4
internal extension Dictionary where Key == String, Value == Any {
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 5 and NSDictionary+ARTDictionaryUtil.m, line 6
    func artString(_ key: String) -> String? {
        return artTyped(String.self, key: key)
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 6 and NSDictionary+ARTDictionaryUtil.m, line 10
    func artNumber(_ key: String) -> NSNumber? {
        return artTyped(NSNumber.self, key: key)
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 7 and NSDictionary+ARTDictionaryUtil.m, line 14
    func artTimestamp(_ key: String) -> Date? {
        if let number = artNumber(key) {
            return Date.artDateFromNumberMs(number)
        }
        if let string = artString(key) {
            return Date.artDateFromIntegerMs(Int64(string) ?? 0)
        }
        return nil
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 8 and NSDictionary+ARTDictionaryUtil.m, line 26
    func artArray(_ key: String) -> [Any]? {
        return artTyped([Any].self, key: key)
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 9 and NSDictionary+ARTDictionaryUtil.m, line 30
    func artDictionary(_ key: String) -> [String: Any]? {
        return artTyped([String: Any].self, key: key)
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 13 and NSDictionary+ARTDictionaryUtil.m, line 34
    func artTyped<T>(_ type: T.Type, key: String) -> T? {
        return self[key] as? T
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 10 and NSDictionary+ARTDictionaryUtil.m, line 42
    func artInteger(_ key: String) -> Int {
        if let number = artNumber(key) {
            return number.intValue
        }
        if let string = artString(key) {
            return Int(string) ?? 0
        }
        return 0
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 11 and NSDictionary+ARTDictionaryUtil.m, line 54
    func artBoolean(_ key: String) -> Bool {
        let value = self[key]
        if let boolean = value as? Bool {
            return boolean
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        return artInteger(key) != 0
    }
    
    // swift-migration: original location NSDictionary+ARTDictionaryUtil.h, line 18 and NSDictionary+ARTDictionaryUtil.m, line 58
    func addingValueAsURLQueryItem(_ value: String, forKey key: String) -> [String: Any] {
        var mutableDict = self
        mutableDict[key] = URLQueryItem(name: key, value: value)
        return mutableDict
    }
}
