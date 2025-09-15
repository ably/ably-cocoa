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
    func stats(_ callback: @escaping ARTPaginatedStatsCallback)
    
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
    public func stats(_ callback: @escaping ARTPaginatedStatsCallback) {
        _internal.statsWithWrapperSDKAgents(nil, callback: callback)
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
    internal var connection: ARTConnectionInternal!

    // swift-migration: original location ARTRealtime+Private.h, line 40 and ARTRealtime.m, line 250
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    internal var channels: ARTRealtimeChannelsInternal!

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
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    internal var queue: DispatchQueue!

    // MARK: - Private Interface Properties (from private extensions in header)
    
    // swift-migration: original location ARTRealtime+Private.h, line 77
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    internal var internalEventEmitter: ARTEventEmitter<ARTEvent, ARTConnectionStateChange>!

    // swift-migration: original location ARTRealtime+Private.h, line 78
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    internal var connectedEventEmitter: ARTEventEmitter<ARTEvent, NSNull>!

    // swift-migration: original location ARTRealtime+Private.h, line 80 and ARTRealtime.m, line 258
    internal var pendingAuthorizations: [(ARTRealtimeConnectionState, ARTErrorInfo?) -> Void]
    
    // MARK: - Implementation Properties (from @implementation block)
    
    // swift-migration: original location ARTRealtime+Private.h, line 94 and ARTRealtime.m, line 244
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    internal var rest: ARTRestInternal!

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
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    private var connectRetryState: ConnectRetryState!

    // swift-migration: original location ARTRealtime.m, line 205
    private let logger: InternalLog
    
    // swift-migration: original location ARTRealtime.m, line 219
    private var _renewingToken: Bool = false
    
    // swift-migration: original location ARTRealtime.m, line 221
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    private var _pingEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>!
    
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
    // swift-migration: Lawrence — changed let to var so that this could be implicitly unwrapped optional; TODO make it so writing is fatalError
    private var _userQueue: DispatchQueue!

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
        // swift-migration: Lawrence — some things moved around here so that we can avoid circular initialization problems (i.e. referring to self before super init called), which Swift is more strict about; we also make some properties implicitly-unwrapped optionals for the same reason

        logger = InternalLog(clientOptions: options)

        _transport = nil
        _networkState = .isUnknown
        _reachabilityClass = ARTOSReachability.self

        msgSerial = 0
        queuedMessages = []
        pendingMessages = []
        pendingMessageStartSerial = 0
        pendingAuthorizations = []

        connectionStateTtl = ARTDefault.connectionStateTtl()
        immediateReconnectionDelay = 0.1

        resuming = false
        reachability = nil

        super.init()

        rest = ARTRestInternal(options: options, realtime: self, logger: logger)
        _userQueue = rest.userQueue
        queue = rest.queue
        
        internalEventEmitter = ARTEventEmitter(queue: rest.queue)
        connectedEventEmitter = ARTEventEmitter(queue: rest.queue)
        _pingEventEmitter = ARTEventEmitter(queue: rest.queue)
        
        channels = ARTRealtimeChannelsInternal(realtime: self, logger: logger)

        connection = ARTConnectionInternal(realtime: self, logger: logger)

        let connectRetryDelayCalculator = BackoffRetryDelayCalculator(
            initialRetryTimeout: options.disconnectedRetryTimeout,
            jitterCoefficientGenerator: options.testOptions.jitterCoefficientGenerator
        )
        connectRetryState = ConnectRetryState(
            retryDelayCalculator: connectRetryDelayCalculator,
            logger: logger,
            logMessagePrefix: "RT: \(Unmanaged.passUnretained(self).toOpaque()) "
        )


        auth.delegate = self
        connection.setState(.initialized)
        
        // swift-migration: Using custom string interpolation for pointer formatting
        ARTLogVerbose(logger, "R:\(pointer: self) initialized with RS:\(pointer: rest)")
        
        rest.prioritizedHost = nil
        
        if let recover = options.recover {
            do {
                let recoveryKey = try ARTConnectionRecoveryKey.fromJsonString(recover)
                msgSerial = recoveryKey.msgSerial // RTN16f
                for (channelName, channelSerial) in recoveryKey.channelSerials {
                    let channel = channels.get(channelName)
                    channel.channelSerial = channelSerial // RTN16j
                }
            } catch {
                ARTLogError(logger, "Couldn't construct a recovery key from the string provided: \(recover)")
            }
        }
        
        if options.autoConnect {
            connect()
        }
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
    
    // MARK: - ARTAuthDelegate
    
    // swift-migration: original location ARTRealtime.m, line 299
    internal func auth(_ auth: ARTAuthInternal, didAuthorize tokenDetails: ARTTokenDetails, completion: @escaping (ARTAuthorizationState, ARTErrorInfo?) -> Void) {
        let waitForResponse: () -> Void = {
            self.pendingAuthorizations.append { state, error in
                switch state {
                case .connected:
                    completion(.succeeded, nil)
                case .failed:
                    completion(.failed, error)
                case .suspended:
                    completion(.failed, ARTErrorInfo.create(withCode: ARTState.authorizationFailed.rawValue, message: "Connection has been suspended"))
                case .closed:
                    completion(.failed, ARTErrorInfo.create(withCode: ARTState.authorizationFailed.rawValue, message: "Connection has been closed"))
                case .disconnected:
                    completion(.cancelled, nil)
                case .initialized, .connecting, .closing:
                    ARTLogDebug(self.logger, "RS:\(pointer: self.rest) authorize completion has been ignored because the connection state is unexpected (\(ARTRealtimeConnectionStateToStr(state)))")
                }
            }
        }
        
        let haltCurrentConnectionAndReconnect: () -> Void = {
            // Halt the current connection and reconnect with the most recent token
            ARTLogDebug(self.logger, "RS:\(pointer: self.rest) halt current connection and reconnect with \(tokenDetails)")
            self.abortAndReleaseTransport(ARTStatus(state: .ok, errorInfo: nil))
            self.setTransportWithResumeKey(self._transport?.resumeKey)
            self._transport?.connect(withToken: tokenDetails.token)
            self.cancelAllPendingAuthorizations()
            waitForResponse()
        }
        
        switch connection.state_nosync {
        case .connected:
            // Update (send AUTH message)
            ARTLogDebug(logger, "RS:\(pointer: rest) AUTH message using \(tokenDetails)")
            let msg = ARTProtocolMessage()
            msg.action = .auth
            msg.auth = ARTAuthDetails(token: tokenDetails.token)
            send(msg, sentCallback: nil, ackCallback: nil)
            waitForResponse()
        case .connecting:
            _transport?.stateEmitter.once(ARTEvent.new(withTransportState: .opened)) { _ in
                haltCurrentConnectionAndReconnect()
            }
        case .closing:
            // Should ignore because the connection is being closed
            ARTLogDebug(logger, "RS:\(pointer: rest) authorize has been cancelled because the connection is closing")
            cancelAllPendingAuthorizations()
        default:
            // Client state is NOT Connecting or Connected, so it should start a new connection
            ARTLogDebug(logger, "RS:\(pointer: rest) new connection from successful authorize \(tokenDetails)")
            performTransitionToState(.connecting, withParams: ARTConnectionStateChangeParams())
            waitForResponse()
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 370
    private func performPendingAuthorizationWithState(_ state: ARTRealtimeConnectionState, error: ARTErrorInfo?) {
        guard !pendingAuthorizations.isEmpty else {
            return
        }
        let pendingAuthorization = pendingAuthorizations.removeFirst()
        switch state {
        case .connected:
            pendingAuthorization(state, nil)
        case .failed:
            pendingAuthorization(state, error)
        default:
            discardPendingAuthorizations()
            pendingAuthorization(state, error)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 389
    private func cancelAllPendingAuthorizations() {
        for pendingAuthorization in pendingAuthorizations {
            pendingAuthorization(.disconnected, nil)
        }
        pendingAuthorizations.removeAll()
    }
    
    // swift-migration: original location ARTRealtime.m, line 396
    private func discardPendingAuthorizations() {
        pendingAuthorizations.removeAll()
    }
    
    // MARK: - Realtime
    
    // swift-migration: original location ARTRealtime.m, line 414
    internal func getClientOptions() -> ARTClientOptions {
        return rest.options
    }
    
    // swift-migration: original location ARTRealtime.m, line 423
    public override var description: String {
        let info: String
        if let token = options.token {
            info = "token: \(token)"
        } else if let authUrl = options.authUrl {
            info = "authUrl: \(authUrl)"
        } else if options.authCallback != nil {
            info = "authCallback: \(String(describing: options.authCallback))"
        } else {
            info = "key: \(options.key ?? "")"
        }
        return "\(super.description) - \n\t \(info);"
    }
    
    // swift-migration: original location ARTRealtime.m, line 448
    deinit {
        ARTLogVerbose(logger, "R:\(pointer: self) dealloc")
        rest.prioritizedHost = nil
    }
    
    // swift-migration: original location ARTRealtime.m, line 454
    internal func connect() {
        queue.sync {
            _connect()
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 460
    private func _connect() {
        if connection.state_nosync == .connecting {
            ARTLogError(logger, "R:\(pointer: self) Ignoring new connection attempt - already in the CONNECTING state.")
            return
        }
        if connection.state_nosync == .closing {
            // New connection
            _transport = nil
        }
        performTransitionToState(.connecting, withParams: ARTConnectionStateChangeParams())
    }
    
    // swift-migration: original location ARTRealtime.m, line 472
    internal func close() {
        queue.sync {
            _close()
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 478
    private func _close() {
        setReachabilityActive(false)
        cancelTimers()
        
        switch connection.state_nosync {
        case .initialized, .closing, .closed, .failed:
            return
        case .connecting:
            internalEventEmitter.once { change in
                self._close()
            }
            return
        case .disconnected, .suspended:
            performTransitionToState(.closed, withParams: ARTConnectionStateChangeParams())
        case .connected:
            performTransitionToState(.closing, withParams: ARTConnectionStateChangeParams())
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 504
    internal func timeWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion: @escaping ARTDateTimeCallback) {
        rest.time(wrapperSDKAgents: wrapperSDKAgents, completion: completion)
    }
    
    // swift-migration: original location ARTRealtime.m, line 510
    internal func request(_ method: String, path: String, params: [String: String]?, body: Any?, headers: [String: String]?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTHTTPPaginatedCallback) throws {
        try rest.request(method, path: path, params: params, body: body, headers: headers, wrapperSDKAgents: wrapperSDKAgents, callback: callback)
    }
    
    // swift-migration: original location ARTRealtime.m, line 521
    internal func ping(_ cb: @escaping ARTCallback) {
        var callback = cb
        
        callback = { error in
            self._userQueue.async {
                cb(error)
            }
        }
        
        queue.async {
            switch self.connection.state_nosync {
            case .initialized, .suspended, .closing, .closed, .failed:
                callback(ARTErrorInfo.create(withCode: 0, status: Int(ARTState.connectionFailed.rawValue), message: "Can't ping a \(ARTRealtimeConnectionStateToStr(self.connection.state_nosync)) connection"))
                return
            case .connecting, .disconnected, .connected:
                if !self.shouldSendEvents {
                    self.connectedEventEmitter.once { _ in
                        self.ping(cb)
                    }
                    return
                }
                let eventListener = self._pingEventEmitter.once(callback)
                eventListener.setTimer(self.options.testOptions.realtimeRequestTimeout) {
                    ARTLogVerbose(self.logger, "R:\(pointer: self) ping timed out")
                    callback(ARTErrorInfo.create(withCode: ARTErrorCode.connectionTimedOut.rawValue, status: Int(ARTState.connectionFailed.rawValue), message: "timed out"))
                }
                eventListener.startTimer()
                self.transport?.sendPing()
            }
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 558
    internal func statsWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedStatsCallback) {
        do {
            try stats(ARTStatsQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: callback)
        } catch {
            // swift-migration: Lawrence: absorb error
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 563
    internal func stats(_ query: ARTStatsQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedStatsCallback) throws {
        try rest.stats(query, wrapperSDKAgents: wrapperSDKAgents, callback: callback)
    }
    
    // swift-migration: original location ARTRealtime.m, line 567
    private func performTransitionToDisconnectedOrSuspendedWithParams(_ params: ARTConnectionStateChangeParams) {
        if isSuspendMode() {
            performTransitionToState(.suspended, withParams: params)
        } else {
            performTransitionToState(.disconnected, withParams: params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 576
    private func updateWithErrorInfo(_ errorInfo: ARTErrorInfo?) {
        ARTLogDebug(logger, "R:\(pointer: self) update requested")
        
        if connection.state_nosync != .connected {
            ARTLogWarn(logger, "R:\(pointer: self) update ignored because connection is not connected")
            return
        }
        
        let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
        performTransitionToState(.connected, withParams: params)
    }
    
    // swift-migration: original location ARTRealtime.m, line 588
    private func didChangeNetworkStateFromState(_ previousState: ARTNetworkState) {
        if _networkState == .isReachable {
            switch connection.state_nosync {
            case .connecting:
                if previousState == .isUnreachable {
                    transportReconnectWithExistingParameters()
                }
            case .disconnected, .suspended:
                performTransitionToState(.connecting, withParams: ARTConnectionStateChangeParams())
            default:
                break
            }
        } else {
            switch connection.state_nosync {
            case .connecting, .connected:
                let unreachable = ARTErrorInfo.create(withCode: -1003, message: "unreachable host")
                let params = ARTConnectionStateChangeParams(errorInfo: unreachable)
                performTransitionToDisconnectedOrSuspendedWithParams(params)
            default:
                break
            }
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 619
    private func setReachabilityActive(_ active: Bool) {
        if active && reachability == nil {
            reachability = _reachabilityClass?.init(logger: logger, queue: queue)
        }
        if active {
            // swift-migration: Lawrence: claude added this `if` trying to fix compilation errors
            if let host = _transport?.host() {
                reachability?.listenForHost(host) { [weak self] reachable in
                guard let self = self else { return }
                
                let previousState = self._networkState
                    self._networkState = reachable ? .isReachable : .isUnreachable
                    self.didChangeNetworkStateFromState(previousState)
                }
            }
        } else {
            reachability?.off()
            _networkState = .isUnknown
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 640
    private func clearConnectionStateIfInactive() {
        let intervalSinceLast = Date().timeIntervalSince(_lastActivity)
        if intervalSinceLast > (maxIdleInterval + connectionStateTtl) {
            connection.setId(nil)
            connection.setKey(nil)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 648
    private func performTransitionToState(_ state: ARTRealtimeConnectionState, withParams params: ARTConnectionStateChangeParams) {
        var channelStateChangeParams: ARTChannelStateChangeParams?
        var stateChangeEventListener: ARTEventListener?
        
        ARTLogVerbose(logger, "R:\(pointer: self) realtime state transitions to \(state.rawValue) - \(ARTRealtimeConnectionStateToStr(state))\(params.retryAttempt != nil ? " (result of \(params.retryAttempt!.id))" : "")")
        
        let event: ARTRealtimeConnectionEvent = state == connection.state_nosync ? .update : ARTRealtimeConnectionEvent(rawValue: Int(state.rawValue))!
        
        let stateChange = ARTConnectionStateChange(
            current: state,
            previous: connection.state_nosync,
            event: event,
            reason: params.errorInfo,
            retryIn: 0,
            retryAttempt: params.retryAttempt
        )
        
        ARTLogDebug(logger, "RT:\(pointer: self) realtime is transitioning from \(stateChange.previous.rawValue) - \(ARTRealtimeConnectionStateToStr(stateChange.previous)) to \(stateChange.current.rawValue) - \(ARTRealtimeConnectionStateToStr(stateChange.current))")
        
        connection.setState(state)
        connection.setErrorReason(params.errorInfo)
        
        connectRetryState.connectionWillTransition(to: stateChange.current)
        
        switch stateChange.current {
        case .connecting:
            // RTN15g We want to enforce a new connection also when there hasn't been activity for longer than (idle interval + TTL)
            if stateChange.previous == .disconnected || stateChange.previous == .suspended {
                clearConnectionStateIfInactive()
            }
            
            stateChangeEventListener = unlessStateChangesBefore(options.testOptions.realtimeRequestTimeout) {
                self.onConnectionTimeOut()
            }
            _connectingTimeoutListener = stateChangeEventListener
            
            var usingFallback = false
            
            if let fallbacks = _fallbacks {
                usingFallback = reconnectWithFallback() // RTN17j
            }
            if !usingFallback {
                if _transport == nil {
                    let resume = stateChange.previous == .failed ||
                                stateChange.previous == .disconnected ||
                                stateChange.previous == .suspended
                    createAndConnectTransportWithConnectionResume(resume)
                }
                setReachabilityActive(true)
            }
            
        case .closing:
            stopIdleTimer()
            setReachabilityActive(false)
            stateChangeEventListener = unlessStateChangesBefore(options.testOptions.realtimeRequestTimeout) {
                self.performTransitionToState(.closed, withParams: ARTConnectionStateChangeParams())
            }
            transport?.sendClose()
            
        case .closed:
            stopIdleTimer()
            setReachabilityActive(false)
            closeAndReleaseTransport()
            connection.setKey(nil)
            connection.setId(nil)
            _transport = nil
            _fallbacks = nil
            rest.prioritizedHost = nil
            auth.cancelAuthorization(nil)
            failPendingMessages(ARTStatus(state: .error, errorInfo: ARTErrorInfo.create(withCode: ARTErrorCode.connectionClosed.rawValue, message: "connection broken before receiving publishing acknowledgment")))
            
        case .failed:
            let status = ARTStatus(state: .connectionFailed, errorInfo: stateChange.reason)
            channelStateChangeParams = ARTChannelStateChangeParams(state: status.state, errorInfo: status.errorInfo)
            abortAndReleaseTransport(status)
            _fallbacks = nil
            rest.prioritizedHost = nil
            auth.cancelAuthorization(stateChange.reason)
            failPendingMessages(ARTStatus(state: .error, errorInfo: ARTErrorInfo.create(withCode: ARTErrorCode.connectionFailed.rawValue, message: "connection broken before receiving publishing acknowledgment")))
            
        case .disconnected:
            closeAndReleaseTransport()
            if _connectionLostAt == nil {
                _connectionLostAt = Date()
                ARTLogVerbose(logger, "RT:\(pointer: self) set connection lost time; expected suspension at \(suspensionTime()) (ttl=\(connectionStateTtl))")
            }
            
            var retryDelay: TimeInterval
            var retryAttempt: ARTRetryAttempt?
            
            // Immediate reconnection as per internal discussion:
            // https://ably-real-time.slack.com/archives/CURL4U2FP/p1742211172312389?thread_ts=1741387920.007779&cid=CURL4U2FP
            // See comment to `testRTN14dAndRTB1` test function for details
            if stateChange.previous == .connected || _fallbacks != nil {
                retryDelay = immediateReconnectionDelay // RTN15a, RTN15h3
            } else {
                retryAttempt = connectRetryState.addRetryAttempt()
                retryDelay = retryAttempt!.delay
            }
            stateChange.setRetryIn(retryDelay)
            ARTLogVerbose(logger, "RT:\(pointer: self) expecting retry in \(retryDelay) seconds...")
            stateChangeEventListener = unlessStateChangesBefore(stateChange.retryIn) {
                self._connectionRetryFromDisconnectedListener = nil
                let params = ARTConnectionStateChangeParams(errorInfo: nil, retryAttempt: retryAttempt)
                self.performTransitionToState(.connecting, withParams: params)
            }
            _connectionRetryFromDisconnectedListener = stateChangeEventListener
            
        case .suspended:
            _fallbacks = nil // RTN17a - "must always prefer the default endpoint", thus resetting fallbacks to start connection sequence again with the default endpoint
            _connectionRetryFromDisconnectedListener?.stopTimer()
            _connectionRetryFromDisconnectedListener = nil
            auth.cancelAuthorization(nil)
            closeAndReleaseTransport()
            stateChange.setRetryIn(options.suspendedRetryTimeout)
            stateChangeEventListener = unlessStateChangesBefore(stateChange.retryIn) {
                self._connectionRetryFromSuspendedListener = nil
                self.performTransitionToState(.connecting, withParams: ARTConnectionStateChangeParams())
            }
            _connectionRetryFromSuspendedListener = stateChangeEventListener
            
        case .connected:
            _fallbacks = nil // RTN17a
            _connectionLostAt = nil
            options.recover = nil // RTN16k
            resendPendingMessagesWithResumed(params.resumed) // RTN19a1
            connectedEventEmitter.emit(nil, with: nil)
            
        case .initialized:
            break
        }
        
        // If there's a channels.release() going on waiting on this channel
        // to detach, doing those operations on it here would fire its event listener and
        // immediately remove the channel from the channels dictionary, thus
        // invalidating the iterator and causing a crashing.
        //
        // So copy the channels and operate on them later, when we're done using the iterator.
        // swift-migration: Lawrence Changed this to not use NSFastEnumeration because that's not compiling in Swift
        let channelsCopy = Array(channels.collection.allValues) as! [ARTRealtimeChannelInternal]

        if shouldSendEvents {
            for channel in channelsCopy {
                let attachParams = ARTAttachRequestParams(reason: stateChange.reason)
                channel.proceedAttachDetach(withParams: attachParams)
            }
            sendQueuedMessages()
        } else if !isActive {
            if channelStateChangeParams == nil {
                if let reason = stateChange.reason {
                    channelStateChangeParams = ARTChannelStateChangeParams(state: .error, errorInfo: reason)
                } else {
                    channelStateChangeParams = ARTChannelStateChangeParams(state: .error)
                }
            }
            
            let channelStatus = ARTStatus(state: channelStateChangeParams!.state, errorInfo: channelStateChangeParams!.errorInfo)
            failQueuedMessages(channelStatus)
            
            // Channels
            for channel in channelsCopy {
                switch stateChange.current {
                case .closing:
                    // do nothing. Closed state is coming.
                    break
                case .closed:
                    let params = ARTChannelStateChangeParams(state: .ok)
                    channel.detachChannel(params)
                case .suspended:
                    channel.setSuspended(channelStateChangeParams!)
                case .failed:
                    channel.setFailed(channelStateChangeParams!)
                default:
                    break
                }
            }
        }
        
        connection.emit(stateChange.event, with: stateChange)
        
        performPendingAuthorizationWithState(stateChange.current, error: stateChange.reason)
        
        internalEventEmitter.emit(ARTEvent.newWithConnectionEvent(ARTRealtimeConnectionEvent(rawValue: Int(state.rawValue))!), with: stateChange)
        
        // stateChangeEventListener may be nil if we're in a failed state
        stateChangeEventListener?.startTimer()
    }
    
    // swift-migration: original location ARTRealtime.m, line 855
    private func createAndConnectTransportWithConnectionResume(_ resume: Bool) {
        var resumeKey: String?
        if resume {
            resumeKey = connection.key_nosync
            resuming = true
        }
        setTransportWithResumeKey(resumeKey)
        transportConnectForcingNewToken(_renewingToken, newConnection: true)
    }
    
    // swift-migration: original location ARTRealtime.m, line 865
    private func abortAndReleaseTransport(_ status: ARTStatus) {
        _transport?.abort(status)
        _transport = nil
    }
    
    // swift-migration: original location ARTRealtime.m, line 870
    private func closeAndReleaseTransport() {
        if let transport = _transport {
            transport.close()
            _transport = nil
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 877
    private func resetTransportWithResumeKey(_ resumeKey: String?) {
        closeAndReleaseTransport()
        setTransportWithResumeKey(resumeKey)
    }
    
    // swift-migration: original location ARTRealtime.m, line 882
    private func setTransportWithResumeKey(_ resumeKey: String?) {
        let factory = options.testOptions.transportFactory
        _transport = factory.transport(withRest: rest, options: options, resumeKey: resumeKey, logger: logger)
        _transport?.delegate = self
    }
    
    // swift-migration: original location ARTRealtime.m, line 888
    @discardableResult
    private func unlessStateChangesBefore(_ deadline: TimeInterval, do callback: @escaping () -> Void) -> ARTEventListener {
        let eventListener = internalEventEmitter.once { (change: ARTConnectionStateChange) in
            // Any state change cancels the timeout.
        }
        eventListener.setTimer(deadline) {
            callback()
        }
        return eventListener
    }
    
    // swift-migration: original location ARTRealtime.m, line 898
    private func onHeartbeat() {
        ARTLogVerbose(logger, "R:\(pointer: self) heartbeat received")
        if connection.state_nosync != .connected {
            let msg = "received a ping when in state \(ARTRealtimeConnectionStateToStr(connection.state_nosync))"
            ARTLogWarn(logger, "R:\(pointer: self) \(msg)")
        }
        _pingEventEmitter.emit(nil, with: nil)
    }
    
    // swift-migration: original location ARTRealtime.m, line 907
    private func onConnected(_ message: ARTProtocolMessage) {
        _renewingToken = false
        
        switch connection.state_nosync {
        case .connecting:
            if resuming {
                if message.connectionId == connection.id_nosync {
                    ARTLogDebug(logger, "RT:\(pointer: self) connection \"\(message.connectionId ?? "")\" has reconnected and resumed successfully")
                } else {
                    ARTLogWarn(logger, "RT:\(pointer: self) connection \"\(message.connectionId ?? "")\" has reconnected, but resume failed. Error: \"\(message.error?.message ?? "")\"")
                }
            }
            // If there's no previous connectionId, then don't reset the msgSerial
            //as it may have been set by recover data (unless the recover failed).
            let prevConnId = connection.id_nosync
            let connIdChanged = prevConnId != nil && message.connectionId != prevConnId
            let recoverFailure = prevConnId == nil && message.error != nil // RTN16d
            let resumed = !(connIdChanged || recoverFailure)
            if !resumed {
                ARTLogDebug(logger, "RT:\(pointer: self) msgSerial of connection \"\(connection.id_nosync ?? "")\" has been reset")
                msgSerial = 0
                pendingMessageStartSerial = 0
            }
            
            connection.setId(message.connectionId)
            connection.setKey(message.connectionKey)
            // swift-migration: Lawrence added the if
            if let maxMessageSize = message.connectionDetails?.maxMessageSize {
                connection.setMaxMessageSize(maxMessageSize)
            }

            if let connectionDetails = message.connectionDetails {
                // swift-migration: Lawrence added the zero check (it's unclear what the original Objective-C was going for — whether it was optional or zero check)
                if connectionDetails.connectionStateTtl != 0 {
                    self.connectionStateTtl = connectionDetails.connectionStateTtl
                }
                // swift-migration: Lawrence added the zero check (it's unclear what the original Objective-C was going for)
                if connectionDetails.maxIdleInterval != 0 {
                    self.maxIdleInterval = connectionDetails.maxIdleInterval
                    _lastActivity = Date()
                    setIdleTimer()
                }
            }
            let params = ARTConnectionStateChangeParams(errorInfo: message.error)
            params.resumed = resumed  // RTN19a
            performTransitionToState(.connected, withParams: params)
            
        case .connected:
            // Renewing token.
            updateWithErrorInfo(message.error)
        default:
            break
        }
        
        resuming = false
    }
    
    // swift-migration: original location ARTRealtime.m, line 961
    private func onDisconnected() {
        onDisconnected(nil)
    }
    
    // swift-migration: original location ARTRealtime.m, line 965
    private func onDisconnected(_ message: ARTProtocolMessage?) {
        ARTLogInfo(logger, "R:\(pointer: self) Realtime disconnected")
        let error = message?.error
        
        if isTokenError(error) && !_renewingToken { // If already reconnecting, give up.
            if !auth.tokenIsRenewable {
                let params = ARTConnectionStateChangeParams(errorInfo: error)
                performTransitionToState(.failed, withParams: params)
                return
            }
            
            let params = ARTConnectionStateChangeParams(errorInfo: error)
            performTransitionToDisconnectedOrSuspendedWithParams(params)
            connection.setErrorReason(nil)
            _renewingToken = true
            performTransitionToState(.connecting, withParams: ARTConnectionStateChangeParams())
            return
        }
        
        let params = ARTConnectionStateChangeParams(errorInfo: error)
        performTransitionToDisconnectedOrSuspendedWithParams(params)
    }
    
    // swift-migration: original location ARTRealtime.m, line 991
    private func onClosed() {
        ARTLogInfo(logger, "R:\(pointer: self) Realtime closed")
        switch connection.state_nosync {
        case .closed:
            break
        case .closing:
            connection.setId(nil)
            performTransitionToState(.closed, withParams: ARTConnectionStateChangeParams())
        default:
            assertionFailure("Invalid Realtime state transitioning to Closed: expected Closing or Closed, has \(ARTRealtimeConnectionStateToStr(connection.state_nosync))")
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1006
    private func onAuth() {
        ARTLogInfo(logger, "R:\(pointer: self) server has requested an authorize")
        switch connection.state_nosync {
        case .connecting, .connected:
            transportConnectForcingNewToken(true, newConnection: false)
        default:
            ARTLogError(logger, "Invalid Realtime state: expected Connecting or Connected, has \(ARTRealtimeConnectionStateToStr(connection.state_nosync))")
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1019
    private func onError(_ message: ARTProtocolMessage) {
        if message.channel != nil {
            onChannelMessage(message)
        } else {
            let error = message.error
            
            if isTokenError(error) && auth.tokenIsRenewable {
                if _renewingToken {
                    // Already retrying; give up.
                    connection.setErrorReason(error)
                    let params = ARTConnectionStateChangeParams(errorInfo: error)
                    performTransitionToDisconnectedOrSuspendedWithParams(params)
                    return
                }
                transportReconnectWithRenewedToken()
                return
            }
            
            connection.setId(nil)
            let params = ARTConnectionStateChangeParams(errorInfo: message.error)
            performTransitionToState(.failed, withParams: params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1043
    private func cancelTimers() {
        ARTLogVerbose(logger, "R:\(pointer: self) cancel timers")
        _connectionRetryFromSuspendedListener?.stopTimer()
        _connectionRetryFromSuspendedListener = nil
        _connectionRetryFromDisconnectedListener?.stopTimer()
        _connectionRetryFromDisconnectedListener = nil
        // Cancel connecting scheduled work
        _connectingTimeoutListener?.stopTimer()
        _connectingTimeoutListener = nil
        // Cancel auth scheduled work
        artDispatchCancel(_authenitcatingTimeoutWork)
        _authenitcatingTimeoutWork = nil
        _authTask?.cancel()
        _authTask = nil
        // Idle timer
        stopIdleTimer()
        // Ping timer
        _pingEventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtime.m, line 1063
    private func onConnectionTimeOut() {
        ARTLogVerbose(logger, "R:\(pointer: self) connection timed out")
        // Cancel connecting scheduled work
        _connectingTimeoutListener?.stopTimer()
        _connectingTimeoutListener = nil
        // Cancel auth scheduled work
        artDispatchCancel(_authenitcatingTimeoutWork)
        _authenitcatingTimeoutWork = nil
        _authTask?.cancel()
        _authTask = nil
        
        let error: ARTErrorInfo
        if auth.authorizing_nosync && (options.authUrl != nil || options.authCallback != nil) {
            error = ARTErrorInfo.create(withCode: ARTErrorCode.authConfiguredProviderFailure.rawValue, status: Int(ARTState.connectionFailed.rawValue), message: "timed out")
        } else {
            error = ARTErrorInfo.create(withCode: ARTErrorCode.connectionTimedOut.rawValue, status: Int(ARTState.connectionFailed.rawValue), message: "timed out")
        }
        switch connection.state_nosync {
        case .connected:
            let params = ARTConnectionStateChangeParams(errorInfo: error)
            performTransitionToState(.connected, withParams: params)
        default:
            let params = ARTConnectionStateChangeParams(errorInfo: error)
            performTransitionToDisconnectedOrSuspendedWithParams(params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1095
    private func isTokenError(_ error: ARTErrorInfo?) -> Bool {
        guard let error = error else { return false }
        return DefaultErrorChecker().isTokenError(error)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1099
    private func transportReconnectWithExistingParameters() {
        resetTransportWithResumeKey(_transport?.resumeKey)
        let host = getClientOptions().testOptions.reconnectionRealtimeHost // for tests purposes only, always `nil` in production
        if let host = host {
            transport?.setHost(host)
        }
        transportConnectForcingNewToken(false, newConnection: true)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1108
    private func transportReconnectWithHost(_ host: String) {
        resetTransportWithResumeKey(_transport?.resumeKey)
        transport?.setHost(host)
        transportConnectForcingNewToken(false, newConnection: true)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1114
    private func transportReconnectWithRenewedToken() {
        _renewingToken = true
        resetTransportWithResumeKey(_transport?.resumeKey)
        _connectingTimeoutListener?.restartTimer()
        transportConnectForcingNewToken(true, newConnection: true)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1121
    private func transportConnectForcingNewToken(_ forceNewToken: Bool, newConnection: Bool) {
        let options = getClientOptions().copy() as! ARTClientOptions
        if options.isBasicAuth() {
            // Basic
            // swift-migration: Lawrence added unwrap, isBasicAuth doesn't communicate that this is not nil
            transport?.connect(withKey: options.key!)
        } else {
            // Token
            ARTLogDebug(logger, "R:\(pointer: self) connecting with token auth; authorising (timeout of \(self.options.testOptions.realtimeRequestTimeout))")
            
            if !forceNewToken && auth.tokenRemainsValid {
                // Reuse token
                ARTLogDebug(logger, "R:\(pointer: self) reusing token for auth")
                // swift-migration: Lawrence added unwrap
                transport?.connect(withToken: unwrapValueWithAmbiguousObjectiveCNullability(auth.tokenDetails?.token))
            } else {
                // New Token
                auth.setTokenDetails(nil)
                
                // Schedule timeout handler
                _authenitcatingTimeoutWork = artDispatchScheduled(self.options.testOptions.realtimeRequestTimeout, rest.queue) {
                    self.onConnectionTimeOut()
                }
                
                let delegate = auth.delegate
                if newConnection {
                    // Deactivate use of `ARTAuthDelegate`: `authorize` should complete without waiting for a CONNECTED state.
                    auth.delegate = nil
                }

                _authTask = auth._authorize(nil, options: options) { tokenDetails, error in
                    // Cancel scheduled work
                    artDispatchCancel(self._authenitcatingTimeoutWork)
                    self._authenitcatingTimeoutWork = nil
                    self._authTask = nil
                    
                    // It's still valid?
                    switch self.connection.state_nosync {
                    case .closing, .closed:
                        return
                    default:
                        break
                    }
                    
                    ARTLogDebug(self.logger, "R:\(pointer: self) authorized: \(String(describing: tokenDetails)) error: \(String(describing: error))")
                    if let error = error {
                        self.handleTokenAuthError(error as NSError)
                        return
                    }
                    
                    if forceNewToken && newConnection {
                        self.resetTransportWithResumeKey(self._transport?.resumeKey)
                    }
                    if newConnection {
                        // swift-migration: Lawrence added unwrap, we've already checked that error is nil
                        self.transport?.connect(withToken: tokenDetails!.token)
                    }
                }
                
                auth.delegate = delegate
            }
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1187
    private func handleTokenAuthError(_ error: NSError) {
        ARTLogError(logger, "R:\(pointer: self) token auth failed with \(error.description)")
        if error.code == ARTErrorCode.incompatibleCredentials.rawValue {
            // RSA15c
            let errorInfo = ARTErrorInfo.createFromNSError(error)
            let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
            performTransitionToState(.failed, withParams: params)
        } else if options.authUrl != nil || options.authCallback != nil {
            if error.code == ARTErrorCode.forbidden.rawValue { /* RSA4d */
                let errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.authConfiguredProviderFailure.rawValue,
                                                   status: error.artStatusCode,
                                                   message: error.description)
                let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
                performTransitionToState(.failed, withParams: params)
            } else {
                let errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.authConfiguredProviderFailure.rawValue, status: Int(ARTState.connectionFailed.rawValue), message: error.description)
                switch connection.state_nosync {
                case .connected:
                    // RSA4c3
                    connection.setErrorReason(errorInfo)
                default:
                    // RSA4c
                    let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
                    performTransitionToDisconnectedOrSuspendedWithParams(params)
                }
            }
        } else {
            // RSA4b
            let errorInfo = ARTErrorInfo.createFromNSError(error)
            let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
            performTransitionToDisconnectedOrSuspendedWithParams(params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1226
    private func onAck(_ message: ARTProtocolMessage) {
        ack(message)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1230
    private func onNack(_ message: ARTProtocolMessage) {
        nack(message)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1234
    private func onChannelMessage(_ message: ARTProtocolMessage) {
        guard let channelName = message.channel else {
            return
        }
        let channel = channels._getChannel(channelName, options: nil, addPrefix: false)
        channel.onChannelMessage(message)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1242
    private func onSuspended() {
        performTransitionToState(.suspended, withParams: ARTConnectionStateChangeParams())
    }
    
    // swift-migration: original location ARTRealtime.m, line 1246
    private func suspensionTime() -> Date {
        return _connectionLostAt?.addingTimeInterval(connectionStateTtl) ?? Date()
    }
    
    // swift-migration: original location ARTRealtime.m, line 1250
    private func isSuspendMode() -> Bool {
        let currentTime = Date()
        return currentTime.timeIntervalSince(suspensionTime()) > 0
    }
    
    // swift-migration: original location ARTRealtime.m, line 1280
    private func sendImpl(_ pm: ARTProtocolMessage, reuseMsgSerial: Bool, sentCallback: ARTCallback?, ackCallback: ARTStatusCallback?) {
        if pm.ackRequired {
            if !reuseMsgSerial { // RTN19a2
                pm.msgSerial = NSNumber(value: msgSerial)
            }
        }
        
        for msg in pm.messages ?? [] {
            // swift-migration: Lawrence added unwrap to get compiling
            msg.connectionId = unwrapValueWithAmbiguousObjectiveCNullability(connection.id_nosync)
        }
        
        do {
            let data = try rest.defaultEncoder.encodeProtocolMessage(pm)
            
            if pm.ackRequired {
                if !reuseMsgSerial {
                    msgSerial += 1
                }
                let pendingMessage = ARTPendingMessage(protocolMessage: pm, ackCallback: ackCallback)
                pendingMessages.append(pendingMessage)
            }
            
            ARTLogDebug(logger, "RT:\(pointer: self) sending action \(pm.action.rawValue) - \(ARTProtocolMessageActionToStr(pm.action))")
            if let data = data {
                if transport?.send(data, withSource: pm) == true {
                    sentCallback?(nil)
                    // `ackCallback()` is called with ACK/NACK action
                }
            }
        } catch {
            let e = ARTErrorInfo.createFromNSError(error as NSError)
            sentCallback?(e)
            ackCallback?(ARTStatus(state: .error, errorInfo: e))
            return
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1322
    internal func send(_ msg: ARTProtocolMessage, reuseMsgSerial: Bool, sentCallback: ARTCallback?, ackCallback: ARTStatusCallback?) {
        if shouldSendEvents {
            sendImpl(msg, reuseMsgSerial: reuseMsgSerial, sentCallback: sentCallback, ackCallback: ackCallback)
        }
        // see RTL6c2, RTN19, RTN7 and TO3g
        else if msg.ackRequired {
            if isActive && options.queueMessages {
                let lastQueuedMessage = queuedMessages.last //RTL6d5
                let maxSize = connection.maxMessageSize
                let merged = lastQueuedMessage?.merge(from: msg, maxSize: maxSize, sentCallback: nil, ackCallback: ackCallback) ?? false
                if !merged {
                    let qm = ARTQueuedMessage(protocolMessage: msg, sentCallback: sentCallback, ackCallback: ackCallback)
                    queuedMessages.append(qm)
                    ARTLogDebug(logger, "RT:\(pointer: self) (channel: \(msg.channel ?? "")) protocol message with action '\(msg.action.rawValue) - \(ARTProtocolMessageActionToStr(msg.action))' has been queued (\(msg.messages ?? []))")
                } else {
                    ARTLogVerbose(logger, "RT:\(pointer: self) (channel: \(msg.channel ?? "")) message \(msg) has been bundled to \(lastQueuedMessage?.msg ?? ARTProtocolMessage())")
                }
            }
            // RTL6c4
            else {
                let error = connection.error_nosync
                ARTLogDebug(logger, "RT:\(pointer: self) (channel: \(msg.channel ?? "")) protocol message with action '\(msg.action.rawValue) - \(ARTProtocolMessageActionToStr(msg.action))' can't be sent or queued: \(String(describing: error))")
                sentCallback?(error)
                ackCallback?(ARTStatus(state: .error, errorInfo: error))
            }
        } else {
            ARTLogDebug(logger, "RT:\(pointer: self) (channel: \(msg.channel ?? "")) sending protocol message with action '\(msg.action.rawValue) - \(ARTProtocolMessageActionToStr(msg.action))' was ignored: \(String(describing: connection.error_nosync))")
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1358
    internal func send(_ msg: ARTProtocolMessage, sentCallback: ARTCallback?, ackCallback: ARTStatusCallback?) {
        send(msg, reuseMsgSerial: false, sentCallback: sentCallback, ackCallback: ackCallback)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1362
    private func resendPendingMessagesWithResumed(_ resumed: Bool) {
        let pendingMessagesCopy = pendingMessages
        if !pendingMessagesCopy.isEmpty {
            ARTLogDebug(logger, "RT:\(pointer: self) resending messages waiting for acknowledgment")
        }
        pendingMessages = []
        for pendingMessage in pendingMessagesCopy {
            let pm = pendingMessage.msg
            send(pm, reuseMsgSerial: resumed, sentCallback: nil) { status in
                pendingMessage.ackCallback()(status)
            }
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1376
    private func failPendingMessages(_ status: ARTStatus) {
        let pms = pendingMessages
        pendingMessages = []
        for pendingMessage in pms {
            pendingMessage.ackCallback()(status)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1384
    private func sendQueuedMessages() {
        let qms = queuedMessages
        queuedMessages = []
        
        for message in qms {
            sendImpl(message.msg, reuseMsgSerial: false, sentCallback: message.sentCallback(), ackCallback: message.ackCallback())
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1393
    private func failQueuedMessages(_ status: ARTStatus) {
        let qms = queuedMessages
        queuedMessages = []
        for message in qms {
            message.sentCallback()(status.errorInfo)
            message.ackCallback()(status)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1402
    private func ack(_ message: ARTProtocolMessage) {
        let serial = message.msgSerial?.int64Value ?? 0
        let count = Int(message.count)
        var nackMessages: [ARTPendingMessage] = []
        var ackMessages: [ARTPendingMessage] = []
        ARTLogVerbose(logger, "R:\(pointer: self) ACK: msgSerial=\(serial), count=\(count)")
        ARTLogVerbose(logger, "R:\(pointer: self) ACK (before processing): pendingMessageStartSerial=\(pendingMessageStartSerial), pendingMessages=\(pendingMessages.count)")
        
        var serialToProcess = serial
        var countToProcess = count
        
        if serial < pendingMessageStartSerial {
            // This is an error condition and shouldn't happen but
            // we can handle it gracefully by only processing the
            // relevant portion of the response
            countToProcess -= Int(pendingMessageStartSerial - serial)
            serialToProcess = pendingMessageStartSerial
        }
        
        if serialToProcess > pendingMessageStartSerial {
            // This counts as a nack of the messages earlier than serial,
            // as well as an ack
            let nCount = Int(serialToProcess - pendingMessageStartSerial)
            let nackCount = min(nCount, pendingMessages.count)
            if nCount > pendingMessages.count {
                ARTLogError(logger, "R:\(pointer: self) ACK: receiving a serial greater than expected")
            }
            nackMessages = Array(pendingMessages.prefix(nackCount))
            pendingMessages.removeFirst(nackCount)
            pendingMessageStartSerial = serialToProcess
        }
        
        if serialToProcess == pendingMessageStartSerial {
            let ackCount = min(countToProcess, pendingMessages.count)
            if countToProcess > pendingMessages.count {
                ARTLogError(logger, "R:\(pointer: self) ACK: count response is greater than the total of pending messages")
            }
            ackMessages = Array(pendingMessages.prefix(ackCount))
            pendingMessages.removeFirst(ackCount)
            pendingMessageStartSerial += Int64(ackCount)
        }
        
        for msg in nackMessages {
            msg.ackCallback()(ARTStatus(state: .error, errorInfo: message.error))
        }
        
        for msg in ackMessages {
            msg.ackCallback()(ARTStatus(state: .ok, errorInfo: nil))
        }
        
        ARTLogVerbose(logger, "R:\(pointer: self) ACK (after processing): pendingMessageStartSerial=\(pendingMessageStartSerial), pendingMessages=\(pendingMessages.count)")
    }
    
    // swift-migration: original location ARTRealtime.m, line 1463
    private func nack(_ message: ARTProtocolMessage) {
        let serial = message.msgSerial?.int64Value ?? 0
        var count = Int(message.count)
        ARTLogVerbose(logger, "R:\(pointer: self) NACK: msgSerial=\(serial), count=\(count)")
        ARTLogVerbose(logger, "R:\(pointer: self) NACK (before processing): pendingMessageStartSerial=\(pendingMessageStartSerial), pendingMessages=\(pendingMessages.count)")
        
        if serial != pendingMessageStartSerial {
            // This is an error condition and it shouldn't happen but
            // we can handle it gracefully by only processing the
            // relevant portion of the response
            count -= Int(pendingMessageStartSerial - serial)
        }
        
        let nackCount = min(count, pendingMessages.count)
        if count > pendingMessages.count {
            ARTLogError(logger, "R:\(pointer: self) NACK: count response is greater than the total of pending messages")
        }
        
        let nackMessages = Array(pendingMessages.prefix(nackCount))
        pendingMessages.removeFirst(nackCount)
        pendingMessageStartSerial += Int64(nackCount)
        
        for msg in nackMessages {
            msg.ackCallback()(ARTStatus(state: .error, errorInfo: message.error))
        }
        
        ARTLogVerbose(logger, "R:\(pointer: self) NACK (after processing): pendingMessageStartSerial=\(pendingMessageStartSerial), pendingMessages=\(pendingMessages.count)")
    }
    
    // swift-migration: original location ARTRealtime.m, line 1497
    private func reconnectWithFallback() -> Bool {
        guard let host = _fallbacks?.popFallbackHost() else {
            ARTLogDebug(logger, "R:\(pointer: self) No fallback hosts left, trying primary one again...")
            _fallbacks = nil
            return false
        }
        
        ARTLogDebug(logger, "R:\(pointer: self) checking internet connection and then retrying realtime at \(host)")
        rest.internetIsUp { isUp in
            if !isUp { // RTN17c
                let errorInfo = ARTErrorInfo.create(withCode: 0, message: "no Internet connection")
                let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
                self.performTransitionToState(.disconnected, withParams: params)
                return
            }
            
            ARTLogDebug(self.logger, "R:\(pointer: self) internet OK; retrying realtime connection at \(host)")
            self.rest.prioritizedHost = host
            self.transportReconnectWithHost(host)
        }
        return true
    }
    
    // swift-migration: original location ARTRealtime.m, line 1521
    private func shouldRetryWithFallbackForError(_ error: ARTRealtimeTransportError, options: ARTClientOptions) -> Bool {
        if (error.type == .badResponse && error.badResponseCode >= 500 && error.badResponseCode <= 504) ||
           error.type == .hostUnreachable || error.type == .timeout {
            // RTN17b3
            if options.fallbackHostsUseDefault {
                return true
            }
            
            // RTN17b1
            if !(options.hasCustomRealtimeHost || options.hasCustomPort || options.hasCustomTlsPort) {
                return true
            }
            
            // RTN17b2
            if options.fallbackHosts != nil {
                return true
            }
            
            // RSC15g2
            if options.hasEnvironmentDifferentThanProduction {
                return true
            }
        }
        return false
    }
    
    // swift-migration: original location ARTRealtime.m, line 1550
    private func onActivity() {
        ARTLogVerbose(logger, "R:\(pointer: self) activity")
        _lastActivity = Date()
        setIdleTimer()
    }
    
    // swift-migration: original location ARTRealtime.m, line 1556
    private func setIdleTimer() {
        if maxIdleInterval <= 0 {
            ARTLogVerbose(logger, "R:\(pointer: self) set idle timer had been ignored")
            return
        }
        artDispatchCancel(_idleTimer)
        
        _idleTimer = artDispatchScheduled(options.testOptions.realtimeRequestTimeout + maxIdleInterval, rest.queue) {
            ARTLogError(self.logger, "R:\(pointer: self) No activity seen from realtime in \(Date().timeIntervalSince(self._lastActivity)) seconds; assuming connection has dropped")
            
            let idleTimerExpired = ARTErrorInfo.create(withCode: ARTErrorCode.disconnected.rawValue, status: 408, message: "Idle timer expired")
            let params = ARTConnectionStateChangeParams(errorInfo: idleTimerExpired)
            self.performTransitionToDisconnectedOrSuspendedWithParams(params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1572
    private func stopIdleTimer() {
        artDispatchCancel(_idleTimer)
        _idleTimer = nil
    }
    
    // swift-migration: original location ARTRealtime.m, line 1577
    internal func setReachabilityClass(_ reachabilityClass: ARTReachability.Type?) {
        _reachabilityClass = reachabilityClass
    }
    
    // MARK: - ARTRealtimeTransportDelegate implementation
    
    // swift-migration: original location ARTRealtime.m, line 1583
    public func realtimeTransport(_ transport: ARTRealtimeTransport, didReceiveMessage message: ARTProtocolMessage) {
        onActivity()
        
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        if connection.state_nosync == .disconnected {
            // Already disconnected
            return
        }
        
        ARTLogVerbose(logger, "R:\(pointer: self) did receive Protocol Message \(ARTProtocolMessageActionToStr(message.action)) (connection state is \(ARTRealtimeConnectionStateToStr(connection.state_nosync)))")
        
        if let error = message.error {
            ARTLogVerbose(logger, "R:\(pointer: self) Protocol Message with error \(error)")
        }
        
        assert(transport === self.transport, "Unexpected transport")
        
        switch message.action {
        case .heartbeat:
            onHeartbeat()
        case .error:
            onError(message)
        case .connected:
            // Set Auth#clientId
            if let connectionDetails = message.connectionDetails {
                auth.setProtocolClientId(connectionDetails.clientId)
            }
            // Event
            onConnected(message)
        case .disconnect, .disconnected:
            onDisconnected(message)
        case .ack:
            onAck(message)
        case .nack:
            onNack(message)
        case .closed:
            onClosed()
        case .auth:
            onAuth()
        default:
            onChannelMessage(message)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1646
    public func realtimeTransportAvailable(_ transport: ARTRealtimeTransport) {
        // Do nothing
    }
    
    // swift-migration: original location ARTRealtime.m, line 1650
    public func realtimeTransportClosed(_ transport: ARTRealtimeTransport) {
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        if connection.state_nosync == .closing {
            // Close succeeded. Nothing more to do.
            performTransitionToState(.closed, withParams: ARTConnectionStateChangeParams())
        } else if connection.state_nosync != .closed && connection.state_nosync != .failed {
            // Unexpected closure; recover.
            performTransitionToDisconnectedOrSuspendedWithParams(ARTConnectionStateChangeParams())
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1665
    public func realtimeTransportDisconnected(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?) {
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        if connection.state_nosync == .closing {
            performTransitionToState(.closed, withParams: ARTConnectionStateChangeParams())
        } else {
            let errorInfo = error != nil ? ARTErrorInfo.createFromNSError(error!.error) : nil
            let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
            performTransitionToDisconnectedOrSuspendedWithParams(params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1680
    public func realtimeTransportFailed(_ transport: ARTRealtimeTransport, withError transportError: ARTRealtimeTransportError) {
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        ARTLogDebug(logger, "R:\(pointer: self) realtime transport failed: \(transportError)")
        
        let errorInfo = ARTErrorInfo.createFromNSError(transportError.error)
        let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
        
        let clientOptions = getClientOptions()
        
        if !isSuspendMode() && shouldRetryWithFallbackForError(transportError, options: clientOptions) {
            ARTLogDebug(logger, "R:\(pointer: self) host is down; can retry with fallback host")
            if _fallbacks == nil {
                let hosts = ARTFallbackHosts.hosts(fromOptions: clientOptions)
                _fallbacks = ARTFallback(fallbackHosts: hosts, shuffleArray: clientOptions.testOptions.shuffleArray)
            }
            if let fallbacks = _fallbacks {
                if fallbacks.isEmpty() {
                    _fallbacks = nil
                    ARTLogVerbose(logger, "R:\(pointer: self) No fallback hosts left, will try primary one again...")
                }
                performTransitionToDisconnectedOrSuspendedWithParams(params) // RTN14d, RTN17j
            } else {
                performTransitionToState(.failed, withParams: params)
            }
        } else {
            performTransitionToDisconnectedOrSuspendedWithParams(params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1713
    public func realtimeTransportNeverConnected(_ transport: ARTRealtimeTransport) {
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        let errorInfo = ARTErrorInfo.create(withCode: ARTClientCodeError.transport.rawValue, message: "Transport never connected")
        let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
        performTransitionToDisconnectedOrSuspendedWithParams(params)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1724
    public func realtimeTransportRefused(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?) {
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        if let error = error, error.type == .refused {
            let errorInfo = ARTErrorInfo.create(withCode: ARTClientCodeError.transport.rawValue, message: "Connection refused using \(error.url)")
            let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
            performTransitionToDisconnectedOrSuspendedWithParams(params)
        } else if let error = error {
            let errorInfo = ARTErrorInfo.createFromNSError(error.error)
            let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
            performTransitionToDisconnectedOrSuspendedWithParams(params)
        } else {
            let params = ARTConnectionStateChangeParams()
            performTransitionToDisconnectedOrSuspendedWithParams(params)
        }
    }
    
    // swift-migration: original location ARTRealtime.m, line 1746
    public func realtimeTransportTooBig(_ transport: ARTRealtimeTransport) {
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        let errorInfo = ARTErrorInfo.create(withCode: ARTClientCodeError.transport.rawValue, message: "Transport too big")
        let params = ARTConnectionStateChangeParams(errorInfo: errorInfo)
        performTransitionToDisconnectedOrSuspendedWithParams(params)
    }
    
    // swift-migration: original location ARTRealtime.m, line 1757
    public func realtimeTransportSetMsgSerial(_ transport: ARTRealtimeTransport, msgSerial: Int64) {
        guard transport === self.transport else {
            // Old connection
            return
        }
        
        self.msgSerial = msgSerial
    }
}
