//
//  ARTLog.m
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTLog.h"

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

@implementation ARTLog

- (instancetype)init {
    if (self = [super init]) {
        // Default
        self->_logLevel = ARTLogLevelWarn;
    }
    return self;
}

- (void)verbose:(NSString *)message {
    [self log:message withLevel:ARTLogLevelVerbose];
}

- (void)debug:(NSString *)message {
    [self log:message withLevel:ARTLogLevelDebug];
}

- (void)info:(NSString *)message {
    [self log:message withLevel:ARTLogLevelInfo];
}

- (void)warn:(NSString *)message {
    [self log:message withLevel:ARTLogLevelWarn];
}

- (void)error:(NSString *)message {
    [self log:message withLevel:ARTLogLevelError];
}

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level {
    if (level >= self.logLevel) {
        NSLog(@"%s: %@", logLevelName(level), message);
    }
}

@end
