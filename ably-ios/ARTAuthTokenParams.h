//
//  ARTAuthTokenParams.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTAuthTokenRequest;

NS_ASSUME_NONNULL_BEGIN

@interface ARTAuthTokenParams : NSObject

@property (nonatomic, assign) NSTimeInterval ttl;
@property (nonatomic, copy) NSString *capability;
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, strong, null_resettable) NSDate *timestamp;

- (instancetype)init;

- (NSMutableArray *)toArray; //X7: NSArray<NSURLQueryItem *>
- (NSArray *)toArrayWithUnion:(NSArray *)items; //X7: NSArray<NSURLQueryItem *>
- (NSDictionary *)toDictionaryWithUnion:(NSArray *)items;

@end

@interface ARTAuthTokenParams(SignedRequest)

- (ARTAuthTokenRequest *)sign:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
