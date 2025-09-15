import Foundation
import Dispatch

// swift-migration: original location ARTClientOptions.h, line 14
/// A key for the `ARTClientOptions.plugins` property.
public typealias ARTPluginName = String

// swift-migration: original location ARTClientOptions.m, line 15
/// Set this key in `ARTClientOptions.plugins` to `AblyLiveObjects.Plugin.self` after importing `AblyLiveObjects` from the  [ably/ably-liveobjects-swift-plugin](https://github.com/ably/ably-liveobjects-swift-plugin) repository in order to enable LiveObjects functionality.
public let ARTPluginNameLiveObjects: ARTPluginName = "LiveObjects"

// swift-migration: original location ARTClientOptions.m, line 17
public var ARTDefaultEnvironment: String? = nil

// swift-migration: original location ARTClientOptions.h, line 20
/// Passes additional client-specific properties to the REST `-[ARTRestProtocol initWithOptions:]` or the Realtime `-[ARTRealtimeProtocol initWithOptions:]`.
public class ARTClientOptions: ARTAuthOptions {
    
    // swift-migration: original location ARTClientOptions.m, line 21
    private var pluginData: [String: Any] = [:]
    
    // swift-migration: original location ARTClientOptions.h, line 25
    /// Enables a non-default Ably host to be specified. For development environments only. The default value is `rest.ably.io`.
    public var restHost: String? {
        get {
            // swift-migration: original location ARTClientOptions.m, line 71
            if let restHost = _restHost {
                return restHost
            }
            if environment == ARTDefaultProduction {
                return ARTDefault.restHost()
            }
            return hasEnvironment ? host(ARTDefault.restHost(), forEnvironment: environment!) : ARTDefault.restHost()
        }
        set { _restHost = newValue }
    }
    private var _restHost: String?

    // swift-migration: original location ARTClientOptions.h, line 30
    /// Enables a non-default Ably host to be specified for realtime connections. For development environments only. The default value is `realtime.ably.io`.
    public var realtimeHost: String? {
        get {
            // swift-migration: original location ARTClientOptions.m, line 81
            if let realtimeHost = _realtimeHost {
                return realtimeHost
            }
            if environment == ARTDefaultProduction {
                return ARTDefault.realtimeHost()
            }
            
            return hasEnvironment ? host(ARTDefault.realtimeHost(), forEnvironment: environment!) : ARTDefault.realtimeHost()
        }
        set { _realtimeHost = newValue }
    }
    private var _realtimeHost: String?

    // swift-migration: original location ARTClientOptions.h, line 35
    /// Enables a non-default Ably port to be specified. For development environments only. The default value is 80.
    public var port: Int = 0

    // swift-migration: original location ARTClientOptions.h, line 40
    /// Enables a non-default Ably TLS port to be specified. For development environments only. The default value is 443.
    public var tlsPort: Int = 0

    // swift-migration: original location ARTClientOptions.h, line 45
    /// Enables a [custom environment](https://ably.com/docs/platform-customization) to be used with the Ably service.
    public var environment: String?

    // swift-migration: original location ARTClientOptions.h, line 50
    /// When `false`, the client will use an insecure connection. The default is `true`, meaning a TLS connection will be used to connect to Ably.
    public var tls: Bool = true

    // swift-migration: original location ARTClientOptions.h, line 55
    /// Controls the log output of the library. This is an object to handle each line of log output.
    public var logHandler: ARTLog = ARTLog()

    // swift-migration: original location ARTClientOptions.h, line 60
    /// Controls the verbosity of the logs output from the library. Levels include `ARTLogLevelVerbose`, `ARTLogLevelDebug`, `ARTLogLevelInfo`, `ARTLogLevelWarn` and `ARTLogLevelError`.
    public var logLevel: ARTLogLevel = .none

    // swift-migration: original location ARTClientOptions.h, line 65
    /// If `false`, this disables the default behavior whereby the library queues messages on a connection in the disconnected or connecting states. The default behavior enables applications to submit messages immediately upon instantiating the library without having to wait for the connection to be established. Applications may use this option to disable queueing if they wish to have application-level control over the queueing. The default is `true`.
    public var queueMessages: Bool = true

    // swift-migration: original location ARTClientOptions.h, line 70
    /// If `false`, prevents messages originating from this connection being echoed back on the same connection. The default is `true`.
    public var echoMessages: Bool = true

