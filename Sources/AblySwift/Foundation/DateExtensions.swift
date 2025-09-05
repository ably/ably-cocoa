import Foundation

// MARK: - Date Extensions

extension Date {
    /// Creates a Date from milliseconds since 1970
    static func artDate(fromIntegerMs ms: Int64) -> Date {
        let intervalSince1970 = TimeInterval(ms) / 1000.0
        return Date(timeIntervalSince1970: intervalSince1970)
    }
    
    /// Creates a Date from NSNumber containing milliseconds since 1970
    static func artDate(fromNumberMs number: NSNumber) -> Date {
        return artDate(fromIntegerMs: number.int64Value)
    }
    
    /// Converts Date to NSNumber containing milliseconds since 1970
    func artToNumberMs() -> NSNumber {
        return NSNumber(value: artToIntegerMs())
    }
    
    /// Converts Date to Integer containing milliseconds since 1970
    func artToIntegerMs() -> Int {
        return Int(round(timeIntervalSince1970 * 1000.0))
    }
}