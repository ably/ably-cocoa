import Foundation
// swift-migration: equivalent of @import _AblyPluginSupportPrivate

// swift-migration: original location ARTPublicRealtimeChannelUnderlyingObjects.h, line 6 and ARTPublicRealtimeChannelUnderlyingObjects.m, line 3
internal class APDefaultPublicRealtimeChannelUnderlyingObjects: NSObject, APPublicRealtimeChannelUnderlyingObjects {
    
    // swift-migration: original location ARTPublicRealtimeChannelUnderlyingObjects.m, line 5
    internal let client: APRealtimeClient
    
    // swift-migration: original location ARTPublicRealtimeChannelUnderlyingObjects.m, line 6
    internal let channel: APRealtimeChannel
    
    // swift-migration: original location ARTPublicRealtimeChannelUnderlyingObjects.h, line 8 and ARTPublicRealtimeChannelUnderlyingObjects.m, line 8
    internal init(client: APRealtimeClient, channel: APRealtimeChannel) {
        self.client = client
        self.channel = channel
        super.init()
    }

}