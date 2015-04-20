//
//  ARTHttpPaginatedResult.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTHttpPaginatedResult.h"

@interface ARTHttpPaginatedResult ()

@property (readonly, strong, nonatomic) ARTHttp *http;
@property (readonly, strong, nonatomic) id currentValue;
@property (readonly, strong, nonatomic) NSString *contentType;
@property (readonly, strong, nonatomic) ARTHttpRequest *relFirst;
@property (readonly, strong, nonatomic) ARTHttpRequest *relCurrent;
@property (readonly, strong, nonatomic) ARTHttpRequest *relNext;
@property (readonly, strong, nonatomic) ARTHttpResponseProcessor responseProcessor;

@end

@implementation ARTHttpPaginatedResult

- (instancetype)initWithHttp:(ARTHttp *)http current:(id)current contentType:(NSString *)contentType relFirst:(ARTHttpRequest *)relFirst relCurrent:(ARTHttpRequest *)relCurrent relNext:(ARTHttpRequest *)relNext responseProcessor:(ARTHttpResponseProcessor)responseProcessor {
    self = [super init];
    if (self) {
        _http = http;
        _currentValue = current;
        _contentType = contentType;
        _relFirst = relFirst;
        _relCurrent = relCurrent;
        _relNext = relNext;
        _responseProcessor = responseProcessor;
    }
    return self;
}

- (id)currentItems {
    return self.currentValue;
}

- (BOOL)hasFirst {
    return !!self.relFirst;
}

- (BOOL)hasCurrent {
    return !!self.relCurrent;
}

- (BOOL)hasNext {
    return !!self.relNext;
}

- (void)getFirstPage:(ARTPaginatedResultCb)cb {
    [ARTHttpPaginatedResult makePaginatedRequest:self.http request:self.relFirst responseProcessor:self.responseProcessor cb:cb];
}

- (void)getCurrentPage:(ARTPaginatedResultCb)cb {
    [ARTHttpPaginatedResult makePaginatedRequest:self.http request:self.relCurrent responseProcessor:self.responseProcessor cb:cb];
}

- (void)getNextPage:(ARTPaginatedResultCb)cb {
    [ARTHttpPaginatedResult makePaginatedRequest:self.http request:self.relNext responseProcessor:self.responseProcessor cb:cb];
}


+ (id<ARTCancellable>)makePaginatedRequest:(ARTHttp *)http request:(ARTHttpRequest *)request responseProcessor:(ARTHttpResponseProcessor)responseProcessor cb:(ARTPaginatedResultCb)cb {
    return [http makeRequest:request cb:^(ARTHttpResponse *response) {
        if (!response) {
            cb(ARTStatusError, nil);
            return;
        }

        if (response.status < 200 || response.status >= 300) {
            cb(ARTStatusError, nil);
//            NSLog(@"Body: %@", [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding]);
            return;
        }

        id currentValue = responseProcessor(response);

        NSString *contentType = response.contentType;
        NSDictionary *links = response.links;

        ARTHttpRequest *firstRelRequest = [request requestWithRelativeUrl:[links objectForKey:@"first"]];
        ARTHttpRequest *currentRelRequest = [request requestWithRelativeUrl:[links objectForKey:@"current"]];
        ARTHttpRequest *nextRelRequest = [request requestWithRelativeUrl:[links objectForKey:@"next"]];

        cb(ARTStatusOk, [[ARTHttpPaginatedResult alloc] initWithHttp:http current:currentValue contentType:contentType relFirst:firstRelRequest relCurrent:currentRelRequest relNext:nextRelRequest responseProcessor:responseProcessor]);
    }];
}

@end
