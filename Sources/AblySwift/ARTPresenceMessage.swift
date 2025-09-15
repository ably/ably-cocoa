import Foundation

let ARTPresenceMessageException = "ARTPresenceMessageException"
let ARTAblyMessageInvalidPresenceId = "Received presence message id is invalid %@"

// swift-migration: original location ARTPresenceMessage.h, line 8
/**
 * Describes the possible actions members in the presence set can emit.
 */
public enum ARTPresenceAction: UInt, Sendable {
    /**
     * A member is not present in the channel.
     */
    case absent = 0
    /**
     * When subscribing to presence events on a channel that already has members present, this event is emitted for every member already present on the channel before the subscribe listener was registered.
     */
    case present = 1
    /**
     * A new member has entered the channel.
     */
    case enter = 2
    /**
     * A member who was present has now left the channel. This may be a result of an explicit request to leave or implicitly when detaching from the channel. Alternatively, if a member's connection is abruptly disconnected and they do not resume their connection within a minute, Ably treats this as a leave event as the client is no longer present.
     */
    case leave = 3
    /**
     * An already present member has updated their member data. Being notified of member data updates can be very useful, for example, it can be used to update the status of a user when they are typing a message.
     */
    case update = 4
}

// swift-migration: original location ARTPresenceMessage.h, line 32
/// :nodoc:
func ARTPresenceActionToStr(_ action: ARTPresenceAction) -> String {
    switch action {
    case .absent:
        return "Absent" //0
    case .present:
        return "Present" //1
    case .enter:
        return "Enter" //2
    case .leave:
        return "Leave" //3
    case .update:
        return "Update" //4
    }
}

// swift-migration: original location ARTPresenceMessage.h, line 39
/**
 * Contains an individual presence update sent to, or received from, Ably.
 */
public class ARTPresenceMessage: ARTBaseMessage {

    // swift-migration: original location ARTPresenceMessage.h, line 44 and ARTPresenceMessage.m, line 12
    /**
     * The type of `ARTPresenceAction` the `ARTPresenceMessage` is for.
     */
    public var action: ARTPresenceAction

    // swift-migration: original location ARTPresenceMessage.m, line 8
    public required init() {
        // Default
        self.action = .enter
        super.init()
    }

    // swift-migration: original location ARTPresenceMessage.m, line 17
    public override func copy(with zone: NSZone?) -> Any {
        let message = super.copy(with: zone) as! ARTPresenceMessage
        message.action = self.action
        return message
    }

    // swift-migration: original location ARTPresenceMessage.m, line 23
    public override var description: String {
        var description = super.description
        if description.count > 2 {
            description.removeLast(2)
        }
        description += ",\n"
        description += " action: \(self.action.rawValue),\n"
        description += "}"
        return description
    }

    // swift-migration: original location ARTPresenceMessage.h, line 51 and ARTPresenceMessage.m, line 32
    /**
     * Combines `ARTBaseMessage.clientId` and `ARTBaseMessage.connectionId` to ensure that multiple connected clients with an identical `clientId` are uniquely identifiable.
     *
     * @return A combination of `ARTBaseMessage.clientId` and `ARTBaseMessage.connectionId`.
     */
    public func memberKey() -> String {
        return "\(self.connectionId):\(self.clientId ?? "")"
    }

    // swift-migration: original location ARTPresenceMessage.h, line 54 and ARTPresenceMessage.m, line 36
    /// :nodoc:
    public func isEqualToPresenceMessage(_ presence: ARTPresenceMessage?) -> Bool {
        guard let presence = presence else {
            return false
        }

        let haveEqualConnectionId = (self.connectionId == presence.connectionId)
        let haveEqualCliendId = (self.clientId == nil && presence.clientId == nil) || 
                               (self.clientId == presence.clientId)

        return haveEqualConnectionId && haveEqualCliendId
    }

    // swift-migration: original location ARTPresenceMessage+Private.h, line 10 and ARTPresenceMessage.m, line 47
    internal func parseId() -> [String]? {
        guard let id = self.id else {
            return nil
        }
        let idParts = id.components(separatedBy: CharacterSet(charactersIn: ":"))
        if idParts.count != 3 {
            fatalError("\(ARTPresenceMessageException): \(String(format: ARTAblyMessageInvalidPresenceId, id))")
        }
        return idParts
    }

    // swift-migration: original location ARTPresenceMessage+Private.h, line 8 and ARTPresenceMessage.m, line 58
    /**
     Returns whether this presenceMessage is synthesized, i.e. was not actually sent by the connection (usually means a leave event sent 15s after a disconnection). This is useful because synthesized messages cannot be compared for newness by id lexicographically - RTP2b1.
     */
    internal func isSynthesized() -> Bool {
        guard let id = self.id, let connectionId else {
            return false
        }
        return !id.hasPrefix(connectionId)
    }

    // swift-migration: original location ARTPresenceMessage+Private.h, line 11 and ARTPresenceMessage.m, line 62
    internal func msgSerialFromId() -> Int {
        guard let idParts = parseId() else { return 0 }
        return Int(idParts[1]) ?? 0
    }

    // swift-migration: original location ARTPresenceMessage+Private.h, line 12 and ARTPresenceMessage.m, line 67
    internal func indexFromId() -> Int {
        guard let idParts = parseId() else { return 0 }
        return Int(idParts[2]) ?? 0
    }

    // MARK: - NSObject

    // swift-migration: original location ARTPresenceMessage.m, line 74
    public override func isEqual(_ object: Any?) -> Bool {
        if self === object as AnyObject? {
            return true
        }

        guard let object = object as? ARTPresenceMessage else {
            return false
        }

        return isEqualToPresenceMessage(object)
    }

    // swift-migration: original location ARTPresenceMessage.m, line 86
    public override var hash: Int {
        return (connectionId?.hash ?? 0) ^ (clientId?.hash ?? 0)
    }
}

// MARK: - ARTEvent

// swift-migration: original location ARTPresenceMessage.h, line 61
/// :nodoc:
extension ARTEvent {
    // swift-migration: original location ARTPresenceMessage.h, line 62 and ARTPresenceMessage.m, line 113
    convenience init(presenceAction value: ARTPresenceAction) {
        self.init(string: "ARTPresenceAction\(ARTPresenceActionToStr(value))")
    }

    // swift-migration: original location ARTPresenceMessage.h, line 63 and ARTPresenceMessage.m, line 117
    static func new(withPresenceAction value: ARTPresenceAction) -> ARTEvent {
        return ARTEvent(presenceAction: value)
    }
}
