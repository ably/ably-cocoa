#import "ARTWrapperSDKProxyPushChannelSubscriptions+Private.h"
#import "ARTWrapperSDKProxyOptions.h"
#import "ARTPushChannelSubscriptions+Private.h"

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
    [self.underlyingPushChannelSubscriptions.internal list:params
                                          wrapperSDKAgents:self.proxyOptions.agents
                                                  callback:callback];
}

- (void)listChannels:(nonnull ARTPaginatedTextCallback)callback {
    [self.underlyingPushChannelSubscriptions.internal listChannelsWithWrapperSDKAgents:self.proxyOptions.agents
                                                                            completion:callback];
}

- (void)remove:(nonnull ARTPushChannelSubscription *)subscription callback:(nonnull ARTCallback)callback {
    [self.underlyingPushChannelSubscriptions.internal remove:subscription
                                            wrapperSDKAgents:self.proxyOptions.agents
                                                    callback:callback];
}

- (void)removeWhere:(nonnull NSStringDictionary *)params callback:(nonnull ARTCallback)callback {
    [self.underlyingPushChannelSubscriptions.internal removeWhere:params
                                                 wrapperSDKAgents:self.proxyOptions.agents
                                                         callback:callback];
}

- (void)save:(nonnull ARTPushChannelSubscription *)channelSubscription callback:(nonnull ARTCallback)callback {
    [self.underlyingPushChannelSubscriptions.internal save:channelSubscription
                                          wrapperSDKAgents:self.proxyOptions.agents
                                                  callback:callback];
}

@end
