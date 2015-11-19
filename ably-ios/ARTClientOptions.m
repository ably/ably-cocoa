//
//  ARTClientOptions.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTClientOptions.h"

#import "ARTDefault.h"

@interface ARTClientOptions ()

- (instancetype)initDefaults;

@end

@implementation ARTClientOptions

- (instancetype)initDefaults {
    self = [super initDefaults];
    _restPort = [ARTDefault TLSPort];
    _realtimePort = [ARTDefault TLSPort];
    _queueMessages = YES;
    _echoMessages = YES;
    _binary = false;
    _autoConnect = true;
    _tls = YES;
    _logLevel = ARTLogLevelNone;
    _disconnectedRetryTimeout = 15.0; //Seconds
    _suspendedRetryTimeout = 30.0; //Seconds
    _httpOpenTimeout = 4.0; //Seconds
    _httpRequestTimeout = 15.0; //Seconds
    _httpMaxRetryDuration = 10.0; //Seconds
    _httpMaxRetryCount = 3;
    return self;
}

- (NSString*)getRestHost {
    return _environment ? [NSString stringWithFormat:@"%@-%@", _environment, [ARTDefault restHost]] : [ARTDefault restHost];
}

- (NSString*)getRealtimeHost {
    return _environment ? [NSString stringWithFormat:@"%@-%@", _environment, [ARTDefault realtimeHost]] : [ARTDefault realtimeHost];
}

+ (NSURL*)restUrl:(NSString *)host port:(int)port tls:(BOOL)tls {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = tls ? @"https" : @"http";
    components.host = host;
    components.port = [NSNumber numberWithInt:port];
    return components.URL;
}

- (NSURL *)restUrl {
    return [ARTClientOptions restUrl:self.restHost port:self.restPort tls:self.tls];
}

+ (NSURL*)realtimeUrl:(NSString *)host port:(int)port tls:(BOOL)tls {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = tls ? @"wss" : @"ws";
    components.host = host;
    components.port = [NSNumber numberWithInt:port];
    return components.URL;
}

- (NSURL *)realtimeUrl {
    return [ARTClientOptions realtimeUrl:self.realtimeHost port:self.realtimePort tls:self.tls];
}

- (bool)isFallbackPermitted {
    // FIXME: self.restHost is immutable!
    return [self.restHost isEqualToString:[ARTDefault restHost]];
}

- (id)copyWithZone:(NSZone *)zone {
    ARTClientOptions *options = [super copyWithZone:zone];

    options.restPort = self.restPort;
    options.realtimePort = self.realtimePort;
    options.queueMessages = self.queueMessages;
    options.echoMessages = self.echoMessages;
    options.recover = self.recover;
    options.binary = self.binary;
    options.autoConnect = self.autoConnect;
    options.connectionSerial = self.connectionSerial;
    options.resumeKey = self.resumeKey;
    options.environment = self.environment;
    options.tls = self.tls;
    options.logLevel = self.logLevel;
    
    return options;
}

@end
