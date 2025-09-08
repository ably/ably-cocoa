import Foundation

// swift-migration: original location ARTAuth+Private.h, line 8
public enum ARTAuthorizationState: UInt {
    case succeeded = 0  // ItemType: nil
    case failed = 1     // ItemType: NSError  
    case cancelled = 2  // ItemType: nil
}

// swift-migration: original location ARTAuth+Private.h, line 16
internal class ARTAuthInternal {
    // swift-migration: original location ARTAuth+Private.h, line 18 and ARTAuth.m clientId getter
    internal var clientId: String? {
        var result: String?
        queue.sync {
            result = clientId_nosync()
        }
        return result
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 19
    internal private(set) var tokenDetails: ARTTokenDetails?
    
    // swift-migration: original location ARTAuth+Private.h, line 48
    internal let queue: DispatchQueue
    
    // swift-migration: original location ARTAuth+Private.h, line 52
    internal let options: ARTClientOptions
    
    // swift-migration: original location ARTAuth+Private.h, line 53
    internal private(set) var method: ARTAuthMethod = .basic
    
    // swift-migration: original location ARTAuth+Private.h, line 56
    internal private(set) var timeOffset: NSNumber?
    
    // swift-migration: original location ARTAuth+Private.h, line 58
    internal weak var delegate: ARTAuthDelegate?
    
    // swift-migration: original location ARTAuth+Private.h, line 91
    private let logger: ARTInternalLog
    
    // swift-migration: original location ARTAuth.m, line 98
    private weak var rest: ARTRestInternal? // weak because rest owns auth
    
    // swift-migration: original location ARTAuth.m, line 99
    private let userQueue: DispatchQueue
    
    // swift-migration: original location ARTAuth.m, line 100
    private var _tokenParams: ARTTokenParams
    
    // swift-migration: original location ARTAuth.m, line 102
    private var protocolClientId: String?
    
    // swift-migration: original location ARTAuth.m, line 103
    private var authorizationsCount: Int = 0
    
    // swift-migration: original location ARTAuth.m, line 104
    private let cancelationEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>
    
    // swift-migration: original location ARTAuth+Private.h, line 76 and ARTAuth.m, line 107
    internal init(_ rest: ARTRestInternal, withOptions options: ARTClientOptions, logger: ARTInternalLog) {
        self.rest = rest
        self.userQueue = rest.userQueue
        self.queue = rest.queue
        self.tokenDetails = options.tokenDetails
        self.options = options
        self.logger = logger
        self.protocolClientId = nil
        self.cancelationEventEmitter = ARTInternalEventEmitter(queue: rest.queue)
        self._tokenParams = options.defaultTokenParams ?? ARTTokenParams(options: options)
        self.authorizationsCount = 0
        
        validate(options)
        
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
            name: .NSSystemClockDidChange,
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
        NotificationCenter.default.removeObserver(self, name: .NSSystemClockDidChange, object: nil)
        #endif
    }
    
    // swift-migration: original location ARTAuth.m, line 154
    @objc private func didReceiveCurrentLocaleDidChangeNotification(_ notification: Notification) {
        ARTLogDebug(logger, "RS:\(String(describing: rest)) NSCurrentLocaleDidChangeNotification received")
        discardTimeOffset()
    }
    
    // swift-migration: original location ARTAuth.m, line 159
    @objc private func didReceiveApplicationSignificantTimeChangeNotification(_ notification: Notification) {
        ARTLogDebug(logger, "RS:\(String(describing: rest)) UIApplicationSignificantTimeChangeNotification received")
        discardTimeOffset()
    }
    
    // swift-migration: original location ARTAuth.m, line 164
    private func validate(_ options: ARTClientOptions) {
        // Only called from constructor, no need to synchronize.
        ARTLogDebug(logger, "RS:\(String(describing: rest)) validating \(options)")
        
        if options.isBasicAuth() {
            if !options.tls {
                fatalError("Basic authentication only connects over HTTPS (tls).")
            }
            // Basic
            ARTLogDebug(logger, "RS:\(String(describing: rest)) setting up auth method Basic (anonymous)")
            method = .basic
        } else if options.tokenDetails != nil {
            // TokenDetails
            ARTLogDebug(logger, "RS:\(String(describing: rest)) setting up auth method Token with token details")
            method = .token
        } else if options.token != nil {
            // Token
            ARTLogDebug(logger, "RS:\(String(describing: rest)) setting up auth method Token with supplied token only")
            method = .token
            options.tokenDetails = ARTTokenDetails(token: options.token!)
        } else if options.authUrl != nil && options.authCallback != nil {
            fatalError("Incompatible authentication configuration: please specify either authCallback and authUrl.")
        } else if options.authUrl != nil {
            // Authentication url
            ARTLogDebug(logger, "RS:\(String(describing: rest)) setting up auth method Token with authUrl")
            method = .token
        } else if options.authCallback != nil {
            // Authentication callback
            ARTLogDebug(logger, "RS:\(String(describing: rest)) setting up auth method Token with authCallback")
            method = .token
        } else if options.key != nil {
            // Token
            ARTLogDebug(logger, "RS:\(String(describing: rest)) setting up auth method Token with key")
            method = .token
        } else {
            fatalError("Could not setup authentication method with given options.")
        }
        
        if options.clientId == "*" {
            fatalError("Invalid clientId: cannot contain only a wildcard \"*\".")
        }
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 78 and ARTAuth.m, line 206
    private func mergeOptions(_ customOptions: ARTAuthOptions?) -> ARTAuthOptions {
        return customOptions != nil ? options.merge(with: customOptions!) : options
    }
    
    // swift-migration: original location ARTAuth.m, line 210
    private func storeOptions(_ customOptions: ARTAuthOptions) {
        options.key = customOptions.key
        options.tokenDetails = customOptions.tokenDetails?.copy()
        options.authCallback = customOptions.authCallback
        options.authUrl = customOptions.authUrl
        options.authHeaders = customOptions.authHeaders
        options.authMethod = customOptions.authMethod
        options.authParams = customOptions.authParams
        options.useTokenAuth = customOptions.useTokenAuth
        options.queryTime = false
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 79 and ARTAuth.m, line 222
    private func mergeParams(_ customParams: ARTTokenParams?) -> ARTTokenParams {
        return customParams ?? ARTTokenParams(options: options)
    }
    
    // swift-migration: original location ARTAuth.m, line 226
    private func storeParams(_ customOptions: ARTTokenParams) {
        options.clientId = customOptions.clientId
        options.defaultTokenParams = customOptions
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 81 and ARTAuth.m, line 231
    private func buildURL(_ options: ARTAuthOptions, withParams params: ARTTokenParams) -> URL? {
        guard let authUrl = options.authUrl else { return nil }
        var urlComponents = URLComponents(url: authUrl, resolvingAgainstBaseURL: true)
        
        if options.isMethodGET() {
            // TokenParams take precedence over any configured authParams when a name conflict occurs
            let unitedParams = params.toArray(withUnion: options.authParams)
            
            // When GET, use query string params
            if urlComponents?.queryItems == nil {
                urlComponents?.queryItems = []
            }
            urlComponents?.queryItems?.append(contentsOf: unitedParams)
        }
        
        guard let rest = rest else { return nil }
        urlComponents?.queryItems?.append(URLQueryItem(name: "format", value: rest.defaultEncoder.formatAsString()))
        
        // swift-migration: Handling '+' sign pitfall as documented in original code
        if let percentEncodedQuery = urlComponents?.percentEncodedQuery {
            urlComponents?.percentEncodedQuery = percentEncodedQuery.replacingOccurrences(of: "+", with: "%2B")
        }
        
        return urlComponents?.url
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 82 and ARTAuth.m, line 259
    private func buildRequest(_ options: ARTAuthOptions, withParams params: ARTTokenParams) -> URLRequest? {
        guard let url = buildURL(options, withParams: params) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = options.authMethod
        
        // HTTP Header Fields
        if options.isMethodPOST() {
            // TokenParams take precedence over any configured authParams when a name conflict occurs
            let unitedParams = params.toDictionary(withUnion: options.authParams)
            let encodedParametersString = ARTFormEncode(unitedParams)
            let formData = encodedParametersString.data(using: .utf8)
            request.httpBody = formData
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            if let formData = formData {
                request.setValue("\(formData.count)", forHTTPHeaderField: "Content-Length")
            }
        } else {
            guard let rest = rest else { return nil }
            request.setValue(rest.defaultEncoder.mimeType(), forHTTPHeaderField: "Accept")
        }
        
        if let authHeaders = options.authHeaders {
            for (key, value) in authHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 54 and ARTAuth.m, line 286
    internal var isTokenAuth: Bool {
        return tokenDetails != nil || authorizing_nosync
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 97 and ARTAuth.m, line 290
    internal var tokenIsRenewable: Bool {
        return canRenewTokenAutomatically(options)
    }
    
    // swift-migration: original location ARTAuth.m, line 294
    private func canRenewTokenAutomatically(_ options: ARTAuthOptions) -> Bool {
        return options.authCallback != nil || options.authUrl != nil || options.key != nil
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 100 and ARTAuth.m, line 298
    internal var tokenRemainsValid: Bool {
        guard let tokenDetails = tokenDetails, tokenDetails.token != nil else {
            return false
        }
        
        guard let expires = tokenDetails.expires else {
            return true
        }
        
        // RSA4b1: Only check expiry client-side if local clock has been adjusted.
        // If it hasn't, assume the token remains valid.
        if !hasTimeOffset {
            return true
        }
        
        return expires.timeIntervalSince(currentDate) > 0
    }
    
    // swift-migration: original location ARTAuth.m, line 316
    internal func requestToken(_ callback: @escaping ARTTokenDetailsCallback) {
        // If the object arguments are omitted, the client library configured defaults are used
        requestToken(_tokenParams, withOptions: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 321
    internal func requestToken(_ tokenParams: ARTTokenParams?, withOptions authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback) {
        let userCallback = callback
        let wrappedCallback: ARTTokenDetailsCallback = { tokenDetails, error in
            self.userQueue.async {
                userCallback(tokenDetails, error)
            }
        }
        
        queue.async {
            self._requestToken(tokenParams, withOptions: authOptions, callback: wrappedCallback)
        }
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 68 and ARTAuth.m, line 338
    @discardableResult
    private func _requestToken(_ tokenParams: ARTTokenParams?, withOptions authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback) -> ARTCancellable? {
        // If options, params passed in, they're used instead of stored, don't merge them
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
            
            guard let tokenDetails = tokenDetails else {
                callback(nil, error)
                return
            }
            
            if let clientId = self.clientId_nosync(), let tokenClientId = tokenDetails.clientId,
               tokenClientId != "*" && clientId != tokenClientId {
                callback(nil, ARTErrorInfo.create(withCode: ARTErrorIncompatibleCredentials, message: "incompatible credentials"))
                return
            }
            callback(tokenDetails, nil)
        }
        
        if replacedOptions.authUrl != nil {
            guard let request = buildRequest(replacedOptions, withParams: currentTokenParams),
                  let rest = rest else {
                callback(nil, ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: "Failed to build request"))
                return nil
            }
            
            ARTLogDebug(logger, "RS:\(String(describing: rest)) using authUrl (\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? ""))")
            
            task = rest.executeRequest(request, withAuthOption: .off, wrapperSDKAgents: nil) { response, data, error in
                if let error = error {
                    checkerCallback(nil, error)
                } else if let response = response, let data = data {
                    ARTLogDebug(self.logger, "RS:\(String(describing: self.rest)) ARTAuth: authUrl response \(response)")
                    self.handleAuthUrlResponse(response, withData: data, completion: checkerCallback)
                } else {
                    checkerCallback(nil, ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: "Invalid response"))
                }
            }
        } else {
            var tokenDetailsFactory: ((ARTTokenParams, @escaping ARTTokenDetailsCallback) -> Void)?
            
            if let authCallback = replacedOptions.authCallback {
                // swift-migration: Complex callback management to prevent memory leaks as documented in original code
                var safeCallback: ARTTokenDetailsCompatibleCallback?
                task = artCancellableFromCallback({ tokenDetailsCompat, error in
                    if let error = error {
                        callback(nil, error)
                    } else if let tokenDetailsCompat = tokenDetailsCompat {
                        tokenDetailsCompat.toTokenDetails(self.toAuth(), callback: callback)
                    }
                }, &safeCallback)
                
                let userCallback: ARTAuthCallback = { tokenParams, callback in
                    self.userQueue.async {
                        authCallback(tokenParams, callback)
                    }
                }
                
                tokenDetailsFactory = { tokenParams, callback in
                    userCallback(tokenParams) { tokenDetailsCompat, error in
                        self.queue.async {
                            // safeCallback is declared weak above so could be nil at this point.
                            if let callback = safeCallback {
                                callback(tokenDetailsCompat, error)
                            }
                            task?.cancel()
                        }
                    }
                }
                ARTLogDebug(logger, "RS:\(String(describing: rest)) ARTAuth: using authCallback")
            } else {
                tokenDetailsFactory = { tokenParams, callback in
                    // Create a TokenRequest and execute it
                    let timeTask = self._createTokenRequest(currentTokenParams, options: replacedOptions) { tokenRequest, error in
                        if let error = error {
                            callback(nil, error)
                        } else if let tokenRequest = tokenRequest {
                            task = self.executeTokenRequest(tokenRequest, callback: callback)
                        }
                    }
                    if let timeTask = timeTask {
                        task = timeTask
                    }
                }
            }
            
            tokenDetailsFactory?(currentTokenParams, checkerCallback)
        }
        
        return task
    }
    
    // swift-migration: original location ARTAuth.m, line 446
    private func toAuth() -> ARTAuth {
        // This feels hackish, but the alternative would be to change
        // ARTTokenDetailsCompatible to take a ARTAuthProtocol so we can just
        // pass self, but that would
        // break backwards-compatibility for users that have their own
        // ARTTokenDetailsCompatible implementations.
        guard let rest = rest else {
            fatalError("Rest is nil in toAuth")
        }
        let dealloc = ARTQueuedDealloc(object: rest, queue: queue)
        return ARTAuth(internal: self, queuedDealloc: dealloc)
    }
    
    // swift-migration: original location ARTAuth.m, line 456
    private func handleAuthUrlResponse(_ response: HTTPURLResponse, withData data: Data, completion: @escaping ARTTokenDetailsCallback) {
        guard let rest = rest else {
            completion(nil, ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: "Rest is nil"))
            return
        }
        
        // The token retrieved is assumed by the library to be a token string if the response has Content-Type "text/plain", or taken to be a TokenRequest or TokenDetails object if the response has Content-Type "application/json"
        if response.mimeType == "application/json" {
            var decodeError: Error?
            if let tokenDetails = rest.encoders["application/json"]?.decodeTokenDetails(data, error: &decodeError) {
                if decodeError != nil {
                    completion(nil, decodeError)
                } else if tokenDetails.token == nil {
                    if let tokenRequest = rest.encoders["application/json"]?.decodeTokenRequest(data, error: &decodeError) {
                        if decodeError != nil {
                            completion(nil, decodeError)
                        } else {
                            tokenRequest.toTokenDetails(toAuth(), callback: completion)
                        }
                    } else {
                        completion(nil, ARTErrorInfo.create(withCode: ARTStateAuthUrlIncompatibleContent, message: "content response cannot be used for token request"))
                    }
                } else {
                    completion(tokenDetails, nil)
                }
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
    
    // swift-migration: original location ARTAuth+Private.h, line 85 and ARTAuth.m, line 492
    @discardableResult
    private func executeTokenRequest(_ tokenRequest: ARTTokenRequest, callback: @escaping ARTTokenDetailsCallback) -> ARTCancellable? {
        guard let rest = rest else {
            callback(nil, ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: "Rest is nil"))
            return nil
        }
        
        let encoder = rest.defaultEncoder
        
        guard let keyName = tokenRequest.keyName else {
            callback(nil, ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: "Token request key name is nil"))
            return nil
        }
        
        let requestUrl = URL(string: "/keys/\(keyName)/requestToken?format=\(encoder.formatAsString())", relativeTo: rest.baseUrl)!
        
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
        
        return rest.executeRequest(request, withAuthOption: .off, wrapperSDKAgents: nil) { response, data, error in
            if let error = error {
                callback(nil, error)
            } else if let data = data {
                var decodeError: Error?
                let tokenDetails = encoder.decodeTokenDetails(data, error: &decodeError)
                if let decodeError = decodeError {
                    callback(nil, decodeError)
                } else {
                    callback(tokenDetails, nil)
                }
            }
        }
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 59 and ARTAuth.m, line 526
    internal var authorizing: Bool {
        var count = 0
        queue.sync {
            count = authorizationsCount
        }
        return count > 0
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 60 and ARTAuth.m, line 534
    internal var authorizing_nosync: Bool {
        return authorizationsCount > 0
    }
    
    // swift-migration: original location ARTAuth.m, line 538
    internal func authorize(_ callback: @escaping ARTTokenDetailsCallback) {
        authorize(options.defaultTokenParams, options: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 542
    internal func authorize(_ tokenParams: ARTTokenParams?, options authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback) {
        let userCallback = callback
        let wrappedCallback: ARTTokenDetailsCallback = { tokenDetails, error in
            self.userQueue.async {
                userCallback(tokenDetails, error)
            }
        }
        
        queue.async {
            self._authorize(tokenParams, options: authOptions, callback: wrappedCallback)
        }
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 62 and ARTAuth.m, line 559
    @discardableResult
    internal func _authorize(_ tokenParams: ARTTokenParams?, options authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback) -> ARTCancellable? {
        let replacedOptions = authOptions?.copy() ?? options.copy()
        storeOptions(replacedOptions)
        
        let currentTokenParams = mergeParams(tokenParams)
        storeParams(currentTokenParams)
        
        let lastDelegate = delegate
        
        let authorizeId = UUID().uuidString
        var hasBeenExplicitlyCanceled = false
        
        // Request always a new token
        ARTLogVerbose(logger, "RS:\(String(describing: rest)) ARTAuthInternal [authorize.\(authorizeId), delegate=\(lastDelegate != nil ? "YES" : "NO")]: requesting new token")
        
        authorizationsCount += 1
        let task = _requestToken(currentTokenParams, withOptions: replacedOptions) { tokenDetails, error in
            self.authorizationsCount -= 1
            
            let successCallbackBlock: () -> Void = {
                ARTLogVerbose(self.logger, "RS:\(String(describing: self.rest)) ARTAuthInternal [authorize.\(authorizeId)]: success callback: \(String(describing: tokenDetails))")
                callback(tokenDetails, nil)
            }
            
            let failureCallbackBlock: (Error) -> Void = { error in
                ARTLogVerbose(self.logger, "RS:\(String(describing: self.rest)) ARTAuthInternal [authorize.\(authorizeId)]: failure callback: \(error) with token details \(String(describing: tokenDetails))")
                callback(tokenDetails, error)
            }
            
            let canceledCallbackBlock: () -> Void = {
                ARTLogVerbose(self.logger, "RS:\(String(describing: self.rest)) ARTAuthInternal [authorize.\(authorizeId)]: canceled callback")
                callback(nil, ARTErrorInfo.create(withCode: Int(kCFURLErrorCancelled), message: "Authorization has been canceled"))
            }
            
            if let error = error {
                ARTLogDebug(self.logger, "RS:\(String(describing: self.rest)) ARTAuthInternal [authorize.\(authorizeId)]: token request failed: \(error)")
                failureCallbackBlock(error)
                return
            }
            
            if hasBeenExplicitlyCanceled {
                canceledCallbackBlock()
                return
            }
            
            ARTLogDebug(self.logger, "RS:\(String(describing: self.rest)) ARTAuthInternal [authorize.\(authorizeId)]: token request succeeded: \(String(describing: tokenDetails))")
            
            self.setTokenDetails(tokenDetails)
            self.method = .token
            
            guard let tokenDetails = tokenDetails else {
                failureCallbackBlock(ARTErrorInfo.create(withCode: 0, message: "Token details are empty"))
                return
            }
            
            if let lastDelegate = lastDelegate {
                lastDelegate.auth(self, didAuthorize: tokenDetails) { state, error in
                    switch state {
                    case .succeeded:
                        if hasBeenExplicitlyCanceled {
                            canceledCallbackBlock()
                            return
                        }
                        successCallbackBlock()
                        self.setTokenDetails(tokenDetails)
                    case .failed:
                        ARTLogDebug(self.logger, "RS:\(String(describing: self.rest)) authorization failed with \"\(String(describing: error))\" but the request token has already completed")
                        failureCallbackBlock(error ?? ARTErrorInfo.create(withCode: 0, message: "Unknown error"))
                        self.setTokenDetails(nil)
                    case .cancelled:
                        ARTLogDebug(self.logger, "RS:\(String(describing: self.rest)) authorization cancelled but the request token has already completed")
                        canceledCallbackBlock()
                    }
                }
            } else {
                successCallbackBlock()
            }
        }
        
        cancelationEventEmitter.once { error in
            hasBeenExplicitlyCanceled = true
            task?.cancel()
        }
        
        return task
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 66 and ARTAuth.m, line 656
    internal func cancelAuthorization(_ error: ARTErrorInfo?) {
        ARTLogDebug(logger, "RS:\(String(describing: rest)) authorization cancelled with \(String(describing: error))")
        cancelationEventEmitter.emit(nil, with: error)
    }
    
    // swift-migration: original location ARTAuth.m, line 661
    internal func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        createTokenRequest(_tokenParams, options: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.m, line 665
    internal func createTokenRequest(_ tokenParams: ARTTokenParams?, options: ARTAuthOptions?, callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        let userCallback = callback
        let wrappedCallback: (ARTTokenRequest?, Error?) -> Void = { tokenRequest, error in
            self.userQueue.async {
                userCallback(tokenRequest, error)
            }
        }
        
        queue.async {
            self._createTokenRequest(tokenParams, options: options, callback: wrappedCallback)
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 680
    @discardableResult
    private func _createTokenRequest(_ tokenParams: ARTTokenParams?, options: ARTAuthOptions?, callback: @escaping (ARTTokenRequest?, Error?) -> Void) -> ARTCancellable? {
        let replacedOptions = options ?? self.options
        let currentTokenParams = tokenParams ?? _tokenParams.copy() // copy since _tokenParams should be read-only
        currentTokenParams.timestamp = currentDate
        
        if let capability = currentTokenParams.capability {
            // Validate: Capability JSON text
            do {
                _ = try JSONSerialization.jsonObject(with: capability.data(using: .utf8)!, options: [])
            } catch {
                let userInfo = [NSLocalizedDescriptionKey: "Capability: \(error.localizedDescription)"]
                callback(nil, NSError(domain: ARTAblyErrorDomain, code: (error as NSError).code, userInfo: userInfo))
                return nil
            }
        }
        
        guard let key = replacedOptions.key else {
            let userInfo = [NSLocalizedDescriptionKey: "no key provided for signing token requests"]
            callback(nil, NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: userInfo))
            return nil
        }
        
        if hasTimeOffsetWithValue && !replacedOptions.queryTime {
            currentTokenParams.timestamp = currentDate
            callback(currentTokenParams.sign(key), nil)
            return nil
        } else {
            if replacedOptions.queryTime {
                guard let rest = rest else {
                    callback(nil, ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: "Rest is nil"))
                    return nil
                }
                
                return rest._time(withWrapperSDKAgents: nil) { time, error in
                    if let error = error {
                        callback(nil, error)
                    } else if let time = time {
                        let serverTime = self.handleServerTime(time)
                        self.timeOffset = NSNumber(value: serverTime.timeIntervalSinceNow)
                        currentTokenParams.timestamp = serverTime
                        callback(currentTokenParams.sign(key), nil)
                    }
                }
            } else {
                callback(currentTokenParams.sign(key), nil)
                return nil
            }
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 730
    private func handleServerTime(_ time: Date) -> Date {
        return time
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 88 and ARTAuth.m, line 734
    internal func setProtocolClientId(_ clientId: String?) {
        protocolClientId = clientId
        #if os(iOS)
        setLocalDeviceClientId_nosync(protocolClientId)
        #endif
    }
    
    // swift-migration: original location ARTAuth.m, line 741
    // swift-migration: Method removed as it duplicates the property above
    
    // swift-migration: original location ARTAuth+Private.h, line 50 and ARTAuth.m, line 749
    internal func clientId_nosync() -> String? {
        if let protocolClientId = protocolClientId {
            return protocolClientId
        } else if let tokenDetails = tokenDetails, let tokenClientId = tokenDetails.clientId {
            return tokenClientId
        } else {
            return options.clientId
        }
    }
    
    // swift-migration: original location ARTAuth.m, line 761
    private var currentDate: Date {
        return Date().addingTimeInterval(timeOffset?.doubleValue ?? 0)
    }
    
    // swift-migration: original location ARTAuth.m, line 765
    private var hasTimeOffset: Bool {
        return timeOffset != nil
    }
    
    // swift-migration: original location ARTAuth.m, line 769
    private var hasTimeOffsetWithValue: Bool {
        return timeOffset != nil && timeOffset!.doubleValue > 0
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 91 and ARTAuth.m, line 773
    internal func discardTimeOffset() {
        // This may run after dealloc has been called in _rest. I've seen this
        // happen when rest.auth is put in a variable, even if (apparently) that
        // variable doesn't outlive rest! See commit 5a354524 for a reproducible
        // example, by running the Auth.swift tests. Instruments reports a memory
        // leak, but I wasn't able to get to why it happens after a full day. So
        // I'm just adding this check.
        if rest == nil {
            removeTimeOffsetObserver()
            return
        }
        
        // Called from NSNotificationCenter, so must put change in the queue.
        queue.sync {
            clearTimeOffset()
        }
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 103 and ARTAuth.m, line 791
    internal func setTokenDetails(_ tokenDetails: ARTTokenDetails?) {
        self.tokenDetails = tokenDetails
        #if os(iOS)
        setLocalDeviceClientId_nosync(tokenDetails?.clientId)
        #endif
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 106 and ARTAuth.m, line 798
    internal func setTimeOffset(_ offset: TimeInterval) {
        timeOffset = NSNumber(value: offset)
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 107 and ARTAuth.m, line 802
    internal func clearTimeOffset() {
        timeOffset = nil
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 111 and ARTAuth.m, line 806
    internal func appId() -> String? {
        var s: String?
        if let key = options.key {
            s = key
        } else if let token = options.token {
            s = token
        } else if let tokenDetails = tokenDetails {
            s = tokenDetails.token
        }
        
        guard let s = s else {
            return nil
        }
        
        let parts = s.components(separatedBy: ".")
        if parts.count < 2 {
            return nil
        }
        return parts[0]
    }
    
    #if os(iOS)
    // swift-migration: original location ARTAuth.m, line 826
    private func setLocalDeviceClientId_nosync(_ clientId: String?) {
        guard let clientId = clientId, clientId != "*",
              let rest = rest,
              clientId != rest.device_nosync.clientId else {
            return
        }
        
        rest.device_nosync.setClientId(clientId)
        rest.storage.setObject(clientId, forKey: ARTClientIdKey)
        rest.push.getActivationMachine { stateMachine in
            if !(stateMachine.current_nosync is ARTPushActivationStateNotActivated) {
                stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
            }
        }
    }
    #endif
}

// swift-migration: original location ARTAuth+Private.h, line 42
internal protocol ARTAuthDelegate: AnyObject {
    func auth(_ auth: ARTAuthInternal, didAuthorize tokenDetails: ARTTokenDetails, completion: @escaping (ARTAuthorizationState, ARTErrorInfo?) -> Void)
}

// swift-migration: original location ARTAuth.h, line 91 and ARTAuth.m, line 28
public class ARTAuth: NSObject, ARTAuthProtocol {
    // swift-migration: original location ARTAuth+Private.h, line 117
    internal let `internal`: ARTAuthInternal
    
    // swift-migration: original location ARTAuth.m, line 29
    private let dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTAuth+Private.h, line 119
    internal init(internal: ARTAuthInternal, queuedDealloc dealloc: ARTQueuedDealloc) {
        self.internal = `internal`
        self.dealloc = dealloc
        super.init()
    }
    
    // swift-migration: original location ARTAuth+Private.h, line 120
    internal func internalAsync(_ use: @escaping (ARTAuthInternal) -> Void) {
        `internal`.queue.async {
            use(self.internal)
        }
    }
    
    // swift-migration: original location ARTAuth.h, line 22 and ARTAuth.m, line 47
    public var clientId: String? {
        return `internal`.clientId
    }
    
    // swift-migration: original location ARTAuth.h, line 25 and ARTAuth.m, line 51
    public var tokenDetails: ARTTokenDetails? {
        return `internal`.tokenDetails
    }
    
    // swift-migration: original location ARTAuth.h, line 37 and ARTAuth.m, line 55
    public func requestToken(_ tokenParams: ARTTokenParams?, withOptions authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback) {
        `internal`.requestToken(tokenParams, withOptions: authOptions, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.h, line 46 and ARTAuth.m, line 61
    public func requestToken(_ callback: @escaping ARTTokenDetailsCallback) {
        `internal`.requestToken(callback)
    }
    
    // swift-migration: original location ARTAuth.h, line 55 and ARTAuth.m, line 65
    public func authorize(_ tokenParams: ARTTokenParams?, options authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback) {
        `internal`.authorize(tokenParams, options: authOptions, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.h, line 64 and ARTAuth.m, line 71
    public func authorize(_ callback: @escaping ARTTokenDetailsCallback) {
        `internal`.authorize(callback)
    }
    
    // swift-migration: original location ARTAuth.h, line 73 and ARTAuth.m, line 75
    public func createTokenRequest(_ tokenParams: ARTTokenParams?, options: ARTAuthOptions?, callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        `internal`.createTokenRequest(tokenParams, options: options, callback: callback)
    }
    
    // swift-migration: original location ARTAuth.h, line 82 and ARTAuth.m, line 81
    public func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void) {
        `internal`.createTokenRequest(callback)
    }
}

// swift-migration: original location ARTAuth.h, line 17
public protocol ARTAuthProtocol {
    // swift-migration: original location ARTAuth.h, line 22
    var clientId: String? { get }
    
    // swift-migration: original location ARTAuth.h, line 25
    var tokenDetails: ARTTokenDetails? { get }
    
    // swift-migration: original location ARTAuth.h, line 37
    func requestToken(_ tokenParams: ARTTokenParams?, withOptions authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback)
    
    // swift-migration: original location ARTAuth.h, line 46
    func requestToken(_ callback: @escaping ARTTokenDetailsCallback)
    
    // swift-migration: original location ARTAuth.h, line 55
    func authorize(_ tokenParams: ARTTokenParams?, options authOptions: ARTAuthOptions?, callback: @escaping ARTTokenDetailsCallback)
    
    // swift-migration: original location ARTAuth.h, line 64
    func authorize(_ callback: @escaping ARTTokenDetailsCallback)
    
    // swift-migration: original location ARTAuth.h, line 73
    func createTokenRequest(_ tokenParams: ARTTokenParams?, options: ARTAuthOptions?, callback: @escaping (ARTTokenRequest?, Error?) -> Void)
    
    // swift-migration: original location ARTAuth.h, line 82
    func createTokenRequest(_ callback: @escaping (ARTTokenRequest?, Error?) -> Void)
}

// swift-migration: original location ARTAuth.m, line 842
extension String: ARTTokenDetailsCompatible {
    public func toTokenDetails(_ auth: ARTAuth, callback: @escaping ARTTokenDetailsCallback) {
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
    public static func new(withAuthorizationState value: ARTAuthorizationState) -> ARTEvent {
        return ARTEvent(authorizationState: value)
    }
}