//
//  ARTChannelOptions.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "Ably/ARTChannelOptions.h"

#import "Ably/ARTEncoder.h"

@implementation ARTChannelOptions

- (instancetype)initWithCipher:(id<ARTCipherParamsCompatible>)cipherParams {
    if (self = [super init]) {
        self->_cipher = [cipherParams toCipherParams];
    }
    return self;
}

- (instancetype)initWithCipherKey:(id<ARTCipherKeyCompatible>)key {
    return [self initWithCipher:@{@"key": key}];
}

@end
