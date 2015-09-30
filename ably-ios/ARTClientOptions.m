//
//  ARTClientOptions.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTClientOptions.h"
#import "ARTClientOptions+Private.h"
#import "ARTDefault.h"

@interface ARTClientOptions ()

- (instancetype)initDefaults;

@end

@implementation ARTClientOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _authOptions = [ARTAuthOptions options];
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
        _authOptions = [ARTAuthOptions optionsWithKey:key];

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

+ (NSURL*)restUrl:(NSString *)host port:(int)port {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.tls ? @"https" : @"http";
    components.host = host;
    components.port = port;
    return components.URL;
}

- (NSURL *)restUrl {
    return [ARTClientOptions restUrl:self.restHost port:self.restPort];
}

- (bool)isFallbackPermitted {
    // FIXME: self.restHost is immutable!
    return [self.restHost isEqualToString:[ARTDefault restHost]];
}

@end
