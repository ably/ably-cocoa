import Foundation

// swift-migration: Placeholder types for unmigrated dependencies
// These will be replaced with actual implementations as files are migrated

// Placeholder for ARTJsonCompatible protocol
public protocol ARTJsonCompatible {
    func toJSON() throws -> [String: Any]?
    func toJSONString() -> String?
}

// ARTDataEncoder and ARTDataEncoderOutput implemented in ARTDataEncoder.swift

// swift-migration: ARTErrorInfo placeholder removed - now implemented in ARTStatus.swift

// ARTEvent implemented in ARTEventEmitter.swift

// swift-migration: ARTAblyErrorDomain constant now defined in ARTStatus.swift

// Placeholder for ARTRetryAttempt
public class ARTRetryAttempt {
    public init() {
        fatalError("ARTRetryAttempt not yet migrated")
    }
}

// ARTInternalLog implemented in ARTInternalLog.swift

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

// swift-migration: ARTTokenDetails placeholder removed - now implemented in ARTTokenDetails.swift

// swift-migration: ARTTokenParams placeholder removed - now implemented in ARTTokenParams.swift

// Placeholder for ARTWebSocket protocol and related types
public protocol ARTWebSocket {
    var delegate: ARTWebSocketDelegate? { get set }
    var readyState: ARTWebSocketReadyState { get }
    func setDelegateDispatchQueue(_ queue: DispatchQueue)
    func open()
    func send(_ data: Data)
    func close(withCode code: Int, reason: String)
}

public protocol ARTWebSocketDelegate: AnyObject {
    func webSocketDidOpen(_ webSocket: ARTWebSocket)
    func webSocket(_ webSocket: ARTWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool)
    func webSocket(_ webSocket: ARTWebSocket, didFailWithError error: Error)
    func webSocket(_ webSocket: ARTWebSocket, didReceiveMessage message: Any)
}

public enum ARTWebSocketReadyState: Int {
    case connecting = 0
    case open = 1
    case closing = 2
    case closed = 3
}

public class ARTSRWebSocket: NSObject, ARTWebSocket {
    public weak var delegate: ARTWebSocketDelegate?
    public var readyState: ARTWebSocketReadyState = .closed
    
    public init(urlRequest: URLRequest, logger: ARTInternalLog?) {
        fatalError("ARTSRWebSocket not yet migrated")
    }
    
    public func setDelegateDispatchQueue(_ queue: DispatchQueue) {
        fatalError("ARTSRWebSocket not yet migrated")
    }
    
    public func open() {
        fatalError("ARTSRWebSocket not yet migrated")
    }
    
    public func send(_ data: Data) {
        fatalError("ARTSRWebSocket not yet migrated")
    }
    
    public func close(withCode code: Int, reason: String) {
        fatalError("ARTSRWebSocket not yet migrated")
    }
}

// SocketRocket constants (to be replaced when SocketRocket wrapper is migrated)
public let ARTSRWebSocketErrorDomain = "com.squareup.SocketRocket"
public let ARTSRHTTPResponseErrorKey = "HTTPResponseKey"

// swift-migration: ARTTokenRequest placeholder removed - now implemented in ARTTokenRequest.swift

// swift-migration: ARTClientOptions placeholder removed - now implemented

// Placeholder for ARTRestInternal
public class ARTRestInternal {
    public let userQueue: DispatchQueue = DispatchQueue.main
    public let queue: DispatchQueue = DispatchQueue.main
    public let baseUrl: URL = URL(string: "https://rest.ably.io")!
    public let encoders: [String: ARTEncoder] = [:]
    public var device_nosync: ARTLocalDevice { fatalError("ARTRestInternal not yet migrated") }
    internal var storage: ARTLocalDeviceStorage { fatalError("ARTRestInternal not yet migrated") }
    public var options: ARTClientOptions { fatalError("ARTRestInternal not yet migrated") }
    public var device: ARTLocalDevice { fatalError("ARTRestInternal not yet migrated") }
    // swift-migration: push property moved to extension below
    
    public init() {
        fatalError("ARTRestInternal not yet migrated")
    }
    
    public func defaultEncoder() -> ARTEncoder {
        fatalError("ARTRestInternal not yet migrated")
    }
    
