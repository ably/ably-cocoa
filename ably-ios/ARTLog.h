//
//  ARTLog.h
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ARTLogLevel) {
    ArtLogLevelVerbose,
    ArtLogLevelDebug,
    ArtLogLevelInfo,
    ArtLogLevelWarn,
    ArtLogLevelError,
    ArtLogLevelNone
};

typedef void(^ARTLogCallback)(id);

@protocol ArtLogProtocol
- (void)log:(id) message;
@end

@interface ARTLog : NSObject
{
    
}

+(void) setLogLevel:(ARTLogLevel) level;
+(void) setLogCallback:(ARTLogCallback) cb;
+(void) verbose:(id) str;
+(void) debug:(id) str;
+(void) info:(id) str;
+(void) warn:(id) str;
+(void) error:(id) str;

@end
