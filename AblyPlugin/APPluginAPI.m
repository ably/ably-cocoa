#import "APPluginAPI.h"
#import "ARTRealtimeChannel+Plugins.h"
#import "ARTRealtimeChannel+Private.h"

@implementation APPluginAPI

+ (void)setPluginDataValue:(nonnull id)value
                    forKey:(nonnull NSString *)key
                   channel:(nonnull ARTRealtimeChannel *)channel {
    [channel setPluginDataValue:value forKey:key];
}

+ (nullable id)pluginDataValueForKey:(nonnull NSString *)key
                             channel:(nonnull ARTRealtimeChannel *)channel {
    return [channel pluginDataValueForKey:key];
}

+ (void)addPluginProtocolMessageListener:(APProtocolMessageListener)listener
                                 channel:(nonnull ARTRealtimeChannel *)channel {
    [channel addPluginProtocolMessageListener:listener];
}

+ (void)sendProtocolMessage:(ARTProtocolMessage *)protocolMessage
                    channel:(ARTRealtimeChannel *)channel {
    [channel.internal sendProtocolMessage:protocolMessage];
}

@end
