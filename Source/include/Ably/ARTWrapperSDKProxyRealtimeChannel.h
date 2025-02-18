#import <Foundation/Foundation.h>
#import <Ably/ARTRealtimeChannel.h>

@class ARTWrapperSDKProxyRealtimeChannel;
@class ARTWrapperSDKProxyPushChannel;
@class ARTWrapperSDKProxyRealtimePresence;

NS_ASSUME_NONNULL_BEGIN

/**
 * An object which wraps an instance of `ARTRealtimeChannel` and provides a similar API. It allows Ably-authored wrapper SDKs to send analytics information so that Ably can track the usage of the wrapper SDK.
 *
 * - Important: This class should only be used by Ably-authored SDKs.
 */
NS_SWIFT_SENDABLE
@interface ARTWrapperSDKProxyRealtimeChannel : NSObject <ARTRealtimeChannelProtocol>

- (instancetype)init NS_UNAVAILABLE;

@property (readonly) ARTWrapperSDKProxyRealtimePresence *presence;

#if TARGET_OS_IPHONE
@property (readonly) ARTWrapperSDKProxyPushChannel *push;
#endif

@end

NS_ASSUME_NONNULL_END
