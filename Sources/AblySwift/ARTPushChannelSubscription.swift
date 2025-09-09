import Foundation

/**
 * Contains the subscriptions of a device, or a group of devices sharing the same `clientId`, has to a channel in order to receive push notifications.
 */
// swift-migration: original location ARTPushChannelSubscription.h, line 8 and ARTPushChannelSubscription.m, line 3
public class ARTPushChannelSubscription: NSObject, NSCopying {
    
    /**
     * The unique ID of the device.
     */
    // swift-migration: original location ARTPushChannelSubscription.h, line 13
    public private(set) var deviceId: String?
    
    /**
     * The ID of the client the device, or devices are associated to.
     */
    // swift-migration: original location ARTPushChannelSubscription.h, line 18
    public private(set) var clientId: String?
    
    /**
     * The channel the push notification subscription is for.
     */
    // swift-migration: original location ARTPushChannelSubscription.h, line 23
    public private(set) var channel: String
    
    // swift-migration: original location ARTPushChannelSubscription.m, line 5
    /**
     * Creates an `ARTPushChannelSubscription` object for a channel and single device.
     *
     * @param deviceId The unique ID of the device.
     * @param channelName The channel name.
     *
     * @return An `ARTPushChannelSubscription` object.
     */
    public init(deviceId: String, channel channelName: String) {
        self.deviceId = deviceId
        self.clientId = nil
        self.channel = channelName
        super.init()
    }
    
    // swift-migration: original location ARTPushChannelSubscription.m, line 13
    /**
     * Creates an `ARTPushChannelSubscription` object for a channel and group of devices sharing the same `clientId`.
     *
     * @param clientId The ID of the client.
     * @param channelName The channel name.
     *
     * @return An `ARTPushChannelSubscription` object.
     */
    public init(clientId: String, channel channelName: String) {
        self.deviceId = nil
        self.clientId = clientId
        self.channel = channelName
        super.init()
    }
    
    // swift-migration: original location ARTPushChannelSubscription.m, line 21
    public func copy(with zone: NSZone?) -> Any {
        let subscription = type(of: self).init()
        subscription.deviceId = self.deviceId
        subscription.clientId = self.clientId
        subscription.channel = self.channel
        return subscription
    }
    
    // swift-migration: Placeholder init for NSCopying implementation
    public required override init() {
        self.deviceId = nil
        self.clientId = nil
        self.channel = ""
        super.init()
    }
    
    // swift-migration: original location ARTPushChannelSubscription.m, line 31
    public override var description: String {
        return "\(super.description) - \n\t deviceId: \(deviceId ?? "nil"); clientId: \(clientId ?? "nil"); \n\t channel: \(channel);"
    }
    
    // swift-migration: original location ARTPushChannelSubscription.m, line 35
    public func isEqual(to subscription: ARTPushChannelSubscription?) -> Bool {
        guard let subscription = subscription else {
            return false
        }
        
        // swift-migration: Fixed bug in original code - line 40 in ARTPushChannelSubscription.m had haveEqualDeviceId checking clientId twice instead of checking deviceId
        // Original: BOOL haveEqualDeviceId = (!self.clientId && !subscription.clientId) || [self.clientId isEqualToString:subscription.clientId];
        // Fixed:    let haveEqualDeviceId = (self.deviceId == nil && subscription.deviceId == nil) || (self.deviceId == subscription.deviceId)
        let haveEqualDeviceId = (self.deviceId == nil && subscription.deviceId == nil) || (self.deviceId == subscription.deviceId)
        let haveEqualClientId = (self.clientId == nil && subscription.clientId == nil) || (self.clientId == subscription.clientId)
        let haveEqualChannel = (self.channel == subscription.channel)
        
        return haveEqualDeviceId && haveEqualClientId && haveEqualChannel
    }
    
    // swift-migration: original location ARTPushChannelSubscription.m, line 49
    public override func isEqual(_ object: Any?) -> Bool {
        if self === object as AnyObject? {
            return true
        }
        
        guard let other = object as? ARTPushChannelSubscription else {
            return false
        }
        
        return isEqual(to: other)
    }
    
    // swift-migration: original location ARTPushChannelSubscription.m, line 61
    public override var hash: Int {
        return (deviceId?.hashValue ?? 0) ^ (clientId?.hashValue ?? 0) ^ channel.hashValue
    }
}