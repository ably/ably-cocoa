import Foundation

// swift-migration: original location ARTConnectionDetails.h, line 9 and ARTConnectionDetails.m, line 3
/**
 * Contains any constraints a client should adhere to and provides additional metadata about a `ARTConnection`, such as if a request to `-[ARTChannelProtocol publish:callback:]` a message that exceeds the maximum message size should be rejected immediately without communicating with Ably.
 */
internal class ARTConnectionDetails: NSObject {
    
    // swift-migration: original location ARTConnectionDetails.h, line 16
    /**
     * Contains the client ID assigned to the token. If `clientId` is `nil` or omitted, then the client is prohibited from assuming a `clientId` in any operations, however if `clientId` is a wildcard string `*`, then the client is permitted to assume any `clientId`. Any other string value for `clientId` implies that the `clientId` is both enforced and assumed for all operations from this client.
     */
    internal private(set) var clientId: String?
    
    // swift-migration: original location ARTConnectionDetails.h, line 21
    /**
     * The connection secret key string that is used to resume a connection and its state.
     */
    internal private(set) var connectionKey: String?
    
    // swift-migration: original location ARTConnectionDetails.h, line 26
    /**
     * The maximum message size is an attribute of an Ably account and enforced by Ably servers. `maxMessageSize` indicates the maximum message size allowed by the Ably account this connection is using. Overrides the default value of `+[ARTDefault maxMessageSize]`.
     */
    internal let maxMessageSize: Int
    
    // swift-migration: original location ARTConnectionDetails.h, line 31
    /**
     * Overrides the default `maxFrameSize`.
     */
    internal let maxFrameSize: Int
    
    // swift-migration: original location ARTConnectionDetails.h, line 36
    /**
     * The maximum allowable number of requests per second from a client or Ably. In the case of a realtime connection, this restriction applies to the number of messages sent, whereas in the case of REST, it is the total number of REST requests per second.
     */
    internal let maxInboundRate: Int
    
    // swift-migration: original location ARTConnectionDetails.h, line 42
    /**
     * The duration that Ably will persist the connection state for when a Realtime client is abruptly disconnected.
     * @see `+[ARTDefault connectionStateTtl]`
     */
    internal let connectionStateTtl: TimeInterval
    
    // swift-migration: original location ARTConnectionDetails.h, line 47
    /**
     * A unique identifier for the front-end server that the client has connected to. This server ID is only used for the purposes of debugging.
     */
    internal let serverId: String?
    
    // swift-migration: original location ARTConnectionDetails.h, line 52
    /**
     * The maximum length of time in milliseconds that the server will allow no activity to occur in the server to client direction. After such a period of inactivity, the server will send a `HEARTBEAT` or transport-level ping to the client. If the value is `0`, the server will allow arbitrarily-long levels of inactivity.
     */
    internal private(set) var maxIdleInterval: TimeInterval
    
    // swift-migration: original location ARTConnectionDetails.h, line 55 and ARTConnectionDetails.m, line 5
    internal init(clientId: String?, connectionKey: String?, maxMessageSize: Int, maxFrameSize: Int, maxInboundRate: Int, connectionStateTtl: TimeInterval, serverId: String?, maxIdleInterval: TimeInterval) {
        self.clientId = clientId
        self.connectionKey = connectionKey
        self.maxMessageSize = maxMessageSize
        self.maxFrameSize = maxFrameSize
        self.maxInboundRate = maxInboundRate
        self.connectionStateTtl = connectionStateTtl
        self.serverId = serverId
        self.maxIdleInterval = maxIdleInterval
        super.init()
    }
    
    // swift-migration: original location ARTConnectionDetails+Private.h, line 10 and ARTConnectionDetails.m, line 26
    internal func setMaxIdleInterval(_ seconds: TimeInterval) {
        maxIdleInterval = seconds
    }
}