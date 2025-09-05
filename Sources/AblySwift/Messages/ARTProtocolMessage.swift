import Foundation

/**
 * Enumerates the possible actions on a `ARTProtocolMessage`
 */
@frozen
public enum ARTProtocolMessageAction: UInt, Sendable {
    /**
     * A `heartbeat` action.
     */
    case heartbeat = 0
    /**
     * An `ack` action.
     */
    case ack = 1
    /**
     * A `nack` action.
     */
    case nack = 2
    /**
     * A `connect` action.
     */
    case connect = 3
    /**
     * A `connected` action.
     */
    case connected = 4
    /**
     * A `disconnect` action.
     */
    case disconnect = 5
    /**
     * A `disconnected` action.
     */
    case disconnected = 6
    /**
     * A `close` action.
     */
    case close = 7
    /**
     * A `closed` action.
     */
    case closed = 8
    /**
     * A `error` action.
     */
    case error = 9
    /**
     * A `attach` action.
     */
    case attach = 10
    /**
     * An `attached` action.
     */
    case attached = 11
    /**
     * A `detach` action.
     */
    case detach = 12
    /**
     * A `detached` action.
     */
    case detached = 13
    /**
     * A `presence` action.
     */
    case presence = 14
    /**
     * A `message` action.
     */
    case message = 15
    /**
     * A `sync` action.
     */
    case sync = 16
    /**
     * An `auth` action.
     */
    case auth = 17
}

/// :nodoc:
public func ARTProtocolMessageActionToStr(_ action: ARTProtocolMessageAction) -> String {
    switch action {
    case .heartbeat: return "heartbeat"
    case .ack: return "ack"
    case .nack: return "nack"
    case .connect: return "connect"
    case .connected: return "connected"
    case .disconnect: return "disconnect"
    case .disconnected: return "disconnected"
    case .close: return "close"
    case .closed: return "closed"
    case .error: return "error"
    case .attach: return "attach"
    case .attached: return "attached"
    case .detach: return "detach"
    case .detached: return "detached"
    case .presence: return "presence"
    case .message: return "message"
    case .sync: return "sync"
    case .auth: return "auth"
    }
}

/**
 * Contains a `ARTProtocolMessage` object
 */
public class ARTProtocolMessage: NSObject, NSCopying, @unchecked Sendable {
    
    /// The action, `ARTProtocolMessageAction`.
    public var action: ARTProtocolMessageAction = .heartbeat
    
    /// The channel the message is for. Populated if action is message, presence, attach, attached, detach or detached.
    public var channel: String?
    
    /// The channelSerial. Populated if action is attached.
    public var channelSerial: String?
    
    /// The connection ID. Populated if action is connected.
    public var connectionId: String?
    
    /// The connection key. Populated if action is connected.
    public var connectionKey: String?
    
    /// The connection serial. Populated if action is connected.
    public var connectionSerial: NSNumber?
    
    /// Contains any arbitrary key-value pairs, which may contain metadata and ancillary payloads for the message.
    public var connectionDetails: [String: Any]?
    
    /// The channel serial after which messages should be retrieved. Populated if action is attached.
    public var channelSerial_CP: String?
    
    /// A unique ID assigned by Ably to this message. Populated if action is message or presence.
    public var id: String?
    
    /// The message serial. Populated if action is message or presence.
    public var msgSerial: NSNumber?
    
    /// Timestamp of when the message was received by Ably. Populated if action is message or presence.
    public var timestamp: Date?
    
    /// The error details. Populated if action is error.
    public var error: ARTErrorInfo?
    
    /// Array of Message and PresenceMessage objects. Populated if action is message, presence or sync.
    public var messages: [Any]?
    
    /// Array of PresenceMessage objects. Populated if action is presence or sync.
    public var presence: [ARTPresenceMessage]?
    
    /// The auth details. Populated if action is auth.
    public var auth: [String: Any]?
    
    /// An encoded value. Populated if action is connected.
    public var connectionStateTtl: NSNumber?
    
    /// The channel parameters. Populated if action is attach.
    public var params: [String: String]?
    
    /// The channel modes.
    public var mode: NSNumber?
    
    /// The channel state. Populated if action is attached.
    public var resumed: NSNumber?
    
    /// Contains any arbitrary key-value pairs which may also contain metadata and ancillary payloads.
    public var flags: NSNumber?
    
    // MARK: - Initializers
    
    public override init() {
        super.init()
    }
    
    public init(action: ARTProtocolMessageAction) {
        self.action = action
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = ARTProtocolMessage()
        copy.action = self.action
        copy.channel = self.channel
        copy.channelSerial = self.channelSerial
        copy.connectionId = self.connectionId
        copy.connectionKey = self.connectionKey
        copy.connectionSerial = self.connectionSerial
        copy.connectionDetails = self.connectionDetails
        copy.channelSerial_CP = self.channelSerial_CP
        copy.id = self.id
        copy.msgSerial = self.msgSerial
        copy.timestamp = self.timestamp
        copy.error = self.error
        copy.messages = self.messages
        copy.presence = self.presence
        copy.auth = self.auth
        copy.connectionStateTtl = self.connectionStateTtl
        copy.params = self.params
        copy.mode = self.mode
        copy.resumed = self.resumed
        copy.flags = self.flags
        return copy
    }
    
