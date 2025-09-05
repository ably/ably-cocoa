//
//  ARTConnectionDetails.swift
//  AblySwift
//
//  Created during Swift migration from Objective-C.
//  Copyright © 2024 Ably Real-time Ltd. All rights reserved.
//

import Foundation

/**
 * Contains any constraints a client should adhere to and provides additional information about how the connection is configured.
 */
public class ARTConnectionDetails: NSObject, @unchecked Sendable {
    
    /**
     * A unique private connection key used to recover or resume a realtime connection and its state.
     */
    public private(set) var clientId: String?
    
    /**
     * A unique private connection key used to recover or resume a realtime connection and its state.
     */
    public private(set) var connectionKey: String?
    
    /**
     * The maximum message size is an attribute of an Ably account and enforced by Ably servers. maxMessageSize indicates the maximum message size allowed by the Ably account this connection is using.
     */
    public private(set) var maxMessageSize: Int
    
    /**
     * The maximum frame size is the maximum size for a single frame of a realtime WebSocket connection.
     */
    public private(set) var maxFrameSize: Int
    
    /**
     * The max inbound rate is the maximum inbound message rate allowed by the Ably account this connection is using.
     */
    public private(set) var maxInboundRate: Int
    
    /**
     * To ensure connection state recovery and channel continuity are possible, connection state is persisted by Ably for two minutes by default.
     */
    public private(set) var connectionStateTtl: TimeInterval
    
    /**
     * A unique identifier for the Ably server where this connection was established.
     */
    public private(set) var serverId: String
    
    /**
     * To ensure connection state recovery and channel continuity are possible, after a successful connection is established, if there has been no activity within a time period set by this connectionStateTtl attribute, Ably will send a heartbeat or ping message to the client. If the client does not respond within maxIdleInterval milliseconds, the connection will be considered unusable and will be closed.
     */
    public private(set) var maxIdleInterval: TimeInterval
    
    // MARK: - Initializers
    
    public init(clientId: String? = nil,
                connectionKey: String? = nil,
                maxMessageSize: Int = 0,
                maxFrameSize: Int = 0,
                maxInboundRate: Int = 0,
                connectionStateTtl: TimeInterval = 0,
                serverId: String = "",
                maxIdleInterval: TimeInterval = 0) {
        self.clientId = clientId
        self.connectionKey = connectionKey
        self.maxMessageSize = maxMessageSize
        self.maxFrameSize = maxFrameSize
        self.maxInboundRate = maxInboundRate
        self.connectionStateTtl = connectionStateTtl
        self.serverId = serverId
        self.maxIdleInterval = maxIdleInterval
    }
    
    // MARK: - Setters (Internal)
    
    internal func setMaxIdleInterval(_ seconds: TimeInterval) {
        maxIdleInterval = seconds
    }
    
    // MARK: - Description
    
    public override var description: String {
        return """
        ARTConnectionDetails {
            clientId: \(clientId ?? "nil")
            connectionKey: \(connectionKey ?? "nil")
            maxMessageSize: \(maxMessageSize)
            maxFrameSize: \(maxFrameSize)
            maxInboundRate: \(maxInboundRate)
            connectionStateTtl: \(connectionStateTtl)
            serverId: \(serverId)
            maxIdleInterval: \(maxIdleInterval)
        }
        """
    }
}