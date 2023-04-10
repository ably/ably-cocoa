#import "ARTLogAdapter.h"
#import "ARTLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTLogAdapter ()

@property (nonatomic, readonly) ARTLog *logger;

@end

NS_ASSUME_NONNULL_END

@implementation ARTLogAdapter

- (instancetype)initWithLogger:(ARTLog *)logger {
    if (self = [super init]) {
        _logger = logger;
    }

    return self;
}

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level {
    [self.logger log:message withLevel:level];
}

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(NSString *)fileName line:(NSInteger)line {
    NSString *const augmentedMessage = [NSString stringWithFormat:@"(%@:%ld) %@", fileName, (long)line, message];
    [self log:augmentedMessage withLevel:level];
}

- (ARTLogLevel)logLevel {
    return self.logger.logLevel;
}

- (void)setLogLevel:(ARTLogLevel)logLevel {
    self.logger.logLevel = logLevel;
}

@end