    // swift-migration: original location ARTClientOptions.h, line 75
    /// When `true`, the more efficient MsgPack binary encoding is used. When `false`, JSON text encoding is used. The default is `true`.
    public var useBinaryProtocol: Bool = true

    // swift-migration: original location ARTClientOptions.h, line 80
    /// When `true`, the client connects to Ably as soon as it is instantiated. You can set this to `false` and explicitly connect to Ably using the `-[ARTConnectionProtocol connect]` method. The default is `true`.
    public var autoConnect: Bool = true

    // swift-migration: original location ARTClientOptions.h, line 85
    /// Enables a connection to inherit the state of a previous connection that may have existed under a different instance of the Realtime library. This might happen upon the app restart where a recovery key string can be explicitly provided to the `-[ARTRealtimeProtocol initWithOptions:]` initializer. See [connection state recovery](https://ably.com/docs/realtime/connection/#connection-state-recovery) for further information.
    public var recover: String?

    // swift-migration: original location ARTClientOptions.h, line 88
    /// :nodoc:
    public var pushFullWait: Bool = false

    // swift-migration: original location ARTClientOptions.h, line 93
    /// A client ID, used for identifying this client when publishing messages or for presence purposes. The `clientId` can be any non-empty string, except it cannot contain a `*`. This option is primarily intended to be used in situations where the library is instantiated with a key. Note that a `clientId` may also be implicit in a token used to instantiate the library. An error will be raised if a `clientId` specified here conflicts with the `clientId` implicit in the token.
    public var clientId: String?

    // swift-migration: original location ARTClientOptions.h, line 98
    /// When a `ARTTokenParams` object is provided, it overrides the client library defaults when issuing new Ably Tokens or Ably `ARTTokenRequest`s.
    public var defaultTokenParams: ARTTokenParams? {
        get { _defaultTokenParams }
        set {
            if let value = newValue {
                _defaultTokenParams = ARTTokenParams(tokenParams: value)
            } else {
                _defaultTokenParams = nil
            }
        }
    }
    private var _defaultTokenParams: ARTTokenParams?

    // swift-migration: original location ARTClientOptions.h, line 103
    /// If the connection is still in the `ARTRealtimeConnectionState.ARTRealtimeDisconnected` state after this delay, the client library will attempt to reconnect automatically. The default is 15 seconds.
    public var disconnectedRetryTimeout: TimeInterval = 15.0

    // swift-migration: original location ARTClientOptions.h, line 108
    /// When the connection enters the `ARTRealtimeConnectionState.ARTRealtimeSuspended` state, after this delay, if the state is still `ARTRealtimeConnectionState.ARTRealtimeSuspended`, the client library attempts to reconnect automatically. The default is 30 seconds.
    public var suspendedRetryTimeout: TimeInterval = 30.0

    // swift-migration: original location ARTClientOptions.h, line 113
    /// When a channel becomes `ARTRealtimeChannelState.ARTRealtimeChannelSuspended` following a server initiated `ARTRealtimeChannelState.ARTRealtimeChannelDetached`, after this delay, if the channel is still `ARTRealtimeChannelState.ARTRealtimeChannelSuspended` and the connection is `ARTRealtimeConnectionState.ARTRealtimeConnected`, the client library will attempt to re-attach the channel automatically. The default is 15 seconds.
    public var channelRetryTimeout: TimeInterval = 15.0

    // swift-migration: original location ARTClientOptions.h, line 118
    /// Timeout for opening a connection to Ably to initiate an HTTP request. The default is 4 seconds.
    public var httpOpenTimeout: TimeInterval = 4.0

    // swift-migration: original location ARTClientOptions.h, line 123
    /// Timeout for a client performing a complete HTTP request to Ably, including the connection phase. The default is 10 seconds.
    public var httpRequestTimeout: TimeInterval = 10.0

    // swift-migration: original location ARTClientOptions.h, line 128
    /// The maximum time before HTTP requests are retried against the default endpoint. The default is 600 seconds.
    public var fallbackRetryTimeout: TimeInterval = 600.0

    // swift-migration: original location ARTClientOptions.h, line 133
    /// The maximum number of fallback hosts to use as a fallback when an HTTP request to the primary host is unreachable or indicates that it is unserviceable. The default value is 3.
    public var httpMaxRetryCount: UInt = 3

    // swift-migration: original location ARTClientOptions.h, line 138
    /// The maximum elapsed time in which fallback host retries for HTTP requests will be attempted. The default is 15 seconds.
    public var httpMaxRetryDuration: TimeInterval = 15.0

