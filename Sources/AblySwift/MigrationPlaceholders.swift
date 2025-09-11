import Foundation

// swift-migration: Placeholder types for unmigrated dependencies
// These will be replaced with actual implementations as files are migrated

// MARK: - Things already implemented that should have been moved to correct file — get Claude to sort it out

// Placeholder for ARTPaginatedResultResponseProcessor
// swift-migration: Changed from inout Error? parameter to throws pattern per PRD requirements
public typealias ARTPaginatedResultResponseProcessor = (HTTPURLResponse?, Data?) throws -> [Any]?

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

// MARK: - Wrapper SDK proxy

// Placeholder for ARTWrapperSDKProxyOptions
public class ARTWrapperSDKProxyOptions: NSObject {
    public override init() {
        super.init()
        fatalError("ARTWrapperSDKProxyOptions not yet migrated")
    }
}

// Placeholder for ARTWrapperSDKProxyRealtime
public class ARTWrapperSDKProxyRealtime: NSObject {
    public init(realtime: ARTRealtime, proxyOptions: ARTWrapperSDKProxyOptions) {
        super.init()
        fatalError("ARTWrapperSDKProxyRealtime not yet migrated")
    }
}

// MARK: - Plugin stuff

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

// Placeholder for APObjectMessageProtocol
public protocol APObjectMessageProtocol {}

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

// MARK: - Fake logger

// Placeholder logger core
// Lawrence: Yeah, this does indeed need to exist; there's an NSCoding implementation that just calls the wrong initializer
public class PlaceholderLogCore: ARTInternalLogCore {
    public var logLevel: ARTLogLevel = .debug

    public init() {}

    public func log(_ message: String, withLevel level: ARTLogLevel, file fileName: UnsafePointer<CChar>, line: Int) {
        // swift-migration: Placeholder implementation
    }
}

// MARK: - Push stuff (we haven't tried compiling on iOS yet)

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

#endif

// MARK: - An extension that it uses instead of the properly-migrated one because of still using NSMutableDictionary somewhere

// Extension for NSDictionary to add art_asURLQueryItems method
extension NSDictionary {
    func art_asURLQueryItems() -> [URLQueryItem] {
        return compactMap { key, value in
            guard let keyString = key as? String, let valueString = value as? String else { return nil }
            return URLQueryItem(name: keyString, value: valueString)
        }
    }
}

// MARK: - Encoding stuff

// Placeholder for ARTJsonLikeEncoderDelegate protocol
public protocol ARTJsonLikeEncoderDelegate {
    func mimeType() -> String
    func format() -> ARTEncoderFormat
    func formatAsString() -> String
    func decode(_ data: Data) throws -> Any?
    func encode(_ obj: Any) throws -> Data?
}

// Placeholder types for ARTEncoder protocol

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

// Keep this as placeholder for now since it's complex
public class ARTJsonLikeEncoderPlaceholder: ARTEncoder {
    public init(rest: ARTRestInternal?, delegate: ARTJsonLikeEncoderDelegate, logger: ARTInternalLog) {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    // Required ARTEncoder methods
    public func mimeType() -> String {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func format() -> ARTEncoderFormat {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func formatAsString() -> String {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decode(_ data: Data) throws -> Any? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encode(any obj: Any) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    // swift-migration: Removed inout Error? wrapper method - using throws pattern instead
    
    public func decodeToArray(_ data: Data) throws -> [Dictionary<String, Any>]? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeTokenRequest(_ request: ARTTokenRequest) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeTokenRequest(_ data: Data) throws -> ARTTokenRequest? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeTokenDetails(_ tokenDetails: ARTTokenDetails) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeTokenDetails(_ data: Data) throws -> ARTTokenDetails? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeMessage(_ message: ARTMessage) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeMessage(_ data: Data) throws -> ARTMessage? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeMessages(_ messages: [ARTMessage]) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeMessages(_ data: Data) throws -> [ARTMessage]? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodePresenceMessage(_ message: ARTPresenceMessage) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodePresenceMessage(_ data: Data) throws -> ARTPresenceMessage? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodePresenceMessages(_ messages: [ARTPresenceMessage]) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodePresenceMessages(_ data: Data) throws -> [ARTPresenceMessage]? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeProtocolMessage(_ message: ARTProtocolMessage) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeProtocolMessage(_ data: Data) throws -> ARTProtocolMessage? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeDeviceDetails(_ deviceDetails: ARTDeviceDetails) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeDeviceDetails(_ data: Data) throws -> ARTDeviceDetails? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeLocalDevice(_ device: ARTLocalDevice) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeChannelDetails(_ data: Data) throws -> ARTChannelDetails? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeDevicesDetails(_ data: Data) throws -> [ARTDeviceDetails]? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeDeviceIdentityTokenDetails(_ data: Data) throws -> ARTDeviceIdentityTokenDetails? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodeDevicePushDetails(_ devicePushDetails: ARTDevicePushDetails) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeDevicePushDetails(_ data: Data) throws -> ARTDevicePushDetails? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encodePushChannelSubscription(_ channelSubscription: ARTPushChannelSubscription) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodePushChannelSubscription(_ data: Data) throws -> ARTPushChannelSubscription? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodePushChannelSubscriptions(_ data: Data) throws -> [ARTPushChannelSubscription]? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeTime(_ data: Data) throws -> Date? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeErrorInfo(_ error: Data) throws -> ARTErrorInfo? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func decodeStats(_ data: Data) throws -> [Any]? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
    
    public func encode(localDevice: ARTLocalDevice) throws -> Data? {
        fatalError("ARTJsonLikeEncoder not yet migrated")
    }
}
