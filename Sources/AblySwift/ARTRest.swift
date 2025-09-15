import Foundation

// swift-migration: ARTPaginatedStatsCallback now defined in ARTTypes.swift

// swift-migration: original location ARTRest.h, line 22
public protocol ARTRestInstanceMethodsProtocol: NSObjectProtocol {
    /**
     * Retrieves the time from the Ably service. Clients that do not have access to a sufficiently well maintained time source and wish to issue Ably `ARTTokenRequest`s with a more accurate timestamp should use the `ARTAuthOptions.queryTime` property instead of this method.
     *
     * @param callback A callback for receiving the time as a `NSDate` object.
     */
    func time(_ callback: @escaping ARTDateTimeCallback)
    
    /**
     * Makes a REST request to a provided path. This is provided as a convenience for developers who wish to use REST API functionality that is either not documented or is not yet included in the public API, without having to directly handle features such as authentication, paging, fallback hosts, MsgPack and JSON support.
     *
     * @param method The request method to use, such as GET, POST.
     * @param path The request path.
     * @param params The parameters to include in the URL query of the request. The parameters depend on the endpoint being queried. See the [REST API reference](https://ably.com/docs/api/rest-api) for the available parameters of each endpoint.
     * @param body The JSON body of the request.
     * @param headers Additional HTTP headers to include in the request.
     * @param callback A callback for retriving `ARTHttpPaginatedResponse` object returned by the HTTP request, containing an empty or JSON-encodable object.
     
     * @throws An error if the request parameters are invalid.
     */
    func request(_ method: String, path: String, params: NSStringDictionary?, body: Any?, headers: NSStringDictionary?, callback: @escaping ARTHTTPPaginatedCallback) throws
    
    /// :nodoc: TODO: docstring
    func stats(_ callback: @escaping ARTPaginatedStatsCallback) throws
    
    /**
     * Queries the REST `/stats` API and retrieves your application's usage statistics. Returns a `ARTPaginatedResult` object, containing an array of `ARTStats` objects. See the [Stats docs](https://ably.com/docs/general/statistics).
     *
     * @param query An `ARTStatsQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTStats` objects.
     * 
     * @throws An error if the query parameters are invalid.
     */
    func stats(_ query: ARTStatsQuery?, callback: @escaping ARTPaginatedStatsCallback) throws
    
    #if os(iOS)
    /**
     * Retrieves an `ARTLocalDevice` object that represents the current state of the device as a target for push notifications.
     */
    var device: ARTLocalDevice { get }
    #endif
}

// swift-migration: original location ARTRest.h, line 80
public protocol ARTRestProtocol: ARTRestInstanceMethodsProtocol {
    init(options: ARTClientOptions)
    init(key: String)
    init(token: String)
}

// swift-migration: original location ARTRest.h, line 110 and ARTRest.m, line 51
public class ARTRest: NSObject, ARTRestProtocol {
    
