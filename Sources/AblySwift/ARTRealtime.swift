//
//  ARTRealtime.swift
//
//

import Foundation

// swift-migration: ARTConnectionStateChange.setRetryIn method is implemented elsewhere

// swift-migration: original location ARTRealtime.h, line 30
/**
 This protocol contains the non-initializer instance methods provided by the `ARTRealtime` client class.
 */
public protocol ARTRealtimeInstanceMethodsProtocol: NSObjectProtocol {
    
    #if os(iOS)
    // swift-migration: original location ARTRealtime.h, line 36
    /**
     * Retrieves a `ARTLocalDevice` object that represents the current state of the device as a target for push notifications.
     */
    var device: ARTLocalDevice { get }
    #endif
    
    // swift-migration: original location ARTRealtime.h, line 42
    /**
     * A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. A `clientId` may also be implicit in a token used to instantiate the library; an error will be raised if a `clientId` specified here conflicts with the `clientId` implicit in the token.
     */
    var clientId: String? { get }
    
    // swift-migration: original location ARTRealtime.h, line 49
    /**
     * Retrieves the time from the Ably service. Clients that do not have access to a sufficiently well maintained time source and wish to issue Ably `ARTTokenRequest`s with a more accurate timestamp should use the `ARTAuthOptions.queryTime` property instead of this method.
     *
     * @param callback A callback for receiving the time as a `NSDate` object.
     */
    func time(_ callback: @escaping ARTDateTimeCallback)
    
    // swift-migration: original location ARTRealtime.h, line 64
    /**
     * Makes a REST request to a provided path. This is provided as a convenience for developers who wish to use REST API functionality that is either not documented or is not yet included in the public API, without having to directly handle features such as authentication, paging, fallback hosts, MsgPack and JSON support.
     *
     * @param method The request method to use, such as GET, POST.
     * @param path The request path.
     * @param params The parameters to include in the URL query of the request. The parameters depend on the endpoint being queried. See the [REST API reference](https://ably.com/docs/api/rest-api) for the available parameters of each endpoint.
     * @param body The JSON body of the request.
     * @param headers Additional HTTP headers to include in the request.
     * @param callback A callback for retriving `ARTHttpPaginatedResponse` object returned by the HTTP request, containing an empty or JSON-encodable object.
     */
    func request(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?, callback: @escaping ARTHTTPPaginatedCallback) throws
    
    // swift-migration: original location ARTRealtime.h, line 73
    /// :nodoc: TODO: docstring
    func ping(_ cb: @escaping ARTCallback)
    
    // swift-migration: original location ARTRealtime.h, line 76
    /// :nodoc: TODO: docstring
    func stats(_ callback: @escaping ARTPaginatedStatsCallback) -> Bool
    
    // swift-migration: original location ARTRealtime.h, line 87
    /**
     * Queries the REST `/stats` API and retrieves your application's usage statistics. Returns a `ARTPaginatedResult` object, containing an array of `ARTStats` objects. See the [Stats docs](https://ably.com/docs/general/statistics).
     *
     * @param query An `ARTStatsQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTStats` objects.
     */
    func stats(_ query: ARTStatsQuery?, callback: @escaping ARTPaginatedStatsCallback) throws
    
    // swift-migration: original location ARTRealtime.h, line 92
    /**
     * Calls `-[ARTConnectionProtocol connect]` and causes the connection to open, entering the connecting state. Explicitly calling `connect` is unnecessary unless the `ARTClientOptions.autoConnect` property is disabled.
     */
    func connect()
    
    // swift-migration: original location ARTRealtime.h, line 97
    /**
     * Calls `-[ARTConnectionProtocol close]` and causes the connection to close, entering the closing state. Once closed, the library will not attempt to re-establish the connection without an explicit call to `connect`.
     */
    func close()
}

// swift-migration: original location ARTRealtime.h, line 104
/**
 The protocol upon which the top level object `ARTRealtime` is implemented.
 */
public protocol ARTRealtimeProtocol: ARTRealtimeInstanceMethodsProtocol {
    
    // swift-migration: original location ARTRealtime.h, line 114
    /**
     * Constructs an `ARTRealtime` object using an Ably `ARTClientOptions` object.
     *
     * @param options An `ARTClientOptions` object.
     */
    init(options: ARTClientOptions)
    
    // swift-migration: original location ARTRealtime.h, line 121
    /**
     * Constructs an `ARTRealtime` object using an Ably API key.
     *
     * @param key The Ably API key used to validate the client.
     */
    init(key: String)
    
