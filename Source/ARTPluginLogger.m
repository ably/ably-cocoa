#import "ARTPluginLogger.h"
#import "ARTInternalLog.h"

@interface ARTPluginLogger ()

@property (nonatomic, readonly) ARTInternalLog *underlying;

@end

@implementation ARTPluginLogger

- (instancetype)initWithUnderlying:(ARTInternalLog *)underlying {
    if (self = [super init]) {
        _underlying = underlying;
    }

    return self;
}

// MARK: - APLogger

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSInteger)line {
    [self.underlying log:message withLevel:level file:fileName line:line];
}

@end
