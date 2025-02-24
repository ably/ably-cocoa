#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannel ()

- (void)setPluginDataValue:(id)value forKey:(NSString *)key;
- (nullable id)pluginDataValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
