//
//  ARTPaginatedResult+Private.h
//  ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPaginatedResult.h"

@class ARTRest;

ART_ASSUME_NONNULL_BEGIN

@interface ARTPaginatedResult ()

typedef NSArray *__art_nullable(^ARTPaginatedResultResponseProcessor)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable);

+ (void)executePaginated:(ARTRest *)rest withRequest:(NSMutableURLRequest *)request
              andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
                       callback:(ARTPaginatedResultCallback)callback;

@end

ART_ASSUME_NONNULL_END
