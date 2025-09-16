import Foundation
import _AblyPluginSupportPrivate

// swift-migration: original location ARTProtocolMessage.h, line 15
/// :nodoc:
public enum ARTProtocolMessageAction: UInt {
    case heartbeat = 0
    case ack = 1
    case nack = 2
    case connect = 3
    case connected = 4
    case disconnect = 5
    case disconnected = 6
    case close = 7
    case closed = 8
    case error = 9
    case attach = 10
    case attached = 11
    case detach = 12
    case detached = 13
    case presence = 14
    case message = 15
    case sync = 16
    case auth = 17
    case object = 19
    case objectSync = 20
    case annotation = 21
}

// swift-migration: original location ARTProtocolMessage+Private.h, line 2
/// ARTProtocolMessageFlag bitmask
public struct ARTProtocolMessageFlag: OptionSet {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let hasPresence = ARTProtocolMessageFlag(rawValue: 1 << 0)
    public static let hasBacklog = ARTProtocolMessageFlag(rawValue: 1 << 1)
    public static let resumed = ARTProtocolMessageFlag(rawValue: 1 << 2)
    public static let hasLocalPresence = ARTProtocolMessageFlag(rawValue: 1 << 3)
    public static let transient = ARTProtocolMessageFlag(rawValue: 1 << 4)
    public static let attachResume = ARTProtocolMessageFlag(rawValue: 1 << 5)
    public static let hasObjects = ARTProtocolMessageFlag(rawValue: 1 << 7)
    public static let presence = ARTProtocolMessageFlag(rawValue: 1 << 16)
    public static let publish = ARTProtocolMessageFlag(rawValue: 1 << 17)
    public static let subscribe = ARTProtocolMessageFlag(rawValue: 1 << 18)
    public static let presenceSubscribe = ARTProtocolMessageFlag(rawValue: 1 << 19)
    public static let objectSubscribe = ARTProtocolMessageFlag(rawValue: 1 << 24)
    public static let objectPublish = ARTProtocolMessageFlag(rawValue: 1 << 25)
}

// swift-migration: original location ARTProtocolMessage.h, line 40
/// :nodoc:
func ARTProtocolMessageActionToStr(_ action: ARTProtocolMessageAction) -> String {
    switch action {
    case .heartbeat:
        return "Heartbeat" //0
    case .ack:
        return "Ack" //1
    case .nack:
        return "Nack" //2
    case .connect:
        return "Connect" //3
    case .connected:
        return "Connected" //4
    case .disconnect:
        return "Disconnect" //5
    case .disconnected:
        return "Disconnected" //6
    case .close:
        return "Close" //7
    case .closed:
        return "Closed" //8
    case .error:
        return "Error" //9
    case .attach:
        return "Attach" //10
    case .attached:
        return "Attached" //11
    case .detach:
        return "Detach" //12
    case .detached:
        return "Detached" //13
    case .presence:
        return "Presence" //14
    case .message:
        return "Message" //15
    case .sync:
        return "Sync" //16
    case .auth:
        return "Auth" //17
    case .object:
        return "Object" //19
    case .objectSync:
        return "ObjectSync" //20
    case .annotation:
        return "Annotation" //21
    @unknown default:
        // Because we blindly assign the action field of a ProtocolMessage received over the wire to a variable of type ARTProtocolMessageAction, we can't rely on the compiler's exhaustive checking of switch statements for ARTProtocolMessageAction.
        //
        // TODO: we have https://github.com/ably/specification/issues/304 for making sure we properly implement the RSF1 robustness principle for enums.
        return "Unknown"
    }
}

// swift-migration: original location ARTProtocolMessage.h, line 50
/**
 * :nodoc:
 * A message sent and received over the Realtime protocol.
 * ARTProtocolMessage always relates to a single channel only, but can contain multiple individual messages or presence messages.
 * ARTProtocolMessage are serially numbered on a connection.
 */
public class ARTProtocolMessage: NSObject, NSCopying {

    // swift-migration: original location ARTProtocolMessage.h, line 52 and ARTProtocolMessage.m, line 14
    internal var action: ARTProtocolMessageAction = .heartbeat
    
    // swift-migration: original location ARTProtocolMessage.h, line 53 and ARTProtocolMessage.m, line 14
    internal var count: Int32 = 0
    
    // swift-migration: original location ARTProtocolMessage.h, line 54 and ARTProtocolMessage.m, line 26
    internal var error: ARTErrorInfo?
    
    // swift-migration: original location ARTProtocolMessage.h, line 55 and ARTProtocolMessage.m, line 15
    internal var id: String?
    
