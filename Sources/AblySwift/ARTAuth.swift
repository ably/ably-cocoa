import Foundation
#if os(iOS)
import UIKit
#endif

// swift-migration: original location ARTAuth+Private.h, line 8
public enum ARTAuthorizationState: UInt {
    case succeeded = 0  // ItemType: nil
    case failed = 1     // ItemType: NSError
    case cancelled = 2  // ItemType: nil
}

// swift-migration: original location ARTAuth.h, line 17
/// The protocol upon which the `ARTAuth` is implemented.
public protocol ARTAuthProtocol {
    /// A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error is raised if a `clientId` specified here conflicts with the `clientId` implicit in the token. Find out more about [identified clients](https://ably.com/docs/core-features/authentication#identified-clients).
    var clientId: String? { get }
    
    /// :nodoc:
    var tokenDetails: ARTTokenDetails? { get }
    
    /// Calls the `requestToken` REST API endpoint to obtain an Ably Token according to the specified `ARTTokenParams` and `ARTAuthOptions`. Both `ARTTokenParams` and `ARTAuthOptions` are optional. When omitted or `nil`, the default token parameters and authentication options for the client library are used, as specified in the `ARTClientOptions` when the client library was instantiated, or later updated with an explicit `authorize` request. Values passed in are used instead of, rather than being merged with, the default values. To understand why an Ably `ARTTokenRequest` may be issued to clients in favor of a token, see [Token Authentication explained](https://ably.com/docs/core-features/authentication/#token-authentication).
    func requestToken(
        _ tokenParams: ARTTokenParams?,
        withOptions authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    )
    
    /// See `requestToken(_:withOptions:callback:)` for details.
    func requestToken(_ callback: @escaping ARTTokenDetailsCallback)
    
    /// Instructs the library to get a new token immediately. When using the realtime client, it upgrades the current realtime connection to use the new token, or if not connected, initiates a connection to Ably, once the new token has been obtained. Also stores any `ARTTokenParams` and `ARTAuthOptions` passed in as the new defaults, to be used for all subsequent implicit or explicit token requests. Any `ARTTokenParams` and `ARTAuthOptions` objects passed in entirely replace, as opposed to being merged with, the current client library saved values.
    func authorize(
        _ tokenParams: ARTTokenParams?,
        options authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    )
    
    /// See `authorize(_:options:callback:)` for details.
    func authorize(_ callback: @escaping ARTTokenDetailsCallback)
    
    /// Creates and signs an Ably `ARTTokenRequest` based on the specified (or if none specified, the client library stored) `ARTTokenParams` and `ARTAuthOptions`. Note this can only be used when the API `key` value is available locally. Otherwise, the Ably `ARTTokenRequest` must be obtained from the key owner. Use this to generate an Ably `ARTTokenRequest` in order to implement an Ably Token request callback for use by other clients. Both `ARTTokenParams` and `ARTAuthOptions` are optional. When omitted or `nil`, the default token parameters and authentication options for the client library are used, as specified in the `ARTClientOptions` when the client library was instantiated, or later updated with an explicit `authorize` request. Values passed in are used instead of, rather than being merged with, the default values. To understand why an Ably `ARTTokenRequest` may be issued to clients in favor of a token, see [Token Authentication explained](https://ably.com/docs/core-features/authentication/#token-authentication).
    func createTokenRequest(
        _ tokenParams: ARTTokenParams?,
        options: ARTAuthOptions?,
        callback: @escaping (ARTTokenRequest?, Error?) -> Void
    )
    
    /// See `createTokenRequest(_:options:callback:)` for details.
    func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void)
}

// swift-migration: original location ARTAuth.h, line 92
/// Creates Ably `ARTTokenRequest` objects and obtains Ably Tokens from Ably to subsequently issue to less trusted clients.
public class ARTAuth: NSObject, ARTAuthProtocol, Sendable {
    
    // swift-migration: original location ARTAuth.m, line 29
    internal let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTAuth.m, line 33
    internal let _internal: ARTAuthInternal
    
    // swift-migration: original location ARTAuth.m, line 32
    public init(internal internalAuth: ARTAuthInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = internalAuth
        self._dealloc = queuedDealloc
        super.init()
    }
    
