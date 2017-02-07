//
//  ARTPaginatedResult.m
//  ably
//
//  Created by Yavor Georgiev on 10.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPaginatedResult+Private.h"

#import "ARTHttp.h"
#import "ARTAuth.h"
#import "ARTRest+Private.h"

@implementation ARTPaginatedResult {
    __weak ARTRest *_rest;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
    NSMutableURLRequest *_relFirst;
    NSMutableURLRequest *_relCurrent;
    NSMutableURLRequest *_relNext;
    ARTPaginatedResultResponseProcessor _responseProcessor;
}

- (instancetype)initWithItems:(NSArray *)items
                     rest:(ARTRest *)rest
                     relFirst:(NSMutableURLRequest *)relFirst
                   relCurrent:(NSMutableURLRequest *)relCurrent
                      relNext:(NSMutableURLRequest *)relNext
            responseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor {
    if (self = [super init]) {
        _items = items;
        
        _relFirst = relFirst;
        
        _relCurrent = relCurrent;
        
        _relNext = relNext;
        _hasNext = !!relNext;
        _isLast = !_hasNext;
        
        _rest = rest;
        _userQueue = rest.userQueue;
        _queue = rest.queue;
        _responseProcessor = responseProcessor;
    }
    
    return self;
}

- (void)first:(void (^)(__GENERIC(ARTPaginatedResult, id) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (callback) {
        void (^userCallback)(__GENERIC(ARTPaginatedResult, id) *__art_nullable result, ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(__GENERIC(ARTPaginatedResult, id) *__art_nullable result, ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    [self.class executePaginated:_rest withRequest:_relFirst andResponseProcessor:_responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)next:(void (^)(__GENERIC(ARTPaginatedResult, id) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (callback) {
        void (^userCallback)(__GENERIC(ARTPaginatedResult, id) *__art_nullable result, ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(__GENERIC(ARTPaginatedResult, id) *__art_nullable result, ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_rest);
            dispatch_async(_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    if (!_relNext) {
        // If there is no next page, we can't make a request, so we answer the callback
        // with a nil PaginatedResult. That's why the callback has the result as nullable
        // anyway. (That, and that it can fail.)
        callback(nil, nil);
        return;
    }
    [self.class executePaginated:_rest withRequest:_relNext andResponseProcessor:_responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

static NSDictionary *extractLinks(NSHTTPURLResponse *response) {
    NSString *linkHeader = response.allHeaderFields[@"Link"];
    if (!linkHeader) {
        return nil;
    }
    
    static NSRegularExpression *linkRegex;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        linkRegex = [NSRegularExpression regularExpressionWithPattern:@"\\s*<([^>]*)>;\\s*rel=\"([^\"]*)\"" options:0 error:nil];
    });
    
    NSMutableDictionary *links = [NSMutableDictionary dictionary];
    
    NSArray *matches = [linkRegex matchesInString:linkHeader options:0 range:NSMakeRange(0, linkHeader.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange linkUrlRange = [match rangeAtIndex:1];
        NSRange linkRelRange = [match rangeAtIndex:2];
        
        NSString *linkUrl = [linkHeader substringWithRange:linkUrlRange];
        NSString *linkRels = [linkHeader substringWithRange:linkRelRange];
        
        for (NSString *linkRel in [linkRels componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
            [links setObject:linkUrl forKey:linkRel];
        }
    }
    
    return links;
}

static NSMutableURLRequest *requestRelativeTo(NSMutableURLRequest *request, NSString *path) {
    if (!path) {
        return nil;
    }
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:request.URL];
    return [NSMutableURLRequest requestWithURL:url];
}

+ (void)executePaginated:(ARTRest *)rest withRequest:(NSMutableURLRequest *)request andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor callback:(void (^)(__GENERIC(ARTPaginatedResult, id) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(rest) {
    [rest.logger debug:__FILE__ line:__LINE__ message:@"Paginated request: %@", request];

    [rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, [ARTErrorInfo createFromNSError:error]);
        } else {
            [[rest logger] debug:__FILE__ line:__LINE__ message:@"Paginated response: %@", response];
            [[rest logger] debug:__FILE__ line:__LINE__ message:@"Paginated response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];

            NSError *decodeError = nil;
            NSArray *items = responseProcessor(response, data, &decodeError);

            if (decodeError) {
                callback(nil, [ARTErrorInfo createFromNSError:decodeError]);
                return;
            }

            NSDictionary *links = extractLinks(response);

            NSMutableURLRequest *firstRel = requestRelativeTo(request, links[@"first"]);
            NSMutableURLRequest *currentRel = requestRelativeTo(request, links[@"current"]);;
            NSMutableURLRequest *nextRel = requestRelativeTo(request, links[@"next"]);;

            ARTPaginatedResult *result = [[ARTPaginatedResult alloc] initWithItems:items
                                                                              rest:rest
                                                                          relFirst:firstRel
                                                                        relCurrent:currentRel
                                                                           relNext:nextRel
                                                                 responseProcessor:responseProcessor];

            callback(result, nil);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
}

@end
