//
//  ARTTokenParams.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@class ARTTokenRequest;

ART_ASSUME_NONNULL_BEGIN

/**
 Type that provided parameters of a token request.
 */
@interface ARTTokenParams : NSObject

/**
 Represents time to live (expiry) of this token in seconds.
 */
@property (nonatomic, assign) NSTimeInterval ttl;

/**
 Contains the capability JSON stringified.
 */
@property (nonatomic, copy) NSString *capability;

/**
 A clientId to associate with this token.
 */
@property (art_nullable, nonatomic, copy) NSString *clientId;

/**
 Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
 */
@property (nonatomic, strong, null_resettable) NSDate *timestamp;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *)clientId;

- (__GENERIC(NSMutableArray, NSURLQueryItem *) *)toArray;
- (__GENERIC(NSArray, NSURLQueryItem *) *)toArrayWithUnion:(NSArray *)items;
- (__GENERIC(NSDictionary, NSString *, NSString *) *)toDictionaryWithUnion:(__GENERIC(NSArray, NSURLQueryItem *) *)items;

@end

@interface ARTTokenParams(SignedRequest)

- (ARTTokenRequest *)sign:(NSString *)key;
- (ARTTokenRequest *)sign:(NSString *)key withNonce:(NSString *)randomNonce;

@end

ART_ASSUME_NONNULL_END
