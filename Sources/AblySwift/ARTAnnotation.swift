import Foundation

// swift-migration: original location ARTTypes.h, line 9
/// Enumerates the possible values of the `action` field of an `ARTAnnotation`
public enum ARTAnnotationAction: UInt, Sendable {
    /// A created annotation.
    case create = 0
    /// A deleted annotation.
    case delete = 1
}

// swift-migration: original location ARTAnnotation.h, line 21
/// :nodoc:
func ARTAnnotationActionToStr(_ action: ARTAnnotationAction) -> String {
    switch action {
    case .create:
        return "Create" // 0
    case .delete:
        return "Delete" // 1
    }
}

// swift-migration: original location ARTAnnotation.h, line 26 and ARTAnnotation.m, line 8
public class ARTAnnotation: NSObject, NSCopying, Sendable {
    
    // swift-migration: original location ARTAnnotation.h, line 29
    /// A Unique ID assigned by Ably to this message.
    public let id: String?
    
    // swift-migration: original location ARTAnnotation.h, line 32
    /// The action, whether this is an annotation being added or removed, one of the `ARTAnnotationAction` enum values.
    public let action: ARTAnnotationAction
    
    // swift-migration: original location ARTAnnotation.h, line 35
    /// The client ID of the publisher of this message.
    public let clientId: String?
    
    // swift-migration: original location ARTAnnotation.h, line 38
    /// The name of this annotation. This is the field that most annotation aggregations will operate on. For example, using "distinct.v1" aggregation (specified in the type), the message summary will show a list of clients who have published an annotation with each distinct annotation.name.
    public let name: String?
    
    // swift-migration: original location ARTAnnotation.h, line 41
    /// An optional count, only relevant to certain aggregation methods, see aggregation methods documentation for more info.
    public let count: NSNumber?
    
    // swift-migration: original location ARTAnnotation.h, line 44
    /// The message payload, if provided.
    public let data: Any?
    
    // swift-migration: original location ARTAnnotation.h, line 47
    /// This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
    public let encoding: String?
    
    // swift-migration: original location ARTAnnotation.h, line 50
    /// Timestamp of when the message was received by Ably, as a `NSDate` object.
    public let timestamp: Date?
    
    // swift-migration: original location ARTAnnotation.h, line 53
    /// This annotation's unique serial (lexicographically totally ordered).
    public let serial: String
    
    // swift-migration: original location ARTAnnotation.h, line 56
    /// The serial of the message (of type `MESSAGE_CREATE`) that this annotation is annotating.
    public let messageSerial: String
    
    // swift-migration: original location ARTAnnotation.h, line 59
    /// The type of annotation it is, typically some identifier together with an aggregation method; for example: "emoji:distinct.v1". Handled opaquely by the SDK and validated serverside.
    public let type: String
    
    // swift-migration: original location ARTAnnotation.h, line 62
    /// A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
    public let extras: ARTJsonCompatible?
    
