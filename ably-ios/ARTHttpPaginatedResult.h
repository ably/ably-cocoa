//
//  ARTHttpPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTHttp.h"
#import "ARTPaginatedResult.h"

@interface ARTHttpPaginatedResult : NSObject <ARTPaginatedResult>

typedef id (^ARTHttpResponseProcessor)(ARTHttpResponse *);

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithHttp:(ARTHttp *)http current:(id)current contentType:(NSString *)contentType relFirst:(ARTHttpRequest *)relFirst relCurrent:(ARTHttpRequest *)relCurrent relNext:(ARTHttpRequest *)relNext responseProcessor:(ARTHttpResponseProcessor)responseProcessor;

+ (id<ARTCancellable>)makePaginatedRequest:(ARTHttp *)http request:(ARTHttpRequest *)request responseProcessor:(ARTHttpResponseProcessor)responseProcessor cb:(ARTPaginatedResultCb)cb;

@end
