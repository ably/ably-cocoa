#import "ARTInternalLogBackend.h"
#import "ARTVersion2Log.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTDefaultInternalLogBackend ()

@property (nonatomic, readonly) id<ARTVersion2Log> logger;

@end

NS_ASSUME_NONNULL_END

@implementation ARTDefaultInternalLogBackend

- (instancetype)initWithLogger:(id<ARTVersion2Log>)logger {
    if (self = [super init]) {
        _logger = logger;
    }

    return self;
}

// MARK: Logging

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSInteger)line {
    NSString *const fileNameNSString = [NSString stringWithUTF8String:fileName];
    NSString *const lastPathComponent = fileNameNSString ? fileNameNSString.lastPathComponent : @"";
    [self.logger log:message withLevel:level file:lastPathComponent line:line];
}

// MARK: Log level

- (ARTLogLevel)logLevel {
    return self.logger.logLevel;
}

- (void)setLogLevel:(ARTLogLevel)logLevel {
    self.logger.logLevel = logLevel;
}

@end
