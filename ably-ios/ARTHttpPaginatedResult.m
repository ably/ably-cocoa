//
//  ARTHttpPaginatedResult.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTHttpPaginatedResult.h"
#import "ARTLog.h"
#import "ARTStatus.h"

@implementation ARTHttpPaginatedResult {
    ARTHttp *_http;
    NSString *_contentType;
    ARTHttpRequest *_relFirst;
    ARTHttpRequest *_relCurrent;
    ARTHttpRequest *_relNext;
    ARTHttpResponseProcessor _responseProcessor;
}

- (instancetype)initWithHttp:(ARTHttp *)http items:(NSArray *)items contentType:(NSString *)contentType relFirst:(ARTHttpRequest *)relFirst relCurrent:(ARTHttpRequest *)relCurrent relNext:(ARTHttpRequest *)relNext responseProcessor:(ARTHttpResponseProcessor)responseProcessor {
    self = [super init];
    if (self) {
        _http = http;

        _items = [items copy];
        _contentType = [contentType copy];

        _hasFirst = !!relFirst;
        _relFirst = relFirst;

        _hasCurrent = !!relCurrent;
        _relCurrent = relCurrent;

        _hasNext = !!relNext;
        _relNext = relNext;

        _responseProcessor = responseProcessor;
    }
    return self;
}

- (void)first:(ARTPaginatedResultCallback)callback {
    [ARTHttpPaginatedResult makePaginatedRequest:_http request:_relFirst responseProcessor:_responseProcessor callback:callback];
}

- (void)current:(ARTPaginatedResultCallback)callback {
    [ARTHttpPaginatedResult makePaginatedRequest:_http request:_relCurrent responseProcessor:_responseProcessor callback:callback];
}

- (void)next:(ARTPaginatedResultCallback)callback {
    [ARTHttpPaginatedResult makePaginatedRequest:_http request:_relNext responseProcessor:_responseProcessor callback:callback];
}


+ (id<ARTCancellable>)makePaginatedRequest:(ARTHttp *)http request:(ARTHttpRequest *)request responseProcessor:(ARTHttpResponseProcessor)responseProcessor callback:(ARTPaginatedResultCallback)callback {
    return [http makeRequest:request cb:^(ARTHttpResponse *response) {
        if (!response) {
            ARTErrorInfo * info = [[ARTErrorInfo alloc] init];
            [info setCode:40000 message:@"ARTHttpPaginatedResult got no response"];
            [ARTStatus state:ARTStatusError info:info];
            callback([ARTStatus state:ARTStatusError info:info], nil);
            return;
        }

        if (response.status < 200 || response.status >= 300) {
            ARTErrorInfo * info = [[ARTErrorInfo alloc] init];
            [info setCode:40000 message:[NSString stringWithFormat:@"ARTHttpPaginatedResult response.status invalid: %d", response.status]];
            callback([ARTStatus state:ARTStatusError info:info], nil);
            
            return;
        }

        NSArray *items = responseProcessor(response);

        NSString *contentType = response.contentType;
        NSDictionary *links = response.links;

        ARTHttpRequest *firstRelRequest = [request requestWithRelativeUrl:[links objectForKey:@"first"]];
        ARTHttpRequest *currentRelRequest = [request requestWithRelativeUrl:[links objectForKey:@"current"]];
        ARTHttpRequest *nextRelRequest = [request requestWithRelativeUrl:[links objectForKey:@"next"]];

        ARTPaginatedResult *result = [[ARTHttpPaginatedResult alloc] initWithHttp:http
                                                                            items:items
                                                                      contentType:contentType
                                                                         relFirst:firstRelRequest
                                                                       relCurrent:currentRelRequest
                                                                          relNext:nextRelRequest responseProcessor:responseProcessor];
        callback([ARTStatus state:ARTStatusOk], result);
    }];
}

@end
