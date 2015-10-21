//
//  ARTClientOptions.h
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTAuthOptions.h"
#import "ARTLog.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTClientOptions : ARTAuthOptions

@property (readonly, getter=getRestHost) NSString *restHost;
@property (readonly, getter=getRealtimeHost) NSString *realtimeHost;

@property (nonatomic, assign, nonatomic) int restPort;
@property (nonatomic, assign, nonatomic) int realtimePort;
@property (readwrite, strong, nonatomic) NSString *environment;
@property (nonatomic, assign) BOOL tls;
@property (nonatomic, assign) ARTLogLevel logLevel;

@property (readwrite, assign, nonatomic) BOOL queueMessages;
@property (readwrite, assign, nonatomic) BOOL echoMessages;
@property (readwrite, assign, nonatomic) BOOL binary;
@property (readwrite, assign, nonatomic) BOOL autoConnect;
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (art_nullable, readwrite, copy, nonatomic) NSString *resumeKey;
@property (art_nullable, readwrite, copy, nonatomic) NSString *recover;

- (bool)isFallbackPermitted;

+ (NSURL*)restUrl:(NSString *)host port:(int)port tls:(BOOL)tls;
- (NSURL *)restUrl;

+ (NSURL*)realtimeUrl:(NSString *)host port:(int)port tls:(BOOL)tls;
- (NSURL *)realtimeUrl;

@end

ART_ASSUME_NONNULL_END
