//
//  ARTHttpPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTHttp.h>
#import <ably/ARTPaginatedResult.h>

@interface ARTHttpPaginatedResult : ARTPaginatedResult

typedef NSArray *(^ARTHttpResponseProcessor)(ARTHttpResponse *);

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithHttp:(ARTHttp *)http
                       items:(NSArray *)items
                 contentType:(NSString *)contentType
                    relFirst:(ARTHttpRequest *)relFirst
                  relCurrent:(ARTHttpRequest *)relCurrent
                     relNext:(ARTHttpRequest *)relNext
           responseProcessor:(ARTHttpResponseProcessor)responseProcessor;

+ (id<ARTCancellable>)makePaginatedRequest:(ARTHttp *)http
                                   request:(ARTHttpRequest *)request
                         responseProcessor:(ARTHttpResponseProcessor)responseProcessor
                                  callback:(ARTPaginatedResultCallback)callback;

@end
