//
//  ARTChannelOptions.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTCrypto.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTChannelOptions : NSObject

@property (nonatomic, strong, art_nullable) ARTCipherParams *cipher;


- (instancetype)initWithCipher:(id<ARTCipherParamsCompatible> __art_nullable)cipherParams;
- (instancetype)initWithCipherKey:(id<ARTCipherKeyCompatible>)key;

@end

ART_ASSUME_NONNULL_END