    // swift-migration: original location ARTAnnotation.h, line 64 and ARTAnnotation.m, line 10
    public init(
        id annotationId: String?,
        action: ARTAnnotationAction,
        clientId: String?,
        name: String?,
        count: NSNumber?,
        data: Any?,
        encoding: String?,
        timestamp: Date,
        serial: String,
        messageSerial: String,
        type: String,
        extras: ARTJsonCompatible?
    ) {
        self.id = annotationId
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
    
    // swift-migration: original location ARTAnnotation.m, line 39
    public override var description: String {
        var description = super.description
        let endIndex = description.index(description.endIndex, offsetBy: -2)
        if description.count > 2 {
            description = String(description[..<endIndex])
        }
        description += ",\n"
        description += " id: \(String(describing: self.id)),\n"
        description += " action: \(ARTAnnotationActionToStr(self.action))\n"
        description += " clientId: \(String(describing: self.clientId)),\n"
        description += " name: \(String(describing: self.name))\n"
        description += " count: \(String(describing: self.count))\n"
        description += " data: \(String(describing: self.data))\n"
        description += " encoding: \(String(describing: self.encoding)),\n"
        description += " timestamp: \(String(describing: self.timestamp)),\n"
        description += " serial: \(String(describing: self.serial))\n"
        description += " messageSerial: \(String(describing: self.messageSerial))\n"
        description += " type: \(String(describing: self.type))\n"
        description += " extras: \(String(describing: self.extras))\n"
        description += "}"
        return description
    }
    
    // swift-migration: original location NSCopying protocol and ARTAnnotation.m, line 59
    public func copy(with zone: NSZone? = nil) -> Any {
        let annotation = ARTAnnotation(
            id: self.id,
            action: self.action,
            clientId: self.clientId,
            name: self.name,
            count: self.count,
            data: self.data,
            encoding: self.encoding,
            timestamp: self.timestamp ?? Date(),
            serial: self.serial,
            messageSerial: self.messageSerial,
            type: self.type,
            extras: self.extras
        )
        return annotation
    }
    
    // swift-migration: original location ARTAnnotation+Private.h, line 9 and ARTBaseMessage.m, line (inherited)
    /// Private computed property - inherited from ARTBaseMessage
    internal var isIdEmpty: Bool {
        return id == nil || id == ""
    }
    
    // swift-migration: original location ARTAnnotation+Private.h, line 11 and ARTAnnotation.m, line 76
    internal func decode(with encoder: ARTDataEncoder) throws -> ARTAnnotation {
        let decoded = encoder.decode(self.data, encoding: self.encoding)
        if let errorInfo = decoded.errorInfo {
            throw NSError(
                domain: ARTAblyErrorDomain,
                code: errorInfo.code,
                userInfo: [
                    NSLocalizedDescriptionKey: "decoding failed",
                    NSLocalizedFailureReasonErrorKey: errorInfo.message
                ]
            )
        }
        let ret = self.copy() as! ARTAnnotation
        return ARTAnnotation(
            id: ret.id,
            action: ret.action,
            clientId: ret.clientId,
            name: ret.name,
            count: ret.count,
            data: decoded.data,
            encoding: decoded.encoding,
            timestamp: ret.timestamp ?? Date(),
            serial: ret.serial,
            messageSerial: ret.messageSerial,
            type: ret.type,
            extras: ret.extras
        )
    }
    
    // swift-migration: original location ARTAnnotation+Private.h, line 12 and ARTAnnotation.m, line 88
    internal func encode(with encoder: ARTDataEncoder) throws -> ARTAnnotation {
        let encoded = encoder.encode(self.data)
        if let errorInfo = encoded.errorInfo {
            throw NSError(
                domain: ARTAblyErrorDomain,
                code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey: "encoding failed",
                    NSLocalizedFailureReasonErrorKey: errorInfo.message
                ]
            )
        }
        let ret = self.copy() as! ARTAnnotation
        let newEncoding = NSString.artAddEncoding(encoded.encoding, toString: self.encoding)
        return ARTAnnotation(
            id: ret.id,
            action: ret.action,
            clientId: ret.clientId,
            name: ret.name,
            count: ret.count,
            data: encoded.data,
            encoding: newEncoding,
            timestamp: ret.timestamp ?? Date(),
            serial: ret.serial,
            messageSerial: ret.messageSerial,
            type: ret.type,
            extras: ret.extras
        )
    }
}

// swift-migration: original location ARTAnnotation.m, line 114
extension ARTEvent {
    // swift-migration: original location ARTAnnotation.m, line 116
    convenience init(annotationType type: String) {
        self.init(string: "ARTAnnotation:\(type)")
    }
    
    // swift-migration: original location ARTAnnotation.m, line 120
    class func new(withAnnotationType type: String) -> ARTEvent {
        return ARTEvent(annotationType: type)
    }
}