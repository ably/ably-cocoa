#import "APPluginAPI.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTChannel+Private.h"
#import "ARTInternalLog+APLogger.h"

@implementation APPluginAPI

+ (APPluginAPI *)sharedInstance {
    static APPluginAPI *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[APPluginAPI alloc] init];
    });

    return sharedInstance;
}

- (void)setPluginDataValue:(nonnull id)value
                    forKey:(nonnull NSString *)key
                   channel:(nonnull ARTRealtimeChannel *)channel {
    [channel.internal setPluginDataValue:value forKey:key];
}

- (nullable id)pluginDataValueForKey:(nonnull NSString *)key
                             channel:(nonnull ARTRealtimeChannel *)channel {
    return [channel.internal pluginDataValueForKey:key];
}

- (id<APLogger>)loggerForChannel:(ARTRealtimeChannel *)channel {
    return channel.internal.logger;
}

@end
