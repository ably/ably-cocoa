//
//  ARTClientOptions.h
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTAuth.h"

@interface ARTClientOptions : NSObject

@property (readwrite, strong, nonatomic) ARTAuthOptions *authOptions;
@property (readwrite, strong, nonatomic) NSString *clientId;
@property ( strong, nonatomic) NSString *restHost;
@property (readwrite, assign, nonatomic) int restPort;
@property (readwrite, assign, nonatomic) int realtimePort;

@property (readwrite, assign, nonatomic) BOOL queueMessages;
@property (readwrite, assign, nonatomic) BOOL echoMessages;
@property (readwrite, assign, nonatomic) BOOL binary;
@property (readwrite, assign, nonatomic) BOOL autoConnect;
@property (readwrite, strong, nonatomic) NSString *environment;
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (readwrite, copy, nonatomic) NSString *resumeKey;
@property (readwrite, copy, nonatomic) NSString *recover;
@property (readonly, strong, nonatomic) NSURL *restUrl;

@property (nonatomic, assign) Class loggerClass;

- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key;


// realtime requires a rest host so we explictly set both together when using realtime.
- (void) setRealtimeHost:(NSString *)realtimeHost withRestHost:(NSString *) restHost;
- (NSString *) realtimeHost;
-(bool) isFallbackPermitted;

+ (NSURL *) restUrl:(NSString *) host port:(int) port;
+ (instancetype)options;
+ (instancetype)optionsWithKey:(NSString *)key;
- (instancetype)clone;

@end
