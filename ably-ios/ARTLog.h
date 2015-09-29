//
//  ARTLog.h
//  ably-ios
//
//  Created by vic on 16/04/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/CompatibilityMacros.h>

__ART_ASSUME_NONNULL_BEGIN

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

- (void)log:(NSString *)message withLevel:(ARTLogLevel)level;

@end

@interface ARTLog (Shorthand)

- (void)verbose:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)debug:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)info:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)warn:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)error:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

@end

__ART_ASSUME_NONNULL_END