    // swift-migration: original location ARTRest+Private.h, line 121 and ARTRest.m, line 51
    internal let `internal`: ARTRestInternal
    private var _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRest.h, line 115 and ARTRest.m, line 128
    public var channels: ARTRestChannels {
        return ARTRestChannels(internal: `internal`.channels, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRest.h, line 125 and ARTRest.m, line 132
    public var auth: ARTAuth {
        return ARTAuth(internal: `internal`.auth, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRest.h, line 120 and ARTRest.m, line 136
    public var push: ARTPush {
        return ARTPush(internal: `internal`.push, queuedDealloc: _dealloc)
    }
    
    #if os(iOS)
    // swift-migration: original location ARTRest+Private.h, line 28 and ARTRest.m, line 142
    public var device: ARTLocalDevice {
        return `internal`.device
    }
    #endif
    
    // swift-migration: original location ARTRest+Private.h, line 123 and ARTRest.m, line 55
    internal func internalAsync(_ use: @escaping (ARTRestInternal) -> Void) {
        `internal`.queue.async {
            use(self.`internal`)
        }
    }
    
    // swift-migration: original location ARTRest.m, line 61
    private func initCommon() {
        _dealloc = ARTQueuedDealloc(ref: `internal`, queue: `internal`.queue)
    }
    
    // swift-migration: original location ARTRest.h, line 90 and ARTRest.m, line 65
    public required init(options: ARTClientOptions) {
        `internal` = ARTRestInternal(options: options)
        _dealloc = ARTQueuedDealloc(ref: `internal`, queue: `internal`.queue)
        super.init()
    }
    
    // swift-migration: original location ARTRest.h, line 96 and ARTRest.m, line 74
    public required init(key: String) {
        `internal` = ARTRestInternal(key: key)
        _dealloc = ARTQueuedDealloc(ref: `internal`, queue: `internal`.queue)
        super.init()
    }
    
    // swift-migration: original location ARTRest.h, line 102 and ARTRest.m, line 83
    public required init(token: String) {
        `internal` = ARTRestInternal(token: token)
        _dealloc = ARTQueuedDealloc(ref: `internal`, queue: `internal`.queue)
        super.init()
    }
    
    // swift-migration: original location ARTRest.h, line 128 and ARTRest.m, line 92
    public class func create(options: ARTClientOptions) -> ARTRest {
        return ARTRest(options: options)
    }
    
    // swift-migration: original location ARTRest.h, line 131 and ARTRest.m, line 96
    public class func create(key: String) -> ARTRest {
        return ARTRest(key: key)
    }
    
    // swift-migration: original location ARTRest.h, line 134 and ARTRest.m, line 100
    public class func create(token: String) -> ARTRest {
        return ARTRest(token: token)
    }
    
    // swift-migration: original location ARTRest.h, line 29 and ARTRest.m, line 104
    public func time(_ callback: @escaping ARTDateTimeCallback) {
        `internal`.time(wrapperSDKAgents: nil, completion: callback)
    }
    
    // swift-migration: original location ARTRest.h, line 44 and ARTRest.m, line 109 - converted to throwing function per PRD
    public func request(_ method: String, path: String, params: NSStringDictionary?, body: Any?, headers: NSStringDictionary?, callback: @escaping ARTHTTPPaginatedCallback) throws {
        try `internal`.request(method, path: path, params: params, body: body, headers: headers, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRest.h, line 53 and ARTRest.m, line 119 - converted to throwing function per PRD
    public func stats(_ callback: @escaping ARTPaginatedStatsCallback) throws {
        let success = `internal`.stats(wrapperSDKAgents: nil, completion: callback)
        if !success {
            throw NSError(domain: ARTAblyErrorDomain, code: 40003, userInfo: [NSLocalizedDescriptionKey: "Stats request failed"])
        }
    }
    
    // swift-migration: original location ARTRest.h, line 64 and ARTRest.m, line 124 - converted to throwing function per PRD
    public func stats(_ query: ARTStatsQuery?, callback: @escaping ARTPaginatedStatsCallback) throws {
        try `internal`.stats(query, wrapperSDKAgents: nil, callback: callback)
    }
}

// swift-migration: original location ARTRest+Private.h, line 17 and ARTRest.m, line 165
public class ARTRestInternal: NSObject {
    
    // swift-migration: original location ARTRest+Private.h, line 158 and ARTRest.m, line 166
    private let _logger: InternalLog
    
    // swift-migration: original location ARTRest+Private.h, line 24 and ARTRest.m, line 205
    internal var channels: ARTRestChannelsInternal!
    
    // swift-migration: original location ARTRest+Private.h, line 25 and ARTRest.m, line 205
    internal var auth: ARTAuthInternal!
    
    // swift-migration: original location ARTRest+Private.h, line 26 and ARTRest.m, line 206
    internal var push: ARTPushInternal!
    
    // swift-migration: original location ARTRest+Private.h, line 33 and ARTRest.m, line 183
    public let options: ARTClientOptions
    
    // swift-migration: original location ARTRest+Private.h, line 34 and ARTRest.m, line 182
    internal weak var realtime: ARTRealtimeInternal?
    
    // swift-migration: original location ARTRest+Private.h, line 35 and ARTRest.m, line 747
    public var defaultEncoder: ARTEncoder {
        return encoders[defaultEncoding]!
    }
    
    // swift-migration: original location ARTRest+Private.h, line 36 and ARTRest.m, line 201
    public var defaultEncoding: String!
    
    // swift-migration: original location ARTRest+Private.h, line 37 and ARTRest.m, line 197
    public var encoders: [String: ARTEncoder]!
    
    // swift-migration: original location ARTRest+Private.h, line 40
    public var prioritizedHost: String?
    
    // swift-migration: original location ARTRest+Private.h, line 42 and ARTRest.m, line 193
    internal var httpExecutor: ARTHTTPExecutor
    
    // swift-migration: original location ARTRest+Private.h, line 43 and ARTRest.m, line 751
    public var baseUrl: URL {
        let components = options.restUrlComponents()
        let prioritizedHost = self.prioritizedHost
        if let host = prioritizedHost {
            var mutableComponents = components
            mutableComponents.host = host
            return mutableComponents.url!
        }
        return components.url!
    }
    
    // swift-migration: original location ARTRest+Private.h, line 44 and ARTRest.m, line 760
    public var currentFallbackHost: String? {
        didSet {
            if currentFallbackHost == nil {
                _fallbackRetryExpiration = nil
            }
            
            if oldValue == currentFallbackHost {
                return
            }
            
            let now = continuousClock.now()
            _fallbackRetryExpiration = continuousClock.addingDuration(options.fallbackRetryTimeout, to: now)
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 45 and ARTRest.m, line 762
    internal private(set) var fallbackRetryExpiration: ARTContinuousClockInstant?
    private var _fallbackRetryExpiration: ARTContinuousClockInstant?
    
    // swift-migration: original location ARTRest+Private.h, line 47 and ARTRest.m, line 186
    public let queue: DispatchQueue
    
    // swift-migration: original location ARTRest+Private.h, line 48 and ARTRest.m, line 187
    public let userQueue: DispatchQueue
    
    // swift-migration: original location ARTRest+Private.h, line 61 and ARTRest.m, line 226
    public var logger_onlyForUseInClassMethodsAndTests: InternalLog {
        return logger
    }
    
    // swift-migration: original location ARTRest+Private.h, line 64 and ARTRest.m, line 191
    internal let http: ARTHttp
    
    // swift-migration: original location ARTRest+Private.h, line 65 and ARTRest.m, line 202
    internal var fallbackCount: Int
    
    // swift-migration: original location ARTRest+Private.h, line 159 and ARTRest.m, line 185
    private let continuousClock: ARTContinuousClock
    
    // swift-migration: original location ARTRest.m, line 167
    private var tokenErrorRetries: UInt = 0
    
    #if os(iOS)
    // swift-migration: original location ARTRest+Private.h, line 30 and ARTRest.m, line 189
    internal var storage: ARTDeviceStorage
    
    // swift-migration: original location ARTRest+Private.h, line 28 and ARTRest.m, line 776
    internal var device: ARTLocalDevice {
        var result: ARTLocalDevice!
        queue.sync {
            result = device_nosync
        }
        return result
    }
    
    // swift-migration: original location ARTRest+Private.h, line 29 and ARTRest.m, line 784
    internal var device_nosync: ARTLocalDevice {
        var result: ARTLocalDevice!
        ARTRestInternal.deviceAccessQueue.sync {
            result = sharedDevice_onlyCallOnDeviceAccessQueue()
        }
        return result
    }
    #endif
    
    // swift-migration: original location ARTRest+Private.h, line 67 and ARTRest.m, line 172
    public init(options: ARTClientOptions) {
        let logger = InternalLog(clientOptions: options)
        self._logger = logger
        self.options = options.copy() as! ARTClientOptions
        self.continuousClock = ARTContinuousClock()
        self.queue = options.internalDispatchQueue
        self.userQueue = options.dispatchQueue
        
        #if os(iOS)
        self.storage = ARTLocalDeviceStorage.new(logger: logger)
        #endif
        
        self.http = ARTHttp(queue: queue, logger: logger)
        self.httpExecutor = http
        
        self.fallbackCount = 0
        
        super.init()
        
        let jsonEncoder = ARTJsonLikeEncoder(rest: self, delegate: ARTJsonEncoder(), logger: logger)
        let msgPackEncoder = ARTJsonLikeEncoder(rest: self, delegate: ARTMsgPackEncoder(), logger: logger)
        
        self.encoders = [
            jsonEncoder.mimeType(): jsonEncoder,
            msgPackEncoder.mimeType(): msgPackEncoder
        ]
        
        self.defaultEncoding = options.useBinaryProtocol ? msgPackEncoder.mimeType() : jsonEncoder.mimeType()
        
        self.auth = ARTAuthInternal(self, withOptions: options, logger: logger)
        self.push = ARTPushInternal(rest: self, logger: logger)
        self.channels = ARTRestChannelsInternal(rest: self, logger: logger)
        
        ARTLogVerbose(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) initialized")
    }
    
    // swift-migration: original location ARTRest+Private.h, line 177 and ARTRest.m, line 177
    internal convenience init(options: ARTClientOptions, realtime: ARTRealtimeInternal?, logger: InternalLog) {
        self.init(options: options)
        self.realtime = realtime
    }
    
    // swift-migration: original location ARTRest+Private.h, line 21 and ARTRest.m, line 214
    public convenience init(key: String) {
        let options = ARTClientOptions()
        options.key = key
        self.init(options: options)
    }
    
    // swift-migration: original location ARTRest+Private.h, line 22 and ARTRest.m, line 218
    public convenience init(token: String) {
        let options = ARTClientOptions()
        options.token = token
        self.init(options: options)
    }
    
    // swift-migration: original location ARTRest.m, line 170
    public var logger: InternalLog {
        return _logger
    }
    
    // swift-migration: original location ARTRest.m, line 222
    deinit {
        ARTLogVerbose(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) dealloc")
    }
    
    // swift-migration: original location ARTRest.m, line 230
    public override var description: String {
        let info: String
        if let token = options.token {
            info = "token: \(token)"
        } else if let authUrl = options.authUrl {
            info = "authUrl: \(authUrl)"
        } else if options.authCallback != nil {
            info = "authCallback: \(String(describing: options.authCallback!))"
        } else {
            info = "key: \(options.key ?? "")"
        }
        return "\(super.description) - \n\t \(info);"
    }
    
    // swift-migration: original location ARTRest+Private.h, line 74 and ARTRest.m, line 322
    @discardableResult
    internal func executeRequest(_ request: URLRequest, wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        return executeRequest(request, fallbacks: nil, retries: 0, originalRequestId: nil, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
    }
    
    // swift-migration: original location ARTRest+Private.h, line 80 and ARTRest.m, line 247
    @discardableResult
    internal func executeRequest(_ request: URLRequest, withAuthOption authOption: ARTAuthentication, wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        var mutableRequest = request
        mutableRequest.url = URL(string: mutableRequest.url!.relativePath, relativeTo: baseUrl)
        
        switch authOption {
        case .off:
            return executeRequest(mutableRequest, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
        case .on:
            tokenErrorRetries = 0
            return executeRequestWithAuthentication(mutableRequest, withMethod: auth.method, force: false, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
        case .newToken:
            tokenErrorRetries = 0
            return executeRequestWithAuthentication(mutableRequest, withMethod: auth.method, force: true, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
        case .tokenRetry:
            tokenErrorRetries = tokenErrorRetries + 1
            return executeRequestWithAuthentication(mutableRequest, withMethod: auth.method, force: true, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
        case .useBasic:
            return executeRequestWithAuthentication(mutableRequest, withMethod: .basic, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
        }
    }
    
    // swift-migration: original location ARTRest.m, line 271
    @discardableResult
    private func executeRequestWithAuthentication(_ request: URLRequest, withMethod method: ARTAuthMethod, wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        return executeRequestWithAuthentication(request, withMethod: method, force: false, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
    }
    
    // swift-migration: original location ARTRest.m, line 278
    @discardableResult
    private func executeRequestWithAuthentication(_ request: URLRequest, withMethod method: ARTAuthMethod, force: Bool, wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) calculating authorization \(method.rawValue)")
        
        var task: ARTCancellable?
        
        if method == .basic {
            let authorization = prepareBasicAuthorisationHeader(options.key!)
            var mutableRequest = request
            mutableRequest.setValue(authorization, forHTTPHeaderField: "Authorization")
            ARTLogVerbose(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) ARTRest: \(authorization)")
            task = executeRequest(mutableRequest, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
        } else {
            if !force && auth.tokenRemainsValid {
                let authorization = prepareTokenAuthorisationHeader(auth.tokenDetails!.token)
                ARTLogVerbose(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) ARTRestInternal reusing token: authorization bearer in Base64 \(authorization)")
                var mutableRequest = request
                mutableRequest.setValue(authorization, forHTTPHeaderField: "Authorization")
                task = executeRequest(mutableRequest, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
            } else {
                task = auth._authorize(nil, options: options) { [weak self] tokenDetails, error in
                    guard let self = self else { return }
                    if let error = error {
                        ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) ARTRestInternal reissuing token failed \(error)")
                        completion(nil, nil, error)
                        return
                    }
                    let authorization = self.prepareTokenAuthorisationHeader(tokenDetails!.token)
                    ARTLogVerbose(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) ARTRestInternal reissuing token: authorization bearer \(authorization)")
                    var mutableRequest = request
                    mutableRequest.setValue(authorization, forHTTPHeaderField: "Authorization")
                    task = self.executeRequest(mutableRequest, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
                }
            }
        }
        return task
    }
    
    // swift-migration: original location ARTRest.m, line 345
    @discardableResult
    private func executeRequest(_ request: URLRequest, fallbacks: ARTFallback?, retries: UInt, originalRequestId: String?, wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        
        var requestId: String?
        var blockFallbacks = fallbacks
        
        var updatedRequest = request.settingAcceptHeader(defaultEncoder: defaultEncoder, encoders: encoders)
        var mutableRequest = updatedRequest
        mutableRequest.timeoutInterval = options.httpRequestTimeout
        mutableRequest.setValue(ARTDefault.apiVersion(), forHTTPHeaderField: "X-Ably-Version")
        mutableRequest.setValue(agentIdentifier(wrapperSDKAgents: wrapperSDKAgents), forHTTPHeaderField: "Ably-Agent")
        
        if let clientId = options.clientId, !auth.isTokenAuth {
            mutableRequest.setValue(encodeBase64(clientId), forHTTPHeaderField: "X-Ably-ClientId")
        }
        updatedRequest = mutableRequest
        
        if options.addRequestIds {
            if fallbacks != nil {
                requestId = originalRequestId
            } else {
                let randomId = UUID().uuidString
                requestId = Data(randomId.utf8).base64EncodedString()
            }
            
            updatedRequest = updatedRequest.appendingQueryItem(URLQueryItem(name: "request_id", value: requestId))
        }
        
        // RSC15f - reset the successed fallback host on fallbackRetryTimeout expiration
        if let _ = currentFallbackHost,
           let fallbackRetryExpiration = fallbackRetryExpiration,
           continuousClock.now().isAfter(fallbackRetryExpiration) {
            ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) fallbackRetryExpiration ids expired, reset `prioritizedHost` and `currentFallbackHost`")
            
            self.currentFallbackHost = nil
            self.prioritizedHost = nil
            updatedRequest = updatedRequest.replacingHostWith(options.restHost!)
        }
        
        ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) executing request \(updatedRequest)")
        
        let task = httpExecutor.execute(updatedRequest) { [weak self] response, data, error in
            guard let self = self else { return }
            
            var finalError = error
            var finalData = data
            
            // Error messages in plaintext and HTML format
            if finalError == nil, let data = finalData, !data.isEmpty, updatedRequest.url?.host != self.options.authUrl?.host {
                let contentType = response?.allHeaderFields["Content-Type"] as? String ?? ""
                
                let validContentType = self.encoders.values.contains { encoder in
                    contentType.contains(encoder.mimeType())
                }
                
                if !validContentType {
                    let plain = String(data: data, encoding: .utf8) ?? ""
                    finalError = ARTErrorInfo.create(withCode: (response?.statusCode ?? 0) * 100, 
                                                   status: response?.statusCode ?? 0, 
                                                   message: plain.art_shortString)
                    finalData = nil
                    ARTLogError(self.logger, "Request \(updatedRequest) failed with \(finalError!)")
                }
            }
            
            if let response = response, response.statusCode >= 400 {
                if let data = finalData {
                    let dataError = try? self.encoders[response.mimeType ?? ""]?.decodeErrorInfo(data)
                    let errorBecauseShouldNotRenewToken = self.errorBecauseShouldNotRenewToken(dataError)
                    
                    if errorBecauseShouldNotRenewToken == nil {
                        ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) retry request \(updatedRequest)")
                        if self.tokenErrorRetries < 1 {
                            _ = self.executeRequest(mutableRequest, withAuthOption: .tokenRetry, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
                            return
                        }
                    }
                    
                    if let errorBecauseShouldNotRenewToken = errorBecauseShouldNotRenewToken {
                        finalError = errorBecauseShouldNotRenewToken
                    } else if let dataError = dataError {
                        finalError = dataError
                    }
                }
                
                if finalError == nil {
                    finalError = ARTErrorInfo.create(
                        withCode: response.statusCode * 100,
                        status: response.statusCode,
                        message: String(data: finalData ?? Data(), encoding: .utf8) ?? ""
                    )
                }
            } else {
                // Response Status Code < 400 and no errors
                if finalError == nil && self.currentFallbackHost != nil {
                    ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) switching `prioritizedHost` to fallback host \(self.currentFallbackHost!)")
                    self.prioritizedHost = self.currentFallbackHost
                }
            }
            
            if retries < self.options.httpMaxRetryCount && self.shouldRetryWithFallback(updatedRequest, response: response, error: finalError) {
                if blockFallbacks == nil {
                    let hosts = ARTFallbackHosts.hosts(fromOptions: self.options)
                    blockFallbacks = ARTFallback(fallbackHosts: hosts, shuffleArray: self.options.testOptions.shuffleArray)
                }
                
                if let fallback = blockFallbacks, let host = fallback.popFallbackHost() {
                    ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) host is down; retrying request at \(host)")
                    
                    self.currentFallbackHost = host
                    var newRequest = updatedRequest
                    newRequest.setValue(host, forHTTPHeaderField: "Host")
                    newRequest.url = URL.copyFromURL(updatedRequest.url!, withHost: host)
                    
                    _ = self.executeRequest(newRequest,
                                                    fallbacks: blockFallbacks,
                                                    retries: retries + 1,
                                                    originalRequestId: originalRequestId,
                                                    wrapperSDKAgents: wrapperSDKAgents,
                                                    completion: completion)
                    return
                }
            }
            
            if let error = finalError {
                if let artError = error as? ARTErrorInfo {
                    completion(response, finalData, artError)
                } else {
                    completion(response, finalData, NSError.copyFromError(error as NSError, withRequestId: requestId))
                }
            } else {
                completion(response, finalData, nil)
            }
        }
        
        return task
    }
    
    // swift-migration: original location ARTRest.m, line 492
    private func errorBecauseShouldNotRenewToken(_ error: ARTErrorInfo?) -> ARTErrorInfo? {
        if let error = error, DefaultErrorChecker().isTokenError(error) {
            if auth.tokenIsRenewable {
                return nil
            }
            return ARTErrorInfo.create(withCode: ARTState.requestTokenFailed.rawValue, message: ARTAblyMessageNoMeansToRenewToken)
        }
        return error
    }
    
    // swift-migration: original location ARTRest.m, line 503
    private func shouldRetryWithFallback(_ request: URLRequest, response: HTTPURLResponse?, error: Error?) -> Bool {
        if request.url?.host == options.authUrl?.host {
            return false
        }
        
        if let response = response, response.statusCode >= 500 && response.statusCode <= 504 {
            return true
        }
        
        if let error = error as NSError?, 
           error.domain == NSURLErrorDomain && 
           (error.code == -1003 || error.code == -1001) { // Unreachable or timed out
            return true
        }
        
        return false
    }
    
    // swift-migration: original location ARTRest.m, line 519
    private var currentHost: String {
        if let prioritizedHost = prioritizedHost {
            return prioritizedHost
        }
        return options.restHost ?? ARTDefault.restHost()
    }
    
    // swift-migration: original location ARTRest.m, line 527
    private func prepareBasicAuthorisationHeader(_ key: String) -> String {
        let keyData = key.data(using: .utf8)!
        let keyBase64 = keyData.base64EncodedString()
        return "Basic \(keyBase64)"
    }
    
    // swift-migration: original location ARTRest.m, line 534
    private func prepareTokenAuthorisationHeader(_ token: String) -> String {
        return "Bearer \(token)"
    }
    
    // swift-migration: original location ARTRest.m, line 539
    internal func time(wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTDateTimeCallback) {
        let userCallback = completion
        let wrappedCallback: ARTDateTimeCallback = { time, error in
            self.userQueue.async {
                userCallback(time, error)
            }
        }
        
        queue.async {
            self._time(wrapperSDKAgents: wrapperSDKAgents, completion: wrappedCallback)
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 69 and ARTRest.m, line 555
    @discardableResult
    internal func _time(wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTDateTimeCallback) -> ARTCancellable? {
        let requestUrl = URL(string: "/time", relativeTo: baseUrl)!
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        let accept = encoders.values.map { $0.mimeType() }.joined(separator: ",")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        
        return executeRequest(request, withAuthOption: .off, wrapperSDKAgents: wrapperSDKAgents) { [weak self] response, data, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let response = response else {
                completion(nil, ARTErrorInfo.create(withCode: 0, message: "No response received"))
                return
            }
            
            if response.statusCode >= 400 {
                let dataError = try? self.encoders[response.mimeType ?? ""]?.decodeErrorInfo(data ?? Data())
                completion(nil, dataError)
            } else {
                let time = try? self.encoders[response.mimeType ?? ""]?.decodeTime(data ?? Data())
                completion(time, nil)
            }
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 100 and ARTRest.m, line 579
    // swift-migration: Converted inout Error pattern to Swift throws pattern per PRD requirements
    internal func request(_ method: String, path: String, params: NSStringDictionary?, body: Any?, headers: NSStringDictionary?, wrapperSDKAgents: NSStringDictionary?, callback: @escaping ARTHTTPPaginatedCallback) throws {
        
        let userCallback = callback
        let wrappedCallback: ARTHTTPPaginatedCallback = { response, error in
            self.userQueue.async {
                userCallback(response, error)
            }
        }
        
        let allowedMethods = ["get", "post", "patch", "put", "delete"]
        if !allowedMethods.contains(method.lowercased()) {
            throw NSError(
                domain: ARTAblyErrorDomain,
                code: 40005,
                userInfo: [NSLocalizedDescriptionKey: "Method isn't valid."]
            )
        }
        
        if let body = body {
            if !(body is [String: Any]) && !(body is [Any]) {
                throw NSError(
                    domain: ARTAblyErrorDomain,
                    code: 40006,
                    userInfo: [NSLocalizedDescriptionKey: "Body should be a Dictionary or an Array."]
                )
            }
        }
        
        if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw NSError(
                domain: ARTAblyErrorDomain,
                code: 40007,
                userInfo: [NSLocalizedDescriptionKey: "Path cannot be empty."]
            )
        }
        
        guard let url = URL(string: path, relativeTo: baseUrl) else {
            throw NSError(
                domain: ARTAblyErrorDomain,
                code: 40007,
                userInfo: [NSLocalizedDescriptionKey: "Path isn't valid for an URL."]
            )
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var queryItems: [URLQueryItem] = []
        
        if let params = params {
            for (key, value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        components.queryItems = queryItems
        
        var mutableRequest = URLRequest(url: components.url!)
        mutableRequest.httpMethod = method
        
        if let headers = headers {
            for (key, value) in headers {
                mutableRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            do {
                let bodyData = try defaultEncoder.encode(body)
                
                mutableRequest.httpBody = bodyData
                mutableRequest.setValue(defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")
                
                if method.lowercased() == "post" {
                    mutableRequest.setValue("\(bodyData?.count ?? 0)", forHTTPHeaderField: "Content-Length")
                }
            } catch let encodeError {
                throw encodeError
            }
        }
        
        let request = mutableRequest.settingAcceptHeader(defaultEncoder: defaultEncoder, encoders: encoders)
        
        ARTLogDebug(logger, "request \(method) \(path)")
        queue.async {
            ARTHTTPPaginatedResponse.executePaginated(self, withRequest: request, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 85 and ARTRest.m, line 679
    @discardableResult
    internal func internetIsUp(_ callback: @escaping (Bool) -> Void) -> ARTCancellable? {
        let requestUrl = URL(string: "https://internet-up.ably-realtime.com/is-the-internet-up.txt")!
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        return httpExecutor.execute(request) { response, data, error in
            if error != nil {
                callback(false)
                return
            }
            
            let str = data.flatMap { String(data: $0, encoding: .utf8) }
            callback(response?.statusCode == 200 && str == "yes\n")
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 109 and ARTRest.m, line 694
    internal func stats(wrapperSDKAgents: NSStringDictionary?, completion: @escaping ARTPaginatedStatsCallback) -> Bool {
        do {
            try stats(ARTStatsQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: completion)
            return true
        } catch {
            // swift-migration: Handle error appropriately - for now return false to maintain Bool return type
            return false
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 112 and ARTRest.m, line 699
    // swift-migration: Converted inout Error pattern to Swift throws pattern per PRD requirements
    internal func stats(_ query: ARTStatsQuery?, wrapperSDKAgents: NSStringDictionary?, callback: @escaping ARTPaginatedStatsCallback) throws {
        
        let userCallback = callback
        let wrappedCallback: ARTPaginatedStatsCallback = { result, error in
            self.userQueue.async {
                userCallback(result, error)
            }
        }
        
        let actualQuery = query ?? ARTStatsQuery()
        
        if actualQuery.limit > 1000 {
            throw NSError(
                domain: ARTAblyErrorDomain,
                code: ARTDataQueryError.limit.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Limit supports up to 1000 results only"]
            )
        }
        
        if let start = actualQuery.start, let end = actualQuery.end, start.compare(end) == .orderedDescending {
            throw NSError(
                domain: ARTAblyErrorDomain,
                code: ARTDataQueryError.timestampRange.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Start must be equal to or less than end"]
            )
        }
        
        var requestUrl = URLComponents(string: "/stats")!
        // swift-migration: Updated to use throws pattern instead of inout error parameter
        requestUrl.queryItems = try actualQuery.asQueryItems()
        
        let request = URLRequest(url: requestUrl.url(relativeTo: baseUrl)!)
        
        // swift-migration: Updated responseProcessor to use throws pattern instead of inout error parameter
        let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data in
            guard let response = response, let mimeType = response.mimeType else { return nil }
            let result = try self.encoders[mimeType]?.decodeStats(data ?? Data())
            return result
        }
        
        queue.async {
            ARTPaginatedResult<ARTStats>.executePaginated(self, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
        }
    }
    
    // swift-migration: original location ARTRest.m, line 328
    private func agentIdentifier(wrapperSDKAgents: NSStringDictionary?) -> String {
        var additionalAgents: [String: String] = [:]
        
        if let agents = options.agents {
            for (agentName, agentValue) in agents {
                additionalAgents[agentName] = agentValue
            }
        }
        
        if let wrapperAgents = wrapperSDKAgents {
            for (key, value) in wrapperAgents {
                additionalAgents[key] = value
            }
        }
        
        return ARTClientInformation.agentIdentifier(withAdditionalAgents: additionalAgents)
    }
    
    #if os(iOS)
    
    // swift-migration: original location ARTRest.m, line 792
    private static var deviceAccessQueue: DispatchQueue = {
        return DispatchQueue(label: "io.ably.deviceAccess", qos: .default)
    }()
    
    // swift-migration: original location ARTRest.m, line 803
    private static var sharedDeviceNeedsLoading_onlyAccessOnDeviceAccessQueue = true
    
    // swift-migration: original location ARTRest.m, line 805
    private var sharedDevice_onlyCallOnDeviceAccessQueue: ARTLocalDevice {
        var device: ARTLocalDevice!
        
        if ARTRestInternal.sharedDeviceNeedsLoading_onlyAccessOnDeviceAccessQueue {
            device = ARTLocalDevice.device(withStorage: storage, logger: logger)
            ARTRestInternal.sharedDeviceNeedsLoading_onlyAccessOnDeviceAccessQueue = false
        }
        
        return device
    }
    
    // swift-migration: original location ARTRest+Private.h, line 88 and ARTRest.m, line 822
    public func setupLocalDevice_nosync() {
        let device = device_nosync
        let clientId = auth.clientId_nosync
        ARTRestInternal.deviceAccessQueue.sync {
            device.setupDetails(withClientId: clientId)
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 89 and ARTRest.m, line 830
    public func resetLocalDevice_nosync() {
        let device = device_nosync
        ARTRestInternal.deviceAccessQueue.sync {
            device.resetDetails()
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 92 and ARTRest.m, line 837
    public func resetDeviceSingleton() {
        ARTRestInternal.deviceAccessQueue.sync {
            ARTRestInternal.sharedDeviceNeedsLoading_onlyAccessOnDeviceAccessQueue = true
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 94 and ARTRest.m, line 843
    public func setAndPersistAPNSDeviceTokenData(_ deviceTokenData: Data, tokenType: String) {
        let deviceToken = deviceTokenData.deviceTokenString()
        ARTLogInfo(logger, "ARTRest: device token: \(deviceToken) of type: `\(tokenType)`")
        
        let currentDeviceToken = ARTLocalDevice.apnsDeviceToken(ofType: tokenType, fromStorage: storage)
        if currentDeviceToken == deviceToken {
            return // Already stored
        }
        
        device_nosync.setAndPersistAPNSDeviceToken(deviceToken, tokenType: tokenType)
        ARTLogDebug(logger, "ARTRest: device token stored")
        
        push.getActivationMachine { stateMachine in
            stateMachine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
        }
    }
    
    #endif
}

// swift-migration: original location ARTRest.m, line 865
extension Data {
    // swift-migration: original location ARTRest+Private.h, line 127 and ARTRest.m, line 867
    func deviceTokenString() -> String {
        let dataLength = count
        let dataBuffer = withUnsafeBytes { $0.bindMemory(to: UInt8.self) }
        var hexString = ""
        
        for i in 0..<dataLength {
            hexString += String(format: "%02x", dataBuffer[i])
        }
        
        return hexString
    }
}

// swift-migration: ARTRestChannels and ARTRestChannelsInternal placeholders defined in MigrationPlaceholders.swift
// swift-migration: encodeBase64 and art_shortString functions implemented in other files

