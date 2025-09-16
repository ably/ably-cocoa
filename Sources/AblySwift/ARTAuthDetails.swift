import Foundation

// swift-migration: original location ARTAuthDetails.h, line 8
/// Contains the token string used to authenticate a client with Ably.
public class ARTAuthDetails: NSObject, NSCopying {
    
    // swift-migration: original location ARTAuthDetails.h, line 13
    /// The authentication token string.
    public var accessToken: String
    
    // swift-migration: original location ARTAuthDetails.h, line 16
    /// :nodoc:
    public init(token: String) {
        self.accessToken = token
        super.init()
    }
    
    // swift-migration: original location ARTAuthDetails.m, line 12
    public override var description: String {
        return "\(super.description) - \n\t accessToken: \(self.accessToken); \n"
    }
    
    // swift-migration: original location ARTAuthDetails.m, line 16
    public func copy(with zone: NSZone? = nil) -> Any {
        let authDetails = ARTAuthDetails(token: self.accessToken)
        return authDetails
    }
}