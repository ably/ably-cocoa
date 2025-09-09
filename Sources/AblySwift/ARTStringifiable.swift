import Foundation

// swift-migration: original location ARTStringifiable.h, line 7
/// :nodoc:
public class ARTStringifiable: NSObject {

    // swift-migration: original location ARTStringifiable.h, line 11
    public let stringValue: String

    // swift-migration: original location ARTStringifiable.h, line 9
    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable")
    }

    // swift-migration: original location ARTStringifiable+Private.h, line 5 and ARTStringifiable.m, line 6
    internal init(string value: String) {
        stringValue = value
        super.init()
    }

    // swift-migration: original location ARTStringifiable+Private.h, line 6 and ARTStringifiable.m, line 14
    internal init(number value: NSNumber) {
        stringValue = value.stringValue
        super.init()
    }

    // swift-migration: original location ARTStringifiable+Private.h, line 7 and ARTStringifiable.m, line 22
    internal init(bool value: Bool) {
        stringValue = value ? "true" : "false"
        super.init()
    }

    // swift-migration: original location ARTStringifiable.h, line 13 and ARTStringifiable.m, line 31
    public static func with(string value: String) -> ARTStringifiable {
        return ARTStringifiable(string: value)
    }

    // swift-migration: original location ARTStringifiable.h, line 14 and ARTStringifiable.m, line 35
    public static func with(number value: NSNumber) -> ARTStringifiable {
        return ARTStringifiable(number: value)
    }

    // swift-migration: original location ARTStringifiable.h, line 15 and ARTStringifiable.m, line 39
    public static func with(bool value: Bool) -> ARTStringifiable {
        return ARTStringifiable(bool: value)
    }

}