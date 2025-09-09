import Foundation
import CommonCrypto

// swift-migration: original location ARTTokenParams.h, line 13 and ARTTokenParams.m, line 10
/// Defines the properties of an Ably Token.
public class ARTTokenParams: NSObject, NSCopying {
    
    // swift-migration: original location ARTTokenParams.h, line 18
    /// Requested time to live for the token in milliseconds. The default is 60 minutes.
    public var ttl: NSNumber?
    
    // swift-migration: original location ARTTokenParams.h, line 23
    /// The capabilities associated with this Ably Token. The capabilities value is a JSON-encoded representation of the resource paths and associated operations. Read more about capabilities in the [capabilities docs](https://ably.com/docs/core-features/authentication/#capabilities-explained).
    public var capability: String?
    
    // swift-migration: original location ARTTokenParams.h, line 28
    /// A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error is raised if a `clientId` specified here conflicts with the `clientId` implicit in the token. Find out more about [identified clients](https://ably.com/docs/core-features/authentication#identified-clients).
    public var clientId: String?
    
    // swift-migration: original location ARTTokenParams.h, line 33
    /// The timestamp of this request as `NSDate` object. Timestamps, in conjunction with the `nonce`, are used to prevent requests from being replayed. `timestamp` is a "one-time" value, and is valid in a request, but is not validly a member of any default token params such as `ARTClientOptions.defaultTokenParams`.
    public var timestamp: Date?
    
    // swift-migration: original location ARTTokenParams.h, line 38
    /// A cryptographically secure random string of at least 16 characters, used to ensure the `ARTTokenRequest` cannot be reused.
    public var nonce: String?
    
    // swift-migration: original location ARTTokenParams.m, line 12
    public required override init() {
        super.init()
        self.timestamp = nil
        self.capability = nil
        self.clientId = nil
        self.nonce = nil
    }
    
    // swift-migration: original location ARTTokenParams.h, line 44 and ARTTokenParams.m, line 16
    public convenience init(clientId: String?) {
        self.init()
        self.clientId = clientId
    }
    
    // swift-migration: original location ARTTokenParams.h, line 47 and ARTTokenParams.m, line 20
    public convenience init(clientId: String?, nonce: String?) {
        self.init()
        self.clientId = clientId
        self.nonce = nonce
    }
    
    // swift-migration: original location ARTTokenParams.h, line 50 and ARTTokenParams.m, line 30
    public init(options: ARTClientOptions) {
        super.init()
        self.timestamp = nil
        self.capability = nil
        self.clientId = options.clientId
        self.nonce = nil
        
        if let defaultTokenParams = options.defaultTokenParams {
            if let ttl = defaultTokenParams.ttl {
                self.ttl = ttl
            }
            if let capability = defaultTokenParams.capability {
                self.capability = capability
            }
        }
    }
    
    // swift-migration: original location ARTTokenParams.h, line 53 and ARTTokenParams.m, line 39
    public init(tokenParams: ARTTokenParams) {
        super.init()
        self.clientId = tokenParams.clientId
        self.timestamp = nil
        self.ttl = tokenParams.ttl
        self.capability = tokenParams.capability
        self.nonce = tokenParams.nonce
    }
    
    // swift-migration: original location ARTTokenParams.m, line 47
    public override var description: String {
        return "ARTTokenParams: ttl=\(String(describing: ttl)) capability=\(String(describing: capability)) timestamp=\(String(describing: timestamp))"
    }
    
    // swift-migration: original location ARTTokenParams.m, line 52
    public func copy(with zone: NSZone?) -> Any {
        let token = type(of: self).init()
        token.clientId = clientId
        token.nonce = nonce
        token.ttl = ttl
        token.capability = capability
        token.timestamp = timestamp
        return token
    }
    
