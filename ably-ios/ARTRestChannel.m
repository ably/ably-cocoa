//
//  ARTRestChannel.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRestChannel.h"

#import "ARTRest.h"
#import "ARTChannelOptions.h"
#import "ARTChannel+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"

@implementation ARTRestChannel

@dynamic presence;

- (instancetype)initWithRest:(ARTRest *)rest name:(NSString *)name options:(ARTChannelOptions *)options {
    self = [super init];
    /*
    if (self = [super initWithName:name presence:[[ARTRestPresence alloc] initWithChannel:self] options:options]) {
        _logger = rest.logger;
        [_logger debug:@"ARTRestChannel: instantiating under %@", name];
        _rest = rest;
        _basePath = [NSString stringWithFormat:@"/channels/%@", [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    }
     */
    
    return self;
}


- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult *, NSError *))callback {
    NSParameterAssert(query.limit < 1000);
    NSParameterAssert([query.start compare:query.end] != NSOrderedDescending);
    
    // FIXME:
    /*
    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_basePath stringByAppendingPathComponent:@"messages"]];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];
    
    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [_rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodeMessages:data] artMap:^(ARTMessage *message) {
            return [message decode:_payloadEncoder];
        }];
    };
    
    [ARTPaginatedResult executePaginatedRequest:request executor:_rest responseProcessor:responseProcessor callback:callback];
     */
}

- (void)_postMessages:(id)payload callback:(ARTErrorCallback)callback {
    //FIXME:
    /*
    NSData *encodedMessage = nil;
    if ([payload isKindOfClass:[ARTMessage class]]) {
        encodedMessage = [_rest.defaultEncoder encodeMessage:payload];
    } else if ([payload isKindOfClass:[NSArray class]]) {
        encodedMessage = [_rest.defaultEncoder encodeMessages:payload];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[_basePath stringByAppendingPathComponent:@"messages"]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = encodedMessage;
    if (_rest.defaultEncoding) {
        [request setValue:_rest.defaultEncoding forHTTPHeaderField:@"Content-Type"];
    }
    
    [_rest executeRequest:request callback:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (callback) {
            callback(error);
        }
    }];
     */
}

@end
