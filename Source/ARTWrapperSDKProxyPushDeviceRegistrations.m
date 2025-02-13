#import "ARTWrapperSDKProxyPushDeviceRegistrations+Private.h"
#import "ARTWrapperSDKProxyOptions.h"
#import "ARTPushDeviceRegistrations+Private.h"

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
    [self.underlyingPushDeviceRegistrations.internal get:deviceId
                                        wrapperSDKAgents:self.proxyOptions.agents
                                                callback:callback];
}

- (void)list:(nonnull NSStringDictionary *)params callback:(nonnull ARTPaginatedDeviceDetailsCallback)callback {
    [self.underlyingPushDeviceRegistrations.internal list:params
                                         wrapperSDKAgents:self.proxyOptions.agents
                                                 callback:callback];
}

- (void)remove:(nonnull NSString *)deviceId callback:(nonnull ARTCallback)callback {
    [self.underlyingPushDeviceRegistrations.internal remove:deviceId
                                           wrapperSDKAgents:self.proxyOptions.agents
                                                   callback:callback];
}

- (void)removeWhere:(nonnull NSStringDictionary *)params callback:(nonnull ARTCallback)callback {
    [self.underlyingPushDeviceRegistrations.internal removeWhere:params
                                                wrapperSDKAgents:self.proxyOptions.agents
                                                        callback:callback];
}

- (void)save:(nonnull ARTDeviceDetails *)deviceDetails callback:(nonnull ARTCallback)callback {
    [self.underlyingPushDeviceRegistrations.internal save:deviceDetails
                                         wrapperSDKAgents:self.proxyOptions.agents
                                                 callback:callback];
}

@end
