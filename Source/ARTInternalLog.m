#import "ARTInternalLog.h"
#import "ARTInternalLogCore.h"
#import "ARTVersion2Log.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTInternalLog ()

@property (nonatomic, readonly) id<ARTInternalLogCore> core;

@end

NS_ASSUME_NONNULL_END

@implementation ARTInternalLog

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
