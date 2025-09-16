import Foundation

// swift-migration: original location ARTMessage.h, line 10
@objc public enum ARTMessageAction: UInt, Sendable {
    case create = 0
    case update = 1
    case delete = 2
    case meta = 3
    case messageSummary = 4
}

// swift-migration: original location ARTMessage.h, line 38 and ARTMessage.m, line 70
public func ARTMessageActionToStr(_ action: ARTMessageAction) -> String {
    switch action {
    case .create:
        return "Create"
    case .update:
        return "Update"
    case .delete:
        return "Delete"
    case .meta:
        return "Meta"
    case .messageSummary:
        return "Summary"
    }
}

// swift-migration: original location ARTMessage.h, line 47 and ARTMessage.m, line 8
public class ARTMessage: ARTBaseMessage {
    
    // swift-migration: original location ARTMessage.h, line 50
    /// The event name, if available
    public var name: String?
    
    // swift-migration: original location ARTMessage.h, line 53
    /// The action type of the message, one of the `ARTMessageAction` enum values.
    public var action: ARTMessageAction = .create
    
    // swift-migration: original location ARTMessage.h, line 57
    /// The version of the message, lexicographically-comparable with other versions (that share the same serial).
    /// Will differ from the serial only if the message has been updated or deleted.
    public var version: String?
    
    // swift-migration: original location ARTMessage.h, line 60
    /// This message's unique serial (an identifier that will be the same in all future updates of this message).
    public var serial: String?
    
    // swift-migration: original location ARTMessage.h, line 63
    /// The serial of the operation that updated this message.
    public var updateSerial: String?
    
    // swift-migration: original location ARTMessage.h, line 66
    /// The timestamp of the very first version of a given message.
    public var createdAt: Date?
    
    // swift-migration: original location ARTMessage.h, line 69
    /// The timestamp of the most recent update to this message.
    public var updatedAt: Date?
    
    // swift-migration: original location ARTMessage.h, line 72
    /// An opaque string that uniquely identifies some referenced message.
    public var refSerial: String?
    
    // swift-migration: original location ARTMessage.h, line 75
    /// An opaque string that identifies the type of this reference.
    public var refType: String?
    
    // swift-migration: original location ARTMessage.h, line 78
    /// An object containing some optional values for the operation performed.
    public var operation: ARTMessageOperation?
    
    // swift-migration: original location ARTMessage.h, line 81
    /// An annotations summary for the message. The keys of the dict are annotation types, and the values are aggregated summaries for that annotation type.
    public var summary: ARTJsonCompatible?
    
    // swift-migration: Required initializer for NSCopying pattern
    public required init() {
        super.init()
    }
    
    // swift-migration: original location ARTMessage.h, line 89 and ARTMessage.m, line 10
    /// Construct an `ARTMessage` object with an event name and payload.
    ///
    /// - Parameters:
    ///   - name: The event name.
    ///   - data: The message payload.
    public init(name: String?, data: Any?) {
        super.init()
        self.name = name?.copy() as? String
        if data != nil {
            self.data = data
            self.encoding = ""
        }
    }
    
    // swift-migration: original location ARTMessage.h, line 98 and ARTMessage.m, line 21
    /// Construct an `ARTMessage` object with an event name, payload, and a unique client ID.
    ///
    /// - Parameters:
    ///   - name: The event name.
    ///   - data: The message payload.
    ///   - clientId: The client ID of the publisher of this message.
    public init(name: String?, data: Any?, clientId: String?) {
        super.init()
        self.name = name?.copy() as? String
        if data != nil {
            self.data = data
            self.encoding = ""
        }
        self.clientId = clientId
    }
    
    // swift-migration: original location ARTMessage.m, line 28
    public override var description: String {
        let mutableDescription = NSMutableString(string: super.description)
        let removeLength = mutableDescription.length > 2 ? 2 : 0
        mutableDescription.deleteCharacters(in: NSRange(location: mutableDescription.length - removeLength, length: removeLength))
        mutableDescription.append(",\n")
        mutableDescription.appendFormat(" name: %@\n", name ?? "nil")
        mutableDescription.appendFormat(" action: %@\n", ARTMessageActionToStr(action))
        mutableDescription.appendFormat(" serial: %@\n", serial ?? "nil")
        mutableDescription.appendFormat(" updateSerial: %@\n", updateSerial ?? "nil")
        mutableDescription.appendFormat(" version: %@\n", version ?? "nil")
        mutableDescription.appendFormat(" createdAt: %@\n", createdAt?.description ?? "nil")
        mutableDescription.appendFormat(" updatedAt: %@\n", updatedAt?.description ?? "nil")
        mutableDescription.appendFormat(" refType: %@\n", refType ?? "nil")
        mutableDescription.appendFormat(" refSerial: %@\n", refSerial ?? "nil")
        mutableDescription.appendFormat(" operation: %@\n", operation?.description ?? "nil")
        mutableDescription.appendFormat(" summary: %@\n", String(describing: summary))
        mutableDescription.append("}")
        return mutableDescription as String
    }
    
    // swift-migration: original location ARTMessage.m, line 47
    public override func copy(with zone: NSZone?) -> Any {
        let message = super.copy(with: zone) as! ARTMessage
        message.name = self.name
        message.action = self.action
        message.serial = self.serial
        message.updateSerial = self.updateSerial
        message.version = self.version
        message.createdAt = self.createdAt
        message.updatedAt = self.updatedAt
        message.operation = self.operation
        message.refType = self.refType
        message.refSerial = self.refSerial
        message.summary = self.summary
        return message
    }
    
