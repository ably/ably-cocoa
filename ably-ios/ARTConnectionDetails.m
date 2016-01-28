//
//  ARTConnectionDetails.m
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnectionDetails.h"

@implementation ARTConnectionDetails

- (instancetype)initWithClientId:(NSString *__art_nullable)clientId connectionKey:(NSString *__art_nullable)connectionKey {
    if (self == [super init]) {
        _clientId = clientId;
        _connectionKey = connectionKey;
    }
    return self;
}

@end
