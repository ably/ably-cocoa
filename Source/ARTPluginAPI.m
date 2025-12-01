#ifdef ABLY_SUPPORTS_PLUGINS

#import "ARTPluginAPI.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTChannel+Private.h"
#import "ARTInternalLog.h"
#import "ARTPublicRealtimeChannelUnderlyingObjects.h"
#import "ARTClientOptions+Private.h"
#import "ARTErrorInfo+Private.h"
#import "ARTConnectionDetails+Private.h"

static ARTErrorInfo *_ourPublicErrorInfo(id<APPublicErrorInfo> pluginPublicErrorInfo) {
    if (![pluginPublicErrorInfo isKindOfClass:[ARTErrorInfo class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"Expected ARTErrorInfo, got %@", pluginPublicErrorInfo];
    }
    return (ARTErrorInfo *)pluginPublicErrorInfo;
}

static ARTClientOptions *_ourPublicClientOptions(id<APPublicClientOptions> pluginPublicClientOptions) {
    if (![pluginPublicClientOptions isKindOfClass:[ARTClientOptions class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"Expected ARTClientOptions, got %@", pluginPublicClientOptions];
    }
    return (ARTClientOptions *)pluginPublicClientOptions;
}

static ARTRealtimeChannel *_ourPublicRealtimeChannel(id<APPublicRealtimeChannel> pluginPublicRealtimeChannel) {
    if (![pluginPublicRealtimeChannel isKindOfClass:[ARTRealtimeChannel class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"Expected ARTRealtimeChannel, got %@", pluginPublicRealtimeChannel];
    }
    return (ARTRealtimeChannel *)pluginPublicRealtimeChannel;
}

static ARTRealtimeChannelInternal *_internalRealtimeChannel(id<APRealtimeChannel> pluginRealtimeChannel) {
    if (![pluginRealtimeChannel isKindOfClass:[ARTRealtimeChannelInternal class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"Expected ARTRealtimeChannelInternal, got %@", pluginRealtimeChannel];
    }
    return (ARTRealtimeChannelInternal *)pluginRealtimeChannel;
}

static ARTRealtimeInternal *_internalRealtimeClient(id<APRealtimeClient> pluginRealtimeClient) {
    if (![pluginRealtimeClient isKindOfClass:[ARTRealtimeInternal class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"Expected ARTRealtimeInternal, got %@", pluginRealtimeClient];
    }
    return (ARTRealtimeInternal *)pluginRealtimeClient;
}

static ARTInternalLog *_internalLogger(id<APLogger> pluginLogger) {
    if (![pluginLogger isKindOfClass:[ARTInternalLog class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"Expected ARTInternalLog, got %@", pluginLogger];
    }
    return (ARTInternalLog *)pluginLogger;
}

static APRealtimeChannelState _convertOurRealtimeChannelState(ARTRealtimeChannelState ourRealtimeChannelState) {
    switch (ourRealtimeChannelState) {
    case ARTRealtimeChannelInitialized:
        return APRealtimeChannelStateInitialized;
    case ARTRealtimeChannelAttaching:
        return APRealtimeChannelStateAttaching;
    case ARTRealtimeChannelAttached:
        return APRealtimeChannelStateAttached;
    case ARTRealtimeChannelDetaching:
        return APRealtimeChannelStateDetaching;
    case ARTRealtimeChannelDetached:
        return APRealtimeChannelStateDetached;
    case ARTRealtimeChannelSuspended:
        return APRealtimeChannelStateSuspended;
    case ARTRealtimeChannelFailed:
        return APRealtimeChannelStateFailed;
    }

    [NSException raise:NSInternalInconsistencyException format:@"_convertOurRealtimeChannelState failed to map %lu", ourRealtimeChannelState];
}

static ARTLogLevel _convertPluginLogLevel(APLogLevel pluginLogLevel) {
    switch (pluginLogLevel) {
        case APLogLevelVerbose:
            return ARTLogLevelVerbose;
        case APLogLevelDebug:
            return ARTLogLevelDebug;
        case APLogLevelInfo:
            return ARTLogLevelInfo;
        case APLogLevelWarn:
            return ARTLogLevelWarn;
        case APLogLevelError:
            return ARTLogLevelError;
        case APLogLevelNone:
            return ARTLogLevelNone;
    }

    [NSException raise:NSInternalInconsistencyException format:@"_convertPluginLogLevel failed to map %lu", pluginLogLevel];
}

@implementation ARTPluginAPI

+ (void)registerSelf {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARTPluginAPI *instanceToRegister = [[ARTPluginAPI alloc] init];
        [[APDependencyStore sharedInstance] registerPluginAPI:instanceToRegister];
    });
}

- (id<APPublicRealtimeChannelUnderlyingObjects>)underlyingObjectsForPublicRealtimeChannel:(id<APPublicRealtimeChannel>)channel {
    ARTRealtimeChannel *ours = _ourPublicRealtimeChannel(channel);
    return [[APDefaultPublicRealtimeChannelUnderlyingObjects alloc] initWithClient:ours.realtimeInternal
                                                                           channel:ours.internal];

}

- (void)nosync_setPluginDataValue:(nonnull id)value
                           forKey:(nonnull NSString *)key
                          channel:(nonnull id<APRealtimeChannel>)channel {
    ARTRealtimeChannelInternal *internalChannel = _internalRealtimeChannel(channel);
    dispatch_assert_queue(internalChannel.queue);

    [internalChannel setPluginDataValue:value forKey:key];
}

- (nullable id)nosync_pluginDataValueForKey:(nonnull NSString *)key
                                    channel:(nonnull id<APRealtimeChannel>)channel {
    ARTRealtimeChannelInternal *internalChannel = _internalRealtimeChannel(channel);
    dispatch_assert_queue(internalChannel.queue);

    return [internalChannel pluginDataValueForKey:key];
}

- (id<APLogger>)loggerForChannel:(id<APRealtimeChannel>)channel {
    return _internalRealtimeChannel(channel).logger;
}

- (void)setPluginOptionsValue:(id)value forKey:(NSString *)key clientOptions:(id<APPublicClientOptions>)options {
    [_ourPublicClientOptions(options) setPluginOptionsValue:value forKey:key];
}

- (id)pluginOptionsValueForKey:(NSString *)key clientOptions:(id<APPublicClientOptions>)options {
    return [_ourPublicClientOptions(options) pluginOptionsValueForKey:key];
}

- (ARTClientOptions *)optionsForClient:(id<APRealtimeClient>)client {
    return [_internalRealtimeClient(client).options copy];
}

- (dispatch_queue_t)callbackQueueForClient:(id<APRealtimeClient>)client {
    return _internalRealtimeClient(client).options.dispatchQueue;
}

- (dispatch_queue_t)internalQueueForClient:(id<APRealtimeClient>)client {
    return _internalRealtimeClient(client).options.internalDispatchQueue;
}

- (void)nosync_sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages
                                    channel:(id<APRealtimeChannel>)channel
                                 completion:(void (^)(id<APPublicErrorInfo> _Nullable))completion {
    ARTRealtimeChannelInternal *internalChannel = _internalRealtimeChannel(channel);
    dispatch_assert_queue(internalChannel.queue);

    [_internalRealtimeChannel(channel) sendObjectWithObjectMessages:objectMessages
                                                         completion:completion];
}

- (APRealtimeChannelState)nosync_stateForChannel:(id<APRealtimeChannel>)channel {
    ARTRealtimeChannelInternal *internalChannel = _internalRealtimeChannel(channel);
    dispatch_assert_queue(internalChannel.queue);

    return _convertOurRealtimeChannelState(internalChannel.state_nosync);
}

- (void)nosync_fetchServerTimeForClient:(id<APRealtimeClient>)client
                             completion:(void (^)(NSDate * _Nullable, id<APPublicErrorInfo> _Nullable))completion {
    ARTRealtimeInternal *internalRealtimeClient = _internalRealtimeClient(client);
    dispatch_assert_queue(internalRealtimeClient.queue);

    [internalRealtimeClient.auth fetchServerTimeWithCompletion:completion];
}

- (id<APConnectionDetailsProtocol>)nosync_latestConnectionDetailsForClient:(id<APRealtimeClient>)client {
    ARTRealtimeInternal *internalRealtimeClient = _internalRealtimeClient(client);
    dispatch_assert_queue(internalRealtimeClient.queue);

    return internalRealtimeClient.latestConnectionDetails;
}

- (void)log:(NSString *)message
        withLevel:(APLogLevel)level
        file:(const char *)fileName
        line:(NSInteger)line
        logger:(id<APLogger>)logger {
    [_internalLogger(logger) log:message
                             withLevel:_convertPluginLogLevel(level)
                             file:fileName
                             line:line];
}

@end

#endif