    // swift-migration: original location ARTRealtime.h, line 128
    /**
     * Constructs an `ARTRealtime` object using an Ably token string.
     *
     * @param token The Ably token string used to validate the client.
     */
    init(token: String)
}

// swift-migration: original location ARTRealtime.h, line 136 and ARTRealtime.m, line 67
public class ARTRealtime: NSObject, ARTRealtimeProtocol {
    private var _internal: ARTRealtimeInternal
    private var _dealloc: ARTQueuedDealloc?
    
    // swift-migration: original location ARTRealtime.m, line 71
    internal func internalAsync(_ use: @escaping (ARTRealtimeInternal) -> Void) {
        _internal.queue.async {
            use(self._internal)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 77
    internal func internalSync(_ use: (ARTRealtimeInternal) -> Void) {
        _internal.queue.sync {
            use(self._internal)
        }
    }
    
    // swift-migration: original location ARTRealtime.h, line 141 and ARTRealtime.m, line 83
    public var connection: ARTConnection {
        return ARTConnection(internal: _internal.connection, queuedDealloc: _dealloc!)
    }
    
    // swift-migration: original location ARTRealtime.h, line 145 and ARTRealtime.m, line 87
    public var channels: ARTRealtimeChannels {
        // swift-migration: TODO
        fatalError()
        //        return ARTRealtimeChannels()
    }
    
    // swift-migration: original location ARTRealtime.h, line 153 and ARTRealtime.m, line 91
    public var auth: ARTAuth {
        return ARTAuth(internal: _internal.auth, queuedDealloc: _dealloc!)
    }
    
    // swift-migration: original location ARTRealtime.h, line 149 and ARTRealtime.m, line 95
    public var push: ARTPush {
        return ARTPush(internal: _internal.push, queuedDealloc: _dealloc!)
    }
    
    #if os(iOS)
    // swift-migration: original location ARTRealtime.h, line 36 and ARTRealtime.m, line 100
    public var device: ARTLocalDevice {
        return _internal.device
    }
    #endif
    
    // swift-migration: original location ARTRealtime.h, line 42 and ARTRealtime.m, line 105
    public var clientId: String? {
        return _internal.clientId
    }
    
    // swift-migration: original location ARTRealtime.m, line 109
    private func initCommon() {
        _dealloc = ARTQueuedDealloc(ref: _internal, queue: _internal.queue)
    }
    
    // swift-migration: original location ARTRealtime.h, line 114 and ARTRealtime.m, line 113
    public required init(options: ARTClientOptions) {
        _internal = ARTRealtimeInternal(options: options)
        super.init()
        initCommon()
    }
    
    // swift-migration: original location ARTRealtime.h, line 121 and ARTRealtime.m, line 122
    public required init(key: String) {
        _internal = ARTRealtimeInternal(key: key)
        super.init()
        initCommon()
    }
    
    // swift-migration: original location ARTRealtime.h, line 127 and ARTRealtime.m, line 131
    public required init(token: String) {
        _internal = ARTRealtimeInternal(token: token)
        super.init()
        initCommon()
    }
    
    // swift-migration: original location ARTRealtime.m, line 140
    public static func createWithOptions(_ options: ARTClientOptions) -> ARTRealtime {
        return ARTRealtime(options: options)
    }
    
    // swift-migration: original location ARTRealtime.m, line 144
    public static func createWithKey(_ key: String) -> ARTRealtime {
        return ARTRealtime(key: key)
    }
    
    // swift-migration: original location ARTRealtime.m, line 148
    public static func createWithToken(_ tokenId: String) -> ARTRealtime {
        return ARTRealtime(token: tokenId)
    }
    
    // swift-migration: original location ARTRealtime.h, line 49 and ARTRealtime.m, line 152
    public func time(_ cb: @escaping ARTDateTimeCallback) {
        _internal.timeWithWrapperSDKAgents(nil, completion: cb)
    }
    
    // swift-migration: original location ARTRealtime.h, line 64 and ARTRealtime.m, line 157
    // swift-migration: Converted NSErrorPointer pattern to Swift throws pattern per PRD requirements
    public func request(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?, callback: @escaping ARTHTTPPaginatedCallback) throws {
        try _internal.request(method, path: path, params: params, body: body, headers: headers, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtime.h, line 73 and ARTRealtime.m, line 167
    public func ping(_ cb: @escaping ARTCallback) {
        _internal.ping(cb)
    }
    
    // swift-migration: original location ARTRealtime.h, line 76 and ARTRealtime.m, line 171
    public func stats(_ callback: @escaping ARTPaginatedStatsCallback) -> Bool {
        return _internal.statsWithWrapperSDKAgents(nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtime.h, line 87 and ARTRealtime.m, line 176
    // swift-migration: Converted NSErrorPointer pattern to Swift throws pattern per PRD requirements
    public func stats(_ query: ARTStatsQuery?, callback: @escaping ARTPaginatedStatsCallback) throws {
        try _internal.stats(query, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtime.h, line 92 and ARTRealtime.m, line 180
    public func connect() {
        _internal.connect()
    }
    
    // swift-migration: original location ARTRealtime.h, line 97 and ARTRealtime.m, line 184
    public func close() {
        _internal.close()
    }
}

// swift-migration: original location ARTRealtime+WrapperSDKProxy.h, line 8 and ARTRealtime.m, line 190
extension ARTRealtime {
    // swift-migration: original location ARTRealtime+WrapperSDKProxy.h, line 17 and ARTRealtime.m, line 192
    public func createWrapperSDKProxy(options: ARTWrapperSDKProxyOptions) -> ARTWrapperSDKProxyRealtime {
        return ARTWrapperSDKProxyRealtime(realtime: self, proxyOptions: options)
    }
}

private enum ARTNetworkState: UInt {
    // swift-migration: original location ARTRealtime.m, line 211
    case isUnknown = 0
    case isReachable = 1 
    case isUnreachable = 2
}

// swift-migration: original location ARTRealtime+Private.h, line 32 and ARTRealtime.m, line 217
public class ARTRealtimeInternal: NSObject, APRealtimeClient, ARTRealtimeTransportDelegate, ARTAuthDelegate {
    
    // MARK: - Public Interface Properties (from header)
    
    // swift-migration: original location ARTRealtime+Private.h, line 39 and ARTRealtime.m, line 259
    internal let connection: ARTConnectionInternal
    
    // swift-migration: original location ARTRealtime+Private.h, line 40 and ARTRealtime.m, line 250
    internal let channels: ARTRealtimeChannelsInternal
    
    // swift-migration: original location ARTRealtime+Private.h, line 41 and ARTRealtime.m, line 441
    internal var auth: ARTAuthInternal {
        return rest.auth
    }
    
    // swift-migration: original location ARTRealtime+Private.h, line 42 and ARTRealtime.m, line 445
    internal var push: ARTPushInternal {
        return rest.push
    }
    
    #if os(iOS)
    // swift-migration: original location ARTRealtime+Private.h, line 44 and ARTRealtime.m, line 1768
    internal var device: ARTLocalDevice {
        return rest.device
    }
    #endif
    
    // swift-migration: original location ARTRealtime+Private.h, line 46 and ARTRealtime.m, line 419
    internal var clientId: String? {
        // Doesn't need synchronization since it's immutable.
        return rest.options.clientId
    }
    
    // swift-migration: original location ARTRealtime+Private.h, line 48 and ARTRealtime.m, line 246
    internal let queue: DispatchQueue
    
    // MARK: - Private Interface Properties (from private extensions in header)
    
    // swift-migration: original location ARTRealtime+Private.h, line 77
    internal let internalEventEmitter: ARTEventEmitter<ARTEvent, ARTConnectionStateChange>
    
    // swift-migration: original location ARTRealtime+Private.h, line 78
    internal let connectedEventEmitter: ARTEventEmitter<ARTEvent, NSNull>
    
    // swift-migration: original location ARTRealtime+Private.h, line 80 and ARTRealtime.m, line 258
    internal var pendingAuthorizations: [(ARTRealtimeConnectionState, ARTErrorInfo?) -> Void]
    
    // MARK: - Implementation Properties (from @implementation block)
    
    // swift-migration: original location ARTRealtime+Private.h, line 94 and ARTRealtime.m, line 244
    internal let rest: ARTRestInternal
    
    // swift-migration: original location ARTRealtime+Private.h, line 95 and ARTRealtime.m, line 411
    internal var transport: ARTRealtimeTransport? {
        return _transport
    }
    
    // swift-migration: original location ARTRealtime+Private.h, line 96
    internal var reachability: ARTReachability?
    
    // swift-migration: original location ARTRealtime+Private.h, line 97 and ARTRealtime.m, line 260
    internal var connectionStateTtl: TimeInterval
    
    // swift-migration: original location ARTRealtime+Private.h, line 98 and ARTRealtime.m, line 940
    internal var maxIdleInterval: TimeInterval = 0
    
    // swift-migration: original location ARTRealtime+Private.h, line 101 and ARTRealtime.m, line 254
    internal var msgSerial: Int64
    
    // swift-migration: original location ARTRealtime+Private.h, line 104 and ARTRealtime.m, line 255
    internal var queuedMessages: [ARTQueuedMessage]
    
    // swift-migration: original location ARTRealtime+Private.h, line 107 and ARTRealtime.m, line 256
    internal var pendingMessages: [ARTPendingMessage]
    
    // swift-migration: original location ARTRealtime+Private.h, line 110 and ARTRealtime.m, line 257
    internal var pendingMessageStartSerial: Int64
    
    // swift-migration: original location ARTRealtime+Private.h, line 113 and ARTRealtime.m, line 218
    internal var resuming: Bool
    
    // swift-migration: original location ARTRealtime+Private.h, line 115 and ARTRealtime.m, line 415
    internal var options: ARTClientOptions {
        return rest.options
    }
    
    // swift-migration: original location ARTRealtime+Private.h, line 118 and ARTRealtime.m, line 261
    internal var immediateReconnectionDelay: TimeInterval
    
    // MARK: - Private backing storage variables
    
    // swift-migration: original location ARTRealtime.m, line 204
    private let connectRetryState: ARTConnectRetryState
    
    // swift-migration: original location ARTRealtime.m, line 205
    private let logger: ARTInternalLog
    
    // swift-migration: original location ARTRealtime.m, line 219
    private var _renewingToken: Bool = false
    
    // swift-migration: original location ARTRealtime.m, line 221
    private let _pingEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>
    
    // swift-migration: original location ARTRealtime.m, line 222
    private var _connectionLostAt: Date?
    
    // swift-migration: original location ARTRealtime.m, line 223
    private var _lastActivity: Date = Date()
    
    // swift-migration: original location ARTRealtime.m, line 224
    private var _reachabilityClass: ARTReachability.Type?
    
    // swift-migration: original location ARTRealtime.m, line 225
    private var _networkState: ARTNetworkState = .isUnknown
    
    // swift-migration: original location ARTRealtime.m, line 226
    private var _transport: ARTRealtimeTransport?
    
    // swift-migration: original location ARTRealtime.m, line 227
    private var _fallbacks: ARTFallback?
    
    // swift-migration: original location ARTRealtime.m, line 228
    private weak var _connectionRetryFromSuspendedListener: ARTEventListener?
    
    // swift-migration: original location ARTRealtime.m, line 229
    private weak var _connectionRetryFromDisconnectedListener: ARTEventListener?
    
    // swift-migration: original location ARTRealtime.m, line 230
    private weak var _connectingTimeoutListener: ARTEventListener?
    
    // swift-migration: original location ARTRealtime.m, line 231
    private var _authenitcatingTimeoutWork: ARTScheduledBlockHandle?
    
    // swift-migration: original location ARTRealtime.m, line 232
    private var _authTask: ARTCancellable?
    
    // swift-migration: original location ARTRealtime.m, line 233
    private var _idleTimer: ARTScheduledBlockHandle?
    
    // swift-migration: original location ARTRealtime.m, line 234
    private let _userQueue: DispatchQueue
    
    // swift-migration: original location ARTRealtime.m, line 235
    private let _queue: DispatchQueue
    
    // MARK: - Additional Properties for Protocol Conformance
    
    // Properties needed by ARTConnection - these are computed properties
    internal var isActive: Bool { 
        // swift-migration: original location ARTRealtime.m, line 1264
        if shouldSendEvents {
            return true
        }
        switch connection.state_nosync {
        case .initialized, .connecting, .connected:
            return true
        default:
            return false
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1255
    internal var shouldSendEvents: Bool {
        switch connection.state_nosync {
        case .connected:
            return !_renewingToken
        default:
            return false
        }
    }
    
    // swift-migration: original location ARTRealtime+Private.h, line 35 and ARTRealtime.m, line 238
    internal init(options: ARTClientOptions) {
        // swift-migration: TODO - placeholder init - full implementation needed
        fatalError("TODO - init implementation needed")
    }
    
    // swift-migration: original location ARTRealtime.m, line 402
    internal convenience init(key: String) {
        let options = ARTClientOptions()
        options.key = key
        self.init(options: options)
    }
    
    // swift-migration: original location ARTRealtime.m, line 406
    internal convenience init(token: String) {
        let options = ARTClientOptions()
        options.token = token
        self.init(options: options)
    }
    
    
    // swift-migration: original location ARTRealtime.m, line 454
    internal func connect() {
        queue.sync {
            // swift-migration: Simplified - full implementation would be more complex
            connection.setState(.connecting)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 472
    internal func close() {
        queue.sync {
            // swift-migration: Simplified - full implementation would be more complex
            connection.setState(.closing)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 504
    internal func timeWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion: @escaping ARTDateTimeCallback) {
        rest.time(wrapperSDKAgents: wrapperSDKAgents, completion: completion)
    }
    
    // swift-migration: original location ARTRealtime.m, line 510
    // swift-migration: Converted NSErrorPointer pattern to Swift throws pattern per PRD requirements
    internal func request(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTHTTPPaginatedCallback) throws {
        try rest.request(method, path: path, params: params, body: body, headers: headers, wrapperSDKAgents: wrapperSDKAgents, callback: callback)
    }
    
    // swift-migration: original location ARTRealtime.m, line 521  
    internal func ping(_ cb: @escaping ARTCallback) {
        // swift-migration: Simplified - full implementation would include complex state checking and timeout handling
        let userQueue = rest.userQueue
        let callback: ARTCallback = { error in
            userQueue.async {
                cb(error)
            }
        }
        
        queue.async {
            // swift-migration: Simplified ping implementation - just call back with no error for now
            callback(nil)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 558
    internal func statsWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedStatsCallback) -> Bool {
        do {
            try stats(ARTStatsQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: callback)
            return true
        } catch {
            // swift-migration: Handle error appropriately - for now return false to maintain Bool return type
            return false
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 563
    // swift-migration: Converted NSErrorPointer pattern to Swift throws pattern per PRD requirements
    internal func stats(_ query: ARTStatsQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedStatsCallback) throws {
        try rest.stats(query, wrapperSDKAgents: wrapperSDKAgents, callback: callback)
    }
    
    // swift-migration: original location ARTRealtime.m, line 448
    deinit {
        ARTLogVerbose(ARTInternalLog(clientOptions: rest.options), "R:\(Unmanaged.passUnretained(self).toOpaque()) dealloc")
        rest.prioritizedHost = nil
    }
    
    // MARK: - Protocol Conformance
    
    // swift-migration: ARTAuthDelegate protocol method - original location ARTRealtime.m, line 299
    internal func auth(_ auth: ARTAuthInternal, didAuthorize tokenDetails: ARTTokenDetails, completion: @escaping (ARTAuthorizationState, ARTErrorInfo?) -> Void) {
        // swift-migration: Simplified version - full implementation would be much more complex
        completion(.succeeded, nil)
    }
    
    // MARK: - ARTRealtimeTransportDelegate protocol methods
    
    // swift-migration: original location ARTRealtime.m, line 1583
    public func realtimeTransport(_ transport: ARTRealtimeTransport, didReceiveMessage message: ARTProtocolMessage) {
        // swift-migration: Placeholder - complex message handling implementation needed
    }
    
    // swift-migration: original location ARTRealtime.m, line 1646
    public func realtimeTransportAvailable(_ transport: ARTRealtimeTransport) {
        // Do nothing - as per original implementation
    }
    
    // swift-migration: original location ARTRealtime.m, line 1650
    public func realtimeTransportClosed(_ transport: ARTRealtimeTransport) {
        // swift-migration: Placeholder - implementation needed
    }
    
    // swift-migration: original location ARTRealtime.m, line 1665
    public func realtimeTransportDisconnected(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?) {
        // swift-migration: Placeholder - implementation needed
    }
    
    // swift-migration: original location ARTRealtime.m, line 1713
    public func realtimeTransportNeverConnected(_ transport: ARTRealtimeTransport) {
        // swift-migration: Placeholder - implementation needed
    }
    
    // swift-migration: original location ARTRealtime.m, line 1724
    public func realtimeTransportRefused(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?) {
        // swift-migration: Placeholder - implementation needed
    }
    
    // swift-migration: original location ARTRealtime.m, line 1746
    public func realtimeTransportTooBig(_ transport: ARTRealtimeTransport) {
        // swift-migration: Placeholder - implementation needed
    }
    
    // swift-migration: original location ARTRealtime.m, line 1680
    public func realtimeTransportFailed(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError) {
        // swift-migration: Placeholder - implementation needed
    }
    
    // swift-migration: original location ARTRealtime.m, line 1757
    public func realtimeTransportSetMsgSerial(_ transport: ARTRealtimeTransport, msgSerial: Int64) {
        // swift-migration: Placeholder - implementation needed
    }

    // Message sending
    // swift-migration: These two copied by Lawrence for now
    func send(_ msg: ARTProtocolMessage, sentCallback: ARTCallback?, ackCallback: ARTStatusCallback?) {

    }

    func send(_ msg: ARTProtocolMessage, reuseMsgSerial: Bool, sentCallback: ARTCallback?, ackCallback: ARTStatusCallback?) {

    }
}