    public func executeRequest(
        _ request: URLRequest,
        withAuthOption authOption: ARTAuthentication,
        wrapperSDKAgents: [String: String]?,
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

// ARTQueuedDealloc implemented in ARTQueuedDealloc.swift

// ARTEventEmitter, ARTInternalEventEmitter, ARTPublicEventEmitter implemented in ARTEventEmitter.swift

// NSString extension implemented in ARTDataEncoder.swift

// swift-migration: ARTStatus placeholder removed - now implemented in ARTStatus.swift

// Placeholder types needed for ARTConnection and other migrations

// ARTEventListener implemented in ARTEventEmitter.swift

// Placeholder for ARTRealtimeConnectionEvent
public enum ARTRealtimeConnectionEvent: Int {
    case initialized = 0
    case connecting = 1
    case connected = 2
    case disconnected = 3
    case suspended = 4
    case closing = 5
    case closed = 6
    case failed = 7
    case update = 8
}

// Placeholder for ARTConnectionStateCallback
public typealias ARTConnectionStateCallback = (ARTConnectionStateChange) -> Void

// swift-migration: ARTConnectionStateChange and related functions moved to ARTTypes.swift

// swift-migration: ARTCallback moved to ARTTypes.swift

// Placeholder for ARTConnectionProtocol
public protocol ARTConnectionProtocol: NSObjectProtocol {
    var id: String? { get }
    var key: String? { get }
    var maxMessageSize: Int { get }
    var state: ARTRealtimeConnectionState { get }
    var errorReason: ARTErrorInfo? { get }
    var recoveryKey: String? { get }
    
    func createRecoveryKey() -> String?
    func connect()
    func close()
    func ping(_ callback: @escaping ARTCallback)
    
    func off()
    func off(_ listener: ARTEventListener)
    func off(_ event: ARTRealtimeConnectionEvent, listener: ARTEventListener)
    func on(_ cb: @escaping ARTConnectionStateCallback) -> ARTEventListener
    func on(_ event: ARTRealtimeConnectionEvent, callback cb: @escaping ARTConnectionStateCallback) -> ARTEventListener
    func once(_ cb: @escaping ARTConnectionStateCallback) -> ARTEventListener
    func once(_ event: ARTRealtimeConnectionEvent, callback cb: @escaping ARTConnectionStateCallback) -> ARTEventListener
}

// Placeholder for ARTRealtimeInternal
public class ARTRealtimeInternal: NSObject {
    public let rest: ARTRestInternal
    public let options: ARTClientOptions
    public let isActive: Bool = false
    public let msgSerial: Int64 = 0
    public let channels: ARTRealtimeChannelsInternal
    
    public override init() {
        self.rest = ARTRestInternal()
        self.options = ARTClientOptions()
        self.channels = ARTRealtimeChannelsInternal()
        super.init()
        fatalError("ARTRealtimeInternal not yet migrated")
    }
    
    public func connect() {
        fatalError("ARTRealtimeInternal not yet migrated")
    }
    
    public func close() {
        fatalError("ARTRealtimeInternal not yet migrated")  
    }
    
    public func ping(_ callback: @escaping ARTCallback) {
        fatalError("ARTRealtimeInternal not yet migrated")
    }
}

// ARTRestInternal defined above

// Placeholder for ARTRealtimeChannelsInternal
public class ARTRealtimeChannelsInternal: NSObject {
    public var nosyncIterable: [ARTRealtimeChannelInternal] {
        return []
    }
    
    public override init() {
        super.init()
        fatalError("ARTRealtimeChannelsInternal not yet migrated")
    }
}

// Placeholder for ARTRealtimeChannelInternal
public class ARTRealtimeChannelInternal: NSObject {
    public let name: String = ""
    public let channelSerial: String? = nil
    public let attachSerial: String = ""
    public var state_nosync: ARTRealtimeChannelState = .initialized
    
    public override init() {
        super.init()
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
}

// ARTRealtimeChannelState defined above

// Additional placeholder types and constants needed by ARTAuth


// ARTLocalDevice implemented in ARTLocalDevice.swift

// swift-migration: isRegistered property implemented in ARTLocalDevice.swift

// ARTLocalDeviceStorage implemented in ARTLocalDeviceStorage.swift

// swift-migration: ARTPush placeholder removed - now implemented in ARTPush.swift

// swift-migration: ARTPushActivationStateMachine placeholder removed - now implemented in ARTPushActivationStateMachine.swift

// swift-migration: ARTPushActivationState placeholder removed - now implemented in ARTPushActivationState.swift

// swift-migration: ARTPushActivationEvent placeholder removed - now implemented in ARTPushActivationEvent.swift

// Placeholder for ARTCancellable protocol
public protocol ARTCancellable {
    func cancel()
}

// swift-migration: ARTAuthentication and ARTAuthMethod enums moved to ARTTypes.swift

public let ARTAuthenticationOff = ARTAuthentication.off
public let ARTAuthMethodBasic = ARTAuthMethod.basic
public let ARTAuthMethodToken = ARTAuthMethod.token


// swift-migration: ARTTokenDetailsCompatible protocol moved to ARTAuthOptions.swift

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
// swift-migration: ARTAblyMessageNoMeansToRenewToken constant now defined in ARTStatus.swift
public let ARTErrorErrorFromClientTokenCallback = 80019
public let ARTErrorIncompatibleCredentials = 40102
public let ARTStateAuthUrlIncompatibleContent = 40170
// ARTClientIdKey now defined in ARTLocalDevice.swift
public let kCFURLErrorCancelled: CFIndex = -999

public let ARTErrorTokenErrorUnspecified = 40140
public let ARTErrorConnectionLimitsExceeded = 40110

// swift-migration: ARTDeviceId moved to ARTTypes.swift

// Placeholder for ARTDeviceStorage protocol
public protocol ARTDeviceStorage {
    func objectForKey(_ key: String) -> Any?
    func setObject(_ value: Any?, forKey key: String)
    func secretForDevice(_ deviceId: String) -> String?
    func setSecret(_ value: String?, forDevice deviceId: String)
}

// ARTJitterCoefficientGenerator protocol implemented in ARTJitterCoefficientGenerator.swift

// ARTCallback defined above

// swift-migration: ARTMessage placeholder removed - now implemented in ARTMessage.swift

// swift-migration: ARTPaginatedResult placeholder removed - now implemented in ARTPaginatedResult.swift

// Placeholder callback types
public typealias ARTPaginatedMessagesCallback = (ARTPaginatedResult<ARTMessage>?, ARTErrorInfo?) -> Void

// swift-migration: ARTState enum placeholder removed - now implemented in ARTStatus.swift

// These placeholders will be replaced by the actual ARTChannelOptions implementation

// ARTCipherParams, ARTCipherParamsCompatible, and ARTCipherKeyCompatible implemented in ARTCrypto.swift

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

// swift-migration: NSStringDictionary moved to ARTTypes.swift

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

// ARTLog implemented in ARTLog.swift

// Placeholder for ARTLogLevel enum
public enum ARTLogLevel: Int {
    case none = 99
    case error = 4
    case warn = 3
    case info = 2
    case debug = 1
    case verbose = 0
}

// swift-migration: ARTStringifiable class moved to ARTStringifiable.swift

// Placeholder for ARTPushRegistererDelegate protocol (from ARTPush.h)
#if os(iOS)
public protocol ARTPushRegistererDelegate {
    func didActivateAblyPush(_ error: ARTErrorInfo?)
    func didDeactivateAblyPush(_ error: ARTErrorInfo?)
    
    // Optional methods
    func didUpdateAblyPush(_ error: ARTErrorInfo?)
    func didAblyPushRegistrationFail(_ error: ARTErrorInfo?)
    func ablyPushCustomRegister(_ error: ARTErrorInfo?, deviceDetails: ARTDeviceDetails, callback: @escaping (ARTDeviceIdentityTokenDetails?, ARTErrorInfo?) -> Void)
    func ablyPushCustomDeregister(_ error: ARTErrorInfo?, deviceId: ARTDeviceId, callback: @escaping ARTCallback)
}
#else
public protocol ARTPushRegistererDelegate {
    // Not available on non-iOS platforms
}
#endif

// swift-migration: ARTTestClientOptions placeholder removed - now implemented in ARTTestClientOptions.swift

// swift-migration: ARTFallback_shuffleArray moved to ARTFallback.swift - duplicate removed

// swift-migration: ARTFallback_shuffleArray moved to ARTTestClientOptions.swift placeholder section

// swift-migration: ARTPluginAPI placeholder remains - ARTPluginAPI.swift exists but deferred due to complex dependencies
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

// swift-migration: ARTTokenParams extension removed - now implemented in ARTTokenParams.swift

// Placeholder for ARTQueryDirection enum
public enum ARTQueryDirection: UInt {
    case forwards = 0
    case backwards = 1
}

// ARTRealtimeChannelInternal defined above

// swift-migration: dateToMilliseconds function moved to ARTTypes.swift

// swift-migration: ARTRealtimeHistoryError moved to ARTTypes.swift

// swift-migration: ARTClientInformation placeholder removed - now implemented

// Extension for Array to provide artMap functionality
extension Array {
    internal func artMap<T>(_ transform: (Element) -> T) -> [T] {
        return self.map(transform)
    }
}

// swift-migration: Archiving extensions moved to ARTTypes.swift

// ARTGCD implemented in ARTGCD.swift

// Logging functions implemented in ARTInternalLog.swift

// Placeholder for network types
public typealias ARTURLRequestCallback = (HTTPURLResponse?, Data?, Error?) -> Void

// Placeholder for ARTURLSession protocol
public protocol ARTURLSession {
    var queue: DispatchQueue { get }
    init(_ queue: DispatchQueue)
    func get(_ request: URLRequest, completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) -> (any ARTCancellable)?
    func finishTasksAndInvalidate()
}

// Placeholder for ARTURLSessionServerTrust
public class ARTURLSessionServerTrust: ARTURLSession {
    public let queue: DispatchQueue
    
    public required init(_ queue: DispatchQueue) {
        self.queue = queue
    }
    
    public func get(_ request: URLRequest, completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) -> (any ARTCancellable)? {
        fatalError("ARTURLSessionServerTrust not yet migrated")
    }
    
    public func finishTasksAndInvalidate() {
        fatalError("ARTURLSessionServerTrust not yet migrated")
    }
}


// ARTEncoder class already defined above


// Constants defined in ARTConstants.swift

// Placeholder for HTTP response extensions
public extension HTTPURLResponse {
    func extractLinks() -> [String: String] {
        fatalError("HTTPURLResponse extractLinks not yet migrated")
    }
}

// Placeholder for URLRequest extensions
public extension URLRequest {
    static func requestWithPath(_ path: String?, relativeTo baseRequest: URLRequest) -> URLRequest? {
        fatalError("URLRequest requestWithPath not yet migrated")
    }
}

// ARTInternalLogCore protocol and ARTDefaultInternalLogCore class implemented in ARTInternalLogCore.swift

// Placeholder for ARTVersion2Log protocol
public protocol ARTVersion2Log {
    var logLevel: ARTLogLevel { get set }
    func log(_ message: String, withLevel level: ARTLogLevel, file: String, line: Int)
}

// ARTLogAdapter implemented in ARTLogAdapter.swift


// Placeholders for ARTRest types

// Placeholder for ARTHTTPPaginatedCallback
public typealias ARTHTTPPaginatedCallback = (ARTHTTPPaginatedResponse?, ARTErrorInfo?) -> Void

// Placeholder for ARTPaginatedResultResponseProcessor
public typealias ARTPaginatedResultResponseProcessor = (HTTPURLResponse?, Data?, inout Error?) -> [Any]?


// Placeholder for ARTJsonLikeEncoderDelegate protocol
public protocol ARTJsonLikeEncoderDelegate {
    func mimeType() -> String
    func format() -> ARTEncoderFormat  
    func formatAsString() -> String
    func decode(_ data: Data) throws -> Any?
    func encode(_ obj: Any) throws -> Data?
}

// swift-migration: ARTClientCodeError enum now defined in ARTStatus.swift

public let ARTClientCodeErrorInvalidType = ARTClientCodeError.invalidType

// Placeholder types for ARTEncoder protocol


// swift-migration: ARTChannelDetails moved to ARTTypes.swift


// ARTPushChannelSubscription implemented in ARTPushChannelSubscription.swift

// Placeholder implementation for ARTEncoder protocol
public class ARTEncoderPlaceholder: ARTEncoder {
    public func mimeType() -> String {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func format() -> ARTEncoderFormat {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func formatAsString() -> String {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decode(_ data: Data) throws -> Any? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encode(any obj: Any) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeToArray(_ data: Data) throws -> [Dictionary<String, Any>]? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeTokenRequest(_ request: ARTTokenRequest) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeTokenRequest(_ data: Data) throws -> ARTTokenRequest? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeTokenDetails(_ tokenDetails: ARTTokenDetails) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeTokenDetails(_ data: Data) throws -> ARTTokenDetails? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeMessage(_ message: ARTMessage) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeMessage(_ data: Data) throws -> ARTMessage? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeMessages(_ messages: [ARTMessage]) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeMessages(_ data: Data) throws -> [ARTMessage]? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodePresenceMessage(_ message: ARTPresenceMessage) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodePresenceMessage(_ data: Data) throws -> ARTPresenceMessage? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodePresenceMessages(_ messages: [ARTPresenceMessage]) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodePresenceMessages(_ data: Data) throws -> [ARTPresenceMessage]? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeProtocolMessage(_ message: ARTProtocolMessage) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeProtocolMessage(_ data: Data) throws -> ARTProtocolMessage? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeDeviceDetails(_ deviceDetails: ARTDeviceDetails) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeDeviceDetails(_ data: Data) throws -> ARTDeviceDetails? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeLocalDevice(_ device: ARTLocalDevice) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeChannelDetails(_ data: Data) throws -> ARTChannelDetails? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeDevicesDetails(_ data: Data) throws -> [ARTDeviceDetails]? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeDeviceIdentityTokenDetails(_ data: Data) throws -> ARTDeviceIdentityTokenDetails? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodeDevicePushDetails(_ devicePushDetails: ARTDevicePushDetails) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeDevicePushDetails(_ data: Data) throws -> ARTDevicePushDetails? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func encodePushChannelSubscription(_ channelSubscription: ARTPushChannelSubscription) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodePushChannelSubscription(_ data: Data) throws -> ARTPushChannelSubscription? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodePushChannelSubscriptions(_ data: Data) throws -> [ARTPushChannelSubscription]? {
        fatalError("ARTEncoder not yet migrated")
    }
    
// swift-migration: These methods are now defined in the original sections above
    
    public func decodeTime(_ data: Data) throws -> Date? {
        fatalError("ARTEncoder not yet migrated")
    }
    
    public func decodeErrorInfo(_ error: Data) throws -> ARTErrorInfo? {
        fatalError("ARTEncoder not yet migrated")
    }

    public func decodeStats(_ data: Data) throws -> [Any]? {
        fatalError("ARTEncoder not yet migrated")
    }
   
    public func encode(localDevice: ARTLocalDevice) throws -> Data? {
        fatalError("ARTEncoder not yet migrated")
    }
}

// swift-migration: ARTMessageOperation placeholder removed - now implemented in ARTMessageOperation.swift

// Placeholder for ARTJsonLikeEncoder
public class ARTJsonLikeEncoder {
    public let delegate: ARTJsonLikeEncoderDelegate
    
    public init(delegate: ARTJsonLikeEncoderDelegate) {
        self.delegate = delegate
    }
    
    public func messageFromDictionary(_ dict: [String: Any]?, protocolMessage: ARTProtocolMessage?) -> ARTMessage? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func messagesFromArray(_ array: [[String: Any]]?, protocolMessage: ARTProtocolMessage?) -> [ARTMessage]? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
}

// swift-migration: ARTErrorInfo.wrap static method now defined in ARTStatus.swift

// Placeholder for APObjectMessageProtocol
public protocol APObjectMessageProtocol {}

// Placeholder for ARTStringFromBool function
func ARTStringFromBool(_ value: Bool) -> String {
    return value ? "true" : "false"
}

// ARTReachability protocol
internal protocol ARTReachability: NSObjectProtocol {
    init(logger: ARTInternalLog, queue: DispatchQueue)
    func listenForHost(_ host: String, callback: @escaping (Bool) -> Void)
    func off()
}

// swift-migration: ARTAuthentication enum already defined above

// ARTStatusCallback and ARTQueuedMessage placeholders
public typealias ARTStatusCallback = (ARTStatus) -> Void

// ARTQueuedMessage implemented in ARTQueuedMessage.swift

// Extension for ARTProtocolMessage to add missing merge method
extension ARTProtocolMessage {
    func merge(from msg: ARTProtocolMessage, maxSize: Int) -> Bool {
        fatalError("ARTProtocolMessage merge method not yet migrated - needed by ARTQueuedMessage")
    }
}

// Placeholder callback types for ARTPresence
public typealias ARTPaginatedPresenceCallback = (ARTPaginatedResult<ARTPresenceMessage>?, ARTErrorInfo?) -> Void

// Placeholder for ARTPresenceQuery
public class ARTPresenceQuery: NSObject {
    public var limit: UInt = 0
    
    public override init() {
        super.init()
        fatalError("ARTPresenceQuery not yet migrated")
    }
    
    internal func asQueryItems() -> [URLQueryItem] {
        fatalError("ARTPresenceQuery not yet migrated")
    }
}

// Placeholder types for Plugin architecture (from _AblyPluginSupportPrivate)
public protocol APPublicRealtimeChannelUnderlyingObjects {
    var client: APRealtimeClient { get }
    var channel: APRealtimeChannel { get }
}

public protocol APRealtimeClient {
    // Placeholder protocol
}

public protocol APRealtimeChannel {
    // Placeholder protocol
}

// Additional placeholders for push notifications architecture
#if os(iOS)
import UIKit

// ARTAPNSDeviceTokenType enum
public enum ARTAPNSDeviceTokenType: Int {
    case defaultType = 0
    case locationType = 1
}

public let ARTAPNSDeviceDefaultTokenType = ARTAPNSDeviceTokenType.defaultType
public let ARTAPNSDeviceLocationTokenType = ARTAPNSDeviceTokenType.locationType

// swift-migration: Push activation event placeholders removed - now implemented in ARTPushActivationEvent.swift

// Placeholder for main app types we might need
public extension ARTRestInternal {
    func setAndPersistAPNSDeviceTokenData(_ data: Data, tokenType: ARTAPNSDeviceTokenType) {
        fatalError("setAndPersistAPNSDeviceTokenData not yet migrated")
    }
    
    func internalAsync(_ block: @escaping (ARTRestInternal) -> Void) {
        fatalError("internalAsync not yet migrated")
    }
}

// Placeholder for ARTRealtime (not yet migrated)
public class ARTRealtime {
    public init() {
        fatalError("ARTRealtime not yet migrated")
    }
    
    public func internalAsync(_ block: @escaping (ARTRealtimeInternal) -> Void) {
        fatalError("ARTRealtime internalAsync not yet migrated")
    }
}

// Placeholder for ARTRealtimeInternal
public class ARTRealtimeInternal {
    public var rest: ARTRestInternal {
        fatalError("ARTRealtimeInternal rest not yet migrated")
    }
}

// Placeholder for ARTRest (not yet migrated)  
public class ARTRest {
    public init() {
        fatalError("ARTRest not yet migrated")
    }
    
    public func internalAsync(_ block: @escaping (ARTRestInternal) -> Void) {
        fatalError("ARTRest internalAsync not yet migrated")
    }
}

// Additional placeholders needed by ARTPush  
public extension ARTRestInternal {
    var push: ARTPushInternal {
        fatalError("ARTRestInternal push not yet migrated")
    }
}

#endif

// swift-migration: ARTPushAdmin placeholder removed - now implemented in ARTPushAdmin.swift

// swift-migration: ARTPushRecipient and ARTJsonObject moved to ARTTypes.swift

// Placeholder for ARTPaginatedPushChannelCallback
public typealias ARTPaginatedPushChannelCallback = (ARTPaginatedResult<ARTPushChannelSubscription>?, ARTErrorInfo?) -> Void

// swift-migration: ARTDataQueryError moved to ARTTypes.swift

// ARTPushDeviceRegistrations and ARTPushChannelSubscriptions implemented in their respective .swift files

// Extension for NSDictionary to add art_asURLQueryItems method
extension NSDictionary {
    func art_asURLQueryItems() -> [URLQueryItem] {
        return compactMap { key, value in
            guard let keyString = key as? String, let valueString = value as? String else { return nil }
            return URLQueryItem(name: keyString, value: valueString)
        }
    }
}

// Extension for Dictionary to add art_asURLQueryItems method
extension Dictionary where Key == String, Value == String {
    func art_asURLQueryItems() -> [URLQueryItem] {
        return map { key, value in
            URLQueryItem(name: key, value: value)
        }
    }
}

// Extension for String to add art_shortString method
extension String {
    var art_shortString: String {
        return self // For now, just return the string as-is
    }
}

// Placeholder for ARTPaginatedTextCallback
public typealias ARTPaginatedTextCallback = (ARTPaginatedResult<String>?, ARTErrorInfo?) -> Void

// Placeholder for ARTPaginatedDeviceDetailsCallback  
public typealias ARTPaginatedDeviceDetailsCallback = (ARTPaginatedResult<ARTDeviceDetails>?, ARTErrorInfo?) -> Void

// swift-migration: ARTErrorInfo methods now defined in ARTStatus.swift

// Extension for URLRequest to add device authentication
extension URLRequest {
    func settingDeviceAuthentication(_ deviceId: String?, localDevice: ARTLocalDevice?) -> URLRequest {
        // swift-migration: Placeholder for device authentication - will be implemented when NSURLRequest+ARTPush.swift is migrated
        return self
    }
    
    func settingDeviceAuthentication(_ deviceId: String?, localDevice: ARTLocalDevice?, logger: ARTInternalLog) -> URLRequest {
        // swift-migration: Placeholder for device authentication - will be implemented when NSURLRequest+ARTPush.swift is migrated
        return self
    }
    
    func settingDeviceAuthentication(_ localDevice: ARTLocalDevice) -> URLRequest {
        // swift-migration: Placeholder for device authentication - will be implemented when NSURLRequest+ARTPush.swift is migrated  
        return self
    }
}

// Extension for NSMutableURLRequest to add device authentication
extension NSMutableURLRequest {
    func settingDeviceAuthentication(_ deviceId: String, localDevice: ARTLocalDevice?) -> NSURLRequest {
        // swift-migration: Placeholder for device authentication - will be implemented when NSURLRequest+ARTPush.swift is migrated
        return self
    }
    
    func settingDeviceAuthentication(_ localDevice: ARTLocalDevice) -> NSURLRequest {
        // swift-migration: Placeholder for device authentication - will be implemented when NSURLRequest+ARTPush.swift is migrated
        return self
    }
}

// Placeholder logger core
public class PlaceholderLogCore: ARTInternalLogCore {
    public var logLevel: ARTLogLevel = .debug
    
    public init() {}
    
    public func log(_ message: String, withLevel level: ARTLogLevel, file fileName: UnsafePointer<CChar>, line: Int) {
        // swift-migration: Placeholder implementation
    }
}

// Utility functions for dictionary access (from NSDictionary+ARTDictionaryUtil)
extension Dictionary where Key == String, Value == Any {
    func artString(_ key: String) -> String? {
        return self[key] as? String
    }
    
    func artNumber(_ key: String) -> NSNumber? {
        return self[key] as? NSNumber
    }
    
    func artTimestamp(_ key: String) -> Date? {
        guard let number = self[key] as? NSNumber else { return nil }
        return Date(timeIntervalSince1970: number.doubleValue / 1000)
    }
    
    func artArray(_ key: String) -> [Any]? {
        return self[key] as? [Any]
    }
    
    func artDictionary(_ key: String) -> [String: Any]? {
        return self[key] as? [String: Any]
    }
    
    func artInteger(_ key: String) -> Int {
        guard let number = self[key] as? NSNumber else { return 0 }
        return number.intValue
    }
    
    func artBoolean(_ key: String) -> Bool {
        guard let value = self[key] else { return false }
        if let boolean = value as? Bool {
            return boolean
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        return false
    }
}

// swift-migration: millisecondsToTimeInterval function moved to ARTTypes.swift
