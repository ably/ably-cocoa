//
//  ARTTokenRequest.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTokenParams.h"

ART_ASSUME_NONNULL_BEGIN

/**
 Type containing the token request details.
 */
@interface ARTTokenRequest : ARTTokenParams

/**
 Identifier for the key (public).
 */
@property (nonatomic, readonly, copy) NSString *keyName;

/**
 Unique 16+ character nonce.
 */
@property (nonatomic, readonly, copy) NSString *nonce;

/**
 Valid HMAC is created using the key secret.
 */
@property (nonatomic, readonly, copy) NSString *mac;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac;

@end

ART_ASSUME_NONNULL_END
