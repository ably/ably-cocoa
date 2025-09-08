import Foundation

// swift-migration: Placeholder types for unmigrated dependencies
// These will be replaced with actual implementations as files are migrated

// Placeholder for ARTJsonCompatible protocol
public protocol ARTJsonCompatible {
    func toJSON() throws -> [String: Any]?
    func toJSONString() -> String?
}

// Placeholder for ARTDataEncoder
public class ARTDataEncoder {
    public init() {}
    
    public init(cipherParams: ARTCipherParams?, logger: ARTInternalLog, error: inout Error?) {
        fatalError("ARTDataEncoder not yet migrated")
    }
    
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
    
    public static func createFromNSError(_ error: Error) -> ARTErrorInfo {
        fatalError("ARTErrorInfo createFromNSError not yet migrated")
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

// Placeholder for ARTRealtimeConnectionState
public enum ARTRealtimeConnectionState: UInt {
    case initialized = 0
    case connecting = 1
    case connected = 2
    case disconnected = 3
    case suspended = 4
    case closing = 5
    case closed = 6
    case failed = 7
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
    
    public func toArray(withUnion other: [URLQueryItem]?) -> [URLQueryItem] {
        fatalError("ARTTokenParams not yet migrated")
    }
    
    public func toDictionary(withUnion other: [URLQueryItem]?) -> [String: String] {
        fatalError("ARTTokenParams not yet migrated")
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

// swift-migration: ARTClientOptions placeholder removed - now implemented

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
    _ callback: ARTTokenDetailsCompatibleCallback,
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

// Placeholder for ARTJitterCoefficientGenerator protocol
public protocol ARTJitterCoefficientGenerator {
    func generateJitterCoefficient() -> Double
}

// Placeholder for ARTCallback
public typealias ARTCallback = (ARTErrorInfo?) -> Void

// Placeholder for ARTMessage
public class ARTMessage: ARTBaseMessage {
    // Note: extras property is inherited from ARTBaseMessage
    
    // swift-migration: ARTMessage inherits from ARTBaseMessage but adds message-specific functionality
    public required init() {
        super.init()
        fatalError("ARTMessage not yet migrated")
    }
    
    public init(name: String?, data: Any?) {
        super.init()
        fatalError("ARTMessage not yet migrated")
    }
    
    public init(name: String?, data: Any?, clientId: String?) {
        super.init()
        fatalError("ARTMessage not yet migrated")
    }
    
    public func encode(with encoder: ARTDataEncoder, error: inout Error?) -> ARTMessage {
        fatalError("ARTMessage encode not yet migrated")
    }
}

// Placeholder for ARTPaginatedResult
public class ARTPaginatedResult<ItemType> {
    public init() {
        fatalError("ARTPaginatedResult not yet migrated")
    }
}

// Placeholder callback types
public typealias ARTPaginatedMessagesCallback = (ARTPaginatedResult<ARTMessage>?, ARTErrorInfo?) -> Void

// Placeholder for ARTState enum
public enum ARTState: UInt {
    case ok = 0
    case connectionClosedByClient
    case connectionDisconnected
    case connectionSuspended
    case connectionFailed
    case accessRefused
    case neverConnected
    case connectionTimedOut
    case attachTimedOut
    case detachTimedOut
    case notAttached
    case invalidArgs
    case cryptoBadPadding
    case noClientId
    case mismatchedClientId
    case requestTokenFailed
    case authorizationFailed
    case authUrlIncompatibleContent
    case badConnectionState
    case error = 99999
}

// These placeholders will be replaced by the actual ARTChannelOptions implementation

// Placeholder for ARTCipherParams
public class ARTCipherParams {
    public init() {
        fatalError("ARTCipherParams not yet migrated")
    }
}

// Placeholder protocols for ARTChannelOptions dependencies
public protocol ARTCipherParamsCompatible {
    func toCipherParams() -> ARTCipherParams
}

public protocol ARTCipherKeyCompatible {
}

// Extension to make Dictionary conform to ARTCipherParamsCompatible, just like the original Objective-C
extension Dictionary: ARTCipherParamsCompatible where Key == String {
    public func toCipherParams() -> ARTCipherParams {
        fatalError("Dictionary.toCipherParams() not yet implemented")
    }
}

// swift-migration: ARTDefault placeholder removed - now implemented

// Placeholder constants for error codes
public let ARTErrorMaxMessageLengthExceeded: Int = 40009

// Placeholder logging functions
public func ARTLogWarn(_ logger: ARTInternalLog, _ message: String) {
    // Placeholder - actual implementation will inject file/line info
}

public func ARTLogError(_ logger: ARTInternalLog, _ message: String) {
    // Placeholder - actual implementation will inject file/line info
}

// Placeholder for NSStringDictionary
public typealias NSStringDictionary = [String: String]

// Placeholder for ARTChannelsDelegate protocol
internal protocol ARTChannelsDelegate: AnyObject {
    func makeChannel(_ channel: String, options: ARTChannelOptions?) -> ARTChannel
}

// Placeholder for ARTRestChannel
internal class ARTRestChannel: ARTChannel {
    internal override init(name: String, andOptions options: ARTChannelOptions, rest: ARTRestInternal, logger: ARTInternalLog) {
        super.init(name: name, andOptions: options, rest: rest, logger: logger)
        fatalError("ARTRestChannel not yet migrated")
    }
}

// Additional placeholders for ARTClientOptions dependencies

// swift-migration: ARTDefault extension placeholder removed - now implemented

// swift-migration: ARTDefaultProduction placeholder removed - now implemented

// Placeholder for ARTLog class
public class ARTLog {
    public init() {
        // Empty init for now
    }
}

// Placeholder for ARTLogLevel enum
public enum ARTLogLevel: UInt {
    case none = 0
    case verbose = 1
    case debug = 2
    case info = 3
    case warn = 4
    case error = 5
}

// Placeholder for ARTStringifiable protocol
public protocol ARTStringifiable {
    func toString() -> String
}

// Placeholder for ARTPushRegistererDelegate protocol  
public protocol ARTPushRegistererDelegate {
    // Placeholder methods
}

// Placeholder for ARTTestClientOptions class
public class ARTTestClientOptions {
    public init() {
        // Empty init for now
    }
}

// Placeholder for ARTPluginAPI class
public class ARTPluginAPI {
    public static func registerSelf() {
        // Placeholder implementation
    }
}

// Placeholder for plugin protocols
public protocol APLiveObjectsPluginProtocol {
    static func internalPlugin() -> APLiveObjectsInternalPluginProtocol
}

public protocol APLiveObjectsInternalPluginProtocol {
    // Placeholder protocol
}

// Extend ARTTokenParams to add missing initializer
extension ARTTokenParams {
    public convenience init(tokenParams: ARTTokenParams) {
        fatalError("ARTTokenParams init(tokenParams:) not yet migrated")
    }
}

// Placeholder for ARTQueryDirection enum
public enum ARTQueryDirection: UInt {
    case forwards = 0
    case backwards = 1
}

// Placeholder for ARTRealtimeChannelInternal
public class ARTRealtimeChannelInternal {
    public var state_nosync: ARTRealtimeChannelState = .initialized
    public var attachSerial: String = ""
    
    public init() {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
}

// Functions already used in the codebase - need to make sure they exist
public func dateToMilliseconds(_ date: Date) -> UInt64 {
    return UInt64(date.timeIntervalSince1970 * 1000)
}

// Placeholder for ARTRealtimeHistoryError enum
public enum ARTRealtimeHistoryError: Int {
    case notAttached = 3  // ARTDataQueryErrorTimestampRange + 1
}

// swift-migration: ARTClientInformation placeholder removed - now implemented

// Extension for Array to provide artMap functionality
extension Array {
    internal func artMap<T>(_ transform: (Element) -> T) -> [T] {
        return self.map(transform)
    }
}