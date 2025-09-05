import Foundation

/**
 * Enumerates the possible values of the `action` field of an `ARTAnnotation`
 */
@frozen
public enum ARTAnnotationAction: UInt, Sendable {
    /**
     * A created annotation.
     */
    case create = 0
    /**
     * A deleted annotation.
     */
    case delete = 1
}

/// :nodoc:
public func ARTAnnotationActionToStr(_ action: ARTAnnotationAction) -> String {
    switch action {
    case .create: return "create"
    case .delete: return "delete"
    }
}

/**
 * Contains an individual annotation that can be applied to messages.
 */
public class ARTAnnotation: NSObject, NSCopying, @unchecked Sendable {
    
    /// A Unique ID assigned by Ably to this message.
    public let id: String?
    
    /// The action, whether this is an annotation being added or removed, one of the `ARTAnnotationAction` enum values.
    public let action: ARTAnnotationAction
    
    /// The client ID of the publisher of this message.
    public let clientId: String?
    
    /// The name of this annotation. This is the field that most annotation aggregations will operate on. For example, using "distinct.v1" aggregation (specified in the type), the message summary will show a list of clients who have published an annotation with each distinct annotation.name.
    public let name: String?
    
    /// An optional count, only relevant to certain aggregation methods, see aggregation methods documentation for more info.
    public let count: NSNumber?
    
    /// The message payload, if provided.
    public let data: Any?
    
    /// This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
    public let encoding: String?
    
    /// Timestamp of when the message was received by Ably, as a `Date` object.
    public let timestamp: Date?
    
    /// This annotation's unique serial (lexicographically totally ordered).
    public let serial: String
    
    /// The serial of the message (of type `MESSAGE_CREATE`) that this annotation is annotating.
    public let messageSerial: String
    
    /// The type of annotation it is, typically some identifier together with an aggregation method; for example: "emoji:distinct.v1". Handled opaquely by the SDK and validated serverside.
    public let type: String
    
    /// A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
    public let extras: ARTJsonCompatible?
    
    // MARK: - Initializers
    
    public init(id: String?,
                action: ARTAnnotationAction,
                clientId: String?,
                name: String?,
                count: NSNumber?,
                data: Any?,
                encoding: String?,
                timestamp: Date?,
                serial: String,
                messageSerial: String,
                type: String,
                extras: ARTJsonCompatible?) {
        self.id = id
        self.action = action
        self.clientId = clientId
        self.name = name
        self.count = count
        self.data = data
        self.encoding = encoding
        self.timestamp = timestamp
        self.serial = serial
        self.messageSerial = messageSerial
        self.type = type
        self.extras = extras
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return ARTAnnotation(
            id: self.id,
            action: self.action,
            clientId: self.clientId,
            name: self.name,
            count: self.count,
            data: self.data,
            encoding: self.encoding,
            timestamp: self.timestamp,
            serial: self.serial,
            messageSerial: self.messageSerial,
            type: self.type,
            extras: self.extras
        )
    }
    
    // MARK: - Description
    
    public override var description: String {
        var components: [String] = []
        
        if let id = id {
            components.append("id: \(id)")
        }
        components.append("action: \(ARTAnnotationActionToStr(action))")
        if let clientId = clientId {
            components.append("clientId: \(clientId)")
        }
        if let name = name {
            components.append("name: \(name)")
        }
        if let count = count {
            components.append("count: \(count)")
        }
        if let timestamp = timestamp {
            components.append("timestamp: \(timestamp)")
        }
        components.append("serial: \(serial)")
        components.append("messageSerial: \(messageSerial)")
        components.append("type: \(type)")
        if let encoding = encoding {
            components.append("encoding: \(encoding)")
        }
        if data != nil {
            components.append("data: <present>")
        }
        if extras != nil {
            components.append("extras: <present>")
        }
        
        return "ARTAnnotation(\(components.joined(separator: ", ")))"
    }
    
    // MARK: - Encoding/Decoding
    
    /// :nodoc:
    public func decode(with encoder: ARTDataEncoder) throws -> ARTAnnotation {
        let decoded = encoder.decode(data, encoding: encoding)
        if let errorInfo = decoded.errorInfo {
            throw NSError(domain: ARTAblyErrorDomain, code: errorInfo.code, userInfo: [NSLocalizedDescriptionKey: errorInfo.message])
        }
        
        return ARTAnnotation(
            id: self.id,
            action: self.action,
            clientId: self.clientId,
            name: self.name,
            count: self.count,
            data: decoded.data,
            encoding: decoded.encoding,
            timestamp: self.timestamp,
            serial: self.serial,
            messageSerial: self.messageSerial,
            type: self.type,
            extras: self.extras
        )
    }
    
    /// :nodoc:
    public func encode(with encoder: ARTDataEncoder) throws -> ARTAnnotation {
        let encoded = encoder.encode(data)
        if let errorInfo = encoded.errorInfo {
            throw NSError(domain: ARTAblyErrorDomain, code: errorInfo.code, userInfo: [NSLocalizedDescriptionKey: errorInfo.message])
        }
        
        return ARTAnnotation(
            id: self.id,
            action: self.action,
            clientId: self.clientId,
            name: self.name,
            count: self.count,
            data: encoded.data,
            encoding: encoded.encoding,
            timestamp: self.timestamp,
            serial: self.serial,
            messageSerial: self.messageSerial,
            type: self.type,
            extras: self.extras
        )
    }
}

// MARK: - ARTEvent Extensions for Annotations
// TODO: Implement ARTEvent extensions when ARTEvent is migrated in a later phase