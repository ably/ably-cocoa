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

@property (readwrite, strong, nonatomic, getter=getRestHost) NSString *restHost;
@property (readwrite, strong, nonatomic, getter=getRealtimeHost) NSString *realtimeHost;

@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) NSInteger tlsPort;
@property (readwrite, strong, nonatomic) NSString *environment;
@property (nonatomic, assign) BOOL tls;
@property (nonatomic, strong, readwrite) ARTLog *logHandler;
@property (nonatomic, assign) ARTLogLevel logLevel;

@property (readwrite, assign, nonatomic) BOOL queueMessages;
@property (readwrite, assign, nonatomic) BOOL echoMessages;
@property (readwrite, assign, nonatomic) BOOL useBinaryProtocol;
@property (readwrite, assign, nonatomic) BOOL autoConnect;
@property (art_nullable, readwrite, copy, nonatomic) NSString *recover;

/**
 Represents time to live (expiry) of this token in seconds.
 */
@property (nonatomic, assign) NSTimeInterval ttl;

/**
 Contains the capability JSON stringified.
 */
@property (nonatomic, copy) NSString *capability;

/**
 Represents the timeout (in seconds) to retry connection when it's disconnected.
 When the connection is in the DISCONNECTED state, how frequently the client library attempts to reconnect automatically.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval disconnectedRetryTimeout;

/**
 Represents the timeout (in seconds) to retry connection when it's suspended.
 When the connection is in the SUSPENDED state, how frequently the client library attempts to reconnect automatically.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval suspendedRetryTimeout;

/**
 Timeout for opening the connection, available in the client library if supported by the transport.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpOpenTimeout;

/**
 Timeout for any single HTTP request and response.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpRequestTimeout;

/**
 Max number of fallback host retries for HTTP requests that fail due to network issues or server problems.
 */
@property (readwrite, assign, nonatomic) NSUInteger httpMaxRetryCount;

/**
 Max elapsed time in which fallback host retries for HTTP requests will be attempted i.e. if the first default host attempt takes 5s, and then the subsequent fallback retry attempt takes 7s, no further fallback host attempts will be made as the total elapsed time of 12s exceeds the default 10s limit.
 */
@property (readwrite, assign, nonatomic) NSTimeInterval httpMaxRetryDuration;

- (NSURL *)restUrl;
- (NSURL *)realtimeUrl;

@end

ART_ASSUME_NONNULL_END
