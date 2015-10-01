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

- (instancetype)init {
    self = [super init];
    if (self) {
        _authOptions = [[ARTAuthOptions alloc] init];
        if (!_authOptions) {
            self = nil;
        }
        self = [self initDefaults];
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        _authOptions = [[ARTAuthOptions alloc] initWithKey:key];

        if (!_authOptions) {
            self = nil;
        }
        self = [self initDefaults];
    }
    return self;
}

- (NSString*)getRestHost {
    return _environment ? [NSString stringWithFormat:@"%@-%@", _environment, [ARTDefault restHost]] : [ARTDefault restHost];
}

- (NSString*)getRealtimeHost {
    return _environment ? [NSString stringWithFormat:@"%@-%@", _environment, [ARTDefault realtimeHost]] : [ARTDefault realtimeHost];
}

- (instancetype)initDefaults {
    _clientId = nil;
    _restPort = [ARTDefault TLSPort];
    _realtimePort = [ARTDefault TLSPort];
    _queueMessages = YES;
    _connectionSerial = 0;
    _echoMessages = YES;
    _recover = nil;
    _binary = false;
    _autoConnect = true;
    _resumeKey = nil;
    _environment = nil;
    _tls = YES;
    return self;
}

+ (instancetype)options {
    return [[ARTClientOptions alloc] init];
}

+ (instancetype)optionsWithKey:(NSString *)key {
    return [[ARTClientOptions alloc] initWithKey:key];
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

- (bool)isFallbackPermitted {
    // FIXME: self.restHost is immutable!
    return [self.restHost isEqualToString:[ARTDefault restHost]];
}

- (id)copyWithZone:(NSZone *)zone {
    ARTClientOptions *options = [[ARTClientOptions allocWithZone:zone] init];
    
    options.authOptions = [self.authOptions copy];
    if (!options.authOptions) {
        return nil;
    }
    
    options.clientId = self.clientId;
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
    
    return options;
}

@end
