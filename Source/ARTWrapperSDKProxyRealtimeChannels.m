#import "ARTWrapperSDKProxyRealtimeChannels+Private.h"
#import "ARTWrapperSDKProxyRealtimeChannel+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyRealtimeChannels ()

@property (nonatomic, readonly) ARTRealtimeChannels *underlyingChannels;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyRealtimeChannels

- (instancetype)initWithChannels:(ARTRealtimeChannels *)channels proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingChannels = channels;
        _proxyOptions = proxyOptions;
    }

    return self;
}

- (BOOL)exists:(nonnull NSString *)name {
    return [self.underlyingChannels exists:name];
}

- (void)release:(nonnull NSString *)name {
    [self.underlyingChannels release:name];
}

- (void)release:(nonnull NSString *)name callback:(nullable ARTCallback)errorInfo {
    [self.underlyingChannels release:name callback:errorInfo];
}

- (ARTWrapperSDKProxyRealtimeChannel *)get:(NSString *)name {
    ARTRealtimeChannel *channel = [self.underlyingChannels get:name];
    return [[ARTWrapperSDKProxyRealtimeChannel alloc] initWithChannel:channel proxyOptions:self.proxyOptions];
}

- (ARTWrapperSDKProxyRealtimeChannel *)get:(NSString *)name options:(ARTRealtimeChannelOptions *)options {
    ARTRealtimeChannel *channel = [self.underlyingChannels get:name options:options];
    return [[ARTWrapperSDKProxyRealtimeChannel alloc] initWithChannel:channel proxyOptions:self.proxyOptions];
}

@end

