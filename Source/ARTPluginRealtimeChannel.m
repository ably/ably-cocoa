#import "ARTPluginRealtimeChannel.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTChannel+Private.h"
#import "ARTPluginLogger.h"

@interface ARTPluginRealtimeChannel ()

@property (nonatomic, readonly) ARTRealtimeChannelInternal *underlying;

@end

@implementation ARTPluginRealtimeChannel

@synthesize logger = _logger;

- (instancetype)initWithUnderlying:(ARTRealtimeChannelInternal *)underlying {
    if (self = [super init]) {
        _underlying = underlying;
        _logger = [[ARTPluginLogger alloc] initWithUnderlying:underlying.logger];
    }

    return self;
}

// MARK: - APRealtimeChannel

- (ARTRealtimeChannelState)state {
    return self.underlying.state;
}

- (nullable id)pluginDataValueForKey:(nonnull NSString *)key {
    return [self.underlying pluginDataValueForKey:key];
}

- (void)setPluginDataValue:(nonnull id)value forKey:(nonnull NSString *)key {
    [self.underlying setPluginDataValue:value forKey:key];
}

- (void)sendObjectWithObjectMessages:(nonnull NSArray<id<APObjectMessageProtocol>> *)objectMessages completion:(void (^ _Nullable)(ARTErrorInfo * _Nullable))completion {
    [self.underlying sendStateWithObjectMessages:objectMessages completion:completion];
}

- (BOOL)throwIfUnpublishableState:(ARTErrorInfo * _Nullable __autoreleasing * _Nullable)error {
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
    return NO;
}

@end
