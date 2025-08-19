#import "APPluginAPI.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTChannel+Private.h"
#import "ARTInternalLog+APLogger.h"
#import "ARTRealtimeChannelInternal+APRealtimeChannel.h"
#import "ARTRealtimeInternal+APRealtimeClient.h"
#import "APDefaultPublicRealtimeChannelUnderlyingObjects.h"
#import "ARTClientOptions+Private.h"

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

@implementation APPluginAPI

+ (APPluginAPI *)sharedInstance {
    static APPluginAPI *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[APPluginAPI alloc] init];
    });

    return sharedInstance;
}

- (id<APPublicRealtimeChannelUnderlyingObjects>)underlyingObjectsForPublicRealtimeChannel:(ARTRealtimeChannel *)channel {
    return [[APDefaultPublicRealtimeChannelUnderlyingObjects alloc] initWithClient:channel.realtimeInternal
                                                                           channel:channel.internal];

}

- (void)setPluginDataValue:(nonnull id)value
                    forKey:(nonnull NSString *)key
                   channel:(nonnull id<APRealtimeChannel>)channel {
    [_internalRealtimeChannel(channel) setPluginDataValue:value forKey:key];
}

- (nullable id)pluginDataValueForKey:(nonnull NSString *)key
                             channel:(nonnull id<APRealtimeChannel>)channel {
    return [_internalRealtimeChannel(channel) pluginDataValueForKey:key];
}

- (id<APLogger>)loggerForChannel:(id<APRealtimeChannel>)channel {
    return _internalRealtimeChannel(channel).logger;
}

- (void)setPluginOptionsValue:(id)value forKey:(NSString *)key clientOptions:(ARTClientOptions *)options {
    [options setPluginOptionsValue:value forKey:key];
}

- (id)pluginOptionsValueForKey:(NSString *)key clientOptions:(ARTClientOptions *)options {
    return [options pluginOptionsValueForKey:key];
}

- (ARTClientOptions *)optionsForClient:(id<APRealtimeClient>)client {
    return [_internalRealtimeClient(client).options copy];
}

/// Provides plugins with the queue on which all user callbacks for a given client should be called.
- (dispatch_queue_t)callbackQueueForClient:(id<APRealtimeClient>)client {
    return _internalRealtimeClient(client).options.dispatchQueue;
}

- (dispatch_queue_t)internalQueueForClient:(id<APRealtimeClient>)client {
    return _internalRealtimeClient(client).options.internalDispatchQueue;
}

- (void)sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages channel:(id<APRealtimeChannel>)channel completion:(void (^)(ARTErrorInfo * _Nonnull))completion {
    [_internalRealtimeChannel(channel) sendStateWithObjectMessages:objectMessages
                                                        completion:completion];
}

@end
