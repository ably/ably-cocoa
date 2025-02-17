#import "ARTWrapperSDKProxyRealtimeChannel+Private.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTWrapperSDKProxyOptions.h"
#import "ARTWrapperSDKProxyPushChannel+Private.h"
#import "ARTWrapperSDKProxyRealtimePresence+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyRealtimeChannel ()

@property (nonatomic, readonly) ARTRealtimeChannel *underlyingChannel;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyRealtimeChannel

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingChannel = channel;
        _proxyOptions = proxyOptions;
#if TARGET_OS_IOS
        _push = [[ARTWrapperSDKProxyPushChannel alloc] initWithPushChannel:channel.push
                                                              proxyOptions:proxyOptions];
#endif
        _presence = [[ARTWrapperSDKProxyRealtimePresence alloc] initWithRealtimePresence:channel.presence
                                                                            proxyOptions:proxyOptions];
    }

    return self;
}

- (ARTErrorInfo *)errorReason {
    return self.underlyingChannel.errorReason;
}

- (NSString *)name {
    return self.underlyingChannel.name;
}

- (ARTRealtimeChannelOptions *)getOptions {
    return self.underlyingChannel.options;
}

- (ARTChannelProperties *)properties {
    return self.underlyingChannel.properties;
}

- (ARTRealtimeChannelState)state {
    return self.underlyingChannel.state;

}

- (void)history:(nonnull ARTPaginatedMessagesCallback)callback {
    [self.underlyingChannel.internal historyWithWrapperSDKAgents:self.proxyOptions.agents
                                                      completion:callback];
}

- (void)publish:(nonnull NSArray<ARTMessage *> *)messages {
    [self.underlyingChannel publish:messages];
}

- (void)publish:(nonnull NSArray<ARTMessage *> *)messages callback:(nullable ARTCallback)callback {
    [self.underlyingChannel publish:messages callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data {
    [self.underlyingChannel publish:name data:data];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data callback:(nullable ARTCallback)callback {
    [self.underlyingChannel publish:name data:data callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(nonnull NSString *)clientId {
    [self.underlyingChannel publish:name data:data clientId:clientId];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(nonnull NSString *)clientId callback:(nullable ARTCallback)callback {
    [self.underlyingChannel publish:name data:data clientId:clientId callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(nonnull NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras {
    [self.underlyingChannel publish:name data:data clientId:clientId extras:extras];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(nonnull NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable ARTCallback)callback {
    [self.underlyingChannel publish:name data:data clientId:clientId extras:extras callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras {
    [self.underlyingChannel publish:name data:data extras:extras];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable ARTCallback)callback {
    [self.underlyingChannel publish:name data:data extras:extras callback:callback];
}

- (void)attach {
    [self.underlyingChannel attach];
}

- (void)attach:(nullable ARTCallback)callback {
    [self.underlyingChannel attach:callback];
}

- (void)detach {
    [self.underlyingChannel detach];
}

- (void)detach:(nullable ARTCallback)callback {
    [self.underlyingChannel detach:callback];
}

- (BOOL)history:(ARTRealtimeHistoryQuery * _Nullable)query callback:(nonnull ARTPaginatedMessagesCallback)callback error:(NSError * _Nullable __autoreleasing * _Nullable)errorPtr {
    return [self.underlyingChannel.internal history:query wrapperSDKAgents:self.proxyOptions.agents callback:callback error:errorPtr];
}

- (void)off {
    [self.underlyingChannel off];
}

- (void)off:(nonnull ARTEventListener *)listener {
    [self.underlyingChannel off:listener];
}

- (void)off:(ARTChannelEvent)event listener:(nonnull ARTEventListener *)listener {
    [self.underlyingChannel off:event listener:listener];
}

- (nonnull ARTEventListener *)on:(nonnull void (^)(ARTChannelStateChange * _Nonnull))cb {
    return [self.underlyingChannel on:cb];
}

- (nonnull ARTEventListener *)on:(ARTChannelEvent)event callback:(nonnull void (^)(ARTChannelStateChange * _Nonnull))cb {
    return [self.underlyingChannel on:event callback:cb];
}

- (nonnull ARTEventListener *)once:(nonnull void (^)(ARTChannelStateChange * _Nonnull))cb {
    return [self.underlyingChannel once:cb];
}

- (nonnull ARTEventListener *)once:(ARTChannelEvent)event callback:(nonnull void (^)(ARTChannelStateChange * _Nonnull))cb {
    return [self.underlyingChannel once:event callback:cb];
}

- (void)setOptions:(ARTRealtimeChannelOptions * _Nullable)options callback:(nullable ARTCallback)callback {
    [self.underlyingChannel setOptions:options callback:callback];
}

- (ARTEventListener * _Nullable)subscribe:(nonnull ARTMessageCallback)callback {
    return [self.underlyingChannel subscribe:callback];
}

- (ARTEventListener * _Nullable)subscribe:(nonnull NSString *)name callback:(nonnull ARTMessageCallback)callback {
    return [self.underlyingChannel subscribe:name callback:callback];
}

- (ARTEventListener * _Nullable)subscribe:(nonnull NSString *)name onAttach:(nullable ARTCallback)onAttach callback:(nonnull ARTMessageCallback)callback {
    return [self.underlyingChannel subscribe:name onAttach:onAttach callback:callback];
}

- (ARTEventListener * _Nullable)subscribeWithAttachCallback:(nullable ARTCallback)onAttach callback:(nonnull ARTMessageCallback)callback {
    return [self.underlyingChannel subscribeWithAttachCallback:onAttach callback:callback];
}

- (void)unsubscribe {
    [self.underlyingChannel unsubscribe];
}

- (void)unsubscribe:(ARTEventListener * _Nullable)listener {
    [self.underlyingChannel unsubscribe:listener];
}

- (void)unsubscribe:(nonnull NSString *)name listener:(ARTEventListener * _Nullable)listener {
    [self.underlyingChannel unsubscribe:name listener:listener];
}

@end
