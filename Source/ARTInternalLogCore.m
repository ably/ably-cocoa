#import "ARTInternalLogCore.h"
#import "ARTInternalLogCore+Testing.h"
#import "ARTVersion2Log.h"
#import "ARTClientOptions.h"
#import "ARTLogAdapter.h"

@implementation ARTDefaultInternalLogCore

- (instancetype)initWithLogger:(id<ARTVersion2Log>)logger {
    if (self = [super init]) {
        _logger = logger;
    }

    return self;
}

- (instancetype)initWithClientOptions:(ARTClientOptions *)options {
    if (options.logLevel != ARTLogLevelNone) {
        options.logHandler.logLevel = options.logLevel;
    }

    id<ARTVersion2Log> logger = [[ARTLogAdapter alloc] initWithLogger:options.logHandler];
    return [self initWithLogger:logger];
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
