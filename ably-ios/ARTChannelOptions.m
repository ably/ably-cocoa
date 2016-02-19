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

- (instancetype)initEncrypted:(BOOL)encrypted cipherParams:(ARTCipherParams *)cipherParams {
    if (self = [super init]) {
        self->_encrypted = encrypted;
        self->_cipherParams = cipherParams;
    }
    return self;
}

@end
