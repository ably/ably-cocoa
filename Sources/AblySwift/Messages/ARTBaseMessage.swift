import Foundation

/**
 A base interface for an `ARTMessage` and an `ARTPresenceMessage` objects.
 */
open class ARTBaseMessage: NSObject, NSCopying, @unchecked Sendable {
    
    /**
     * A Unique ID assigned by Ably to this message.
     */
    public var id: String?
    
    /**
     * Timestamp of when the message was received by Ably, as a `Date` object.
     */
    public var timestamp: Date?
    
    /**
     * The client ID of the publisher of this message.
     */
    public var clientId: String?
    
    /**
     * The connection ID of the publisher of this message.
     */
    public var connectionId: String = ""
    
    /**
     * This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
     */
    public var encoding: String?
    
    /**
     * The message payload, if provided.
     */
    public var data: Any?
    
    /**
     * A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
     */
    public var extras: ARTJsonCompatible?
    
    // MARK: - Initializers
    
    public required override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = type(of: self).init()
        copy.id = self.id
        copy.timestamp = self.timestamp
        copy.clientId = self.clientId
        copy.connectionId = self.connectionId
        copy.encoding = self.encoding
        copy.data = self.data
        copy.extras = self.extras
        return copy
    }
    
    // MARK: - Description
    
    public override var description: String {
        var components: [String] = []
        
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
        if extras != nil {
            components.append("extras: <present>")
        }
        
        return "\(String(describing: type(of: self)))(\(components.joined(separator: ", ")))"
    }
    
    // MARK: - Message Size
    
    /// :nodoc:
    public func messageSize() -> Int {
        var size = 0
        
        if let id = id {
            size += id.utf8.count
        }
        if let clientId = clientId {
            size += clientId.utf8.count
        }
        size += connectionId.utf8.count
        if let encoding = encoding {
            size += encoding.utf8.count
        }
        
        // Estimate data size based on type
        if let data = data {
            if let stringData = data as? String {
                size += stringData.utf8.count
            } else if let dataData = data as? Data {
                size += dataData.count
            } else if let dictData = data as? [String: Any] {
                // Rough estimate for dictionary
                size += dictData.description.utf8.count
            } else if let arrayData = data as? [Any] {
                // Rough estimate for array
                size += arrayData.description.utf8.count
            } else {
                // Fallback to description size
                size += String(describing: data).utf8.count
            }
        }
        
        return size
    }
    
    // MARK: - Private Properties
    
    /// :nodoc:
    public var isIdEmpty: Bool {
        return id?.isEmpty != false
    }
    
    // MARK: - Encoding/Decoding
    
    /// :nodoc:
    public func decode(with encoder: ARTDataEncoder) throws -> ARTBaseMessage {
        let decoded = encoder.decode(data, encoding: encoding)
        if let errorInfo = decoded.errorInfo {
            throw NSError(domain: ARTAblyErrorDomain, code: errorInfo.code, userInfo: [NSLocalizedDescriptionKey: errorInfo.message])
        }
        
        let copy = self.copy() as! ARTBaseMessage
        copy.data = decoded.data
        copy.encoding = decoded.encoding
        return copy
    }
    
    /// :nodoc:
    public func encode(with encoder: ARTDataEncoder) throws -> ARTBaseMessage {
        let encoded = encoder.encode(data)
        if let errorInfo = encoded.errorInfo {
            throw NSError(domain: ARTAblyErrorDomain, code: errorInfo.code, userInfo: [NSLocalizedDescriptionKey: errorInfo.message])
        }
        
        let copy = self.copy() as! ARTBaseMessage
        copy.data = encoded.data
        copy.encoding = encoded.encoding
        return copy
    }
}