    // swift-migration: original location ARTProtocolMessage.h, line 56 and ARTProtocolMessage.m, line 16
    internal var channel: String?
    
    // swift-migration: original location ARTProtocolMessage.h, line 57 and ARTProtocolMessage.m, line 17
    internal var channelSerial: String?
    
    // swift-migration: original location ARTProtocolMessage.h, line 58 and ARTProtocolMessage.m, line 18
    internal var connectionId: String?
    
    // swift-migration: original location ARTProtocolMessage.h, line 59 and ARTProtocolMessage.m, line 19
    private var _connectionKey: String?
    
    // swift-migration: original location ARTProtocolMessage.h, line 60 and ARTProtocolMessage.m, line 20
    internal var msgSerial: NSNumber?
    
    // swift-migration: original location ARTProtocolMessage.h, line 61 and ARTProtocolMessage.m, line 21
    internal var timestamp: Date?
    
    // swift-migration: original location ARTProtocolMessage.h, line 62 and ARTProtocolMessage.m, line 22
    internal var messages: [ARTMessage]?
    
    // swift-migration: original location ARTProtocolMessage.h, line 63 and ARTProtocolMessage.m, line 23
    internal var presence: [ARTPresenceMessage]?
    
    // swift-migration: original location ARTProtocolMessage.h, line 64 and ARTProtocolMessage.m, line 24
    internal var annotations: [ARTAnnotation]?
    
    // swift-migration: original location ARTProtocolMessage.h, line 65
    internal var state: [any _AblyPluginSupportPrivate.ObjectMessageProtocol]?
    
    // swift-migration: original location ARTProtocolMessage.h, line 66 and ARTProtocolMessage.m, line 25
    internal var flags: UInt = 0
    
    // swift-migration: original location ARTProtocolMessage.h, line 67 and ARTProtocolMessage.m, line 27
    internal var connectionDetails: ARTConnectionDetails?
    
    // swift-migration: original location ARTProtocolMessage.h, line 68
    internal var auth: ARTAuthDetails?
    
    // swift-migration: original location ARTProtocolMessage.h, line 69
    internal var params: [String: String]?

    // swift-migration: original location ARTProtocolMessage.m, line 11
    public required override init() {
        super.init()
        // swift-migration: All properties initialized with default values above
    }

    // swift-migration: original location ARTProtocolMessage.h, line 59 and ARTProtocolMessage.m, line 32
    internal var connectionKey: String? {
        get {
            if let connectionDetails = connectionDetails, let connectionKey = connectionDetails.connectionKey {
                return connectionKey
            }
            return _connectionKey
        }
        set {
            _connectionKey = newValue
        }
    }

    // swift-migration: original location ARTProtocolMessage.m, line 39
    public override var description: String {
        var description = "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())> {\n"
        description += " count: \(self.count),\n"
        description += " id: \(String(describing: self.id)),\n"
        description += " action: \(self.action.rawValue) (\(ARTProtocolMessageActionToStr(self.action))),\n"
        description += " channel: \(String(describing: self.channel)),\n"
        description += " channelSerial: \(String(describing: self.channelSerial)),\n"
        description += " connectionId: \(String(describing: self.connectionId)),\n"
        description += " connectionKey: \(String(describing: self.connectionKey)),\n"
        description += " msgSerial: \(String(describing: self.msgSerial)),\n"
        description += " timestamp: \(String(describing: self.timestamp)),\n"
        description += " flags: \(self.flags),\n"
        description += " flags.hasPresence: \(ARTStringFromBool(self.hasPresence)),\n"
        description += " flags.hasObjects: \(ARTStringFromBool(self.hasObjects)),\n"
        description += " flags.hasBacklog: \(ARTStringFromBool(self.hasBacklog)),\n"
        description += " flags.resumed: \(ARTStringFromBool(self.resumed)),\n"
        description += " messages: \(String(describing: self.messages))\n"
        description += " presence: \(String(describing: self.presence))\n"
        description += " annotations: \(String(describing: self.annotations))\n"
        description += " params: \(String(describing: self.params))\n"
        description += "}"
        return description
    }

    // swift-migration: original location ARTProtocolMessage.m, line 63
    public func copy(with zone: NSZone?) -> Any {
        let pm = type(of: self).init()
        pm.action = self.action
        pm.count = self.count
        pm.id = self.id
        pm.channel = self.channel
        pm.channelSerial = self.channelSerial
        pm.connectionId = self.connectionId
        pm.connectionKey = self.connectionKey
        pm.msgSerial = self.msgSerial
        pm.timestamp = self.timestamp
        pm.messages = self.messages
        pm.presence = self.presence
        pm.annotations = self.annotations
        pm.flags = self.flags
        pm.error = self.error
        pm.connectionDetails = self.connectionDetails
        pm.params = self.params
        return pm
    }

