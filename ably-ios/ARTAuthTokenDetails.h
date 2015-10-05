//
//  ARTAuthTokenDetails.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTAuthTokenDetails : NSObject

@property (nonatomic, readonly, copy) NSString *token;
@property (nonatomic, readonly, strong, nullable) NSDate *expires;
@property (nonatomic, readonly, strong, nullable) NSDate *issued;
@property (nonatomic, readonly, copy, nullable) NSString *capability;
@property (nonatomic, readonly, copy, nullable) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithToken:(NSString *)token;

- (instancetype)initWithToken:(NSString *)token expires:(NSDate *)expires issued:(NSDate *)issued capability:(NSString *)capability clientId:(NSString *)clientId;

@end

NS_ASSUME_NONNULL_END
