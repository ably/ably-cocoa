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
        self.logLevel = ArtLogLevelWarn;
    }
    return self;
}

-(void) setLogLevel:(ARTLogLevel) level {
    _logLevel = level;
}

-(void) setLogCallback:(ARTLogCallback) cb {
    _cb = cb;
}

-(void) verbose:(id) str {
    [self log:str level:ArtLogLevelVerbose];
}

-(void) debug:(id) str {
    [self log:str level:ArtLogLevelDebug];
}

-(void) info:(id) str {
    [self log:str level:ArtLogLevelInfo];
}

-(void) warn:(id) str {
    [self log:str level:ArtLogLevelWarn];
}

-(void) error:(id) str {
    [self log:str level:ArtLogLevelError];
}

-(NSString *) logLevelStr:(ARTLogLevel) level {
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

-(void) log:(id) str level:(ARTLogLevel) level {
    ARTLog * logger = self;
    
    NSString * res = [NSString stringWithFormat:@"%@: %@",[self logLevelStr:level],str];
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
