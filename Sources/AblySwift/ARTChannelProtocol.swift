import Foundation

// swift-migration: original location ARTChannelProtocol.h, line 18
/// The protocol upon which `ARTRestChannelProtocol` and `ARTRealtimeChannelProtocol` are based.
public protocol ARTChannelProtocol {
    
    // swift-migration: original location ARTChannelProtocol.h, line 23
    /// The channel name.
    var name: String { get }
    
    // swift-migration: original location ARTChannelProtocol.h, line 31
    /// Publishes a single message to the channel with the given event name and payload. When publish is called with this client library, it won't attempt to implicitly attach to the channel, so long as [transient publishing](https://ably.com/docs/realtime/channels#transient-publish) is available in the library. Otherwise, the client will implicitly attach.
    /// - Parameters:
    ///   - name: The name of the message.
    ///   - data: The payload of the message.
    func publish(_ name: String?, data: Any?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 40
    /// Publishes a single message to the channel with the given event name and payload. A callback may optionally be passed in to this call to be notified of success or failure of the operation. When publish is called with this client library, it won't attempt to implicitly attach to the channel, so long as [transient publishing](https://ably.com/docs/realtime/channels#transient-publish) is available in the library. Otherwise, the client will implicitly attach.
    /// - Parameters:
    ///   - name: The name of the message.
    ///   - data: The payload of the message.
    ///   - callback: A success or failure callback function.
    func publish(_ name: String?, data: Any?, callback: ARTCallback?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 43
    func publish(_ name: String?, data: Any?, clientId: String)
    
    // swift-migration: original location ARTChannelProtocol.h, line 46
    func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 49
    func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 52
    func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 55
    func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 58
    func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 61
    func publish(_ messages: [ARTMessage])
    
    // swift-migration: original location ARTChannelProtocol.h, line 69
    /// Publishes an array of messages to the channel. A callback may optionally be passed in to this call to be notified of success or failure of the operation.
    /// - Parameters:
    ///   - messages: An array of `ARTMessage` objects.
    ///   - callback: A success or failure callback function.
    func publish(_ messages: [ARTMessage], callback: ARTCallback?)
    
    // swift-migration: original location ARTChannelProtocol.h, line 72
    func history(_ callback: @escaping ARTPaginatedMessagesCallback)
}