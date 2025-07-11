#import "ARTPluginRealtimeClient.h"
#import "ARTRealtime+Private.h"

@interface ARTPluginRealtimeClient ()

@property (nonatomic, readonly) ARTRealtimeInternal *underlying;

@end

@implementation ARTPluginRealtimeClient

- (instancetype)initWithUnderlying:(ARTRealtimeInternal *)underlying {
    if (self = [super init]) {
        _underlying = underlying;
    }

    return self;
}

// MARK: - APRealtimeClient

- (void)fetchTimestampWithQueryTime:(BOOL)queryTime
                         completion:(void (^ _Nullable)(ARTErrorInfo *_Nullable error, NSDate *_Nullable timestamp))completion {
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
}

@end
