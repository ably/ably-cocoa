//
//  ARTChannelOptions.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@class ARTCipherParams;

ART_ASSUME_NONNULL_BEGIN

@interface ARTChannelOptions : NSObject

@property (nonatomic, assign) BOOL encrypted;
@property (nonatomic, strong, art_nullable) ARTCipherParams *cipherParams;

- (instancetype)initEncrypted:(BOOL)encrypted cipherParams:(ARTCipherParams *__art_nullable)cipherParams;

@end

ART_ASSUME_NONNULL_END
