import Foundation

// swift-migration: original location ARTDevicePushDetails.h, line 11 and ARTDevicePushDetails.m, line 5
/**
 * Contains the details of the push registration of a device.
 */
public class ARTDevicePushDetails: NSObject, NSCopying {
    
    // swift-migration: original location ARTDevicePushDetails.h, line 16 and ARTDevicePushDetails+Private.h, line 9
    /**
     * A JSON object of key-value pairs that contains of the push transport and address.
     */
    public var recipient: NSMutableDictionary {
        get { return _recipient }
        set { _recipient = newValue }
    }
    internal var _recipient: NSMutableDictionary

    // swift-migration: original location ARTDevicePushDetails.h, line 21 and ARTDevicePushDetails+Private.h, line 10
    /**
     * The current state of the push registration.
     */
    public var state: String? {
        get { return _state }
        set { _state = newValue }
    }
    internal var _state: String?
    
    // swift-migration: original location ARTDevicePushDetails.h, line 26 and ARTDevicePushDetails+Private.h, line 11
    /**
     * An `ARTErrorInfo` object describing the most recent error when the `state` is `Failing` or `Failed`.
     */
    public var errorReason: ARTErrorInfo? {
        get { return _errorReason }
        set { _errorReason = newValue }
    }
    internal var _errorReason: ARTErrorInfo?
    
    // swift-migration: original location ARTDevicePushDetails.h, line 29 and ARTDevicePushDetails.m, line 7
    /// :nodoc:
    public required override init() {
        _recipient = NSMutableDictionary()
        super.init()
    }
    
    // swift-migration: original location ARTDevicePushDetails.m, line 14
    public func copy(with zone: NSZone?) -> Any {
        let push = type(of: self).init()
        
        push.recipient = recipient.mutableCopy() as! NSMutableDictionary
        push.state = self.state
        push.errorReason = (self.errorReason?.copy(with: zone) as? ARTErrorInfo)
        
        return push
    }
    
    // swift-migration: original location ARTDevicePushDetails.m, line 24
    public override var description: String {
        return "\(super.description) - \n\t recipient: \(self.recipient); \n\t state: \(self.state ?? "nil"); \n\t errorReason: \(self.errorReason?.description ?? "nil");"
    }
}