    // swift-migration: original location ARTMessage.m, line 63
    public override func messageSize() -> Int {
        // TO3l8*
        return super.messageSize() + (name?.utf8.count ?? 0)
    }
    
    // Override decode method to return ARTMessage instead of ARTBaseMessage
    internal func decode(with encoder: ARTDataEncoder) throws -> ARTMessage {
        let decoded = try super.decode(withEncoder: encoder) as! ARTMessage
        return decoded
    }
    
    // Override encode method to return ARTMessage instead of ARTBaseMessage
    internal override func encode(with encoder: ARTDataEncoder) throws -> ARTMessage {
        let encoded = try super.encode(with: encoder) as! ARTMessage
        return encoded
    }
    
    // swift-migration: Removed additional encode method with inout Error parameter - using throws pattern instead
}

// MARK: - Decoding Extension

// swift-migration: original location ARTMessage.h, line 102 and ARTMessage.m, line 86
extension ARTMessage {
    
    // swift-migration: original location ARTMessage.h, line 112 and ARTMessage.m, line 88
    /// A static factory method to create an `ARTMessage` object from a deserialized Message-like object encoded using Ably's wire protocol.
    ///
    /// - Parameters:
    ///   - jsonObject: A `Message`-like deserialized object.
    ///   - options: An `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
    ///   - error: A pointer to an error object that will be set if the decoding fails.
    /// - Returns: An `ARTMessage` object or nil if decoding fails.
    public static func fromEncoded(_ jsonObject: [String: Any], channelOptions options: ARTChannelOptions) throws -> ARTMessage {
        let jsonEncoder = ARTJsonLikeEncoder(delegate: ARTJsonEncoder())
        
        // swift-migration: Updated to use try/catch instead of inout error parameter per PRD requirements
        let decoder: ARTDataEncoder
        do {
            decoder = try ARTDataEncoder(cipherParams: options.cipher, logger: InternalLog.sharedClassMethodLogger_readDocumentationBeforeUsing)
        } catch {
            let errorInfo = ARTErrorInfo.wrap(
                ARTErrorInfo.createWithCode(Int(ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue), message: error.localizedDescription),
                prepend: "Decoder can't be created with cipher: \(String(describing: options.cipher))"
            )
            throw errorInfo
        }
        
        guard let message = jsonEncoder.messageFromDictionary(jsonObject, protocolMessage: nil) else {
            let errorInfo = ARTErrorInfo.createWithCode(Int(ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue), message: "Failed to create message from dictionary")
            throw errorInfo
        }
        
        do {
            return try message.decode(with: decoder)
        } catch {
            let errorInfo = ARTErrorInfo.wrap(
                ARTErrorInfo.createWithCode(Int(ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue), message: error.localizedDescription),
                prepend: "Failed to decode data for message: \(message.name ?? "nil"). Decoding array aborted."
            )
            throw errorInfo
        }
    }
    
    // swift-migration: original location ARTMessage.h, line 124 and ARTMessage.m, line 118
    /// A static factory method to create an array of `ARTMessage` objects from an array of deserialized Message-like object encoded using Ably's wire protocol.
    ///
    /// - Parameters:
    ///   - jsonArray: An array of `Message`-like deserialized objects.
    ///   - options: An `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
    ///   - error: A pointer to an error object that will be set if the decoding fails.
    /// - Returns: An array of `ARTMessage` objects or nil if decoding fails.
    public static func fromEncodedArray(_ jsonArray: [[String: Any]], channelOptions options: ARTChannelOptions) throws -> [ARTMessage] {
        let jsonEncoder = ARTJsonLikeEncoder(delegate: ARTJsonEncoder())
        
        // swift-migration: Updated to use try/catch instead of inout error parameter per PRD requirements
        let decoder: ARTDataEncoder
        do {
            decoder = try ARTDataEncoder(cipherParams: options.cipher, logger: InternalLog.sharedClassMethodLogger_readDocumentationBeforeUsing)
        } catch {
            let errorInfo = ARTErrorInfo.wrap(
                ARTErrorInfo.createWithCode(Int(ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue), message: error.localizedDescription),
                prepend: "Decoder can't be created with cipher: \(String(describing: options.cipher))"
            )
            throw errorInfo
        }
        
        guard let messages = jsonEncoder.messagesFromArray(jsonArray, protocolMessage: nil) else {
            let errorInfo = ARTErrorInfo.createWithCode(Int(ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue), message: "Failed to create messages from array")
            throw errorInfo
        }
        
        var decodedMessages: [ARTMessage] = []
        for message in messages {
            do {
                let decodedMessage = try message.decode(with: decoder)
                decodedMessages.append(decodedMessage)
            } catch {
                let errorInfo = ARTErrorInfo.wrap(
                    ARTErrorInfo.createWithCode(Int(ARTErrorCode.ARTErrorUnableToDecodeMessage.rawValue), message: error.localizedDescription),
                    prepend: "Failed to decode data for message: \(message.name ?? "nil"). Decoding array aborted."
                )
                throw errorInfo
            }
        }
        return decodedMessages
    }
}
