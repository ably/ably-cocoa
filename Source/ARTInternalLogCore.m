#import "ARTInternalLogCore.h"
#import "ARTVersion2Log.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTDefaultInternalLogCore ()

@property (nonatomic, readonly) id<ARTVersion2Log> logger;

@end

NS_ASSUME_NONNULL_END

@implementation ARTDefaultInternalLogCore

- (instancetype)initWithLogger:(id<ARTVersion2Log>)logger {
    if (self = [super init]) {
        _logger = logger;
    }

    return self;
}

// MARK: Logging

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level {
    [self.logger log:message withLevel:level];
}

// MARK: Log level

- (ARTLogLevel)logLevel {
    return self.logger.logLevel;
}

- (void)setLogLevel:(ARTLogLevel)logLevel {
    self.logger.logLevel = logLevel;
}

@end