    // swift-migration: original location ARTClientOptions.h, line 143
    /// An array of fallback hosts to be used in the case of an error necessitating the use of an alternative host. If you have been provided a set of custom fallback hosts by Ably, please specify them here.
    public var fallbackHosts: [String]? {
        get { _fallbackHosts }
        set {
            if _fallbackHostsUseDefault {
                fatalError("Could not setup custom fallback hosts because it is currently configured to use default fallback hosts.")
            }
            _fallbackHosts = newValue
        }
    }
    private var _fallbackHosts: [String]?

    // swift-migration: original location ARTClientOptions.h, line 148
    /// DEPRECATED: this property is deprecated and will be removed in a future version. Enables default fallback hosts to be used.
    @available(*, deprecated, message: "Future library releases will ignore any supplied value.")
    public var fallbackHostsUseDefault: Bool {
        get { _fallbackHostsUseDefault }
        set {
            if _fallbackHosts != nil {
                fatalError("Could not configure options to use default fallback hosts because a custom fallback host list is being used.")
            }
            _fallbackHostsUseDefault = newValue
        }
    }
    private var _fallbackHostsUseDefault: Bool = false

    // swift-migration: original location ARTClientOptions.h, line 161
    /// The queue to which all calls to user-provided callbacks will be dispatched asynchronously. It will be used as target queue for an internal, serial queue. It defaults to the main queue.
    public var dispatchQueue: DispatchQueue = DispatchQueue.main

    // swift-migration: original location ARTClientOptions.h, line 169
    /// The queue to which all internal concurrent operations will be dispatched. It must be a serial queue. It shouldn't be the same queue as dispatchQueue. It defaults to a newly created serial queue.
    public var internalDispatchQueue: DispatchQueue = DispatchQueue(label: "io.ably.main", qos: .default)

    // swift-migration: original location ARTClientOptions.h, line 174
    /// When `true`, enables idempotent publishing by assigning a unique message ID client-side, allowing the Ably servers to discard automatic publish retries following a failure such as a network fault. The default is `true`.
    public var idempotentRestPublishing: Bool = true

    // swift-migration: original location ARTClientOptions.h, line 179
    /// When `true`, every REST request to Ably should include a random string in the `request_id` query string parameter. The random string should be a url-safe base64-encoding sequence of at least 9 bytes, obtained from a source of randomness. This request ID must remain the same if a request is retried to a fallback host. Any log messages associated with the request should include the request ID. If the request fails, the request ID must be included in the `ARTErrorInfo` returned to the user. The default is `false`.
    public var addRequestIds: Bool = false

    // swift-migration: original location ARTClientOptions.h, line 184
    /// A set of key-value pairs that can be used to pass in arbitrary connection parameters, such as [`heartbeatInterval`](https://ably.com/docs/realtime/connection#heartbeats) or [`remainPresentFor`](https://ably.com/docs/realtime/presence#unstable-connections).
    public var transportParams: [String: ARTStringifiable]?

    // swift-migration: original location ARTClientOptions.h, line 189
    /// The object that processes Push activation/deactivation-related actions.
    public weak var pushRegistererDelegate: (ARTPushRegistererDelegate & NSObjectProtocol)?

    // swift-migration: original location ARTClientOptions.h, line 203
    /// A set of additional entries for the Ably agent header. Each entry can be a key string or set of key-value pairs. This should only be used by Ably-authored SDKs. If an agent does not have a version, represent this by using the `ARTClientInformationAgentNotVersioned` pointer as the version.
    public var agents: [String: String]?

    // swift-migration: original location ARTClientOptions.h, line 210
    /// A set of plugins that provide additional functionality to the client. Currently supported keys: - `ARTPluginNameLiveObjects`: Allows you to use LiveObjects functionality. Import the `AblyLiveObjects` module from the [ably/ably-liveobjects-swift-plugin](https://github.com/ably/ably-liveobjects-swift-plugin) repository and set the value for this key to `AblyLiveObjects.Plugin.self`. Use a channel's `objects` property to access its LiveObjects functionality.
    public var plugins: [ARTPluginName: Any]?

    // swift-migration: original location ARTClientOptions+TestConfiguration.h, line 18
    /// Defaults to a new instance of `ARTTestClientOptions` (whose properties all have their default values).
    public var testOptions: ARTTestClientOptions = ARTTestClientOptions()

