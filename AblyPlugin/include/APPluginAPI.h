@import Foundation;

@class ARTRealtimeChannel;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PluginAPI)
@interface APPluginAPI: NSObject

+ (void)setPluginDataValue:(id)value
                    forKey:(NSString *)key
                   channel:(ARTRealtimeChannel *)channel;

+ (nullable id)pluginDataValueForKey:(NSString *)key
                             channel:(ARTRealtimeChannel *)channel;

@end

NS_ASSUME_NONNULL_END
