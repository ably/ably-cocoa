//
//  ARTAuthTokenRequest.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTAuthTokenParams.h"

@interface ARTAuthTokenRequest : ARTAuthTokenParams

@property (nonatomic, readonly, copy) NSString *keyName;
@property (nonatomic, readonly, copy) NSString *nonce;
@property (nonatomic, readonly, copy) NSString *mac;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithTokenParams:(ARTAuthTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac;

@end
