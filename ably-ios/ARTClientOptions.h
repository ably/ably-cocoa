//
//  ARTClientOptions.h
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTAuth.h"

@interface ARTClientOptions : NSObject<NSCopying>

@property (readwrite, strong, nonatomic) ARTAuthOptions *authOptions;
@property (readwrite, strong, nonatomic) NSString *clientId;

@property (readonly, getter=getRestHost) NSString *restHost;
@property (readonly, getter=getRealtimeHost) NSString *realtimeHost;

@property (nonatomic, assign, nonatomic) int restPort;
@property (nonatomic, assign, nonatomic) int realtimePort;
@property (readwrite, strong, nonatomic) NSString *environment;
@property (nonatomic, assign) BOOL tls;

@property (readwrite, assign, nonatomic) BOOL queueMessages;
@property (readwrite, assign, nonatomic) BOOL echoMessages;
@property (readwrite, assign, nonatomic) BOOL binary;
@property (readwrite, assign, nonatomic) BOOL autoConnect;
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (readwrite, copy, nonatomic) NSString *resumeKey;
@property (readwrite, copy, nonatomic) NSString *recover;

- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key;

- (bool)isFallbackPermitted;

+ (NSURL*)restUrl:(NSString *)host port:(int)port tls:(BOOL)tls;

@end
