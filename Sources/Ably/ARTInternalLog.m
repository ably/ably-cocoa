#import "ARTInternalLog.h"
#import "ARTInternalLog+Testing.h"
#import "ARTInternalLogCore.h"
#import "ARTVersion2Log.h"
#import "ARTLogAdapter.h"

@implementation ARTInternalLog

+ (ARTInternalLog *)sharedClassMethodLogger_readDocumentationBeforeUsing {
    static ARTInternalLog *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ARTLog *const artLog = [[ARTLog alloc] init];
        artLog.logLevel = ARTLogLevelNone;
        const id<ARTVersion2Log> version2Log = [[ARTLogAdapter alloc] initWithLogger:artLog];
        const id<ARTInternalLogCore> core = [[ARTDefaultInternalLogCore alloc] initWithLogger:version2Log];
        logger = [[ARTInternalLog alloc] initWithCore:core];
    });

    return logger;
}

- (instancetype)initWithCore:(id<ARTInternalLogCore>)core {
    if (self = [super init]) {
        _core = core;
    }

    return self;
}

- (instancetype)initWithLogger:(id<ARTVersion2Log>)logger {
    const id<ARTInternalLogCore> core = [[ARTDefaultInternalLogCore alloc] initWithLogger:logger];
    return [self initWithCore:core];
}

- (instancetype)initWithClientOptions:(ARTClientOptions *)clientOptions {
    const id<ARTInternalLogCore> core = [[ARTDefaultInternalLogCore alloc] initWithClientOptions:clientOptions];
    return [self initWithCore:core];
}

// MARK: Logging

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSInteger)line {
    [self.core log:message withLevel:level file:fileName line:line];
}

- (void)logWithLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSUInteger)line format:(NSString *)format, ... {
    if (self.logLevel <= level) {
        va_list args;
        va_start(args, format);
        NSString *const message = [[NSString alloc] initWithFormat:format arguments:args];
        [self log:message withLevel:level file:fileName line:line];
        va_end(args);
    }
}

// MARK: Log level

- (ARTLogLevel)logLevel {
    return self.core.logLevel;
}

- (void)setLogLevel:(ARTLogLevel)logLevel {
    self.core.logLevel = logLevel;
}

@end
