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
public class ARTErrorInfo: Error {
    public let code: Int
    public let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    public static func create(withCode code: Int, message: String) -> ARTErrorInfo {
        return ARTErrorInfo(code: code, message: message)
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
    public let clientId: String? = nil
    public let token: String? = nil
    public let expires: Date? = nil
    
    public init() {
        fatalError("ARTTokenDetails not yet migrated")
    }
    
    public init(token: String) {
        fatalError("ARTTokenDetails not yet migrated")
    }
    
    public func copy() -> ARTTokenDetails {
        fatalError("ARTTokenDetails not yet migrated")
    }
}

// Placeholder for ARTTokenParams
public class ARTTokenParams {
    public var capability: String? = nil
    public var timestamp: Date? = nil
    public var clientId: String? = nil
    
    public init(options: ARTClientOptions) {
        fatalError("ARTTokenParams not yet migrated")
    }
    
    public func copy() -> ARTTokenParams {
        fatalError("ARTTokenParams not yet migrated")
    }
    
    public func sign(_ key: String) -> ARTTokenRequest {
        fatalError("ARTTokenParams not yet migrated")
    }
    
    public func toArray(withUnion other: [String: String]?) -> [URLQueryItem] {
        fatalError("ARTTokenParams not yet migrated")
    }
    
    public func toDictionary(withUnion other: [String: String]?) -> [String: String] {
        fatalError("ARTTokenParams not yet migrated")
    }
}

// Placeholder for ARTAuthOptions
public class ARTAuthOptions {
    public var authUrl: URL? = nil
    public var authCallback: ARTAuthCallback? = nil
    public var key: String? = nil
    public var token: String? = nil
    public var tokenDetails: ARTTokenDetails? = nil
    public var authHeaders: [String: String]? = nil
    public var authMethod: String = "GET"
    public var authParams: [String: String]? = nil
    public var useTokenAuth: Bool = false
    public var queryTime: Bool = false
    
    public init() {
        fatalError("ARTAuthOptions not yet migrated")
    }
    
    public func copy() -> ARTAuthOptions {
        fatalError("ARTAuthOptions not yet migrated")
    }
    
    public func isMethodGET() -> Bool {
        return authMethod.uppercased() == "GET"
    }
    
    public func isMethodPOST() -> Bool {
        return authMethod.uppercased() == "POST"
    }
}

// Placeholder for ARTTokenRequest
public class ARTTokenRequest {
    public let keyName: String? = nil
    
    public init() {
        fatalError("ARTTokenRequest not yet migrated")
    }
    
    public func toTokenDetails(_ auth: ARTAuth, callback: @escaping ARTTokenDetailsCallback) {
        fatalError("ARTTokenRequest not yet migrated")
    }
}

// Placeholder for ARTClientOptions - inherits from ARTAuthOptions  
public class ARTClientOptions: ARTAuthOptions {
    public var defaultTokenParams: ARTTokenParams? = nil
    public var clientId: String? = nil
    public var tls: Bool = true
    
    public override init() {
        super.init()
        fatalError("ARTClientOptions not yet migrated")
    }
    
    public func isBasicAuth() -> Bool {
        fatalError("ARTClientOptions not yet migrated")
    }
    
    public func merge(with other: ARTAuthOptions) -> ARTAuthOptions {
        fatalError("ARTClientOptions not yet migrated")
    }
}

// Placeholder for ARTRestInternal
public class ARTRestInternal {
    public let userQueue: DispatchQueue = DispatchQueue.main
    public let queue: DispatchQueue = DispatchQueue.main
    public let baseUrl: URL = URL(string: "https://rest.ably.io")!
    public let defaultEncoder: ARTEncoder = ARTEncoder()
    public let encoders: [String: ARTEncoder] = [:]
    public let device_nosync: ARTLocalDevice = ARTLocalDevice()
    public let storage: ARTLocalDeviceStorage = ARTLocalDeviceStorage()
    public let push: ARTPush = ARTPush()
    
    public init() {
        fatalError("ARTRestInternal not yet migrated")
    }
    
    public func executeRequest(
        _ request: URLRequest,
        withAuthOption authOption: ARTAuthentication,
        wrapperSDKAgents: [String]?,
        completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void
    ) -> ARTCancellable {
        fatalError("ARTRestInternal not yet migrated")
    }
    
    public func _time(
        withWrapperSDKAgents: [String]?,
        completion: @escaping (Date?, Error?) -> Void
    ) -> ARTCancellable {
        fatalError("ARTRestInternal not yet migrated")
    }
}

// Placeholder for ARTQueuedDealloc
public class ARTQueuedDealloc {
    public init() {
        fatalError("ARTQueuedDealloc not yet migrated")
    }
    
    public init(object: Any, queue: DispatchQueue) {
        fatalError("ARTQueuedDealloc not yet migrated")
    }
}

// Placeholder for ARTEventEmitter
public class ARTEventEmitter<EventType, DataType> {
    public init(queue: DispatchQueue) {
        fatalError("ARTEventEmitter not yet migrated")
    }
    
