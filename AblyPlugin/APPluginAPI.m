#import "APPluginAPI.h"
#import "ARTRealtimeChannel+Plugins.h"

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

@end