    // swift-migration: original location ARTClientOptions.m, line 29
    @discardableResult
    internal override func initDefaults() -> ARTClientOptions {
        _ = super.initDefaults()
        
        // The LiveObjects repository provides an extension to `ARTClientOptions` so we need to ensure that we register the pluginAPI before that extension is used.
        ARTPluginAPI.registerSelf()
        
        port = ARTDefault.port()
        tlsPort = ARTDefault.tlsPort()
        environment = ARTDefaultEnvironment
        queueMessages = true
        echoMessages = true
        useBinaryProtocol = true
        autoConnect = true
        tls = true
        logLevel = .none
        logHandler = ARTLog()
        disconnectedRetryTimeout = 15.0
        suspendedRetryTimeout = 30.0
        channelRetryTimeout = 15.0
        httpOpenTimeout = 4.0
        httpRequestTimeout = 10.0
        fallbackRetryTimeout = 600.0
        httpMaxRetryDuration = 15.0
        httpMaxRetryCount = 3
        _fallbackHosts = nil
        _fallbackHostsUseDefault = false
        dispatchQueue = DispatchQueue.main
        internalDispatchQueue = DispatchQueue(label: "io.ably.main", qos: .default)
        pushFullWait = false
        idempotentRestPublishing = ARTClientOptions.getDefaultIdempotentRestPublishing(forVersion: ARTDefault.apiVersion())
        addRequestIds = false
        pushRegistererDelegate = nil
        testOptions = ARTTestClientOptions()
        pluginData = [:]
        return self
    }

    // swift-migration: original location ARTAuthOptions.m, line 29 (inherited)
    public required init() {
        super.init()
        _ = initDefaults()
    }

    // swift-migration: added by Lawrence because initializers not inherited
    public override init(key: String?) {
        super.init(key: key)
        _ = initDefaults()
    }

    // swift-migration: added by Lawrence because initializers not inherited
    public override init(token: String?) {
        super.init(token: token)
        _ = initDefaults()
    }

