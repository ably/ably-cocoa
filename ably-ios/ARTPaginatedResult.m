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
        _hasFirst = !!relFirst;
        
        _relCurrent = relCurrent;
        _hasCurrent = !!relCurrent;
        
        _relNext = relNext;
        _hasNext = !!relNext;
        _isLast = !_hasNext;
        
        _rest = rest;
        _responseProcessor = responseProcessor;
    }
    
    return self;
}

- (void)first:(ARTPaginatedResultCallback)callback {
    [self.class executePaginated:_rest withRequest:_relFirst andResponseProcessor:_responseProcessor callback:callback];
}

- (void)current:(ARTPaginatedResultCallback)callback {
    [self.class executePaginated:_rest withRequest:_relCurrent andResponseProcessor:_responseProcessor callback:callback];
}

- (void)next:(ARTPaginatedResultCallback)callback {
    [self.class executePaginated:_rest withRequest:_relNext andResponseProcessor:_responseProcessor callback:callback];
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

+ (void)executePaginated:(ARTRest *)rest withRequest:(NSMutableURLRequest *)request andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor callback:(ARTPaginatedResultCallback)callback {

    [rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            NSArray *items = responseProcessor(response, data);

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
}

@end
