#import "ARTWrapperSDKProxyPushAdmin+Private.h"
#import "ARTPushAdmin+Private.h"
#import "ARTWrapperSDKProxyOptions.h"
#import "ARTWrapperSDKProxyPushDeviceRegistrations+Private.h"
#import "ARTWrapperSDKProxyPushChannelSubscriptions+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyPushAdmin ()

@property (nonatomic, readonly) ARTPushAdmin *underlyingPushAdmin;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyPushAdmin

- (instancetype)initWithPushAdmin:(ARTPushAdmin *)pushAdmin proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingPushAdmin = pushAdmin;
        _proxyOptions = proxyOptions;
        _deviceRegistrations = [[ARTWrapperSDKProxyPushDeviceRegistrations alloc] initWithPushDeviceRegistrations:pushAdmin.deviceRegistrations
                                                                                                     proxyOptions:proxyOptions];
        _channelSubscriptions = [[ARTWrapperSDKProxyPushChannelSubscriptions alloc] initWithPushChannelSubscriptions:pushAdmin.channelSubscriptions
                                                                                                        proxyOptions:proxyOptions];
    }

    return self;
}

- (void)publish:(nonnull ARTPushRecipient *)recipient data:(nonnull ARTJsonObject *)data callback:(nullable ARTCallback)callback {
    [self.underlyingPushAdmin.internal publish:recipient
                                          data:data
                              wrapperSDKAgents:self.proxyOptions.agents
                                      callback:callback];
}

@end
