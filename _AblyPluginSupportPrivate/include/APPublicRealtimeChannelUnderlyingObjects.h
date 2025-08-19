@import Foundation;

@protocol APRealtimeClient;
@protocol APRealtimeChannel;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PublicRealtimeChannelUnderlyingObjects)
NS_SWIFT_SENDABLE
/// The `_AblyPluginSupportPrivate` objects that back an `ARTRealtimeChannel` instance.
@protocol APPublicRealtimeChannelUnderlyingObjects <NSObject>

@property (nonatomic, readonly) id<APRealtimeClient> client;
@property (nonatomic, readonly) id<APRealtimeChannel> channel;

@end

NS_ASSUME_NONNULL_END
