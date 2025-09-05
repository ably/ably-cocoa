#import "ARTLogAdapter.h"
#import "ARTLogAdapter+Testing.h"
#import "ARTLog.h"

@implementation ARTLogAdapter

- (instancetype)initWithLogger:(ARTLog *)logger {
    if (self = [super init]) {
        _logger = logger;
    }

    return self;
}

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(NSString *)fileName line:(NSInteger)line {
    NSString *const augmentedMessage = [NSString stringWithFormat:@"(%@:%ld) %@", fileName, (long)line, message];
    [self.logger log:augmentedMessage withLevel:level];
}

- (ARTLogLevel)logLevel {
    return self.logger.logLevel;
}

- (void)setLogLevel:(ARTLogLevel)logLevel {
    self.logger.logLevel = logLevel;
}

@end
