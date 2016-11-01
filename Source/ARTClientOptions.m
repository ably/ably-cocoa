//
//  ARTClientOptions.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTClientOptions+Private.h"
#import "ARTAuthOptions+Private.h"

#import "ARTDefault.h"
#import "ARTStatus.h"
#import "ARTTokenParams.h"

NSString *ARTDefaultEnvironment = nil;
NSString *const ARTDefaultProduction = @"production";

@interface ARTClientOptions ()

- (instancetype)initDefaults;

@end

@implementation ARTClientOptions

- (instancetype)initDefaults {
    self = [super initDefaults];
    _port = [ARTDefault port];
    _tlsPort = [ARTDefault tlsPort];
    _environment = ARTDefaultEnvironment;
    _queueMessages = YES;
    _echoMessages = YES;
    _useBinaryProtocol = true;
    _autoConnect = true;
    _tls = YES;
    _logLevel = ARTLogLevelNone;
    _disconnectedRetryTimeout = 15.0; //Seconds
    _suspendedRetryTimeout = 30.0; //Seconds
    _httpOpenTimeout = 4.0; //Seconds
    _httpRequestTimeout = 15.0; //Seconds
    _httpMaxRetryDuration = 10.0; //Seconds
    _httpMaxRetryCount = 3;
    _fallbackHosts = nil;
    _fallbackHostsUseDefault = false;
    return self;
}

- (NSString*)getRestHost {
    if (_restHost) {
        return _restHost;
    }
    if ([_environment isEqualToString:ARTDefaultProduction]) {
        return [ARTDefault restHost];
    }
    return _environment ? [NSString stringWithFormat:@"%@-%@", _environment, [ARTDefault restHost]] : [ARTDefault restHost];
}

- (NSString*)getRealtimeHost {
    if (_realtimeHost) {
        return _realtimeHost;
    }
    if ([_environment isEqualToString:ARTDefaultProduction]) {
        return [ARTDefault realtimeHost];
    }
    return _environment ? [NSString stringWithFormat:@"%@-%@", _environment, [ARTDefault realtimeHost]] : [ARTDefault realtimeHost];
}

- (NSURLComponents *)restUrlComponents {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.tls ? @"https" : @"http";
    components.host = self.restHost;
    components.port = [NSNumber numberWithInteger:(self.tls ? self.tlsPort : self.port)];
    return components;
}

- (NSURL*)restUrl {
    return [self restUrlComponents].URL;
}

- (NSURL*)realtimeUrl {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.tls ? @"wss" : @"ws";
    components.host = self.realtimeHost;
    components.port = [NSNumber numberWithInteger:(self.tls ? self.tlsPort : self.port)];
    return components.URL;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTClientOptions *options = [super copyWithZone:zone];

    options.clientId = self.clientId;
    options.port = self.port;
    options.tlsPort = self.tlsPort;
    if (self->_restHost) options.restHost = self.restHost;
    if (self->_realtimeHost) options.realtimeHost = self.realtimeHost;
    options.queueMessages = self.queueMessages;
    options.echoMessages = self.echoMessages;
    options.recover = self.recover;
    options.useBinaryProtocol = self.useBinaryProtocol;
    options.autoConnect = self.autoConnect;
    options.environment = self.environment;
    options.tls = self.tls;
    options.logLevel = self.logLevel;
    options.logHandler = self.logHandler;
    options.suspendedRetryTimeout = self.suspendedRetryTimeout;
    options.disconnectedRetryTimeout = self.disconnectedRetryTimeout;
    options.httpMaxRetryCount = self.httpMaxRetryCount;
    options.httpMaxRetryDuration = self.httpMaxRetryDuration;
    options.httpOpenTimeout = self.httpOpenTimeout;
    options.httpRequestTimeout = self.httpRequestTimeout;
    options->_fallbackHosts = self.fallbackHosts; //ignore setter
    options->_fallbackHostsUseDefault = self.fallbackHostsUseDefault; //ignore setter
    
    return options;
}

- (BOOL)isBasicAuth {
    return self.useTokenAuth == false &&
    self.key != nil &&
    self.clientId == nil &&
    self.token == nil &&
    self.tokenDetails == nil &&
    self.authUrl == nil &&
    self.authCallback == nil;
}

- (BOOL)hasCustomRestHost {
    return (_restHost && ![_restHost isEqualToString:[ARTDefault restHost]]) || _environment;
}

- (BOOL)hasDefaultRestHost {
    return ![self hasCustomRestHost];
}

- (BOOL)hasCustomRealtimeHost {
    return (_realtimeHost && ![_realtimeHost isEqualToString:[ARTDefault realtimeHost]]) || _environment;
}

- (BOOL)hasDefaultRealtimeHost {
    return ![self hasCustomRealtimeHost];
}

- (void)setFallbackHosts:(art_nullable __GENERIC(NSArray, NSString *) *)value {
    if (_fallbackHostsUseDefault) {
        [NSException raise:ARTFallbackIncompatibleOptionsException format:@"Could not setup custom fallback hosts because it is currently configured to use default fallback hosts."];
    }
    _fallbackHosts = value;
}

- (void)setFallbackHostsUseDefault:(BOOL)value {
    if (_fallbackHosts) {
        [NSException raise:ARTFallbackIncompatibleOptionsException format:@"Could not configure options to use default fallback hosts because a custom fallback host list is being used."];
    }
    _fallbackHostsUseDefault = value;
}

+ (void)setDefaultEnvironment:(NSString *)environment {
    ARTDefaultEnvironment = environment;
}

- (void)setDefaultTokenParams:(ARTTokenParams *)value {
    _defaultTokenParams = [[ARTTokenParams alloc] initWithTokenParams:value];
}

@end
