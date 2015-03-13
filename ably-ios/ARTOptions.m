//
//  ARTOptions.m
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTOptions.h"

@interface ARTOptions ()

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

- (instancetype)initDefaults {
    _clientId = nil;
    _restHost = @"rest.ably.io";
    _realtimeHost = @"realtime.ably.io";
    _restPort = 443;
    _realtimePort = 443;
    _queueMessages = NO;
    _echoMessages = YES;
    _recover = nil;
    _binary = false;
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
    NSLog(@"REST URL IS %@", s);
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

    return options;
}

@end
