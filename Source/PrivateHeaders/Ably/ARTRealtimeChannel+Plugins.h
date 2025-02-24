#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ARTProtocolMessageListener)(ARTProtocolMessage *);

@interface ARTRealtimeChannel ()

- (void)setPluginDataValue:(id)value forKey:(NSString *)key;
- (nullable id)pluginDataValueForKey:(NSString *)key;

- (void)addPluginProtocolMessageListener:(ARTProtocolMessageListener)listener;

@end

NS_ASSUME_NONNULL_END
