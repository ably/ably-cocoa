import Foundation

// MARK: - Channel Protocol

/**
 * The protocol upon which `ARTRestChannelProtocol` and `ARTRealtimeChannelProtocol` are based.
 */
public protocol ARTChannelProtocol {
    
    /**
     * The channel name.
     */
    var name: String { get }
    
    /**
     * Publishes a single message to the channel with the given event name and payload.
     */
    func publish(_ name: String?, data: Any?)
    
    /**
     * Publishes a single message to the channel with the given event name and payload.
     * A callback may optionally be passed in to this call to be notified of success or failure.
     */
    func publish(_ name: String?, data: Any?, callback: ARTCallback?)
    
    /**
     * Publishes a single message with client ID
     */
    func publish(_ name: String?, data: Any?, clientId: String)
    
    /**
     * Publishes a single message with client ID and callback
     */
    func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?)
    
    /**
     * Publishes a single message with extras
     */
    func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?)
    
    /**
     * Publishes a single message with extras and callback
     */
    func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?)
    
    /**
     * Publishes a single message with client ID and extras
     */
    func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?)
    
    /**
     * Publishes a single message with client ID, extras, and callback
     */
    func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?)
    
    /**
     * Publishes an array of messages to the channel
     */
    func publish(_ messages: [ARTMessage])
    
    /**
     * Publishes an array of messages to the channel with callback
     */
    func publish(_ messages: [ARTMessage], callback: ARTCallback?)
    
    /**
     * Gets the message history for the channel
     */
    func history(_ callback: @escaping ARTPaginatedMessagesCallback)
}