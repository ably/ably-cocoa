import Foundation

// swift-migration: original location ARTEncoder.h, line 18
/// :nodoc:
public enum ARTEncoderFormat: UInt, Sendable {
    case json = 0
    case msgPack = 1
}

// swift-migration: original location ARTEncoder.h, line 26
/// :nodoc:
public protocol ARTEncoder {
    
    // swift-migration: original location ARTEncoder.h, line 28
    func mimeType() -> String
    
    // swift-migration: original location ARTEncoder.h, line 29
    func format() -> ARTEncoderFormat
    
    // swift-migration: original location ARTEncoder.h, line 30
    func formatAsString() -> String
    
    // swift-migration: original location ARTEncoder.h, line 32
    func decode(_ data: Data) throws -> Any
    
    // swift-migration: original location ARTEncoder.h, line 33
    func encode(_ obj: Any) throws -> Data
    
    // swift-migration: original location ARTEncoder.h, line 35
    /// Decode data to an Array of Dictionaries with AnyObjects.
    ///  - One use case could be when the response is an array of JSON Objects.
    func decodeToArray(_ data: Data) throws -> [Dictionary<String, Any>]?
    
    // TokenRequest
    // swift-migration: original location ARTEncoder.h, line 40
    func encodeTokenRequest(_ request: ARTTokenRequest) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 41
    func decodeTokenRequest(_ data: Data) throws -> ARTTokenRequest?
    
    // TokenDetails
    // swift-migration: original location ARTEncoder.h, line 44
    func encodeTokenDetails(_ tokenDetails: ARTTokenDetails) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 45
    func decodeTokenDetails(_ data: Data) throws -> ARTTokenDetails?
    
    // Message
    // swift-migration: original location ARTEncoder.h, line 48
    func encodeMessage(_ message: ARTMessage) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 49
    func decodeMessage(_ data: Data) throws -> ARTMessage?
    
    // Message list
    // swift-migration: original location ARTEncoder.h, line 52
    func encodeMessages(_ messages: [ARTMessage]) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 53
    func decodeMessages(_ data: Data) throws -> [ARTMessage]?
    
    // PresenceMessage
    // swift-migration: original location ARTEncoder.h, line 56
    func encodePresenceMessage(_ message: ARTPresenceMessage) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 57
    func decodePresenceMessage(_ data: Data) throws -> ARTPresenceMessage?
    
    // PresenceMessage list
    // swift-migration: original location ARTEncoder.h, line 60
    func encodePresenceMessages(_ messages: [ARTPresenceMessage]) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 61
    func decodePresenceMessages(_ data: Data) throws -> [ARTPresenceMessage]?
    
    // ProtocolMessage
    // swift-migration: original location ARTEncoder.h, line 64
    func encodeProtocolMessage(_ message: ARTProtocolMessage) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 65
    func decodeProtocolMessage(_ data: Data) throws -> ARTProtocolMessage?
    
    // DeviceDetails
    // swift-migration: original location ARTEncoder.h, line 68
    func encodeDeviceDetails(_ deviceDetails: ARTDeviceDetails) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 69
    func decodeDeviceDetails(_ data: Data) throws -> ARTDeviceDetails?
    
    // LocalDevice
    // swift-migration: original location ARTEncoder.h, line 72
    func encodeLocalDevice(_ device: ARTLocalDevice) throws -> Data?
    
    // ChannelDetails
    // swift-migration: original location ARTEncoder.h, line 75
    func decodeChannelDetails(_ data: Data) throws -> ARTChannelDetails?
    
    // swift-migration: original location ARTEncoder.h, line 77
    func decodeDevicesDetails(_ data: Data) throws -> [ARTDeviceDetails]?
    
    // swift-migration: original location ARTEncoder.h, line 78
    func decodeDeviceIdentityTokenDetails(_ data: Data) throws -> ARTDeviceIdentityTokenDetails?
    
    // DevicePushDetails
    // swift-migration: original location ARTEncoder.h, line 81
    func encodeDevicePushDetails(_ devicePushDetails: ARTDevicePushDetails) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 82
    func decodeDevicePushDetails(_ data: Data) throws -> ARTDevicePushDetails?
    
    // Push Channel Subscription
    // swift-migration: original location ARTEncoder.h, line 85
    func encodePushChannelSubscription(_ channelSubscription: ARTPushChannelSubscription) throws -> Data?
    
    // swift-migration: original location ARTEncoder.h, line 86
    func decodePushChannelSubscription(_ data: Data) throws -> ARTPushChannelSubscription?
    
    // swift-migration: original location ARTEncoder.h, line 87
    func decodePushChannelSubscriptions(_ data: Data) throws -> [ARTPushChannelSubscription]?
    
    // Others
    // swift-migration: original location ARTEncoder.h, line 90
    func decodeTime(_ data: Data) throws -> Date?
    
    // swift-migration: original location ARTEncoder.h, line 91
    func decodeErrorInfo(_ error: Data) throws -> ARTErrorInfo?
    
    // swift-migration: original location ARTEncoder.h, line 92
    func decodeStats(_ data: Data) throws -> [ARTStats]?
}
