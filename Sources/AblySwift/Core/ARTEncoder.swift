import Foundation

/// :nodoc:
@frozen
public enum ARTEncoderFormat: UInt, Sendable {
    case json = 0
    case msgPack = 1
}

/// :nodoc:
public protocol ARTEncoder {
    
    func mimeType() -> String
    func format() -> ARTEncoderFormat
    func formatAsString() -> String
    
    func decode(_ data: Data) throws -> Any?
    func encode(any obj: Any) throws -> Data?
    
    /// Decode data to an Array of Dictionaries with AnyObjects.
    ///  - One use case could be when the response is an array of JSON Objects.
    func decodeToArray(_ data: Data) throws -> [[String: Any]]?
    
    // TokenRequest
    func encodeTokenRequest(_ request: ARTTokenRequest) throws -> Data?
    func decodeTokenRequest(_ data: Data) throws -> ARTTokenRequest?
    
    // TokenDetails
    func encodeTokenDetails(_ tokenDetails: ARTTokenDetails) throws -> Data?
    func decodeTokenDetails(_ data: Data) throws -> ARTTokenDetails?
    
    // Message
    func encodeMessage(_ message: ARTMessage) throws -> Data?
    func decodeMessage(_ data: Data) throws -> ARTMessage?
    
    // Message list
    func encodeMessages(_ messages: [ARTMessage]) throws -> Data?
    func decodeMessages(_ data: Data) throws -> [ARTMessage]?
    
    // PresenceMessage
    func encodePresenceMessage(_ message: ARTPresenceMessage) throws -> Data?
    func decodePresenceMessage(_ data: Data) throws -> ARTPresenceMessage?
    
    // PresenceMessage list
    func encodePresenceMessages(_ messages: [ARTPresenceMessage]) throws -> Data?
    func decodePresenceMessages(_ data: Data) throws -> [ARTPresenceMessage]?
    
    // ProtocolMessage
    func encodeProtocolMessage(_ message: ARTProtocolMessage) throws -> Data?
    func decodeProtocolMessage(_ data: Data) throws -> ARTProtocolMessage?
    
    // DeviceDetails
    func encodeDeviceDetails(_ deviceDetails: ARTDeviceDetails) throws -> Data?
    func decodeDeviceDetails(_ data: Data) throws -> ARTDeviceDetails?
    
    // LocalDevice
    func encodeLocalDevice(_ device: ARTLocalDevice) throws -> Data?
    
    // ChannelDetails
    func decodeChannelDetails(_ data: Data) throws -> ARTChannelDetails?
    
    func decodeDevicesDetails(_ data: Data) throws -> [ARTDeviceDetails]?
    func decodeDeviceIdentityTokenDetails(_ data: Data) throws -> ARTDeviceIdentityTokenDetails?
    
    // DevicePushDetails
    func encodeDevicePushDetails(_ devicePushDetails: ARTDevicePushDetails) throws -> Data?
    func decodeDevicePushDetails(_ data: Data) throws -> ARTDevicePushDetails?
    
    // Push Channel Subscription
    func encodePushChannelSubscription(_ channelSubscription: ARTPushChannelSubscription) throws -> Data?
    func decodePushChannelSubscription(_ data: Data) throws -> ARTPushChannelSubscription?
    func decodePushChannelSubscriptions(_ data: Data) throws -> [ARTPushChannelSubscription]?
    
    // Others
    func decodeTime(_ data: Data) throws -> Date?
    func decodeErrorInfo(_ error: Data) throws -> ARTErrorInfo?
    func decodeStats(_ data: Data) throws -> [Any]?
}

/// :nodoc:
public protocol ARTJsonLikeEncoderDelegate {
    func mimeType() -> String
    func format() -> ARTEncoderFormat
    func formatAsString() -> String
    
    func decode(_ data: Data) throws -> Any?
    func encode(_ obj: Any) throws -> Data?
}

