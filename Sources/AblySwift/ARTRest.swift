import Foundation

// swift-migration: Placeholder typealias for stats callback
public typealias ARTPaginatedStatsCallback = (ARTPaginatedResult<ARTStats>?, ARTErrorInfo?) -> Void

// swift-migration: original location ARTRest.h, line 22
public protocol ARTRestInstanceMethodsProtocol: NSObjectProtocol {
    func time(_ callback: @escaping ARTDateTimeCallback)
    func request(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?, callback: @escaping ARTHTTPPaginatedCallback, error: UnsafeMutablePointer<Error?>?) -> Bool
    func stats(_ callback: @escaping ARTPaginatedStatsCallback) -> Bool
    func stats(_ query: ARTStatsQuery?, callback: @escaping ARTPaginatedStatsCallback, error: UnsafeMutablePointer<Error?>?) -> Bool
    
    #if os(iOS)
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
    internal let _internal: ARTRestInternal
    private var _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRest.h, line 115 and ARTRest.m, line 128
    public var channels: ARTRestChannels {
        return ARTRestChannels(internal: _internal.channels, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRest.h, line 125 and ARTRest.m, line 132
    public var auth: ARTAuth {
        return ARTAuth(internal: _internal.auth, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRest.h, line 120 and ARTRest.m, line 136
    public var push: ARTPush {
        return ARTPush(internal: _internal.push, queuedDealloc: _dealloc)
    }
    
    #if os(iOS)
    // swift-migration: original location ARTRest+Private.h, line 28 and ARTRest.m, line 142
    public var device: ARTLocalDevice {
        return _internal.device
    }
    #endif
    
    // swift-migration: original location ARTRest+Private.h, line 123 and ARTRest.m, line 55
    public func internalAsync(_ use: @escaping (ARTRestInternal) -> Void) {
        DispatchQueue.global().async {
            use(self._internal)
        }
    }
    
    // swift-migration: original location ARTRest.m, line 61
    private func initCommon() {
        _dealloc = ARTQueuedDealloc(_internal, queue: _internal.queue)
    }
    
    // swift-migration: original location ARTRest.h, line 90 and ARTRest.m, line 65
    public required init(options: ARTClientOptions) {
        _internal = ARTRestInternal(options: options)
        _dealloc = ARTQueuedDealloc()
        super.init()
        initCommon()
    }
    
    // swift-migration: original location ARTRest.h, line 96 and ARTRest.m, line 74
    public required init(key: String) {
        _internal = ARTRestInternal(key: key)
        _dealloc = ARTQueuedDealloc()
        super.init()
        initCommon()
    }
    
    // swift-migration: original location ARTRest.h, line 102 and ARTRest.m, line 83
    public required init(token: String) {
        _internal = ARTRestInternal(token: token)
        _dealloc = ARTQueuedDealloc()
        super.init()
        initCommon()
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
        _internal.time(wrapperSDKAgents: nil, completion: callback)
    }
    
    // swift-migration: original location ARTRest.h, line 44 and ARTRest.m, line 109
    public func request(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?, callback: @escaping ARTHTTPPaginatedCallback, error: UnsafeMutablePointer<Error?>?) -> Bool {
        return _internal.request(method, path: path, params: params, body: body, headers: headers, wrapperSDKAgents: nil, callback: callback, error: error)
    }
    
    // swift-migration: original location ARTRest.h, line 53 and ARTRest.m, line 119
    public func stats(_ callback: @escaping ARTPaginatedStatsCallback) -> Bool {
        return _internal.stats(wrapperSDKAgents: nil, completion: callback)
    }
    
    // swift-migration: original location ARTRest.h, line 64 and ARTRest.m, line 124
    public func stats(_ query: ARTStatsQuery?, callback: @escaping ARTPaginatedStatsCallback, error: UnsafeMutablePointer<Error?>?) -> Bool {
        return _internal.stats(query, wrapperSDKAgents: nil, callback: callback, error: error)
    }
}

// swift-migration: original location ARTRest+Private.h, line 17 and ARTRest.m, line 165
public class ARTRestInternal: NSObject {
    
    // swift-migration: original location ARTRest+Private.h, line 158 and ARTRest.m, line 166
    private let _logger: ARTInternalLog
    
    // swift-migration: original location ARTRest+Private.h, line 24 and ARTRest.m, line 205
    internal let channels: ARTRestChannelsInternal
    
    // swift-migration: original location ARTRest+Private.h, line 25 and ARTRest.m, line 205
    internal let auth: ARTAuthInternal
    
    // swift-migration: original location ARTRest+Private.h, line 26 and ARTRest.m, line 206
    internal let push: ARTPushInternal
    
    // swift-migration: original location ARTRest+Private.h, line 33 and ARTRest.m, line 183
    public let options: ARTClientOptions
    
    // swift-migration: original location ARTRest+Private.h, line 34 and ARTRest.m, line 182
    public weak var realtime: ARTRealtimeInternal?
    
    // swift-migration: original location ARTRest+Private.h, line 35 and ARTRest.m, line 747
    public var defaultEncoder: ARTEncoder {
        return encoders[defaultEncoding]!
    }
    
    // swift-migration: original location ARTRest+Private.h, line 36 and ARTRest.m, line 201
    public let defaultEncoding: String
    
    // swift-migration: original location ARTRest+Private.h, line 37 and ARTRest.m, line 197
    public let encoders: [String: ARTEncoder]
    
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
            _fallbackRetryExpiration = continuousClock.addingDuration(options.fallbackRetryTimeout, toInstant: now)
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
    public var logger_onlyForUseInClassMethodsAndTests: ARTInternalLog {
        return logger
    }
    
    // swift-migration: original location ARTRest+Private.h, line 64 and ARTRest.m, line 191
    public let http: ARTHttp
    
    // swift-migration: original location ARTRest+Private.h, line 65 and ARTRest.m, line 202
    internal var fallbackCount: Int
    
    // swift-migration: original location ARTRest+Private.h, line 159 and ARTRest.m, line 185
    private let continuousClock: ARTContinuousClock
    
    // swift-migration: original location ARTRest.m, line 167
    private var tokenErrorRetries: UInt = 0
    
    #if os(iOS)
    // swift-migration: original location ARTRest+Private.h, line 30 and ARTRest.m, line 189
    public var storage: ARTDeviceStorage
    
    // swift-migration: original location ARTRest+Private.h, line 28 and ARTRest.m, line 776
    public var device: ARTLocalDevice {
        var result: ARTLocalDevice!
        queue.sync {
            result = device_nosync
        }
        return result
    }
    
    // swift-migration: original location ARTRest+Private.h, line 29 and ARTRest.m, line 784
    public var device_nosync: ARTLocalDevice {
        var result: ARTLocalDevice!
        ARTRestInternal.deviceAccessQueue.sync {
            result = sharedDevice_onlyCallOnDeviceAccessQueue
        }
        return result
    }
    #endif
    
    // swift-migration: original location ARTRest+Private.h, line 67 and ARTRest.m, line 172
    public init(options: ARTClientOptions) {
        let logger = ARTInternalLog(clientOptions: options)
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
        
        let jsonEncoder = ARTJsonEncoder()
        let msgPackEncoder = ARTMsgPackEncoder()
        
        self.encoders = [
            jsonEncoder.mimeType(): jsonEncoder,
            msgPackEncoder.mimeType(): msgPackEncoder
        ]
        
        self.defaultEncoding = options.useBinaryProtocol ? msgPackEncoder.mimeType() : jsonEncoder.mimeType()
        self.fallbackCount = 0
        
        self.auth = ARTAuthInternal(self, withOptions: options, logger: logger)
        self.push = ARTPushInternal(rest: nil, logger: logger)
        self.channels = ARTRestChannelsInternal(rest: self, logger: logger)
        
        super.init()
        
        ARTLogVerbose(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) initialized")
    }
    
    // swift-migration: original location ARTRest+Private.h, line 177 and ARTRest.m, line 177
    public convenience init(options: ARTClientOptions, realtime: ARTRealtimeInternal?, logger: ARTInternalLog) {
        self.init(options: options)
        self.realtime = realtime
    }
    
    // swift-migration: original location ARTRest+Private.h, line 21 and ARTRest.m, line 214
    public convenience init(key: String) {
        self.init(options: ARTClientOptions(key: key))
    }
    
    // swift-migration: original location ARTRest+Private.h, line 22 and ARTRest.m, line 218
    public convenience init(token: String) {
        self.init(options: ARTClientOptions(token: token))
    }
    
    // swift-migration: original location ARTRest.m, line 170
    public var logger: ARTInternalLog {
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
            info = "authCallback: \(options.authCallback!)"
        } else {
            info = "key: \(options.key ?? "")"
        }
        return "\(super.description) - \n\t \(info);"
    }
    
    // swift-migration: original location ARTRest+Private.h, line 74 and ARTRest.m, line 322
    @discardableResult
    public func executeRequest(_ request: URLRequest, wrapperSDKAgents: [String: String]?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        return executeRequest(request, fallbacks: nil, retries: 0, originalRequestId: nil, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
    }
    
    // swift-migration: original location ARTRest+Private.h, line 80 and ARTRest.m, line 247
    @discardableResult
    public func executeRequest(_ request: URLRequest, withAuthOption authOption: ARTAuthentication, wrapperSDKAgents: [String: String]?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
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
    private func executeRequestWithAuthentication(_ request: URLRequest, withMethod method: ARTAuthMethod, wrapperSDKAgents: [String: String]?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        return executeRequestWithAuthentication(request, withMethod: method, force: false, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
    }
    
    // swift-migration: original location ARTRest.m, line 278
    @discardableResult
    private func executeRequestWithAuthentication(_ request: URLRequest, withMethod method: ARTAuthMethod, force: Bool, wrapperSDKAgents: [String: String]?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) calculating authorization \(method.rawValue)")
        
        var task: ARTCancellable?
        
        if method == .basic {
            let authorization = prepareBasicAuthorisationHeader(options.key!)
            var mutableRequest = request
            mutableRequest.setValue(authorization, forHTTPHeaderField: "Authorization")
            ARTLogVerbose(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) ARTRest: \(authorization)")
            task = executeRequest(mutableRequest, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
        } else {
            if !force && auth.tokenRemainsValid() {
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
    private func executeRequest(_ request: URLRequest, fallbacks: ARTFallback?, retries: UInt, originalRequestId: String?, wrapperSDKAgents: [String: String]?, completion: @escaping ARTURLRequestCallback) -> ARTCancellable? {
        
        var requestId: String?
        var blockFallbacks = fallbacks
        
        var updatedRequest = request.settingAcceptHeader(defaultEncoder, encoders: encoders)
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
        if let currentFallbackHost = currentFallbackHost,
           let fallbackRetryExpiration = fallbackRetryExpiration,
           continuousClock.now().isAfter(fallbackRetryExpiration) {
            ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) fallbackRetryExpiration ids expired, reset `prioritizedHost` and `currentFallbackHost`")
            
            self.currentFallbackHost = nil
            self.prioritizedHost = nil
            updatedRequest = updatedRequest.replacingHost(with: options.restHost)
        }
        
        ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) executing request \(updatedRequest)")
        
        let task = httpExecutor.executeRequest(updatedRequest) { [weak self] response, data, error in
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
                                                   message: plain.art_shortString(), 
                                                   requestId: requestId)
                    finalData = nil
                    ARTLogError(self.logger, "Request \(updatedRequest) failed with \(finalError!)")
                }
            }
            
            if let response = response, response.statusCode >= 400 {
                if let data = finalData {
                    var decodeError: Error?
                    let dataError = self.encoders[response.mimeType]?.decodeErrorInfo(data, error: &decodeError)
                    let errorBecauseShouldNotRenewToken = self.errorBecauseShouldNotRenewToken(dataError)
                    
                    if errorBecauseShouldNotRenewToken == nil {
                        ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) retry request \(updatedRequest)")
                        if self.tokenErrorRetries < 1 {
                            let newTask = self.executeRequest(mutableRequest, withAuthOption: .tokenRetry, wrapperSDKAgents: wrapperSDKAgents, completion: completion)
                            return
                        }
                    }
                    
                    if let errorBecauseShouldNotRenewToken = errorBecauseShouldNotRenewToken {
                        finalError = errorBecauseShouldNotRenewToken
                    } else if let dataError = dataError {
                        finalError = dataError
                    } else if let decodeError = decodeError {
                        finalError = decodeError
                    }
                }
                
                if finalError == nil {
                    finalError = ARTErrorInfo.create(
                        withCode: response.statusCode * 100,
                        status: response.statusCode,
                        message: String(data: finalData ?? Data(), encoding: .utf8) ?? "",
                        requestId: requestId
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
                    let hosts = ARTFallbackHosts.hosts(from: self.options)
                    blockFallbacks = ARTFallback(fallbackHosts: hosts, shuffleArray: self.options.testOptions?.shuffleArray ?? true)
                }
                
                if let fallback = blockFallbacks, let host = fallback.popFallbackHost() {
                    ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) host is down; retrying request at \(host)")
                    
                    self.currentFallbackHost = host
                    var newRequest = updatedRequest
                    newRequest.setValue(host, forHTTPHeaderField: "Host")
                    newRequest.url = URL.copy(from: updatedRequest.url!, withHost: host)
                    
                    let newTask = self.executeRequest(newRequest,
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
                    completion(response, finalData, NSError.copy(fromError: error, withRequestId: requestId))
                }
            } else {
                completion(response, finalData, nil)
            }
        }
        
        return task
    }
    
    // swift-migration: original location ARTRest.m, line 492
    private func errorBecauseShouldNotRenewToken(_ error: ARTErrorInfo?) -> ARTErrorInfo? {
        if let error = error, ARTDefaultErrorChecker().isTokenError(error) {
            if auth.tokenIsRenewable() {
                return nil
            }
            return ARTErrorInfo.create(withCode: ARTStateRequestTokenFailed, message: ARTAblyMessageNoMeansToRenewToken)
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
        return options.restHost
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
    public func time(wrapperSDKAgents: [String: String]?, completion: @escaping ARTDateTimeCallback) {
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
    public func _time(wrapperSDKAgents: [String: String]?, completion: @escaping ARTDateTimeCallback) -> ARTCancellable? {
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
                var decodeError: Error?
                let dataError = self.encoders[response.mimeType]?.decodeErrorInfo(data ?? Data(), error: &decodeError)
                completion(nil, dataError ?? decodeError)
            } else {
                var decodeError: Error?
                let time = self.encoders[response.mimeType]?.decodeTime(data ?? Data(), error: &decodeError)
                completion(time, decodeError)
            }
        }
    }
    
    // swift-migration: original location ARTRest.m, line 579
    public func request(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTHTTPPaginatedCallback, error: UnsafeMutablePointer<Error?>?) -> Bool {
        
        let userCallback = callback
        let wrappedCallback: ARTHTTPPaginatedCallback = { response, error in
            self.userQueue.async {
                userCallback(response, error)
            }
        }
        
        let allowedMethods = ["get", "post", "patch", "put", "delete"]
        if !allowedMethods.contains(method.lowercased()) {
            if let errorPtr = error {
                errorPtr.pointee = NSError(
                    domain: ARTAblyErrorDomain,
                    code: ARTCustomRequestErrorInvalidMethod.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Method isn't valid."]
                )
            }
            return false
        }
        
        if let body = body {
            if !(body is [String: Any]) && !(body is [Any]) {
                if let errorPtr = error {
                    errorPtr.pointee = NSError(
                        domain: ARTAblyErrorDomain,
                        code: ARTCustomRequestErrorInvalidBody.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Body should be a Dictionary or an Array."]
                    )
                }
                return false
            }
        }
        
        if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let errorPtr = error {
                errorPtr.pointee = NSError(
                    domain: ARTAblyErrorDomain,
                    code: ARTCustomRequestErrorInvalidPath.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Path cannot be empty."]
                )
            }
            return false
        }
        
        guard let url = URL(string: path, relativeTo: baseUrl) else {
            if let errorPtr = error {
                errorPtr.pointee = NSError(
                    domain: ARTAblyErrorDomain,
                    code: ARTCustomRequestErrorInvalidPath.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Path isn't valid for an URL."]
                )
            }
            return false
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var queryItems: [URLQueryItem] = []
        
        params?.forEach { key, value in
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems
        
        var mutableRequest = URLRequest(url: components.url!)
        mutableRequest.httpMethod = method
        
        headers?.forEach { key, value in
            mutableRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            do {
                let bodyData = try defaultEncoder.encode(any: body)
                
                mutableRequest.httpBody = bodyData
                mutableRequest.setValue(defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")
                
                if method.lowercased() == "post" {
                    mutableRequest.setValue("\(bodyData?.count ?? 0)", forHTTPHeaderField: "Content-Length")
                }
            } catch let encodeError {
                if let errorPtr = error {
                    errorPtr.pointee = encodeError
                }
                return false
            }
        }
        
        let request = mutableRequest.settingAcceptHeader(defaultEncoder: defaultEncoder, encoders: encoders)
        
        ARTLogDebug(logger, "request \(method) \(path)")
        queue.async {
            ARTHTTPPaginatedResponse.executePaginated(self, withRequest: request, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
        }
        
        return true
    }
    
    // swift-migration: original location ARTRest+Private.h, line 85 and ARTRest.m, line 679
    @discardableResult
    public func internetIsUp(_ callback: @escaping (Bool) -> Void) -> ARTCancellable? {
        let requestUrl = URL(string: "https://internet-up.ably-realtime.com/is-the-internet-up.txt")!
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        return httpExecutor.executeRequest(request) { response, data, error in
            if error != nil {
                callback(false)
                return
            }
            
            let str = data.flatMap { String(data: $0, encoding: .utf8) }
            callback(response?.statusCode == 200 && str == "yes\n")
        }
    }
    
    // swift-migration: original location ARTRest+Private.h, line 109 and ARTRest.m, line 694
    public func stats(wrapperSDKAgents: [String: String]?, completion: @escaping ARTPaginatedStatsCallback) -> Bool {
        let nilError: UnsafeMutablePointer<Error?>? = nil
        return stats(ARTStatsQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: completion, error: nilError)
    }
    
    // swift-migration: original location ARTRest+Private.h, line 112 and ARTRest.m, line 699
    public func stats(_ query: ARTStatsQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedStatsCallback, error: UnsafeMutablePointer<Error?>?) -> Bool {
        
        let userCallback = callback
        let wrappedCallback: ARTPaginatedStatsCallback = { result, error in
            self.userQueue.async {
                userCallback(result, error)
            }
        }
        
        let actualQuery = query ?? ARTStatsQuery()
        
        if actualQuery.limit > 1000 {
            if let errorPtr = error {
                errorPtr.pointee = NSError(
                    domain: ARTAblyErrorDomain,
                    code: ARTDataQueryError.limit.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Limit supports up to 1000 results only"]
                )
            }
            return false
        }
        
        if let start = actualQuery.start, let end = actualQuery.end, start.compare(end) == .orderedDescending {
            if let errorPtr = error {
                errorPtr.pointee = NSError(
                    domain: ARTAblyErrorDomain,
                    code: ARTDataQueryError.timestampRange.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Start must be equal to or less than end"]
                )
            }
            return false
        }
        
        var requestUrl = URLComponents(string: "/stats")!
        var queryError: Error?
        requestUrl.queryItems = actualQuery.asQueryItems(&queryError)
        
        if let queryError = queryError {
            if let errorPtr = error {
                errorPtr.pointee = queryError
            }
            return false
        }
        
        let request = URLRequest(url: requestUrl.url(relativeTo: baseUrl)!)
        
        let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data, errorPtr in
            guard let response = response, let mimeType = response.mimeType else { return nil }
            do {
                return try self.encoders[mimeType]?.decodeStats(data ?? Data())
            } catch let caughtError {
                if let errorPtr = errorPtr {
                    errorPtr.pointee = caughtError
                }
                return nil
            }
        }
        
        queue.async {
            ARTPaginatedResult<ARTStats>.executePaginated(self, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
        }
        
        return true
    }
    
    // swift-migration: original location ARTRest.m, line 328
    private func agentIdentifier(wrapperSDKAgents: [String: String]?) -> String {
        var additionalAgents: [String: String] = [:]
        
        if let agents = options.agents {
            for (agentName, agentValue) in agents {
                additionalAgents[agentName] = agentValue
            }
        }
        
        if let wrapperAgents = wrapperSDKAgents {
            for (agentName, agentValue) in wrapperAgents {
                additionalAgents[agentName] = agentValue
            }
        }
        
        return ARTClientInformation.agentIdentifierWithAdditionalAgents(additionalAgents)
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

// Placeholder classes - these will be replaced when dependencies are migrated

// swift-migration: ARTRestChannels placeholder for compilation
public class ARTRestChannels: NSObject {
    private let `internal`: ARTRestChannelsInternal
    private let queuedDealloc: ARTQueuedDealloc
    
    internal init(internal: ARTRestChannelsInternal, queuedDealloc: ARTQueuedDealloc) {
        self.`internal` = `internal`
        self.queuedDealloc = queuedDealloc
        super.init()
        fatalError("ARTRestChannels not yet migrated")
    }
}

// swift-migration: ARTRestChannelsInternal placeholder defined in MigrationPlaceholders.swift

// Additional utility functions needed for compilation
private func encodeBase64(_ string: String) -> String {
    return Data(string.utf8).base64EncodedString()
}