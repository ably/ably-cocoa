//
//  ARTAuthTokenDetails.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTAuthTokenDetails.h"

@implementation ARTAuthTokenDetails

- (instancetype)initWithToken:(NSString *)token expires:(NSDate *)expires issued:(NSDate *)issued capability:(NSString *)capability clientId:(NSString *)clientId {
    if (self = [super init]) {
        _token  = [token copy];
        _expires = expires;
        _issued = issued;
        _capability = [capability copy];
        _clientId = [clientId copy];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)token {
    if (self = [super init]) {
        _token = [token copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTAuthTokenDetails: token=%@ clientId=%@ issued=%@ expires=%@",
            self.token, self.clientId, self.issued, self.expires];
}

@end
