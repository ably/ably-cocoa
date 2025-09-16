import Foundation

// swift-migration: original location ARTRealtimeTransport+Private.h, line 15
public enum ARTRealtimeTransportErrorType: UInt, Sendable {
    case other = 0
    case hostUnreachable = 1
    case noInternet = 2
    case timeout = 3
    case badResponse = 4
    case refused = 5
}

// swift-migration: original location ARTRealtimeTransport+Private.h, line 24
public enum ARTRealtimeTransportState: UInt, Sendable {
    case opening = 0
    case opened = 1
    case closing = 2
    case closed = 3
}

// swift-migration: original location ARTRealtimeTransport+Private.h, line 31 and ARTRealtimeTransport.m, line 4
public class ARTRealtimeTransportError: NSObject {
    public var error: Error
    public var type: ARTRealtimeTransportErrorType
    /**
     This meaning of this property is only defined if the error is of type `ARTRealtimeTransportErrorTypeBadResponse`.
     */
    public var badResponseCode: Int = 0
    public var url: URL
    
    // swift-migration: original location ARTRealtimeTransport+Private.h, line 41 and ARTRealtimeTransport.m, line 6
    public init(error: Error, type: ARTRealtimeTransportErrorType, url: URL) {
        self.error = error
        self.type = type
        self.url = url
        super.init()
    }
    
    // swift-migration: original location ARTRealtimeTransport+Private.h, line 42 and ARTRealtimeTransport.m, line 16
    public init(error: Error, badResponseCode: Int, url: URL) {
        self.error = error
        self.type = .badResponse
        self.url = url
        self.badResponseCode = badResponseCode
        super.init()
    }
    
    // swift-migration: original location ARTRealtimeTransport+Private.h, line 44 and ARTRealtimeTransport.m, line 24
    public override var description: String {
        let description = NSMutableString(format: "<ARTRealtimeTransportError: %p {\n", self)
        description.appendFormat("  type: %@\n", ARTRealtimeTransportError.typeDescription(type) as NSString)
        description.appendFormat("  badResponseCode: %ld\n", badResponseCode)
        description.appendFormat("  url: %@\n", url as NSURL)
        description.appendFormat("  error: %@\n", error as NSError)
        description.appendFormat("}>")
        return description as String
    }
    
    // swift-migration: original location ARTRealtimeTransport.m, line 34
    public static func typeDescription(_ type: ARTRealtimeTransportErrorType) -> String {
        switch type {
        case .other:
            return "Other"
        case .hostUnreachable:
            return "Unreachable"
        case .noInternet:
            return "NoInternet"
        case .timeout:
            return "Timeout"
        case .badResponse:
            return "BadResponse"
        case .refused:
            return "Refused"
        }
    }
}

// swift-migration: original location ARTRealtimeTransport+Private.h, line 48
public protocol ARTRealtimeTransportDelegate: AnyObject {
    // All methods must be called from rest's serial queue.
    
    func realtimeTransport(_ transport: ARTRealtimeTransport, didReceiveMessage message: ARTProtocolMessage)
    
    func realtimeTransportAvailable(_ transport: ARTRealtimeTransport)
    
    func realtimeTransportClosed(_ transport: ARTRealtimeTransport)
    func realtimeTransportDisconnected(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?)
    func realtimeTransportNeverConnected(_ transport: ARTRealtimeTransport)
    func realtimeTransportRefused(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?)
    func realtimeTransportTooBig(_ transport: ARTRealtimeTransport)
    func realtimeTransportFailed(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError)
    
    func realtimeTransportSetMsgSerial(_ transport: ARTRealtimeTransport, msgSerial: Int64)
}

// swift-migration: original location ARTRealtimeTransport+Private.h, line 67
public protocol ARTRealtimeTransport: AnyObject {
    // All methods must be called from rest's serial queue.
    
    // swift-migration: Lawrence changed this to optional (that's what the initializer accepts and I think that's what makes sense)
    var resumeKey: String? { get }
    var state: ARTRealtimeTransportState { get }
    var delegate: ARTRealtimeTransportDelegate? { get set }
    var stateEmitter: ARTEventEmitter<ARTEvent, Any> { get }
    
    func send(_ data: Data, withSource decodedObject: Any) -> Bool
    func receive(_ msg: ARTProtocolMessage)
    func receive(with data: Data) -> ARTProtocolMessage?
    func connect(withKey key: String)
    func connect(withToken token: String)
    func sendClose()
    func sendPing()
    func close()
    func abort(_ reason: ARTStatus)
    func host() -> String
    func setHost(_ host: String)
}
