import Foundation

// swift-migration: original location ARTDefault+Private.h, line 3 and ARTDefault.m, line 8
public let ARTDefaultProduction = "production"

// swift-migration: original location ARTDefault.m, line 6
private let ARTDefault_apiVersion = "2" // CSV2

// swift-migration: original location ARTDefault.m, line 10
private let ARTDefault_restHost = "rest.ably.io"

// swift-migration: original location ARTDefault.m, line 11
private let ARTDefault_realtimeHost = "realtime.ably.io"

// swift-migration: original location ARTDefault.m, line 13
private var _connectionStateTtl: TimeInterval = 60.0

// swift-migration: original location ARTDefault.m, line 14
private var _maxProductionMessageSize: Int = 65536

// swift-migration: original location ARTDefault.m, line 15
private var _maxSandboxMessageSize: Int = 16384

// Thread-safe lock for static variables
private let ARTDefaultLock = NSLock()

// swift-migration: original location ARTDefault.h, line 8 and ARTDefault.m, line 17
/**
 Represents default library settings.
 */
public class ARTDefault: NSObject {
    
    // swift-migration: original location ARTDefault.h, line 10 and ARTDefault.m, line 19
    public static func apiVersion() -> String {
        return ARTDefault_apiVersion
    }
    
    // swift-migration: original location ARTDefault.h, line 11 and ARTDefault.m, line 23
    public static func libraryVersion() -> String {
        return ARTClientInformation_libraryVersion
    }
    
    // swift-migration: original location ARTDefault.h, line 14 and ARTDefault.m, line 27
    public static func fallbackHosts(withEnvironment environment: String?) -> [String] {
        let fallbacks = ["a", "b", "c", "d", "e"]
        var prefix = ""
        var suffix = ""
        
        if let env = environment, !env.isEmpty && env != ARTDefaultProduction {
            prefix = "\(env)-"
            suffix = "-fallback"
        }
        
        return fallbacks.artMap { fallback in
            return "\(prefix)\(fallback)\(suffix).ably-realtime.com"
        }
    }
    
    // swift-migration: original location ARTDefault.h, line 13 and ARTDefault.m, line 41
    public static func fallbackHosts() -> [String] {
        return fallbackHosts(withEnvironment: nil)
    }
    
    // swift-migration: original location ARTDefault.h, line 15 and ARTDefault.m, line 45
    public static func restHost() -> String {
        return ARTDefault_restHost
    }
    
    // swift-migration: original location ARTDefault.h, line 16 and ARTDefault.m, line 49
    public static func realtimeHost() -> String {
        return ARTDefault_realtimeHost
    }
    
    // swift-migration: original location ARTDefault.h, line 17 and ARTDefault.m, line 53
    public static func port() -> Int {
        return 80
    }
    
    // swift-migration: original location ARTDefault.h, line 18 and ARTDefault.m, line 57
    public static func tlsPort() -> Int {
        return 443
    }
    
    // swift-migration: original location ARTDefault.h, line 23 and ARTDefault.m, line 61
    /**
     Default in seconds of requested time to live for the token.
     */
    public static func ttl() -> TimeInterval {
        return 60 * 60
    }
    
    // swift-migration: original location ARTDefault.h, line 30 and ARTDefault.m, line 65
    /**
     When the client is in the `ARTRealtimeConnectionState.ARTRealtimeDisconnected` state, once this TTL has passed, the client should change the state to the `ARTRealtimeConnectionState.ARTRealtimeSuspended` state signifying that the state is now lost i.e. channels need to be reattached manually.
     
     Note that this default is override by any `ARTConnectionDetails.connectionStateTtl` of the `ARTProtocolMessageConnected` of the `ARTProtocolMessage`.
     */
    public static func connectionStateTtl() -> TimeInterval {
        return ARTDefaultLock.withLock {
            return _connectionStateTtl
        }
    }
    
    // swift-migration: original location ARTDefault.h, line 35 and ARTDefault.m, line 69
    /**
     * Timeout for the wait of acknowledgement for operations performed via a realtime connection, before the client library considers a request failed and triggers a failure condition. Operations include establishing a connection with Ably, or sending a `ARTProtocolMessageHeartbeat`, `ARTProtocolMessageConnect`, `ARTProtocolMessageAttach`, `ARTProtocolMessageDetach` or `ARTProtocolMessageClose` request. It is the equivalent of `ARTClientOptions.httpRequestTimeout` but for realtime operations, rather than REST. The default is 10 seconds.
     */
    public static func realtimeRequestTimeout() -> TimeInterval {
        return 10.0
    }
    
    // swift-migration: original location ARTDefault.h, line 46 and ARTDefault.m, line 73
    /**
     * The maximum size of messages that can be published in one go. For realtime publishes, the default can be overridden by the `maxMessageSize` in the `ARTConnectionDetails` object.
     */
    public static func maxMessageSize() -> Int {
        return ARTDefaultLock.withLock {
            #if DEBUG
            return _maxSandboxMessageSize
            #else
            return _maxProductionMessageSize
            #endif
        }
    }
    
    // swift-migration: original location ARTDefault+Private.h, line 10 and ARTDefault.m, line 81
    public static func maxSandboxMessageSize() -> Int {
        return ARTDefaultLock.withLock {
            return _maxSandboxMessageSize
        }
    }
    
    // swift-migration: original location ARTDefault+Private.h, line 11 and ARTDefault.m, line 85
    public static func maxProductionMessageSize() -> Int {
        return ARTDefaultLock.withLock {
            return _maxProductionMessageSize
        }
    }
    
    // swift-migration: original location ARTDefault.h, line 38 and ARTDefault.m, line 117
    public static func libraryAgent() -> String {
        return ARTClientInformation.libraryAgentIdentifier()
    }
    
    // swift-migration: original location ARTDefault.h, line 41 and ARTDefault.m, line 121
    public static func platformAgent() -> String {
        return ARTClientInformation.platformAgentIdentifier()
    }
    
    // swift-migration: original location ARTDefault+Private.h, line 7 and ARTDefault.m, line 89
    internal static func setConnectionStateTtl(_ value: TimeInterval) {
        ARTDefaultLock.withLock {
            _connectionStateTtl = value
        }
    }
    
    // swift-migration: original location ARTDefault+Private.h, line 8 and ARTDefault.m, line 95
    internal static func setMaxMessageSize(_ value: Int) {
        ARTDefaultLock.withLock {
            #if DEBUG
            _maxSandboxMessageSize = value
            #else
            _maxProductionMessageSize = value
            #endif
        }
    }
    
    // swift-migration: original location ARTDefault.m, line 105 (not in any header - private method)
    internal static func setMaxProductionMessageSize(_ value: Int) {
        ARTDefaultLock.withLock {
            _maxProductionMessageSize = value
        }
    }
    
    // swift-migration: original location ARTDefault.m, line 111 (not in any header - private method)
    internal static func setMaxSandboxMessageSize(_ value: Int) {
        ARTDefaultLock.withLock {
            _maxSandboxMessageSize = value
        }
    }
}
