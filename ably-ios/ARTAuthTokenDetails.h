//
//  ARTAuthTokenDetails.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTAuthTokenDetails : NSObject

@property (nonatomic, readonly, copy) NSString *token;
@property (nonatomic, readonly, strong, art_nullable) NSDate *expires;
@property (nonatomic, readonly, strong, art_nullable) NSDate *issued;
@property (nonatomic, readonly, copy, art_nullable) NSString *capability;
@property (nonatomic, readonly, copy, art_nullable) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithToken:(NSString *)token;

- (instancetype)initWithToken:(NSString *)token expires:(NSDate *)expires issued:(NSDate *)issued capability:(NSString *)capability clientId:(NSString *)clientId;

@end

ART_ASSUME_NONNULL_END
