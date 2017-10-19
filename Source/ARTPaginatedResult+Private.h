//
//  ARTPaginatedResult+Private.h
//  ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Ably/ARTPaginatedResult.h>

@class ARTRest;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPaginatedResult<ItemType> ()

typedef NSArray<ItemType> *_Nullable(^ARTPaginatedResultResponseProcessor)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable *_Nullable);

+ (void)executePaginated:(ARTRest *)rest withRequest:(NSMutableURLRequest *)request
              andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
                       callback:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
