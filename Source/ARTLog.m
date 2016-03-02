//
//  ARTLog.m
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTLog+Private.h"

static const char *logLevelName(ARTLogLevel level) {
    switch(level) {
        case ARTLogLevelNone:
            return "";
        case ARTLogLevelVerbose:
            return "VERBOSE";
        case ARTLogLevelDebug:
            return "DEBUG";
        case ARTLogLevelInfo:
            return "INFO";
        case ARTLogLevelWarn:
            return "WARN";
        case ARTLogLevelError:
            return "ERROR";
        default:
            return NULL;
    }
}

@implementation ARTLogLine

- (id)initWithDate:(NSDate *)date level:(ARTLogLevel)level message:(NSString *)message {
    self = [self init];
    if (self) {
        _date = date;
        _level = level;
        _message = message;
    }
    return self;
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"%s: %@", logLevelName(self.level), self.message];
}

@end

@implementation ARTLog {
    NSMutableArray *_captured;
}

- (instancetype)init {
    return [self initCapturingOutput:false];
}

- (instancetype)initCapturingOutput:(BOOL)capturing {
    if (self = [super init]) {
        // Default
        self->_logLevel = ARTLogLevelWarn;
        if (capturing) {
            self->_captured = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (void)log:(NSString *)message level:(ARTLogLevel)level {
    ARTLogLine *logLine = [[ARTLogLine alloc] initWithDate:[NSDate date] level:level message:message];
    if (level >= self.logLevel) {
        NSLog(@"%@", [logLine toString]);
        if (_captured) {
            [_captured addObject:logLine];
        }
    }
}

- (NSArray *)getCaptured {
    if (!_captured) {
        [NSException raise:NSInternalInconsistencyException format:@"tried to get captured output in non-capturing instance; use initCapturingOutput:true if you want captured output."];
    }
    return _captured;
}

- (ARTLog *)verboseMode {
    self.logLevel = ARTLogLevelVerbose;
    return self;
}

- (ARTLog *)debugMode {
    self.logLevel = ARTLogLevelDebug;
    return self;
}

- (ARTLog *)warnMode {
    self.logLevel = ARTLogLevelWarn;
    return self;
}

- (ARTLog *)infoMode {
    self.logLevel = ARTLogLevelInfo;
    return self;
}

- (ARTLog *)errorMode {
    self.logLevel = ARTLogLevelError;
    return self;
}

- (void)verbose:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:[[NSString alloc] initWithFormat:format arguments:args] level:ARTLogLevelVerbose];
    va_end(args);
}

- (void)debug:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:[[NSString alloc] initWithFormat:format arguments:args] level:ARTLogLevelDebug];
    va_end(args);
}

- (void)debug:(const char *)fileName line:(NSUInteger)line message:(NSString *)message, ... {
    va_list args;
    va_start(args, message);
    [self log:[[NSString alloc] initWithFormat:[NSString stringWithFormat:@"(%@:%lu) %@", [[NSString stringWithUTF8String:fileName] lastPathComponent], (unsigned long)line, message] arguments:args] level:ARTLogLevelDebug];
    va_end(args);
}

- (void)info:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:[[NSString alloc] initWithFormat:format arguments:args] level:ARTLogLevelInfo];
    va_end(args);
}

- (void)warn:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:[[NSString alloc] initWithFormat:format arguments:args] level:ARTLogLevelWarn];
    va_end(args);
}

- (void)error:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self log:[[NSString alloc] initWithFormat:format arguments:args] level:ARTLogLevelError];
    va_end(args);
}

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level {
    [self log:message level:level];
}

@end