    // swift-migration: original location ARTClientOptions.m, line 67
    public override var description: String {
        return "\(super.description)\n\t clientId: \(clientId ?? "nil");"
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 20 and ARTClientOptions.m, line 92
    internal func restUrlComponents() -> URLComponents {
        var components = URLComponents()
        components.scheme = tls ? "https" : "http"
        components.host = restHost
        components.port = tls ? tlsPort : port
        return components
    }

    // swift-migration: original location ARTClientOptions.h, line 195 and ARTClientOptions.m, line 100
    /// :nodoc:
    public func restUrl() -> URL {
        // swift-migration: Lawrence added force-unwrap to satisfy tests
        return restUrlComponents().url!
    }

    // swift-migration: original location ARTClientOptions.h, line 198 and ARTClientOptions.m, line 104
    /// :nodoc:
    public func realtimeUrl() -> URL? {
        // swift-migration: Lawrence added force-unwrap to satisfy tests
        var components = URLComponents()
        components.scheme = tls ? "wss" : "ws"
        components.host = realtimeHost
        components.port = tls ? tlsPort : port
        return components.url!
    }

    // swift-migration: original location ARTClientOptions.m, line 112
    public override func copy(with zone: NSZone?) -> Any {
        let options = (super.copy(with: zone) as! ARTClientOptions)

        options.clientId = self.clientId
        options.port = self.port
        options.tlsPort = self.tlsPort
        if self._restHost != nil { options.restHost = self.restHost }
        if self._realtimeHost != nil { options.realtimeHost = self.realtimeHost }
        options.queueMessages = self.queueMessages
        options.echoMessages = self.echoMessages
        options.recover = self.recover
        options.useBinaryProtocol = self.useBinaryProtocol
        options.autoConnect = self.autoConnect
        options.environment = self.environment
        options.tls = self.tls
        options.logLevel = self.logLevel
        options.logHandler = self.logHandler
        options.suspendedRetryTimeout = self.suspendedRetryTimeout
        options.disconnectedRetryTimeout = self.disconnectedRetryTimeout
        options.channelRetryTimeout = self.channelRetryTimeout
        options.httpMaxRetryCount = self.httpMaxRetryCount
        options.httpMaxRetryDuration = self.httpMaxRetryDuration
        options.httpOpenTimeout = self.httpOpenTimeout
        options.fallbackRetryTimeout = self.fallbackRetryTimeout
        options._fallbackHosts = self.fallbackHosts
        options._fallbackHostsUseDefault = self.fallbackHostsUseDefault
        options.httpRequestTimeout = self.httpRequestTimeout
        options.dispatchQueue = self.dispatchQueue
        options.internalDispatchQueue = self.internalDispatchQueue
        options.pushFullWait = self.pushFullWait
        options.idempotentRestPublishing = self.idempotentRestPublishing
        options.addRequestIds = self.addRequestIds
        options.pushRegistererDelegate = self.pushRegistererDelegate
        options.transportParams = self.transportParams
        options.agents = self.agents
        options.testOptions = self.testOptions
        options.plugins = self.plugins
        options.pluginData = self.pluginData

        return options
    }

    // swift-migration: original location ARTClientOptions.h, line 192 and ARTClientOptions.m, line 160
    /// :nodoc:
    public func isBasicAuth() -> Bool {
        return useTokenAuth == false &&
            key != nil &&
            token == nil &&
            tokenDetails == nil &&
            authUrl == nil &&
            authCallback == nil
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 11 and ARTClientOptions.m, line 169
    internal var hasCustomRestHost: Bool {
        return (_restHost != nil && _restHost != ARTDefault.restHost()) || (hasEnvironment && !isProductionEnvironment)
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 12 and ARTClientOptions.m, line 173
    internal var hasDefaultRestHost: Bool {
        return !hasCustomRestHost
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 13 and ARTClientOptions.m, line 177
    internal var hasCustomRealtimeHost: Bool {
        return (_realtimeHost != nil && _realtimeHost != ARTDefault.realtimeHost()) || (hasEnvironment && !isProductionEnvironment)
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 14 and ARTClientOptions.m, line 181
    internal var hasDefaultRealtimeHost: Bool {
        return !hasCustomRealtimeHost
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 15 and ARTClientOptions.m, line 185
    internal var hasCustomPort: Bool {
        return port != 0 && port != ARTDefault.port()
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 16 and ARTClientOptions.m, line 189
    internal var hasCustomTlsPort: Bool {
        return tlsPort != 0 && tlsPort != ARTDefault.tlsPort()
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 18 and ARTClientOptions.m, line 207
    internal static func setDefaultEnvironment(_ environment: String?) {
        ARTDefaultEnvironment = environment
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 19 and ARTClientOptions.m, line 215
    internal static func getDefaultIdempotentRestPublishing(forVersion version: String) -> Bool {
        if "1.2".compare(version, options: .numeric) == .orderedDescending {
            return false
        } else {
            return true
        }
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 8 and ARTClientOptions.m, line 224
    internal var isProductionEnvironment: Bool {
        return environment?.lowercased() == ARTDefaultProduction.lowercased()
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 9 and ARTClientOptions.m, line 228
    internal var hasEnvironment: Bool {
        return environment != nil && !(environment?.isEmpty ?? true)
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 10 and ARTClientOptions.m, line 232
    internal var hasEnvironmentDifferentThanProduction: Bool {
        return hasEnvironment && !isProductionEnvironment
    }

    // swift-migration: original location ARTClientOptions.m, line 236
    private func host(_ host: String, forEnvironment environment: String) -> String {
        return "\(environment)-\(host)"
    }

    // MARK: - Plugins

    // swift-migration: original location ARTClientOptions+Private.h, line 25 and ARTClientOptions.m, line 242
    /// The plugin that channels should use to access LiveObjects functionality.
    internal var liveObjectsPlugin: APLiveObjectsInternalPluginProtocol? {
        guard let plugins = plugins,
              let publicPlugin = plugins[ARTPluginNameLiveObjects] as? APLiveObjectsPluginProtocol.Type else {
            return nil
        }

        return publicPlugin.internalPlugin()
    }

    // MARK: - Options for plugins

    // swift-migration: original location ARTClientOptions+Private.h, line 30 and ARTClientOptions.m, line 254
    /// Provides the implementation for `-[ARTPluginAPI setPluginOptionsValue:forKey:options:]`. See documentation for that method in `APPluginAPIProtocol`.
    internal func setPluginOptionsValue(_ value: Any, forKey key: String) {
        pluginData[key] = value
    }

    // swift-migration: original location ARTClientOptions+Private.h, line 32 and ARTClientOptions.m, line 258
    /// Provides the implementation for `-[ARTPluginAPI pluginOptionsValueForKey:options:]`. See documentation for that method in `APPluginAPIProtocol`.
    internal func pluginOptionsValueForKey(_ key: String) -> Any? {
        return pluginData[key]
    }
}