    public func once(_ callback: @escaping (DataType?) -> Void) {
        fatalError("ARTEventEmitter not yet migrated")
    }
    
    public func emit(_ event: EventType?, with data: DataType?) {
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

// Additional placeholder types and constants needed by ARTAuth

// Placeholder for ARTEncoder
public class ARTEncoder {
    public init() {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func formatAsString() -> String {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func mimeType() -> String {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeTokenRequest(_ request: ARTTokenRequest, error: inout Error?) -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeTokenDetails(_ data: Data, error: inout Error?) -> ARTTokenDetails? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeTokenRequest(_ data: Data, error: inout Error?) -> ARTTokenRequest? {
        fatalError("ARTEncoder not yet migrated")
    }
}

// Placeholder for ARTLocalDevice
public class ARTLocalDevice {
    public var clientId: String? = nil
    
    public init() {
        fatalError("ARTLocalDevice not yet migrated")
    }
    
    public func setClientId(_ clientId: String?) {
        fatalError("ARTLocalDevice not yet migrated")
    }
}

// Placeholder for ARTLocalDeviceStorage
public class ARTLocalDeviceStorage {
    public init() {
        fatalError("ARTLocalDeviceStorage not yet migrated")
    }
    
    public func setObject(_ object: Any?, forKey key: String) {
        fatalError("ARTLocalDeviceStorage not yet migrated")
    }
}

// Placeholder for ARTPush
public class ARTPush {
    public init() {
        fatalError("ARTPush not yet migrated")
    }
    
    public func getActivationMachine(_ callback: @escaping (ARTPushActivationStateMachine) -> Void) {
        fatalError("ARTPush not yet migrated")
    }
}

// Placeholder for ARTPushActivationStateMachine
public class ARTPushActivationStateMachine {
    public let current_nosync: ARTPushActivationState = ARTPushActivationStateNotActivated()
    
    public init() {
        fatalError("ARTPushActivationStateMachine not yet migrated")
    }
    
    public func sendEvent(_ event: ARTPushActivationEvent) {
        fatalError("ARTPushActivationStateMachine not yet migrated")
    }
}

// Placeholder for ARTPushActivationState
public class ARTPushActivationState {
    public init() {
        fatalError("ARTPushActivationState not yet migrated")
    }
}

// Placeholder for ARTPushActivationStateNotActivated
public class ARTPushActivationStateNotActivated: ARTPushActivationState {
    public override init() {
        super.init()
    }
}

// Placeholder for ARTPushActivationEvent
public class ARTPushActivationEvent {
    public init() {
        fatalError("ARTPushActivationEvent not yet migrated")
    }
}

// Placeholder for ARTPushActivationEventGotPushDeviceDetails
public class ARTPushActivationEventGotPushDeviceDetails: ARTPushActivationEvent {
    public override init() {
        super.init()
    }
}

// Placeholder for ARTCancellable protocol
public protocol ARTCancellable {
    func cancel()
}

// Placeholder for ARTAuthentication enum
public enum ARTAuthentication: Int {
    case off = 0
    case on = 1
    case useBasic = 2
    case newToken = 3
}

// Placeholder constants
public let ARTAuthenticationOff = ARTAuthentication.off

// Placeholder for ARTAuthMethod enum
public enum ARTAuthMethod: Int {
    case basic = 0
    case token = 1
}

public let ARTAuthMethodBasic = ARTAuthMethod.basic
public let ARTAuthMethodToken = ARTAuthMethod.token

// Placeholder for ARTTokenDetailsCompatible protocol
public protocol ARTTokenDetailsCompatible {
    func toTokenDetails(_ auth: ARTAuth, callback: @escaping ARTTokenDetailsCallback)
}

// Placeholder callback types
public typealias ARTTokenDetailsCompatibleCallback = (ARTTokenDetailsCompatible?, Error?) -> Void
public typealias ARTAuthCallback = (ARTTokenParams?, @escaping ARTTokenDetailsCompatibleCallback) -> Void

// Placeholder logging functions
public func ARTLogVerbose(_ logger: ARTInternalLog, _ message: String) {
    // Placeholder
}

public func ARTFormEncode(_ dictionary: [String: String]) -> String {
    fatalError("ARTFormEncode not yet migrated")
}

// Placeholder function for creating cancellable from callback
public func artCancellableFromCallback(
    _ callback: @escaping ARTTokenDetailsCompatibleCallback,
    _ safeCallback: inout ARTTokenDetailsCompatibleCallback?
) -> ARTCancellable {
    fatalError("artCancellableFromCallback not yet migrated")
}

// Error constants placeholder
public let ARTStateRequestTokenFailed = 40170
public let ARTAblyMessageNoMeansToRenewToken = "No means to renew token"
public let ARTErrorErrorFromClientTokenCallback = 80019
public let ARTErrorIncompatibleCredentials = 40102
public let ARTStateAuthUrlIncompatibleContent = 40170
public let ARTClientIdKey = "ARTClientIdKey"
public let kCFURLErrorCancelled: CFIndex = -999