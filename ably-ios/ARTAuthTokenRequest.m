//
//  ARTAuthTokenRequest.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTAuthTokenRequest.h"

#import "ARTAuthTokenParams.h"

@implementation ARTAuthTokenRequest

@dynamic timestamp;

- (instancetype)initWithTokenParams:(ARTAuthTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac {
    if (self = [super init]) {
        self.ttl = tokenParams.ttl;
        self.capability = tokenParams.capability;
        self.clientId = tokenParams.clientId;
        self.timestamp = tokenParams.timestamp;
        _keyName = [keyName copy];
        _nonce = [nonce copy];
        _mac = [mac copy];
    }
    return self;
}

- (NSDictionary *)asDictionary {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTAuthTokenRequest: keyName=%@ clientId=%@ nonce=%@ mac=%@ ttl=%f capability=%@ timestamp=%@",
            self.keyName, self.clientId, self.nonce, self.mac, self.ttl, self.capability, self.timestamp];
}

@end
