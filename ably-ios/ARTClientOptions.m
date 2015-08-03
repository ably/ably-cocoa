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
@property (readwrite, strong, nonatomic) NSString *realtimeHost;
- (instancetype)initDefaults;

@end

@implementation ARTClientOptions

+(NSString *) getDefaultRestHost:(NSString *) replacement modify:(bool) modify {
    static NSString * restHost =@"rest.ably.io";
    if (modify) {
        restHost = replacement;
    }
    return restHost;
}

+(NSString *) getDefaultRealtimeHost:(NSString *) replacement modify:(bool) modify {
    static NSString * realtimeHost =@"realtime.ably.io";
    if (modify) {
        realtimeHost = replacement;
    }
    return realtimeHost;
}




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

-(NSString *) restHost {
    return _environment ?[NSString stringWithFormat:@"%@-%@", _environment, _restHost] : _restHost;
}

-(NSString * ) defaultRestHost {
    return [ARTClientOptions getDefaultRestHost:@"" modify:false];
}

-(NSString *) defaultRealtimeHost {
    return [ARTClientOptions getDefaultRealtimeHost:@"" modify:false];
}

- (instancetype)initDefaults {
    _clientId = nil;
    self.restHost =  [self defaultRestHost];
    _realtimeHost = [self defaultRealtimeHost];
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
    return self;
}

+ (instancetype)options {
    return [[ARTClientOptions alloc] init];
}

+ (instancetype)optionsWithKey:(NSString *)key {
    return [[ARTClientOptions alloc] initWithKey:key];
}

+(NSURL *) restUrl:(NSString *) host port:(int) port {
    NSString *s = [NSString stringWithFormat:@"https://%@:%d", host, port];
    return [NSURL URLWithString:s];
}
- (NSURL *)restUrl {
    return [ARTClientOptions restUrl:self.restHost port:self.restPort];
}

- (instancetype)clone {
    ARTClientOptions *options = [[ARTClientOptions alloc] init];
    options.authOptions = [self.authOptions clone];
    if (!options.authOptions) {
        return nil;
    }
    
    options.clientId = self.clientId;
    options.restHost = self.restHost;
    options.realtimeHost = self.realtimeHost;
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
    options.loggerClass = self.loggerClass;

    return options;
}

-(void) setRealtimeHost:(NSString *)realtimeHost withRestHost:(NSString *) restHost {
    self.realtimeHost = realtimeHost;
    self.restHost = restHost;
}

- (NSString *)realtimeHost {
    return _environment ?[NSString stringWithFormat:@"%@-%@", _environment, _realtimeHost] : _realtimeHost;
}

- (bool)isFallbackPermitted {
    return [self.restHost isEqualToString:[self defaultRestHost]];
}

@end
