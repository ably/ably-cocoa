import Foundation

// swift-migration: original location NSString+ARTUtil.h, line 3 and NSString+ARTUtil.m, line 3
internal func ARTStringFromBool(_ value: Bool) -> String {
    return value ? "YES" : "NO"
}

// swift-migration: original location NSString+ARTUtil.h, line 5 and NSString+ARTUtil.m, line 7
internal extension String {
    
    // swift-migration: original location NSString+ARTUtil.h, line 7 and NSString+ARTUtil.m, line 9
    static func nilToEmpty(_ string: String?) -> String {
        if let string = string, !string.isEmpty {
            return string
        }
        return ""
    }
    
    // swift-migration: original location NSString+ARTUtil.h, line 8 and NSString+ARTUtil.m, line 16
    func isEmptyString() -> Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // swift-migration: original location NSString+ARTUtil.h, line 9 and NSString+ARTUtil.m, line 20
    func isNotEmptyString() -> Bool {
        return !isEmptyString()
    }
}