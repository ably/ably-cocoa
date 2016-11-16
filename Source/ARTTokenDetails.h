//
//  ARTTokenDetails.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTAuthOptions.h"

ART_ASSUME_NONNULL_BEGIN

/**
 Type containing the token request response.
 */
@interface ARTTokenDetails : NSObject<NSCopying>

/**
 Token string.
 */
@property (nonatomic, readonly, copy) NSString *token;

/**
 Contains the expiry time in milliseconds.
 */
@property (nonatomic, readonly, strong, art_nullable) NSDate *expires;

/**
 Contains the time the token was issued in milliseconds.
 */
@property (nonatomic, readonly, strong, art_nullable) NSDate *issued;

/**
 Contains the capability JSON stringified.
 */
@property (nonatomic, readonly, copy, art_nullable) NSString *capability;

/**
 Contains the clientId assigned to the token if provided.
 */
@property (nonatomic, readonly, copy, art_nullable) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithToken:(NSString *)token;
- (instancetype)initWithToken:(NSString *)token expires:(art_nullable NSDate *)expires issued:(art_nullable  NSDate *)issued capability:(art_nullable  NSString *)capability clientId:(art_nullable NSString *)clientId;

+ (ARTTokenDetails *__art_nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *__art_nullable *__art_nullable)error;

@end

@interface ARTTokenDetails (ARTTokenDetailsCompatible) <ARTTokenDetailsCompatible>
@end

ART_ASSUME_NONNULL_END
