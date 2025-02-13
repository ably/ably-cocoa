#import "ARTWrapperSDKProxyPushChannel+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyPushChannel ()

@property (nonatomic, readonly) ARTPushChannel *underlyingPushChannel;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyPushChannel

- (instancetype)initWithPushChannel:(ARTPushChannel *)pushChannel proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingPushChannel = pushChannel;
        _proxyOptions = proxyOptions;
    }

    return self;
}

- (BOOL)listSubscriptions:(nonnull NSStringDictionary *)params callback:(nonnull ARTPaginatedPushChannelCallback)callback error:(NSError * _Nullable __autoreleasing * _Nullable)errorPtr {
    return [self.underlyingPushChannel listSubscriptions:params callback:callback error:errorPtr];
}

- (void)subscribeClient {
    [self.underlyingPushChannel subscribeClient];
}

- (void)subscribeClient:(nullable ARTCallback)callback {
    [self.underlyingPushChannel subscribeClient:callback];
}

- (void)subscribeDevice {
    [self.underlyingPushChannel subscribeDevice];
}

- (void)subscribeDevice:(nullable ARTCallback)callback {
    [self.underlyingPushChannel subscribeDevice:callback];
}

- (void)unsubscribeClient {
    [self.underlyingPushChannel unsubscribeClient];
}

- (void)unsubscribeClient:(nullable ARTCallback)callback {
    [self.underlyingPushChannel unsubscribeClient:callback];
}

- (void)unsubscribeDevice {
    [self.underlyingPushChannel unsubscribeDevice];
}

- (void)unsubscribeDevice:(nullable ARTCallback)callback {
    [self.underlyingPushChannel unsubscribeDevice:callback];
}

@end