    // swift-migration: original location ARTTokenParams.h, line 56 and ARTTokenParams.m, line 62
    public func toArray() -> [URLQueryItem] {
        var params: [URLQueryItem] = []
        
        if let clientId = self.clientId {
            params.append(URLQueryItem(name: "clientId", value: clientId))
        }
        if let ttl = self.ttl {
            params.append(URLQueryItem(name: "ttl", value: "\(ttl)"))
        }
        if let capability = self.capability {
            params.append(URLQueryItem(name: "capability", value: capability))
        }
        if let timestamp = self.timestamp {
            params.append(URLQueryItem(name: "timestamp", value: "\(dateToMilliseconds(timestamp))"))
        }
        
        return params
    }
    
    // swift-migration: original location ARTTokenParams.m, line 77
    internal func toDictionary() -> [String: String] {
        var params: [String: String] = [:]
        
        if let clientId = self.clientId {
            params["clientId"] = clientId
        }
        if let ttl = self.ttl {
            params["ttl"] = "\(ttl)"
        }
        if let capability = self.capability {
            params["capability"] = capability
        }
        if let timestamp = self.timestamp {
            params["timestamp"] = "\(dateToMilliseconds(timestamp))"
        }
        
        return params
    }
    
    // swift-migration: original location ARTTokenParams.h, line 59 and ARTTokenParams.m, line 92
    public func toArray(withUnion items: [URLQueryItem]) -> [URLQueryItem] {
        var tokenParams = toArray()
        var add = true
        
        for item in items {
            for param in tokenParams {
                // Check if exist
                if param.name == item.name {
                    add = false
                    break
                }
            }
            if add {
                tokenParams.append(item)
            }
            add = true
        }
        
        return tokenParams
    }
    
    // swift-migration: original location ARTTokenParams.h, line 62 and ARTTokenParams.m, line 113
    public func toDictionary(withUnion items: [URLQueryItem]) -> [String: String] {
        var tokenParams = toDictionary()
        var add = true
        
        for item in items {
            for key in tokenParams.keys {
                // Check if exist
                if key == item.name {
                    add = false
                    break
                }
            }
            if add {
                if let value = item.value {
                    tokenParams[item.name] = value
                }
            }
            add = true
        }
        
        return tokenParams // immutable copy in Swift
    }
}

// swift-migration: original location ARTTokenParams.m, line 134
internal func hmacForDataAndKey(_ data: Data, _ key: Data) -> String {
    let cKey = key.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let cData = data.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }
    let keyLen = key.count
    let dataLen = data.count
    
    var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    
    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), cKey, keyLen, cData, dataLen, &hmac)
    let mac = Data(bytes: hmac, count: hmac.count)
    return mac.base64EncodedString()
}

// MARK: - Private methods extension

extension ARTTokenParams {
    
    // swift-migration: original location ARTTokenParams+Private.h, line 5 and ARTTokenParams.m, line 148
    internal func sign(_ key: String) -> ARTTokenRequest {
        return sign(key, withNonce: nonce ?? generateNonce())
    }
    
    // swift-migration: original location ARTTokenParams+Private.h, line 6 and ARTTokenParams.m, line 152
    internal func sign(_ key: String, withNonce nonce: String) -> ARTTokenRequest {
        let keyComponents = decomposeKey(key)
        let keyName = keyComponents[0]
        let keySecret = keyComponents[1]
        let capability = self.capability ?? ""
        let clientId = self.clientId ?? ""
        let ttl = self.ttl != nil ? "\(timeIntervalToMilliseconds(self.ttl!.doubleValue))" : ""
        
        let signText = "\(keyName)\n\(ttl)\n\(capability)\n\(clientId)\n\(dateToMilliseconds(self.timestamp!))\n\(nonce)\n"
        let mac = hmacForDataAndKey(signText.data(using: .utf8)!, keySecret.data(using: .utf8)!)
        
        return ARTTokenRequest(tokenParams: self, keyName: keyName, nonce: nonce, mac: mac)
    }
}