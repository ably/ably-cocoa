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

- (instancetype)initWithClientOptions:(ARTClientOptions *)clientOptions {
    const id<ARTInternalLogBackend> backend = [[ARTDefaultInternalLogBackend alloc] initWithClientOptions:clientOptions];
    return [self initWithBackend:backend];
}

// MARK: Logging

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

@end
