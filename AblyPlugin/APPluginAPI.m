#import "APPluginAPI.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTChannel+Private.h"
#import "ARTInternalLog+APLogger.h"

@implementation APPluginAPI

+ (APPluginAPI *)sharedInstance {
    static APPluginAPI *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[APPluginAPI alloc] init];
    });

    return sharedInstance;
}

- (void)setPluginDataValue:(nonnull id)value
                    forKey:(nonnull NSString *)key
                   channel:(nonnull ARTRealtimeChannel *)channel {
    [channel.internal setPluginDataValue:value forKey:key];
}

- (nullable id)pluginDataValueForKey:(nonnull NSString *)key
                             channel:(nonnull ARTRealtimeChannel *)channel {
    return [channel.internal pluginDataValueForKey:key];
}

- (id<APLogger>)loggerForChannel:(ARTRealtimeChannel *)channel {
    return channel.internal.logger;
}

- (BOOL)throwIfUnpublishableStateForChannel:(ARTRealtimeChannel *)channel error:(ARTErrorInfo * _Nullable __autoreleasing *)error {
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
}

- (void)sendObjectWithObjectMessages:(NSArray<id<APObjectMessageProtocol>> *)objectMessages channel:(ARTRealtimeChannel *)channel completion:(void (^)(ARTErrorInfo * _Nonnull))completion {
    [channel.internal sendStateWithObjectMessages:objectMessages
                                       completion:completion];
}

- (void)fetchTimestampWithQueryTime:(BOOL)queryTime
                           realtime:(ARTRealtime *)realtime
                         completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error, NSDate *_Nullable timestamp))completion {
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
}

@end