    // swift-migration: original location ARTAuth.m, line 41
    private func internalAsync(_ use: @escaping (ARTAuthInternal) -> Void) {
        DispatchQueue.global().async {
            use(self._internal)
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 47
    public var clientId: String? {
        return _internal.clientId
    }
    
    // swift-migration: original location ARTAuth.m, line 51
    public var tokenDetails: ARTTokenDetails? {
        return _internal.tokenDetails
    }
    
    // swift-migration: original location ARTAuth.m, line 55
    public func requestToken(
        _ tokenParams: ARTTokenParams?,
        withOptions authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        _internal.requestToken(tokenParams, withOptions: authOptions, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 61
    public func requestToken(_ callback: @escaping ARTTokenDetailsCallback) {
        _internal.requestToken(callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 65
    public func authorize(
        _ tokenParams: ARTTokenParams?,
        options authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        _internal.authorize(tokenParams, options: authOptions, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 71
    public func authorize(_ callback: @escaping ARTTokenDetailsCallback) {
        _internal.authorize(callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 75
    public func createTokenRequest(
        _ tokenParams: ARTTokenParams?,
        options: ARTAuthOptions?,
        callback: @escaping (ARTTokenRequest?, Error?) -> Void
    ) {
        _internal.createTokenRequest(tokenParams, options: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 81
    public func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        _internal.createTokenRequest(callback)
    }
}

// swift-migration: original location ARTAuth+Private.h, line 42
/// Messages related to the ARTAuth
public protocol ARTAuthDelegate: NSObjectProtocol {
    func auth(
        _ auth: ARTAuthInternal,
        didAuthorize tokenDetails: ARTTokenDetails,
        completion: @escaping (ARTAuthorizationState, ARTErrorInfo?) -> Void
    )
}

// swift-migration: original location ARTAuth+Private.h, line 16
public class ARTAuthInternal: NSObject {
    
    // swift-migration: original location ARTAuth.m, line 98
    private weak var _rest: ARTRestInternal? // weak because rest owns auth
    // swift-migration: original location ARTAuth.m, line 99
    private let _userQueue: DispatchQueue
    // swift-migration: original location ARTAuth.m, line 100
    private var _tokenParams: ARTTokenParams
    // swift-migration: original location ARTAuth.m, line 102
    private var _protocolClientId: String?
    // swift-migration: original location ARTAuth.m, line 103
    private var _authorizationsCount: Int = 0
    // swift-migration: original location ARTAuth.m, line 104
    private let _cancelationEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>
    
    // swift-migration: original location ARTAuth+Private.h, line 48
    public let queue: DispatchQueue
    
    // swift-migration: original location ARTAuth.m, line 91
    internal let logger: ARTInternalLog
    
    // swift-migration: original location ARTAuth+Private.h, line 19
    public var tokenDetails: ARTTokenDetails?
    
    // swift-migration: original location ARTAuth+Private.h, line 52
    public let options: ARTClientOptions
    
    // swift-migration: original location ARTAuth+Private.h, line 53
    public var method: ARTAuthMethod = ARTAuthMethodBasic
    
    // swift-migration: original location ARTAuth+Private.h, line 56
    public var timeOffset: NSNumber?
    
    // swift-migration: original location ARTAuth+Private.h, line 58
    public weak var delegate: ARTAuthDelegate?
    
    // swift-migration: original location ARTAuth.m, line 107
    public init(_ rest: ARTRestInternal, withOptions options: ARTClientOptions, logger: ARTInternalLog) {
        self._rest = rest
        self._userQueue = rest.userQueue
        self.queue = rest.queue
        self.tokenDetails = options.tokenDetails
        self.options = options
        self.logger = logger
        self._protocolClientId = nil
        self._cancelationEventEmitter = ARTInternalEventEmitter(queue: rest.queue)
        self._tokenParams = options.defaultTokenParams ?? ARTTokenParams(options: options)
        self._authorizationsCount = 0
        
        super.init()
        
        // swift-migration: original location ARTAuth.m, line 119
        validate(options)
        
        // swift-migration: original location ARTAuth.m, line 121
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveCurrentLocaleDidChangeNotification(_:)),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
        
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveApplicationSignificantTimeChangeNotification(_:)),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
        #else
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveApplicationSignificantTimeChangeNotification(_:)),
            name: NSNotification.Name.NSSystemClockDidChange,
            object: nil
        )
        #endif
    }
    
    // swift-migration: original location ARTAuth.m, line 141
    deinit {
        removeTimeOffsetObserver()
    }
    
    // swift-migration: original location ARTAuth.m, line 145
    private func removeTimeOffsetObserver() {
        NotificationCenter.default.removeObserver(self, name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.significantTimeChangeNotification, object: nil)
        #else
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSSystemClockDidChange, object: nil)
        #endif
    }
    
    // swift-migration: original location ARTAuth.m, line 154
    @objc private func didReceiveCurrentLocaleDidChangeNotification(_ notification: Notification) {
        ARTLogDebug(logger, "RS:\(_rest) NSCurrentLocaleDidChangeNotification received")
        discardTimeOffset()
    }
    
    // swift-migration: original location ARTAuth.m, line 159
    @objc private func didReceiveApplicationSignificantTimeChangeNotification(_ notification: Notification) {
        ARTLogDebug(logger, "RS:\(_rest) UIApplicationSignificantTimeChangeNotification received")
        discardTimeOffset()
    }
    
    // swift-migration: original location ARTAuth.m, line 164
    private func validate(_ options: ARTClientOptions) {
        ARTLogDebug(logger, "RS:\(_rest) validating \(options)")
        if options.isBasicAuth() {
            if !options.tls {
                fatalError("Basic authentication only connects over HTTPS (tls).")
            }
            ARTLogDebug(logger, "RS:\(_rest) setting up auth method Basic (anonymous)")
            method = ARTAuthMethodBasic
        } else if options.tokenDetails != nil {
            ARTLogDebug(logger, "RS:\(_rest) setting up auth method Token with token details")
            method = ARTAuthMethodToken
        } else if let token = options.token {
            ARTLogDebug(logger, "RS:\(_rest) setting up auth method Token with supplied token only")
            method = ARTAuthMethodToken
            options.tokenDetails = ARTTokenDetails(token: token)
        } else if options.authUrl != nil && options.authCallback != nil {
            fatalError("Incompatible authentication configuration: please specify either authCallback and authUrl.")
        } else if options.authUrl != nil {
            ARTLogDebug(logger, "RS:\(_rest) setting up auth method Token with authUrl")
            method = ARTAuthMethodToken
        } else if options.authCallback != nil {
            ARTLogDebug(logger, "RS:\(_rest) setting up auth method Token with authCallback")
            method = ARTAuthMethodToken
        } else if options.key != nil {
            ARTLogDebug(logger, "RS:\(_rest) setting up auth method Token with key")
            method = ARTAuthMethodToken
        } else {
            fatalError("Could not setup authentication method with given options.")
        }
        
        if options.clientId == "*" {
            fatalError("Invalid clientId: cannot contain only a wilcard \"*\".")
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 206
    private func mergeOptions(_ customOptions: ARTAuthOptions?) -> ARTAuthOptions {
        return customOptions != nil ? options.merge(with: customOptions!) : options
    }
    
    // swift-migration: original location ARTAuth.m, line 210
    private func storeOptions(_ customOptions: ARTAuthOptions) {
        options.key = customOptions.key
        options.tokenDetails = customOptions.tokenDetails?.copy() as? ARTTokenDetails
        options.authCallback = customOptions.authCallback
        options.authUrl = customOptions.authUrl
        options.authHeaders = customOptions.authHeaders
        options.authMethod = customOptions.authMethod
        options.authParams = customOptions.authParams
        options.useTokenAuth = customOptions.useTokenAuth
        options.queryTime = false
    }
    
    // swift-migration: original location ARTAuth.m, line 222
    private func mergeParams(_ customParams: ARTTokenParams?) -> ARTTokenParams {
        return customParams != nil ? customParams! : ARTTokenParams(options: options)
    }
    
    // swift-migration: original location ARTAuth.m, line 226
    private func storeParams(_ customParams: ARTTokenParams) {
        options.clientId = customParams.clientId
        options.defaultTokenParams = customParams
    }
    
    // swift-migration: original location ARTAuth.m, line 231
    private func buildURL(_ options: ARTAuthOptions, withParams params: ARTTokenParams) -> URL {
        var urlComponents = URLComponents(url: options.authUrl!, resolvingAgainstBaseURL: true)!
        
        if options.isMethodGET() {
            let unitedParams = params.toArray(withUnion: options.authParams)
            if urlComponents.queryItems == nil {
                urlComponents.queryItems = []
            }
            urlComponents.queryItems! += unitedParams
        }
        
        let formatQueryItem = URLQueryItem(name: "format", value: _rest!.defaultEncoder.formatAsString())
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + [formatQueryItem]
        
        let percentEncodedQuery = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        urlComponents.percentEncodedQuery = percentEncodedQuery
        
        return urlComponents.url!
    }
    
    // swift-migration: original location ARTAuth.m, line 259
    private func buildRequest(_ options: ARTAuthOptions, withParams params: ARTTokenParams) -> URLRequest {
        let url = buildURL(options, withParams: params)
        var request = URLRequest(url: url)
        request.httpMethod = options.authMethod
        
        if options.isMethodPOST() {
            let unitedParams = params.toDictionary(withUnion: options.authParams)
            let encodedParametersString = ARTFormEncode(unitedParams)
            let formData = encodedParametersString.data(using: .utf8)!
            request.httpBody = formData
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("\(formData.count)", forHTTPHeaderField: "Content-Length")
        } else {
            request.setValue(_rest!.defaultEncoder.mimeType(), forHTTPHeaderField: "Accept")
        }
        
        for (key, value) in options.authHeaders ?? [:] {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 54
    public var isTokenAuth: Bool {
        return tokenDetails != nil || authorizing_nosync
    }
    
    // swift-migration: original location ARTAuth.m, line 290
    public var tokenIsRenewable: Bool {
        return canRenewTokenAutomatically(options)
    }
    
    // swift-migration: original location ARTAuth.m, line 294
    public func canRenewTokenAutomatically(_ options: ARTAuthOptions) -> Bool {
        return options.authCallback != nil || options.authUrl != nil || options.key != nil
    }
    
    // swift-migration: original location ARTAuth.m, line 298
    public var tokenRemainsValid: Bool {
        if let tokenDetails = self.tokenDetails, tokenDetails.token != nil {
            if tokenDetails.expires == nil {
                return true
            }
            
            if !hasTimeOffset() {
                return true
            }
            
            if tokenDetails.expires!.timeIntervalSince(currentDate()) > 0 {
                return true
            }
        }
        return false
    }
    
    // swift-migration: original location ARTAuth.m, line 316
    public func requestToken(_ callback: @escaping ARTTokenDetailsCallback) {
        requestToken(_tokenParams, withOptions: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 321
    public func requestToken(
        _ tokenParams: ARTTokenParams?,
        withOptions authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        // swift-migration: Fixed - use proper queues instead of DispatchQueue.main/.global()
        var modifiedCallback = callback
        if callback != nil {
            let userCallback = callback
            modifiedCallback = { tokenDetails, error in
                self._userQueue.async {
                    userCallback(tokenDetails, error)
                }
            }
        }
        
        queue.async {
            self._requestToken(tokenParams, withOptions: authOptions, callback: modifiedCallback)
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 338
    @discardableResult
    private func _requestToken(
        _ tokenParams: ARTTokenParams?,
        withOptions authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) -> ARTCancellable? {
        let replacedOptions = authOptions ?? options
        let currentTokenParams = (tokenParams ?? _tokenParams).copy()
        var task: ARTCancellable?
        
        if !canRenewTokenAutomatically(replacedOptions) {
            callback(nil, ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: ARTAblyMessageNoMeansToRenewToken))
            return nil
        }
        
        let checkerCallback: ARTTokenDetailsCallback = { tokenDetails, error in
            if let error = error {
                if (error as NSError).code == NSURLErrorTimedOut {
                    let ablyError = ARTErrorInfo.create(withCode: ARTErrorErrorFromClientTokenCallback, message: "Error in requesting auth token")
                    callback(nil, ablyError)
                    return
                }
                callback(nil, error)
                return
            }
            
            if let clientId = self.clientId_nosync, 
               let tokenClientId = tokenDetails?.clientId,
               tokenClientId != "*",
               clientId != tokenClientId {
                callback(nil, ARTErrorInfo.create(withCode: ARTErrorIncompatibleCredentials, message: "incompatible credentials"))
                return
            }
            callback(tokenDetails, nil)
        }
        
        if let authUrl = replacedOptions.authUrl {
            let request = buildRequest(replacedOptions, withParams: currentTokenParams)
            ARTLogDebug(logger, "RS:\(_rest) using authUrl (\(request.httpMethod!) \(request.url!))")
            
            task = _rest!.executeRequest(request, withAuthOption: ARTAuthenticationOff, wrapperSDKAgents: nil) { response, data, error in
                if let error = error {
                    checkerCallback(nil, error)
                } else {
                    ARTLogDebug(self.logger, "RS:\(self._rest) ARTAuth: authUrl response \(String(describing: response))")
                    self.handleAuthUrlResponse(response!, withData: data!, completion: checkerCallback)
                }
            }
        } else {
            let tokenDetailsFactory: (ARTTokenParams, @escaping ARTTokenDetailsCallback) -> Void
            
            if let authCallback = replacedOptions.authCallback {
                var safeCallback: ARTTokenDetailsCompatibleCallback?
                
                task = artCancellableFromCallback({ tokenDetailsCompat, error in
                    if let error = error {
                        callback(nil, error)
                    } else {
                        tokenDetailsCompat?.toTokenDetails(self.toAuth()) { tokenDetails, error in
                            callback(tokenDetails, error)
                        }
                    }
                }, &safeCallback)
                
                let userCallback: ARTAuthCallback = { tokenParams, callback in
                    DispatchQueue.main.async {
                        authCallback(tokenParams, callback)
                    }
                }
                
                tokenDetailsFactory = { tokenParams, callback in
                    userCallback(tokenParams) { tokenDetailsCompat, error in
                        DispatchQueue.global().async {
                            let callback = safeCallback
                            if callback != nil {
                                callback!(tokenDetailsCompat, error)
                            }
                            task?.cancel()
                        }
                    }
                }
                ARTLogDebug(logger, "RS:\(_rest) ARTAuth: using authCallback")
            } else {
                tokenDetailsFactory = { tokenParams, callback in
                    let timeTask = self._createTokenRequest(currentTokenParams, options: replacedOptions) { tokenRequest, error in
                        if let error = error {
                            callback(nil, error)
                        } else {
                            task = self.executeTokenRequest(tokenRequest!, callback: callback)
                        }
                    }
                    if timeTask != nil {
                        task = timeTask
                    }
                }
            }
            
            tokenDetailsFactory(currentTokenParams, checkerCallback)
        }
        
        return task
    }
    
    // swift-migration: original location ARTAuth.m, line 446
    private func toAuth() -> ARTAuth {
        let dealloc = ARTQueuedDealloc(object: _rest!, queue: queue)
        return ARTAuth(internal: self, queuedDealloc: dealloc)
    }
    
    // swift-migration: original location ARTAuth.m, line 456
    private func handleAuthUrlResponse(
        _ response: HTTPURLResponse,
        withData data: Data,
        completion: @escaping ARTTokenDetailsCallback
    ) {
        if response.mimeType == "application/json" {
            var decodeError: Error?
            let tokenDetails = _rest!.encoders["application/json"]!.decodeTokenDetails(data, error: &decodeError)
            if let decodeError = decodeError {
                completion(nil, decodeError)
            } else if tokenDetails?.token == nil {
                let tokenRequest = _rest!.encoders["application/json"]!.decodeTokenRequest(data, error: &decodeError)
                if let decodeError = decodeError {
                    completion(nil, decodeError)
                } else if let tokenRequest = tokenRequest {
                    tokenRequest.toTokenDetails(toAuth(), callback: completion)
                } else {
                    completion(nil, ARTErrorInfo.create(withCode: ARTStateAuthUrlIncompatibleContent, message: "content response cannot be used for token request"))
                }
            } else {
                completion(tokenDetails, nil)
            }
        } else if response.mimeType == "text/plain" || response.mimeType == "application/jwt" {
            let token = String(data: data, encoding: .utf8)
            if token == "" {
                completion(nil, NSError(domain: ARTAblyErrorDomain, code: NSURLErrorCancelled, userInfo: [NSLocalizedDescriptionKey: "authUrl: token is empty"]))
                return
            }
            let tokenDetails = ARTTokenDetails(token: token!)
            completion(tokenDetails, nil)
        } else {
            completion(nil, NSError(domain: ARTAblyErrorDomain, code: NSURLErrorCancelled, userInfo: [NSLocalizedDescriptionKey: "authUrl: invalid MIME type"]))
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 492
    private func executeTokenRequest(
        _ tokenRequest: ARTTokenRequest,
        callback: @escaping ARTTokenDetailsCallback
    ) -> ARTCancellable? {
        let encoder = _rest!.defaultEncoder
        
        let requestUrl = URL(string: "/keys/\(tokenRequest.keyName!)/requestToken?format=\(encoder.formatAsString())", relativeTo: _rest!.baseUrl)!
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        
        var encodeError: Error?
        request.httpBody = encoder.encodeTokenRequest(tokenRequest, error: &encodeError)
        if let encodeError = encodeError {
            callback(nil, encodeError)
            return nil
        }
        request.setValue(encoder.mimeType(), forHTTPHeaderField: "Accept")
        request.setValue(encoder.mimeType(), forHTTPHeaderField: "Content-Type")
        
        return _rest!.executeRequest(request, withAuthOption: ARTAuthenticationOff, wrapperSDKAgents: nil) { response, data, error in
            if let error = error {
                callback(nil, error)
            } else {
                var decodeError: Error?
                let tokenDetails = encoder.decodeTokenDetails(data!, error: &decodeError)
                if let decodeError = decodeError {
                    callback(nil, decodeError)
                } else {
                    callback(tokenDetails, nil)
                }
            }
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 526
    public var authorizing: Bool {
        var count: Int = 0
        queue.sync {
            count = self._authorizationsCount
        }
        return count > 0
    }
    
    // swift-migration: original location ARTAuth.m, line 534
    public var authorizing_nosync: Bool {
        return _authorizationsCount > 0
    }
    
    // swift-migration: original location ARTAuth.m, line 538
    public func authorize(_ callback: @escaping ARTTokenDetailsCallback) {
        authorize(options.defaultTokenParams, options: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 542
    public func authorize(
        _ tokenParams: ARTTokenParams?,
        options authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) {
        // swift-migration: Fixed - use proper queues instead of DispatchQueue.main/.global()
        var modifiedCallback = callback
        if callback != nil {
            let userCallback = callback
            modifiedCallback = { tokenDetails, error in
                self._userQueue.async {
                    userCallback(tokenDetails, error)
                }
            }
        }
        
        queue.async {
            self._authorize(tokenParams, options: authOptions, callback: modifiedCallback)
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 559
    @discardableResult
    public func _authorize(
        _ tokenParams: ARTTokenParams?,
        options authOptions: ARTAuthOptions?,
        callback: @escaping ARTTokenDetailsCallback
    ) -> ARTCancellable? {
        let replacedOptions = authOptions?.copy() as? ARTAuthOptions ?? options.copy() as! ARTAuthOptions
        storeOptions(replacedOptions)
        
        let currentTokenParams = mergeParams(tokenParams)
        storeParams(currentTokenParams)
        
        let lastDelegate = delegate
        
        let authorizeId = UUID().uuidString
        var hasBeenExplicitlyCanceled = false
        
        ARTLogVerbose(logger, "RS:\(_rest) ARTAuthInternal [authorize.\(authorizeId), delegate=\(lastDelegate != nil ? "YES" : "NO")]: requesting new token")
        
        var task: ARTCancellable?
        _authorizationsCount += 1
        
        task = _requestToken(currentTokenParams, withOptions: replacedOptions) { tokenDetails, error in
            self._authorizationsCount -= 1
            
            let successCallbackBlock = {
                ARTLogVerbose(self.logger, "RS:\(self._rest) ARTAuthInternal [authorize.\(authorizeId)]: success callback: \(String(describing: tokenDetails))")
                callback(tokenDetails, nil)
            }
            
            let failureCallbackBlock = { (error: Error?) in
                ARTLogVerbose(self.logger, "RS:\(self._rest) ARTAuthInternal [authorize.\(authorizeId)]: failure callback: \(String(describing: error)) with token details \(String(describing: tokenDetails))")
                callback(tokenDetails, error)
            }
            
            let canceledCallbackBlock = {
                ARTLogVerbose(self.logger, "RS:\(self._rest) ARTAuthInternal [authorize.\(authorizeId)]: canceled callback")
                callback(nil, ARTErrorInfo.create(withCode: Int(kCFURLErrorCancelled), message: "Authorization has been canceled"))
            }
            
            if let error = error {
                ARTLogDebug(self.logger, "RS:\(self._rest) ARTAuthInternal [authorize.\(authorizeId)]: token request failed: \(error)")
                failureCallbackBlock(error)
                return
            }
            
            if hasBeenExplicitlyCanceled {
                canceledCallbackBlock()
                return
            }
            
            ARTLogDebug(self.logger, "RS:\(self._rest) ARTAuthInternal [authorize.\(authorizeId)]: token request succeeded: \(String(describing: tokenDetails))")
            
            self.setTokenDetails(tokenDetails)
            self.method = ARTAuthMethodToken
            
            if tokenDetails == nil {
                failureCallbackBlock(ARTErrorInfo.create(withCode: 0, message: "Token details are empty"))
            } else if let lastDelegate = lastDelegate {
                lastDelegate.auth(self, didAuthorize: tokenDetails!) { state, error in
                    switch state {
                    case .succeeded:
                        if hasBeenExplicitlyCanceled {
                            canceledCallbackBlock()
                            return
                        }
                        successCallbackBlock()
                        self.setTokenDetails(tokenDetails)
                    case .failed:
                        ARTLogDebug(self.logger, "RS:\(self._rest) authorization failed with \"\(String(describing: error))\" but the request token has already completed")
                        failureCallbackBlock(error)
                        self.setTokenDetails(nil)
                    case .cancelled:
                        ARTLogDebug(self.logger, "RS:\(self._rest) authorization cancelled but the request token has already completed")
                        canceledCallbackBlock()
                    }
                }
            } else {
                successCallbackBlock()
            }
        }
        
        _cancelationEventEmitter.once { error in
            hasBeenExplicitlyCanceled = true
            task?.cancel()
        }
        
        return task
    }
    
    // swift-migration: original location ARTAuth.m, line 656
    public func cancelAuthorization(_ error: ARTErrorInfo?) {
        ARTLogDebug(logger, "RS:\(_rest) authorization cancelled with \(String(describing: error))")
        _cancelationEventEmitter.emit(nil, with: error)
    }
    
    // swift-migration: original location ARTAuth.m, line 661
    public func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        // swift-migration: Fixed - use stored options instead of creating empty ARTAuthOptions()
        createTokenRequest(_tokenParams, options: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 665
    public func createTokenRequest(
        _ tokenParams: ARTTokenParams?,
        options: ARTAuthOptions?,
        callback: @escaping (ARTTokenRequest?, Error?) -> Void
    ) {
        // swift-migration: Fixed - use proper queues instead of DispatchQueue.main/.global()
        var modifiedCallback = callback
        if callback != nil {
            let userCallback = callback
            modifiedCallback = { tokenRequest, error in
                self._userQueue.async {
                    userCallback(tokenRequest, error)
                }
            }
        }
        
        queue.async {
            self._createTokenRequest(tokenParams, options: options, callback: modifiedCallback)
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 680
    @discardableResult
    private func _createTokenRequest(
        _ tokenParams: ARTTokenParams?,
        options: ARTAuthOptions?,
        callback: @escaping (ARTTokenRequest?, Error?) -> Void
    ) -> ARTCancellable? {
        // swift-migration: Fixed - use stored options instead of creating empty ARTAuthOptions()
        let replacedOptions = options ?? self.options
        let currentTokenParams = (tokenParams ?? _tokenParams).copy()
        currentTokenParams.timestamp = currentDate()
        
        if let capability = currentTokenParams.capability {
            do {
                _ = try JSONSerialization.jsonObject(with: capability.data(using: String.Encoding.utf8)!, options: [])
            } catch let errorCapability {
                let userInfo = [NSLocalizedDescriptionKey: "Capability: \(errorCapability.localizedDescription)"]
                callback(nil, NSError(domain: ARTAblyErrorDomain, code: (errorCapability as NSError).code, userInfo: userInfo))
                return nil
            }
        }
        
        if replacedOptions.key == nil {
            let userInfo = [NSLocalizedDescriptionKey: "no key provided for signing token requests"]
            callback(nil, NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: userInfo))
            return nil
        }
        
        if hasTimeOffsetWithValue() && !replacedOptions.queryTime {
            currentTokenParams.timestamp = currentDate()
            callback(currentTokenParams.sign(replacedOptions.key!), nil)
            return nil
        } else {
            if replacedOptions.queryTime {
                return _rest!._time(withWrapperSDKAgents: nil) { time, error in
                    if let error = error {
                        callback(nil, error)
                    } else {
                        let serverTime = self.handleServerTime(time!)
                        self.timeOffset = NSNumber(value: serverTime.timeIntervalSinceNow)
                        currentTokenParams.timestamp = serverTime
                        callback(currentTokenParams.sign(replacedOptions.key!), nil)
                    }
                }
            } else {
                callback(currentTokenParams.sign(replacedOptions.key!), nil)
                return nil
            }
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 730
    private func handleServerTime(_ time: Date) -> Date {
        return time
    }
    
    // swift-migration: original location ARTAuth.m, line 734
    public func setProtocolClientId(_ clientId: String?) {
        _protocolClientId = clientId
        #if os(iOS)
        setLocalDeviceClientId_nosync(clientId)
        #endif
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 18
    public var clientId: String? {
        var clientId: String?
        queue.sync {
            clientId = self.clientId_nosync
        }
        return clientId
    }
    
    // swift-migration: original location ARTAuth.m, line 749
    public var clientId_nosync: String? {
        if let protocolClientId = _protocolClientId {
            return protocolClientId
        } else if let tokenClientId = tokenDetails?.clientId {
            return tokenClientId
        } else {
            return options.clientId
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 761
    private func currentDate() -> Date {
        return Date().addingTimeInterval(timeOffset?.doubleValue ?? 0)
    }
    
    // swift-migration: original location ARTAuth.m, line 765
    private func hasTimeOffset() -> Bool {
        return timeOffset != nil
    }
    
    // swift-migration: original location ARTAuth.m, line 769
    private func hasTimeOffsetWithValue() -> Bool {
        return timeOffset != nil && timeOffset!.doubleValue > 0
    }
    
    // swift-migration: original location ARTAuth.m, line 773
    public func discardTimeOffset() {
        if _rest == nil {
            removeTimeOffsetObserver()
            return
        }
        
        queue.sync {
            clearTimeOffset()
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 791
    public func setTokenDetails(_ tokenDetails: ARTTokenDetails?) {
        self.tokenDetails = tokenDetails
        #if os(iOS)
        setLocalDeviceClientId_nosync(tokenDetails?.clientId)
        #endif
    }
    
    // swift-migration: original location ARTAuth.m, line 798
    public func setTimeOffset(_ offset: TimeInterval) {
        timeOffset = NSNumber(value: offset)
    }
    
    // swift-migration: original location ARTAuth.m, line 802
    public func clearTimeOffset() {
        timeOffset = nil
    }
    
    // swift-migration: original location ARTAuth.m, line 806
    public var appId: String? {
        var s: String?
        if let key = options.key {
            s = key
        } else if let token = options.token {
            s = token
        } else if let tokenDetailsToken = tokenDetails?.token {
            s = tokenDetailsToken
        }
        
        guard let s = s else { return nil }
        
        let parts = s.components(separatedBy: ".")
        if parts.count < 2 {
            return nil
        }
        return parts[0]
    }
    
    #if os(iOS)
    // swift-migration: original location ARTAuth.m, line 826
    private func setLocalDeviceClientId_nosync(_ clientId: String?) {
        guard let clientId = clientId,
              clientId != "*",
              clientId != _rest?.device_nosync.clientId else {
            return
        }
        
        _rest?.device_nosync.setClientId(clientId)
        _rest?.storage.setObject(clientId, forKey: ARTClientIdKey)
        _rest?.push.getActivationMachine { stateMachine in
            if !(stateMachine.current_nosync is ARTPushActivationStateNotActivated) {
                stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
            }
        }
    }
    #endif
}

// swift-migration: original location ARTAuth.m, line 842
extension String: ARTTokenDetailsCompatible {
    public func toTokenDetails(_ auth: ARTAuth, callback: @escaping (ARTTokenDetails?, Error?) -> Void) {
        callback(ARTTokenDetails(token: self), nil)
    }
}

// swift-migration: original location ARTAuth.m, line 850
public func ARTAuthorizationStateToStr(_ state: ARTAuthorizationState) -> String {
    switch state {
    case .succeeded:
        return "Succeeded" // 0
    case .failed:
        return "Failed" // 1
    case .cancelled:
        return "Cancelled" // 2
    }
}

// swift-migration: original location ARTAuth.m, line 863
extension ARTEvent {
    // swift-migration: original location ARTAuth.m, line 865
    public convenience init(authorizationState value: ARTAuthorizationState) {
        self.init(string: "ARTAuthorizationState\(ARTAuthorizationStateToStr(value))")
    }
    
    // swift-migration: original location ARTAuth.m, line 869
    public class func new(withAuthorizationState value: ARTAuthorizationState) -> ARTEvent {
        return ARTEvent(authorizationState: value)
    }
}