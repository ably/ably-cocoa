//
//  ARTChannelOptions.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTChannelOptions.h"

#import "ARTEncoder.h"

@implementation ARTChannelOptions

- (instancetype)initEncrypted:(ARTCipherParams *)cipherParams {
    if (self = [super init]) {
        self->_encrypted = YES;
        self->_cipherParams = cipherParams;
    }
    
    return self;
}

+ (instancetype)unencrypted {
    static id unencrypted;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        unencrypted = [[ARTChannelOptions alloc] init];
    });
    
    return unencrypted;
}

@end