    // swift-migration: original location ARTProtocolMessage+Private.h, line 29 and ARTProtocolMessage.m, line 84
    internal func mergeFrom(_ src: ARTProtocolMessage, maxSize: Int) -> Bool {
        if src.channel != self.channel || src.action != self.action {
            // RTL6d3
            return false
        }
        if mergeWithMessages(src.messages, wouldExceedMaxSize: maxSize) {
            // RTL6d1
            return false
        }
        if clientIdsAreDifferent(src.messages) {
            // RTL6d2
            return false
        }

        var proposed: [Any]?
        switch self.action {
        // RTL6d4, RTL6d6
        case .message:
            if let messages = self.messages, let srcMessages = src.messages {
                proposed = messages + srcMessages
            } else {
                proposed = src.messages ?? self.messages
            }
        case .presence:
            if let presence = self.presence, let srcPresence = src.presence {
                proposed = presence + srcPresence
            } else {
                proposed = src.presence ?? self.presence
            }
        case .annotation:
            if let annotations = self.annotations, let srcAnnotations = src.annotations {
                proposed = annotations + srcAnnotations
            } else {
                proposed = src.annotations ?? self.annotations
            }
        default:
            return false
        }

        guard let proposed = proposed else {
            return false
        }

        let ids = (proposed as? [ARTMessage])?.filter { $0.id != nil }.count ?? 0
        if ids > 0 {
            // RTL6d7
            return false
        }

        switch self.action {
        case .message:
            self.messages = proposed as? [ARTMessage]
            return true
        case .presence:
            self.presence = proposed as? [ARTPresenceMessage]
            return true
        case .annotation:
            self.annotations = proposed as? [ARTAnnotation]
            return true
        default:
            return false
        }
    }

    // swift-migration: original location ARTProtocolMessage.m, line 138
    private func clientIdsAreDifferent(_ messages: [ARTMessage]?) -> Bool {
        var queuedClientIds = Set<String>()
        var incomingClientIds = Set<String>()
        
        if let selfMessages = self.messages {
            for message in selfMessages {
                queuedClientIds.insert(message.clientId ?? "")
            }
        }
        
        if let messages = messages {
            for message in messages {
                incomingClientIds.insert(message.clientId ?? "")
            }
        }
        
        queuedClientIds.formUnion(incomingClientIds)
        
        if queuedClientIds.count == 1 {
            return false
        } else {
            return true
        }
    }

    // swift-migration: original location ARTProtocolMessage.m, line 155
    private func mergeWithMessages(_ messages: [ARTMessage]?, wouldExceedMaxSize maxSize: Int) -> Bool {
        var queuedMessagesSize = 0
        
        if let selfMessages = self.messages {
            for message in selfMessages {
                queuedMessagesSize += message.messageSize()
            }
        }
        
        var messagesSize = 0
        if let messages = messages {
            for message in messages {
                messagesSize += message.messageSize()
            }
        }
        
        let totalSize = queuedMessagesSize + messagesSize
        return totalSize > maxSize
    }

    // swift-migration: original location ARTProtocolMessage+Private.h, line 22 and ARTProtocolMessage.m, line 168
    internal var ackRequired: Bool {
        // RTN7a
        return self.action == .message
            || self.action == .presence
            || self.action == .annotation
            || self.action == .object
    }

    // swift-migration: original location ARTProtocolMessage+Private.h, line 24 and ARTProtocolMessage.m, line 176
    internal var hasPresence: Bool {
        return (self.flags & ARTProtocolMessageFlag.hasPresence.rawValue) != 0
    }

    // swift-migration: original location ARTProtocolMessage+Private.h, line 25 and ARTProtocolMessage.m, line 180
    internal var hasObjects: Bool {
        return (self.flags & ARTProtocolMessageFlag.hasObjects.rawValue) != 0
    }

    // swift-migration: original location ARTProtocolMessage+Private.h, line 26 and ARTProtocolMessage.m, line 184
    internal var hasBacklog: Bool {
        return (self.flags & ARTProtocolMessageFlag.hasBacklog.rawValue) != 0
    }

    // swift-migration: original location ARTProtocolMessage+Private.h, line 27 and ARTProtocolMessage.m, line 188
    internal var resumed: Bool {
        return (self.flags & ARTProtocolMessageFlag.resumed.rawValue) != 0
    }

    // swift-migration: original location ARTProtocolMessage.m, line 192
    internal func getConnectionDetails() -> ARTConnectionDetails? {
        return connectionDetails
    }
}
