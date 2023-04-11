#import "ARTInternalLogBackend.h"
#import "ARTVersion2Log.h"
#import "ARTClientOptions.h"
#import "ARTLogAdapter.h"

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

- (instancetype)initWithClientOptions:(ARTClientOptions *)clientOptions {
    ARTLog *legacyLogger;
    if (clientOptions.logHandler) {
        legacyLogger = clientOptions.logHandler;
    }
    else {
        legacyLogger = [[ARTLog alloc] init];
    }

    if (clientOptions.logLevel != ARTLogLevelNone) {
        legacyLogger.logLevel = clientOptions.logLevel;
    }

    id<ARTVersion2Log> underlyingLogger = [[ARTLogAdapter alloc] initWithLogger:legacyLogger];

    return [self initWithLogger:underlyingLogger];
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
