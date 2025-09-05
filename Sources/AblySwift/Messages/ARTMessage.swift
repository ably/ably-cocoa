import Foundation

/**
 * The namespace containing the different types of message actions.
 */
@frozen
public enum ARTMessageAction: UInt, Sendable {
    /**
     * Message action for a newly created message.
     */
    case create = 0
    /**
     * Message action for an updated message.
     */
    case update = 1
    /**
     * Message action for a deleted message.
     */
    case delete = 2
    /**
     * A meta-message (a message originating from ably rather than being
     * explicitly published on a channel), containing information such as
     * inband channel occupancy events that has been requested by channel
     * param.
     */
    case meta = 3
    /**
     * Message action for a message containing the latest rolled-up summary of
     * annotations that have been made to this message.
     */
    case messageSummary = 4
}

public func ARTMessageActionToStr(_ action: ARTMessageAction) -> String {
    switch action {
    case .create: return "create"
    case .update: return "update"
    case .delete: return "delete"
    case .meta: return "meta"
    case .messageSummary: return "messageSummary"
    }
}

/**
 * Contains an individual message that is sent to, or received from, Ably.
 */
public class ARTMessage: ARTBaseMessage, @unchecked Sendable {
    
    /// The event name, if available
    public var name: String?
    
    /// The action type of the message, one of the `ARTMessageAction` enum values.
    public var action: ARTMessageAction = .create
    
    /// The version of the message, lexicographically-comparable with other versions (that share the same serial).
    /// Will differ from the serial only if the message has been updated or deleted.
    public var version: String?
    
    /// This message's unique serial (an identifier that will be the same in all future updates of this message).
    public var serial: String?
    
    /// The serial of the operation that updated this message.
    public var updateSerial: String?
    
    /// The timestamp of the very first version of a given message.
    public var createdAt: Date?
    
    /// The timestamp of the most recent update to this message.
    public var updatedAt: Date?
    
    /// An opaque string that uniquely identifies some referenced message.
    public var refSerial: String?
    
    /// An opaque string that identifies the type of this reference.
    public var refType: String?
    
    /// An object containing some optional values for the operation performed.
    public var operation: ARTMessageOperation?
    
    /// An annotations summary for the message. The keys of the dict are annotation types, and the values are aggregated summaries for that annotation type.
    public var summary: ARTJsonObject?
    
    // MARK: - Initializers
    
    public required init() {
        super.init()
    }
    
    /**
     * Construct an `ARTMessage` object with an event name and payload.
     *
     * @param name The event name.
     * @param data The message payload.
     */
    public init(name: String?, data: Any?) {
        super.init()
        self.name = name
        self.data = data
    }
    
    /**
     * Construct an `ARTMessage` object with an event name, payload, and a unique client ID.
     *
     * @param name The event name.
     * @param data The message payload.
     * @param clientId The client ID of the publisher of this message.
     */
    public init(name: String?, data: Any?, clientId: String) {
        super.init()
        self.name = name
        self.data = data
        self.clientId = clientId
    }
    
    // MARK: - NSCopying Override
    
    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = ARTMessage()
        // Copy base properties
        copy.id = self.id
        copy.timestamp = self.timestamp
        copy.clientId = self.clientId
        copy.connectionId = self.connectionId
        copy.encoding = self.encoding
        copy.data = self.data
        copy.extras = self.extras
        
        // Copy ARTMessage-specific properties
        copy.name = self.name
        copy.action = self.action
        copy.version = self.version
        copy.serial = self.serial
        copy.updateSerial = self.updateSerial
        copy.createdAt = self.createdAt
        copy.updatedAt = self.updatedAt
        copy.refSerial = self.refSerial
        copy.refType = self.refType
        copy.operation = self.operation
        copy.summary = self.summary
        
        return copy
    }
    
    // MARK: - Description Override
    
    public override var description: String {
        var components: [String] = []
        
        if let name = name {
            components.append("name: \(name)")
        }
        components.append("action: \(ARTMessageActionToStr(action))")
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
        if let encoding = encoding {
            components.append("encoding: \(encoding)")
        }
        if data != nil {
            components.append("data: <present>")
        }
        if let serial = serial {
            components.append("serial: \(serial)")
        }
        if let version = version {
            components.append("version: \(version)")
        }
        
        return "ARTMessage(\(components.joined(separator: ", ")))"
    }
}

// MARK: - Decoding Extensions

extension ARTMessage {
    
    /**
     * A static factory method to create an `ARTMessage` object from a deserialized Message-like object encoded using Ably's wire protocol.
     *
     * @param jsonObject A `Message`-like deserialized object.
     * @param options An `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
     *
     * @return An `ARTMessage` object.
     */
    public static func fromEncoded(_ jsonObject: [String: Any], channelOptions: ARTChannelOptions) throws -> ARTMessage {
        let jsonEncoder = ARTJsonLikeEncoder(delegate: ARTJsonEncoder())
        let decoder = try ARTDataEncoder(cipherParams: channelOptions.cipher, logger: ARTInternalLog())
        
        let message = jsonEncoder.message(from: jsonObject, protocolMessage: nil as ARTProtocolMessage?)
        return try message.decode(with: decoder) as! ARTMessage
    }
    
    /**
     * A static factory method to create an array of `ARTMessage` objects from an array of deserialized Message-like object encoded using Ably's wire protocol.
     *
     * @param jsonArray An array of `Message`-like deserialized objects.
     * @param options An `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
     *
     * @return An array of `ARTMessage` objects.
     */
    public static func fromEncodedArray(_ jsonArray: [[String: Any]], channelOptions: ARTChannelOptions) throws -> [ARTMessage] {
        let jsonEncoder = ARTJsonLikeEncoder(delegate: ARTJsonEncoder())
        let decoder = try ARTDataEncoder(cipherParams: channelOptions.cipher, logger: ARTInternalLog())
        
        let messages = jsonEncoder.messages(from: jsonArray, protocolMessage: nil as ARTProtocolMessage?)
        return try messages.map { try $0.decode(with: decoder) as! ARTMessage }
    }
}

// MARK: - Forward Declarations

// These will be migrated in later phases
public class ARTMessageOperation: @unchecked Sendable {}
public class ARTChannelOptions: @unchecked Sendable {
    public var cipher: ARTCipherParams?
    
    public init() {}
}

public class ARTJsonLikeEncoder: @unchecked Sendable {
    private let delegate: ARTJsonLikeEncoderDelegate
    
    public init(delegate: ARTJsonLikeEncoderDelegate) {
        self.delegate = delegate
    }
    
    public func message(from dictionary: [String: Any], protocolMessage: ARTProtocolMessage?) -> ARTMessage {
        // Placeholder implementation - will be completed when migrating ARTJsonLikeEncoder
        fatalError("ARTJsonLikeEncoder.message not yet implemented in Swift migration")
    }
    
    public func messages(from array: [[String: Any]], protocolMessage: ARTProtocolMessage?) -> [ARTMessage] {
        // Placeholder implementation - will be completed when migrating ARTJsonLikeEncoder
        fatalError("ARTJsonLikeEncoder.messages not yet implemented in Swift migration")
    }
}