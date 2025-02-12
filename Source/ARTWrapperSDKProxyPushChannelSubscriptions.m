#import "ARTWrapperSDKProxyPushChannelSubscriptions+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyPushChannelSubscriptions ()

@property (nonatomic, readonly) ARTPushChannelSubscriptions *underlyingPushChannelSubscriptions;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyPushChannelSubscriptions

- (instancetype)initWithPushChannelSubscriptions:(ARTPushChannelSubscriptions *)pushChannelSubscriptions proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingPushChannelSubscriptions = pushChannelSubscriptions;
        _proxyOptions = proxyOptions;
    }

    return self;
}

- (void)list:(nonnull NSStringDictionary *)params callback:(nonnull ARTPaginatedPushChannelCallback)callback {
    [self.underlyingPushChannelSubscriptions list:params
                                         callback:callback];
}

- (void)listChannels:(nonnull ARTPaginatedTextCallback)callback {
    [self.underlyingPushChannelSubscriptions listChannels:callback];
}

- (void)remove:(nonnull ARTPushChannelSubscription *)subscription callback:(nonnull ARTCallback)callback {
    [self.underlyingPushChannelSubscriptions remove:subscription
                                           callback:callback];
}

- (void)removeWhere:(nonnull NSStringDictionary *)params callback:(nonnull ARTCallback)callback {
    [self.underlyingPushChannelSubscriptions removeWhere:params
                                                callback:callback];
}

- (void)save:(nonnull ARTPushChannelSubscription *)channelSubscription callback:(nonnull ARTCallback)callback {
    [self.underlyingPushChannelSubscriptions save:channelSubscription
                                         callback:callback];
}

@end
