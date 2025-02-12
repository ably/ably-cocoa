#import "ARTWrapperSDKProxyPushAdmin+Private.h"

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
    }

    return self;
}

- (ARTPushDeviceRegistrations *)deviceRegistrations {
    return self.underlyingPushAdmin.deviceRegistrations;
}

- (ARTPushChannelSubscriptions *)channelSubscriptions {
    return self.underlyingPushAdmin.channelSubscriptions;
}

- (void)publish:(nonnull ARTPushRecipient *)recipient data:(nonnull ARTJsonObject *)data callback:(nullable ARTCallback)callback {
    [self.underlyingPushAdmin publish:recipient
                                 data:data
                             callback:callback];
}

@end
