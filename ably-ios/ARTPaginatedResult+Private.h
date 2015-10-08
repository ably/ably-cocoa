//
//  ARTPaginatedResult+Private.h
//  ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPaginatedResult.h"

@protocol ARTHTTPExecutor;

@interface ARTPaginatedResult ()

typedef NSArray *(^ARTPaginatedResultResponseProcessor)(NSHTTPURLResponse *, NSData *);

+ (void)executePaginatedRequest:(NSMutableURLRequest *)request executor:(id<ARTHTTPExecutor>)executor
              responseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor
                       callback:(ARTPaginatedResultCallback)callback;

@end