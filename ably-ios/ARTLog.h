//
//  ARTLog.h
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ARTLogLevel) {
    ARTLogLevelVerbose,
    ARTLogLevelDebug,
    ARTLogLevelInfo,
    ARTLogLevelWarn,
    ARTLogLevelError,
    ARTLogLevelNone
};

@interface ARTLog : NSObject

@property (nonatomic, assign) ARTLogLevel logLevel;

- (void)verbose:(NSString *)message;
- (void)debug:(NSString *)message;
- (void)info:(NSString *)message;
- (void)warn:(NSString *)message;
- (void)error:(NSString *)message;

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level;

@end
