import Foundation

// swift-migration: original location ARTBaseMessage.h, line 9 and ARTBaseMessage.m, line 4
public class ARTBaseMessage: NSObject, NSCopying {
    
    // swift-migration: original location ARTBaseMessage.h, line 14
    /// A Unique ID assigned by Ably to this message.
    public var id: String?
    
    // swift-migration: original location ARTBaseMessage.h, line 19
    /// Timestamp of when the message was received by Ably, as a `Date` object.
    public var timestamp: Date?
    
    // Backing storage for clientId to handle setter logic
    private var _clientId: String?
    
    // swift-migration: original location ARTBaseMessage.h, line 24
    /// The client ID of the publisher of this message.
    public var clientId: String? {
        get {
            return _clientId
        }
        set {
            setClientId(newValue)
        }
    }
    
    // swift-migration: Lawrence made this nullable
    // swift-migration: original location ARTBaseMessage.h, line 29
    /// The connection ID of the publisher of this message.
    public var connectionId: String?
    
    // swift-migration: original location ARTBaseMessage.h, line 34
    /// This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
    public var encoding: String?
    
    // swift-migration: original location ARTBaseMessage.h, line 39
    /// The message payload, if provided.
    public var data: Any?
    
    // swift-migration: original location ARTBaseMessage.h, line 44
    /// A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
    public var extras: ARTJsonCompatible?
    
    // swift-migration: Required initializer for NSCopying pattern
    public required override init() {
        super.init()
    }
    
    // swift-migration: original location ARTBaseMessage.m, line 6
    private func setClientId(_ clientId: String?) {
        if let clientId = clientId {
            // swift-migration: Original Objective-C code converted UTF8String, but in Swift we can just use the string directly
            _clientId = String(clientId)
        } else {
            _clientId = nil
        }
    }
    
    // swift-migration: original location ARTBaseMessage.h, line 47 and ARTBaseMessage.m, line 16
    public func copy(with zone: NSZone?) -> Any {
        let message = type(of: self).init()
        message.id = self.id
        message._clientId = self.clientId
        message.timestamp = self.timestamp
        message.data = (self.data as? NSCopying)?.copy(with: zone) ?? self.data
        message.connectionId = self.connectionId
        message.encoding = self.encoding
        message.extras = self.extras
        return message
    }
    
    // swift-migration: original location ARTBaseMessage+Private.h, line 12 and ARTBaseMessage.m, line 28
    internal func decode(withEncoder encoder: ARTDataEncoder) throws -> ARTBaseMessage {
        let decoded = encoder.decode(self.data, encoding: self.encoding)
        if let errorInfo = decoded.errorInfo {
            throw NSError(domain: ARTAblyErrorDomain, code: errorInfo.code, userInfo: [
                NSLocalizedDescriptionKey: "decoding failed",
                NSLocalizedFailureReasonErrorKey: errorInfo.message
            ])
        }
        let ret = self.copy() as! ARTBaseMessage
        ret.data = decoded.data
        ret.encoding = decoded.encoding
        return ret
    }
    
    // swift-migration: original location ARTBaseMessage+Private.h, line 13 and ARTBaseMessage.m, line 40
    internal func encode(with encoder: ARTDataEncoder) throws -> ARTBaseMessage {
        let encoded = encoder.encode(self.data)
        if let errorInfo = encoded.errorInfo {
            throw NSError(domain: ARTAblyErrorDomain, code: 0, userInfo: [
                NSLocalizedDescriptionKey: "encoding failed",
                NSLocalizedFailureReasonErrorKey: errorInfo.message
            ])
        }
        let ret = self.copy() as! ARTBaseMessage
        ret.data = encoded.data
        ret.encoding = NSString.artAddEncoding(encoded.encoding, toString: self.encoding)
        return ret
    }
    
    // swift-migration: original location ARTBaseMessage.h, line 47 and ARTBaseMessage.m, line 52
    public override var description: String {
        var description = "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque())> {\n"
        description += " id: \(String(describing: id)),\n"
        description += " clientId: \(String(describing: clientId)),\n"
        description += " connectionId: \(connectionId),\n"
        description += " timestamp: \(String(describing: timestamp)),\n"
        description += " encoding: \(String(describing: encoding)),\n"
        description += " data: \(String(describing: data))\n"
        description += " extras: \(String(describing: extras))\n"
        description += "}"
        return description
    }
    
    // swift-migration: original location ARTBaseMessage.h, line 50 and ARTBaseMessage.m, line 65
    public func messageSize() -> Int {
        // TO3l8*
        var finalResult = 0
        if let extras = self.extras {
            if let jsonString = extras.toJSONString() {
                finalResult += jsonString.utf8.count
            }
        }
        if let clientId = self.clientId {
            finalResult += clientId.utf8.count
        }
        if let data = self.data {
            if let stringData = data as? String {
                finalResult += stringData.utf8.count
            } else if let nsData = data as? Data {
                finalResult += nsData.count
            } else {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data, options: .withoutEscapingSlashes)
                    finalResult += jsonData.count
                } catch {
                    // Ignore error, don't add to size
                }
            }
        }
        return finalResult
    }
    
    // swift-migration: original location ARTBaseMessage+Private.h, line 10 and ARTBaseMessage.m, line 91
    internal var isIdEmpty: Bool {
        return id == nil || id == ""
    }
}
