//
//  ARTTokenParams.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTClientOptions.h"

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
@property (art_nullable, nonatomic, copy, readwrite) NSString *clientId;

/**
 Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
 */
@property (art_nullable, nonatomic, copy, readwrite) NSDate *timestamp;

@property (nonatomic, readonly, strong) NSString *nonce;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *__art_nullable)clientId;
- (instancetype)initWithClientId:(NSString *__art_nullable)clientId nonce:(NSString *__art_nullable)nonce;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams;

- (__GENERIC(NSMutableArray, NSURLQueryItem *) *)toArray;
- (__GENERIC(NSArray, NSURLQueryItem *) *)toArrayWithUnion:(NSArray *)items;
- (__GENERIC(NSDictionary, NSString *, NSString *) *)toDictionaryWithUnion:(__GENERIC(NSArray, NSURLQueryItem *) *)items;

@end

ART_ASSUME_NONNULL_END
