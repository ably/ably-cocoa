#import "APPluginAPI.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTChannel+Private.h"
#import "ARTInternalLog+APLogger.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimeChannelInternal+APRealtimeChannel.h"
#import "ARTRealtimeInternal+APRealtimeClient.h"
#import "APDefaultPublicRealtimeChannelUnderlyingObjects.h"

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

// TODO
/*
- (id<APRealtimeChannel>)channelForPublicRealtimeChannel:(ARTRealtimeChannel *)channel {
    return channel.internal;
}

- (id<APRealtimeClient>)clientForPublicRealtimeChannel:(ARTRealtimeChannel *)channel {
    return channel.realtimeInternal;
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

- (BOOL)throwIfUnpublishableStateForChannel:(id<APRealtimeChannel>)channel error:(ARTErrorInfo * _Nullable __autoreleasing *)error {
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
}

- (void)sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages channel:(id<APRealtimeChannel>)channel completion:(void (^)(ARTErrorInfo * _Nonnull))completion {
    [_internalRealtimeChannel(channel) sendStateWithObjectMessages:objectMessages
                                                        completion:completion];
}

- (void)fetchTimestampWithQueryTime:(BOOL)queryTime
                           realtime:(id<APRealtimeClient>)realtime
                         completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error, NSDate *_Nullable timestamp))completion {
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
}
 */

@end
