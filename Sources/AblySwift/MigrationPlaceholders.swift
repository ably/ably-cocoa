import Foundation

// swift-migration: Placeholder types for unmigrated dependencies
// These will be replaced with actual implementations as files are migrated

// Placeholder for ARTJsonCompatible protocol
public protocol ARTJsonCompatible {
    // Placeholder implementation
}

// Placeholder for ARTDataEncoder
public class ARTDataEncoder {
    public init() {}
    
    public func decode(_ data: Any?, encoding: String?) -> ARTDataEncoderOutput {
        fatalError("ARTDataEncoder not yet migrated")
    }
    
    public func encode(_ data: Any?) -> ARTDataEncoderOutput {
        fatalError("ARTDataEncoder not yet migrated")
    }
}

// Placeholder for ARTDataEncoderOutput
public class ARTDataEncoderOutput {
    public let data: Any?
    public let encoding: String?
    public let errorInfo: ARTErrorInfo?
    
    public init(data: Any?, encoding: String?, errorInfo: ARTErrorInfo?) {
        self.data = data
        self.encoding = encoding
        self.errorInfo = errorInfo
    }
}

// Placeholder for ARTErrorInfo
public class ARTErrorInfo {
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

// Placeholder for ARTEvent
public class ARTEvent: NSObject {
    public init(string: String) {
        super.init()
        fatalError("ARTEvent not yet migrated")
    }
}

// Placeholder constants
public let ARTAblyErrorDomain = "ARTAblyErrorDomain"

// Placeholder for ARTRetryAttempt
public class ARTRetryAttempt {
    public init() {
        fatalError("ARTRetryAttempt not yet migrated")
    }
}

// Placeholder for ARTInternalLog
public class ARTInternalLog {
    public init() {
        fatalError("ARTInternalLog not yet migrated")
    }
}

// Placeholder for ARTRetryDelayCalculator protocol
public protocol ARTRetryDelayCalculator {
    // Placeholder implementation
}

// Placeholder for ARTRetrySequence
public class ARTRetrySequence {
    public let id: String = "placeholder"
    
    public init(delayCalculator: ARTRetryDelayCalculator) {
        fatalError("ARTRetrySequence not yet migrated")
    }
    
    public func addRetryAttempt() -> ARTRetryAttempt {
        fatalError("ARTRetrySequence not yet migrated")
    }
}

// Placeholder for ARTRealtimeChannelState
public enum ARTRealtimeChannelState: UInt {
    case initialized = 0
    case attaching = 1
    case attached = 2
    case detaching = 3
    case detached = 4
    case suspended = 5
    case failed = 6
}

// Placeholder logging functions
public func ARTLogDebug(_ logger: ARTInternalLog, _ message: String) {
    // Placeholder - actual implementation will inject file/line info
}

// Placeholder typealias for callbacks
public typealias ARTTokenDetailsCallback = (ARTTokenDetails?, Error?) -> Void

// Placeholder for ARTTokenDetails
public class ARTTokenDetails {
    public init() {
        fatalError("ARTTokenDetails not yet migrated")
    }
}

// Placeholder for ARTTokenParams
public class ARTTokenParams {
    public init(options: ARTClientOptions) {
        fatalError("ARTTokenParams not yet migrated")
    }
}

// Placeholder for ARTAuthOptions
public class ARTAuthOptions {
    public init() {
        fatalError("ARTAuthOptions not yet migrated")
    }
}

// Placeholder for ARTTokenRequest
public class ARTTokenRequest {
    public init() {
        fatalError("ARTTokenRequest not yet migrated")
    }
}

// Placeholder for ARTClientOptions
public class ARTClientOptions {
    public let tokenDetails: ARTTokenDetails? = nil
    public let defaultTokenParams: ARTTokenParams? = nil
    
    public init() {
        fatalError("ARTClientOptions not yet migrated")
    }
}

// Placeholder for ARTRestInternal
public class ARTRestInternal {
    public let userQueue: DispatchQueue = DispatchQueue.main
    public let queue: DispatchQueue = DispatchQueue.main
    
    public init() {
        fatalError("ARTRestInternal not yet migrated")
    }
}

// Placeholder for ARTQueuedDealloc
public class ARTQueuedDealloc {
    public init() {
        fatalError("ARTQueuedDealloc not yet migrated")
    }
}

// Placeholder for ARTEventEmitter
public class ARTEventEmitter<EventType, DataType> {
    public init(queue: DispatchQueue) {
        fatalError("ARTEventEmitter not yet migrated")
    }
}

// Placeholder for ARTInternalEventEmitter
public class ARTInternalEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo> {
    public override init(queue: DispatchQueue) {
        super.init(queue: queue)
    }
}

// Placeholder for NSString extension
extension NSString {
    @objc public static func artAddEncoding(_ encoding: String?, toString existingEncoding: String?) -> String? {
        fatalError("NSString+ARTUtil not yet migrated")
    }
}