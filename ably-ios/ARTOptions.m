//
//  ARTOptions.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTOptions.h"

@interface ARTOptions ()
{
    
}
@property (readwrite, strong, nonatomic) NSString *realtimeHost;
- (instancetype)initDefaults;

@end

@implementation ARTOptions

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

-(NSString * ) defaultRestHost {
    return @"rest.ably.io";
}
-(NSString *) defaultRealtimeHost {
    return @"realtime.ably.io";
}

-(int) defaultRestPort {
    return 443;
}

-(int) defaultRealtimePort {
    return 443;
}

- (instancetype)initDefaults {
    _clientId = nil;
    _restHost =  [self defaultRestHost];
    _realtimeHost = [self defaultRealtimeHost];
    _restPort = [self defaultRestPort];
    _realtimePort = [self defaultRealtimePort];
    _queueMessages = NO;
    _resume = nil;
    _echoMessages = YES;
    _recover = nil;
    _binary = false;
    _resumeKey = nil;
    
    return self;
}

+ (instancetype)options {
    return [[ARTOptions alloc] init];
}

+ (instancetype)optionsWithKey:(NSString *)key {
    return [[ARTOptions alloc] initWithKey:key];
}

- (NSURL *)restUrl {
    NSString *s = [NSString stringWithFormat:@"https://%@:%d", self.restHost, self.restPort];
    return [NSURL URLWithString:s];
}

- (instancetype)clone {
    ARTOptions *options = [[ARTOptions alloc] init];
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
    options.resume = self.resume;
    options.resumeKey = self.resumeKey;

    return options;
}

-(void) setRealtimeHost:(NSString *)realtimeHost withRestHost:(NSString *) restHost
{
    self.realtimeHost = realtimeHost;
    self.restHost = restHost;
}
-(NSString *) realtimeHost
{
    return _realtimeHost;
}

@end
