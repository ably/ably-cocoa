#import <Ably/ARTWrapperSDKProxyPushChannelSubscriptions.h>

@class ARTWrapperSDKProxyOptions;

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyPushChannelSubscriptions ()

- (instancetype)initWithPushChannelSubscriptions:(ARTPushChannelSubscriptions *)pushChannelSubscriptions
                                    proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
