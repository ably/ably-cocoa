import Foundation

// swift-migration: original location ARTChannelOptions.h, line 11 and ARTChannelOptions.m, line 5
public class ARTChannelOptions: NSObject, NSCopying {
    private var _cipher: ARTCipherParams?
    private var _frozen: Bool = false
    
    // swift-migration: original location ARTChannelOptions.h, line 16 and ARTChannelOptions.m, line 31
    public var cipher: ARTCipherParams? {
        get {
            return _cipher
        }
        set {
            if isFrozen {
                fatalError("\(type(of: self)): You can't change options after you've passed it to receiver.")
            }
            _cipher = newValue
        }
    }
    
    // swift-migration: original location ARTChannelOptions+Private.h, line 6
    public var isFrozen: Bool {
        get {
            return _frozen
        }
        set {
            _frozen = newValue
        }
    }
    
    // For compatibility with Objective-C property name
    public var frozen: Bool {
        get { return isFrozen }
        set { isFrozen = newValue }
    }
    
    public required override init() {
        super.init()
    }
    
    // swift-migration: original location ARTChannelOptions.h, line 19 and ARTChannelOptions.m, line 9
    public init(cipher cipherParams: ARTCipherParamsCompatible?) {
        super.init()
        self._cipher = cipherParams?.toCipherParams()
    }
    
    // swift-migration: original location ARTChannelOptions.h, line 28 and ARTChannelOptions.m, line 16
    public init(cipherKey key: ARTCipherKeyCompatible) {
        super.init()
        // swift-migration: In Objective-C this used @{@"key": key} dictionary syntax
        // Dictionary conforms to ARTCipherParamsCompatible via extension, just like NSDictionary does in Objective-C
        let cipherDict: [String: Any] = ["key": key]
        self._cipher = cipherDict.toCipherParams()
    }
    
    // swift-migration: original location ARTChannelOptions.m, line 20
    public func copy(with zone: NSZone?) -> Any {
        let copied = type(of: self).init()
        
        // The _frozen flag prevents the instance we were copying from being mutated, but we don't yet want to prevent the new instance from being mutated
        copied._frozen = false
        
        copied._cipher = self._cipher
        
        return copied
    }
}