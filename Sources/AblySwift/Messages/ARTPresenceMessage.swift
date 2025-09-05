import Foundation

/**
 * Describes the possible actions members in the presence set can emit.
 */
@frozen
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

/// :nodoc:
public func ARTPresenceActionToStr(_ action: ARTPresenceAction) -> String {
    switch action {
    case .absent: return "absent"
    case .present: return "present"
    case .enter: return "enter"
    case .leave: return "leave"
    case .update: return "update"
    }
}

/**
 * Contains an individual presence update sent to, or received from, Ably.
 */
public class ARTPresenceMessage: ARTBaseMessage, @unchecked Sendable {
    
    /**
     * The type of `ARTPresenceAction` the `ARTPresenceMessage` is for.
     */
    public var action: ARTPresenceAction = .absent
    
    // MARK: - Initializers
    
    public required init() {
        super.init()
    }
    
    // MARK: - Member Key
    
    /**
     * Combines `ARTBaseMessage.clientId` and `ARTBaseMessage.connectionId` to ensure that multiple connected clients with an identical `clientId` are uniquely identifiable.
     *
     * @return A combination of `ARTBaseMessage.clientId` and `ARTBaseMessage.connectionId`.
     */
    public func memberKey() -> String {
        let clientId = self.clientId ?? ""
        let connectionId = self.connectionId
        
        if clientId.isEmpty {
            return connectionId
        } else {
            return "\(clientId):\(connectionId)"
        }
    }
    
    // MARK: - Equality
    
    /// :nodoc:
    public func isEqual(to presence: ARTPresenceMessage) -> Bool {
        return self.action == presence.action &&
               self.clientId == presence.clientId &&
               self.connectionId == presence.connectionId &&
               self.id == presence.id &&
               self.timestamp == presence.timestamp &&
               self.encoding == presence.encoding &&
               self.memberKey() == presence.memberKey()
    }
    
    // MARK: - NSCopying Override
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = ARTPresenceMessage()
        // Copy base properties
        copy.id = self.id
        copy.timestamp = self.timestamp
        copy.clientId = self.clientId
        copy.connectionId = self.connectionId
        copy.encoding = self.encoding
        copy.data = self.data
        copy.extras = self.extras
        
        // Copy ARTPresenceMessage-specific properties
        copy.action = self.action
        
        return copy
    }
    
    // MARK: - Description Override
    
    public override var description: String {
        var components: [String] = []
        
        components.append("action: \(ARTPresenceActionToStr(action))")
        if let id = id {
            components.append("id: \(id)")
        }
        if let timestamp = timestamp {
            components.append("timestamp: \(timestamp)")
        }
        if let clientId = clientId {
            components.append("clientId: \(clientId)")
        }
        if !connectionId.isEmpty {
            components.append("connectionId: \(connectionId)")
        }
        components.append("memberKey: \(memberKey())")
        if let encoding = encoding {
            components.append("encoding: \(encoding)")
        }
        if data != nil {
            components.append("data: <present>")
        }
        
        return "ARTPresenceMessage(\(components.joined(separator: ", ")))"
    }
}

// MARK: - ARTEvent Extensions

/// :nodoc:
extension ARTEvent {
    public convenience init(presenceAction: ARTPresenceAction) {
        // This will be implemented when ARTEvent is migrated
        self.init()
        // Placeholder - will set the appropriate event value based on presence action
    }
    
    public static func new(withPresenceAction action: ARTPresenceAction) -> ARTEvent {
        return ARTEvent(presenceAction: action)
    }
}

// MARK: - Forward Declarations

// These will be migrated in later phases
public class ARTEvent: @unchecked Sendable {
    public init() {}
}