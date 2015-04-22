//
//  ARTLog.m
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTLog.h"

@implementation ARTLog


static ARTLogLevel g_logLevel = ArtLogLevelWarn;
static ARTLogCallback g_cb = nil;

+(void) setLogLevel:(ARTLogLevel) level {
    g_logLevel = level;
}


+(void) setLogCallback:(ARTLogCallback) cb {
    g_cb= cb;
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

+(void) log:(id) str level:(ARTLogLevel) level {
    if(level >= g_logLevel) {
        if(g_cb) {
            g_cb(str);
        }
        else {
            NSLog(@"%@", str);
        }
    }
}
@end
