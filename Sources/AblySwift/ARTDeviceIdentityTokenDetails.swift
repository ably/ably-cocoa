import Foundation

// swift-migration: original location ARTDeviceIdentityTokenDetails.m, line 6
let ARTCoderTokenKey = "token"
let ARTCoderIssuedKey = "issued"
let ARTCoderExpiresKey = "expires"
let ARTCoderCapabilityKey = "capability"
let ARTCoderClientIdKey = "clientId"

// swift-migration: original location ARTDeviceIdentityTokenDetails.h, line 8 and ARTDeviceIdentityTokenDetails.m, line 12
/**
 * An object representing a unique device identity token used to communicate with APNS.
 */
public class ARTDeviceIdentityTokenDetails: NSObject, NSSecureCoding, NSCopying {
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.h, line 13
    /**
     Token string.
     */
    public let token: String
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.h, line 18
    /**
     Contains the time the token was issued in milliseconds.
     */
    public let issued: Date
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.h, line 23
    /**
     Contains the expiry time in milliseconds.
     */
    public let expires: Date
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.h, line 28
    /**
     Contains the capability JSON stringified.
     */
    public let capability: String
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.h, line 33
    /**
     Contains the clientId assigned to the token if provided.
     */
    public let clientId: String?
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.h, line 39 and ARTDeviceIdentityTokenDetails.m, line 14
    /// :nodoc:
    public init(token: String, issued: Date, expires: Date, capability: String, clientId: String?) {
        self.token = token
        self.issued = issued
        self.expires = expires
        self.capability = capability
        self.clientId = clientId
        super.init()
    }
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.m, line 27
    public override var description: String {
        return "\(super.description) - \n\t token: \(self.token); \n\t issued: \(self.issued); \n\t expires: \(self.expires); \n\t clientId: \(self.clientId ?? "nil");"
    }
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.m, line 31
    public func copy(with zone: NSZone?) -> Any {
        // Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.
        return self
    }
    
    // MARK: - NSCoding
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.m, line 38
    public required init?(coder aDecoder: NSCoder) {
        guard let token = aDecoder.decodeObject(of: NSString.self, forKey: ARTCoderTokenKey) as String?,
              let issued = aDecoder.decodeObject(of: NSDate.self, forKey: ARTCoderIssuedKey) as Date?,
              let expires = aDecoder.decodeObject(of: NSDate.self, forKey: ARTCoderExpiresKey) as Date?,
              let capability = aDecoder.decodeObject(of: NSString.self, forKey: ARTCoderCapabilityKey) as String? else {
            return nil
        }
        
        self.token = token
        self.issued = issued
        self.expires = expires
        self.capability = capability
        self.clientId = aDecoder.decodeObject(of: NSString.self, forKey: ARTCoderClientIdKey) as String?
        
        super.init()
    }
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.m, line 53
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.token, forKey: ARTCoderTokenKey)
        aCoder.encode(self.issued, forKey: ARTCoderIssuedKey)
        aCoder.encode(self.expires, forKey: ARTCoderExpiresKey)
        aCoder.encode(self.capability, forKey: ARTCoderCapabilityKey)
        aCoder.encode(self.clientId, forKey: ARTCoderClientIdKey)
    }
    
    // MARK: - NSSecureCoding
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails.m, line 63
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    // MARK: - Archive/Unarchive
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails+Private.h, line 7 and ARTDeviceIdentityTokenDetails.m, line 69
    internal func archive(withLogger logger: ARTInternalLog?) -> Data {
        return art_archive(withLogger: logger) ?? Data()
    }
    
    // swift-migration: original location ARTDeviceIdentityTokenDetails+Private.h, line 9 and ARTDeviceIdentityTokenDetails.m, line 73
    internal static func unarchive(_ data: Data, withLogger logger: ARTInternalLog?) -> ARTDeviceIdentityTokenDetails? {
        return art_unarchive(fromData: data, withLogger: logger) as? ARTDeviceIdentityTokenDetails
    }
}