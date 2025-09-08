import Foundation

// swift-migration: original location ARTAuthOptions.m, line 6
internal let ARTAuthOptionsMethodDefault = "GET"

// swift-migration: decomposeKey function from ARTTypes.m
internal func decomposeKey(_ key: String) -> [String] {
    return key.components(separatedBy: ":")
}

// swift-migration: original location Ably/ARTAuthOptions.h, line 11
public protocol ARTTokenDetailsCompatible {
    func toTokenDetails(_ auth: ARTAuth, callback: @escaping ARTTokenDetailsCallback)
}


// swift-migration: original location Ably/ARTAuthOptions.h, line 21
public class ARTAuthOptions: NSObject, NSCopying {
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 26
    public var key: String?
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 32
    public var token: String? {
        // swift-migration: original location ARTAuthOptions.m, line 74
        get {
            if let tokenDetails = self.tokenDetails {
                return tokenDetails.token
            }
            return nil
        }
        // swift-migration: original location ARTAuthOptions.m, line 81
        set {
            setToken(newValue)
        }
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 37
    public var tokenDetails: ARTTokenDetails?
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 42
    public var authCallback: ARTAuthCallback?
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 47
    public var authUrl: URL?
    
    // Backing storage for authMethod to avoid infinite recursion
    private var _authMethod: String = ARTAuthOptionsMethodDefault
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 52
    public var authMethod: String {
        get {
            return _authMethod
        }
        set {
            setAuthMethod(newValue)
        }
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 57
    public var authHeaders: [String: String]?
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 62
    public var authParams: [URLQueryItem]?
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 67
    public var queryTime: Bool = false
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 72
    public var useTokenAuth: Bool = false
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 75 and ARTAuthOptions.m, line 8
    public required override init() {
        super.init()
        _ = initDefaults()
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 78 and ARTAuthOptions.m, line 16
    public init(key: String?) {
        super.init()
        if let key = key, decomposeKey(key).count != 2 {
            fatalError("Invalid key: \(key) should be of the form <keyName>:<keySecret>")
        } else if let key = key {
            self.key = key
        }
        _ = initDefaults()
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 81 and ARTAuthOptions.m, line 30
    public init(token: String?) {
        super.init()
        setToken(token)
        _ = initDefaults()
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 84 and ARTAuthOptions.m, line 39
    public init(tokenDetails: ARTTokenDetails?) {
        super.init()
        self.tokenDetails = tokenDetails
        _ = initDefaults()
    }
    
    // swift-migration: original location ARTAuthOptions+Private.h, line 7 and ARTAuthOptions.m, line 48
    @discardableResult
    internal func initDefaults() -> ARTAuthOptions {
        _authMethod = ARTAuthOptionsMethodDefault
        return self
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 87 and ARTAuthOptions.m, line 53
    public func copy(with zone: NSZone?) -> Any {
        let options = type(of: self).init()
        
        options.key = self.key
        options.token = self.token
        options.tokenDetails = self.tokenDetails
        options.authCallback = self.authCallback
        options.authUrl = self.authUrl
        options.authMethod = self.authMethod
        options.authHeaders = self.authHeaders
        options.authParams = self.authParams
        options.queryTime = self.queryTime
        options.useTokenAuth = self.useTokenAuth
        
        return options
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 87 and ARTAuthOptions.m, line 70
    public override var description: String {
        return "\(super.description) - \n\t key: \(String(describing: key)); \n\t token: \(String(describing: token)); \n\t authUrl: \(String(describing: authUrl)); \n\t authMethod: \(authMethod); \n\t hasAuthCallback: \(authCallback != nil);"
    }
    
    // swift-migration: original location ARTAuthOptions.m, line 81
    private func setToken(_ token: String?) {
        if let token = token, !token.isEmpty {
            self.tokenDetails = ARTTokenDetails(token: token)
        }
    }
    
    // swift-migration: original location ARTAuthOptions.m, line 87
    private func setAuthMethod(_ authMethod: String) {
        var method = authMethod
        // HTTP Method
        if method.isEmpty {
            method = ARTAuthOptionsMethodDefault
        }
        _authMethod = method
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 90 and ARTAuthOptions.m, line 95
    public func mergeWith(_ precedenceOptions: ARTAuthOptions) -> ARTAuthOptions {
        let merged = self.copy() as! ARTAuthOptions
        
        if let key = precedenceOptions.key {
            merged.key = key
        }
        if let authCallback = precedenceOptions.authCallback {
            merged.authCallback = authCallback
        }
        if let authUrl = precedenceOptions.authUrl {
            merged.authUrl = authUrl
        }
        if !precedenceOptions.authMethod.isEmpty {
            merged.authMethod = precedenceOptions.authMethod
        }
        if let authHeaders = precedenceOptions.authHeaders {
            merged.authHeaders = authHeaders
        }
        if let authParams = precedenceOptions.authParams {
            merged.authParams = authParams
        }
        if precedenceOptions.queryTime {
            merged.queryTime = precedenceOptions.queryTime
        }
        if precedenceOptions.useTokenAuth {
            merged.useTokenAuth = precedenceOptions.useTokenAuth
        }
        
        return merged
    }
    
    // swift-migration: Alias for mergeWith to match ARTAuth usage
    public func merge(with precedenceOptions: ARTAuthOptions) -> ARTAuthOptions {
        return mergeWith(precedenceOptions)
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 96 and ARTAuthOptions.m, line 118
    public func isMethodPOST() -> Bool {
        return _authMethod == "POST"
    }
    
    // swift-migration: original location Ably/ARTAuthOptions.h, line 93 and ARTAuthOptions.m, line 122
    public func isMethodGET() -> Bool {
        return _authMethod == "GET"
    }
}