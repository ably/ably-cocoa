import Foundation

// swift-migration: original location NSDate+ARTUtil.h, line 3 and NSDate+ARTUtil.m, line 3
internal extension Date {
    
    // swift-migration: original location NSDate+ARTUtil.h, line 6 and NSDate+ARTUtil.m, line 5
    static func artDateFromIntegerMs(_ ms: Int64) -> Date {
        let intervalSince1970 = Double(ms) / 1000.0
        return Date(timeIntervalSince1970: intervalSince1970)
    }
    
    // swift-migration: original location NSDate+ARTUtil.h, line 5 and NSDate+ARTUtil.m, line 10
    static func artDateFromNumberMs(_ number: NSNumber) -> Date {
        return artDateFromIntegerMs(number.int64Value)
    }
    
    // swift-migration: original location NSDate+ARTUtil.h, line 8 and NSDate+ARTUtil.m, line 14
    func artToNumberMs() -> NSNumber {
        return NSNumber(value: artToIntegerMs())
    }
    
    // swift-migration: original location NSDate+ARTUtil.h, line 9 and NSDate+ARTUtil.m, line 18
    func artToIntegerMs() -> Int {
        return Int(round(timeIntervalSince1970 * 1000.0))
    }
}