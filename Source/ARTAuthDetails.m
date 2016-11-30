//
//  ARTAuthDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 19/10/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "ARTAuthDetails.h"

@implementation ARTAuthDetails

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t accessToken: %@; \n", [super description], self.accessToken];
}

- (id)copyWithZone:(NSZone *)zone {
    ARTAuthDetails *authDetails = [[[self class] allocWithZone:zone] init];
    authDetails.accessToken = self.accessToken;
    return authDetails;
}

@end
