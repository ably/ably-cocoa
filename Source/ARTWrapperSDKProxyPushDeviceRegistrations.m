#import "ARTWrapperSDKProxyPushDeviceRegistrations+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyPushDeviceRegistrations ()

@property (nonatomic, readonly) ARTPushDeviceRegistrations *underlyingPushDeviceRegistrations;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyPushDeviceRegistrations

- (instancetype)initWithPushDeviceRegistrations:(ARTPushDeviceRegistrations *)pushDeviceRegistrations proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingPushDeviceRegistrations = pushDeviceRegistrations;
        _proxyOptions = proxyOptions;
    }

    return self;
}

- (void)get:(nonnull ARTDeviceId *)deviceId callback:(nonnull void (^)(ARTDeviceDetails * _Nullable, ARTErrorInfo * _Nullable))callback {
    [self.underlyingPushDeviceRegistrations get:deviceId
                                       callback:callback];
}

- (void)list:(nonnull NSStringDictionary *)params callback:(nonnull ARTPaginatedDeviceDetailsCallback)callback {
    [self.underlyingPushDeviceRegistrations list:params
                                        callback:callback];
}

- (void)remove:(nonnull NSString *)deviceId callback:(nonnull ARTCallback)callback {
    [self.underlyingPushDeviceRegistrations remove:deviceId
                                          callback:callback];
}

- (void)removeWhere:(nonnull NSStringDictionary *)params callback:(nonnull ARTCallback)callback {
    [self.underlyingPushDeviceRegistrations removeWhere:params
                                               callback:callback];
}

- (void)save:(nonnull ARTDeviceDetails *)deviceDetails callback:(nonnull ARTCallback)callback {
    [self.underlyingPushDeviceRegistrations save:deviceDetails
                                        callback:callback];
}

@end
