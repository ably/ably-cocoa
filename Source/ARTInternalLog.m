#import "ARTInternalLog.h"
#import "ARTInternalLogBackend.h"
#import "ARTVersion2Log.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTInternalLog ()

@property (nonatomic, readonly) id<ARTInternalLogBackend> backend;

@end

NS_ASSUME_NONNULL_END

@implementation ARTInternalLog

- (instancetype)initWithBackend:(id<ARTInternalLogBackend>)backend {
    if (self = [super init]) {
        _backend = backend;
    }

    return self;
}

- (instancetype)initWithLogger:(id<ARTVersion2Log>)logger {
    const id<ARTInternalLogBackend> backend = [[ARTDefaultInternalLogBackend alloc] initWithLogger:logger];
    return [self initWithBackend:backend];
}

// MARK: Logging

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level {
    [self.backend log:message withLevel:level];
}

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level file:(const char *)fileName line:(NSInteger)line {
    [self.backend log:message withLevel:level file:fileName line:line];
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
    return self.backend.logLevel;
}

- (void)setLogLevel:(ARTLogLevel)logLevel {
    self.backend.logLevel = logLevel;
}

// MARK: Shorthand

// These implementations are all copied from ARTLog.

- (void)verbose:(NSString *)format, ... {
    if (self.logLevel <= ARTLogLevelVerbose) {
        va_list args;
        va_start(args, format);
        [self log:[[NSString alloc] initWithFormat:format arguments:args]
        withLevel:ARTLogLevelVerbose];
        va_end(args);
    }
}

- (void)verbose:(const char *)fileName line:(NSUInteger)line message:(NSString *)message, ... {
    if (self.logLevel <= ARTLogLevelVerbose) {
        va_list args;
        va_start(args, message);
        [self log:[[NSString alloc] initWithFormat:message arguments:args]
        withLevel:ARTLogLevelVerbose file:fileName line:line];
        va_end(args);
    }
}

- (void)debug:(NSString *)format, ... {
    if (self.logLevel <= ARTLogLevelDebug) {
        va_list args;
        va_start(args, format);
        [self log:[[NSString alloc] initWithFormat:format arguments:args]
        withLevel:ARTLogLevelDebug];
        va_end(args);
    }
}

- (void)debug:(const char *)fileName line:(NSUInteger)line message:(NSString *)message, ... {
    if (self.logLevel <= ARTLogLevelDebug) {
        va_list args;
        va_start(args, message);
        [self log:[[NSString alloc] initWithFormat:message arguments:args]
        withLevel:ARTLogLevelDebug file:fileName line:line];
        va_end(args);
    }
}

- (void)info:(NSString *)format, ... {
    if (self.logLevel <= ARTLogLevelInfo) {
        va_list args;
        va_start(args, format);
        [self log:[[NSString alloc] initWithFormat:format arguments:args]
        withLevel:ARTLogLevelInfo];
        va_end(args);
    }
}

- (void)warn:(NSString *)format, ... {
    if (self.logLevel <= ARTLogLevelWarn) {
        va_list args;
        va_start(args, format);
        [self log:[[NSString alloc] initWithFormat:format arguments:args]
        withLevel:ARTLogLevelWarn];
        va_end(args);
    }
}

- (void)error:(NSString *)format, ... {
    if (self.logLevel <= ARTLogLevelError) {
        va_list args;
        va_start(args, format);
        [self log:[[NSString alloc] initWithFormat:format arguments:args]
        withLevel:ARTLogLevelError];
        va_end(args);
    }
}

@end