    // MARK: - Description
    
    public override var description: String {
        var components: [String] = []
        
        components.append("action: \(ARTProtocolMessageActionToStr(action))")
        
        if let channel = channel {
            components.append("channel: \(channel)")
        }
        if let channelSerial = channelSerial {
            components.append("channelSerial: \(channelSerial)")
        }
        if let connectionId = connectionId {
            components.append("connectionId: \(connectionId)")
        }
        if let connectionKey = connectionKey {
            components.append("connectionKey: \(connectionKey)")
        }
        if let connectionSerial = connectionSerial {
            components.append("connectionSerial: \(connectionSerial)")
        }
        if let id = id {
            components.append("id: \(id)")
        }
        if let msgSerial = msgSerial {
            components.append("msgSerial: \(msgSerial)")
        }
        if let timestamp = timestamp {
            components.append("timestamp: \(timestamp)")
        }
        if error != nil {
            components.append("error: <present>")
        }
        if let messages = messages, !messages.isEmpty {
            components.append("messages: \(messages.count) item(s)")
        }
        if let presence = presence, !presence.isEmpty {
            components.append("presence: \(presence.count) item(s)")
        }
        if auth != nil {
            components.append("auth: <present>")
        }
        if connectionDetails != nil {
            components.append("connectionDetails: <present>")
        }
        if let connectionStateTtl = connectionStateTtl {
            components.append("connectionStateTtl: \(connectionStateTtl)")
        }
        if let params = params, !params.isEmpty {
            components.append("params: \(params.count) item(s)")
        }
        if let mode = mode {
            components.append("mode: \(mode)")
        }
        if let resumed = resumed {
            components.append("resumed: \(resumed)")
        }
        if let flags = flags {
            components.append("flags: \(flags)")
        }
        
        return "ARTProtocolMessage(\(components.joined(separator: ", ")))"
    }
    
    // MARK: - Utility Methods
    
    /// :nodoc:
    public func hasConnectionSerial() -> Bool {
        return connectionSerial != nil && connectionSerial!.intValue != -1
    }
    
    /// :nodoc:
    public func mergeFrom(_ other: ARTProtocolMessage) {
        if other.id != nil {
            self.id = other.id
        }
        if other.connectionId != nil {
            self.connectionId = other.connectionId
        }
        if other.connectionKey != nil {
            self.connectionKey = other.connectionKey
        }
        if other.connectionSerial != nil {
            self.connectionSerial = other.connectionSerial
        }
        if other.connectionDetails != nil {
            self.connectionDetails = other.connectionDetails
        }
        if other.error != nil {
            self.error = other.error
        }
        if other.auth != nil {
            self.auth = other.auth
        }
        if other.connectionStateTtl != nil {
            self.connectionStateTtl = other.connectionStateTtl
        }
    }
    
    /// :nodoc:
    public class func newWithAction(_ action: ARTProtocolMessageAction) -> ARTProtocolMessage {
        return ARTProtocolMessage(action: action)
    }
    
    /// :nodoc:
    public class func newHeartbeatMessage() -> ARTProtocolMessage {
        return ARTProtocolMessage(action: .heartbeat)
    }
    
    /// :nodoc:
    public class func newErrorMessage(_ error: ARTErrorInfo) -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        message.action = .error
        message.error = error
        return message
    }
    
    /// :nodoc:
    public class func newConnectedMessage(_ connectionDetails: [String: Any]?,
                                        connectionId: String?,
                                        connectionKey: String?,
                                        connectionSerial: NSNumber?,
                                        connectionStateTtl: NSNumber?) -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        message.action = .connected
        message.connectionDetails = connectionDetails
        message.connectionId = connectionId
        message.connectionKey = connectionKey
        message.connectionSerial = connectionSerial
        message.connectionStateTtl = connectionStateTtl
        return message
    }
    
    /// :nodoc:
    public class func newDisconnectedMessage(_ error: ARTErrorInfo?) -> ARTProtocolMessage {
        let message = ARTProtocolMessage()
        message.action = .disconnected
        message.error = error
        return message
    }
}

// MARK: - ARTProtocolMessage Extensions

/// :nodoc:
extension ARTProtocolMessage {
    
    /// Returns true if this is an ack or nack action that acknowledges the given msgSerial
    public func acksMsgSerial(_ msgSerial: NSNumber) -> Bool {
        guard action == .ack || action == .nack else {
            return false
        }
        
        guard let messageSerial = self.msgSerial else {
            return false
        }
        
        return messageSerial.intValue >= msgSerial.intValue
    }
    
    /// Returns true if this protocol message indicates a protocol error
    public func isConnectionError() -> Bool {
        return action == .error || (action == .disconnected && error != nil)
    }
    
    /// Returns true if this protocol message should trigger a resume
    public func shouldResume() -> Bool {
        return action == .connected && resumed?.boolValue == true
    }
}