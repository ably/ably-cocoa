//
//  ARTLog.m
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTLog.h"

@interface ARTLog()

@property (nonatomic, assign) ARTLogLevel logLevel;
@property (nonatomic, copy) ARTLogCallback cb;
@end

@implementation ARTLog

-(id) init {
    self = [super init];
    if(self) {
        
    }
    return self;
}

+(ARTLog *) instance {
    static ARTLog * logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[ARTLog alloc] init];
        logger.logLevel = ArtLogLevelWarn;
    });
    return logger;
}

+(void) setLogLevel:(ARTLogLevel) level {
    [ARTLog instance].logLevel = level;
}

+(void) setLogCallback:(ARTLogCallback) cb {
    [ARTLog instance].cb = cb;
}

+(void) verbose:(id) str {
    [ARTLog log:str level:ArtLogLevelVerbose];
}

+(void) debug:(id) str {
    [ARTLog log:str level:ArtLogLevelDebug];
}

+(void) info:(id) str {
    [ARTLog log:str level:ArtLogLevelInfo];
}

+(void) warn:(id) str {
    [ARTLog log:str level:ArtLogLevelWarn];
}

+(void) error:(id) str {
    [ARTLog log:str level:ArtLogLevelError];
}

+(NSString *) logLevelStr:(ARTLogLevel) level {
    switch(level) {
        case ArtLogLevelNone:
            return @"";
        case ArtLogLevelVerbose:
            return @"VERBOSE";
        case ArtLogLevelDebug:
            return @"DEBUG";
        case ArtLogLevelInfo:
            return @"INFO";
        case ArtLogLevelWarn:
            return @"WARN";
        case ArtLogLevelError:
            return @"ERROR";
    }
    return @"";
}

+(void) log:(id) str level:(ARTLogLevel) level {
    ARTLog * logger = [ARTLog instance];
    
    NSString * res = [NSString stringWithFormat:@"%@: %@",[ARTLog logLevelStr:level],str];
    if(level >= logger.logLevel) {
        if(logger.cb) {
            logger.cb(res);
        }
        else {
            NSLog(@"%@",res);
        }
    }
}

@end
