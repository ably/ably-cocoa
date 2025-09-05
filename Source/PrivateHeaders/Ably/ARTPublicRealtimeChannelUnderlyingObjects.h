@import Foundation;
@import _AblyPluginSupportPrivate;

NS_ASSUME_NONNULL_BEGIN

@interface APDefaultPublicRealtimeChannelUnderlyingObjects: NSObject <APPublicRealtimeChannelUnderlyingObjects>

- (instancetype)initWithClient:(id<APRealtimeClient>)client
                       channel:(id<APRealtimeChannel>)channel;

@end

NS_ASSUME_NONNULL_END
