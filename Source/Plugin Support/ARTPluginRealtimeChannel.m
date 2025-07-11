#import "ARTPluginRealtimeChannel.h"
#import "ARTRealtimeChannel+Private.h"

@interface ARTPluginRealtimeChannel ()

@property (nonatomic, readonly) ARTRealtimeChannel *underlying;

@end

@implementation ARTPluginRealtimeChannel

- (instancetype)initWithUnderlying:(ARTRealtimeInternal *)underlying {
    if (self = [super init]) {
        _underlying = underlying;
    }

    return self;
}

// MARK: - APRealtimeChannel

- (void)fetchTimestampWithQueryTime:(BOOL)queryTime
                         completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error, NSDate *_Nullable timestamp))completion {
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
}

@end
