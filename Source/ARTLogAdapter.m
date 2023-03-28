#import "ARTLogAdapter.h"
#import "ARTLog.h"

@interface ARTLogAdapter ()

@property (nonatomic, readonly) ARTLog *logHandler;

@end

@implementation ARTLogAdapter

- (instancetype)initWithLogHandler:(ARTLog *)logHandler {
    if (self = [super init]) {
        _logHandler = logHandler;
    }

    return self;
}

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level {
    [self.logHandler log:message withLevel:level];
}

@end
