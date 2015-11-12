//
//  ARTRestChannel.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRestChannel.h"

#import "ARTRest+Private.h"
#import "ARTChannel+Private.h"
#import "ARTChannelOptions.h"
#import "ARTPresence.h"
#import "ARTMessage.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTEncoder.h"
#import "ARTAuth.h"
#import "ARTNSArray+ARTFunctional.h"

@implementation ARTRestChannel {
@public
    NSString *_basePath;
}

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRest *)rest {
    if (self = [super initWithName:name andOptions:options]) {
        _rest = rest;
        _basePath = [NSString stringWithFormat:@"/channels/%@", [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
        [self.logger debug:@"ARTRestChannel: instantiating under %@", name];
    }
    return self;
}

- (ARTLog *)getLogger {
    return _rest.logger;
}

- (void)history:(ARTDataQuery *)query callback:(void(^)(ARTPaginatedResult *result, NSError *error))callback {
    NSParameterAssert(query.limit < 1000);
    NSParameterAssert([query.start compare:query.end] != NSOrderedDescending);

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_basePath stringByAppendingPathComponent:@"messages"]];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^NSArray *(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [_rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodeMessages:data] artMap:^(ARTMessage *message) {
            return [message decode:_payloadEncoder];
        }];
    };
    
    [ARTPaginatedResult executePaginatedRequest:request executor:_rest.httpExecutor responseProcessor:responseProcessor callback:callback];
}

- (void)internalPostMessages:(id)data callback:(ARTErrorCallback)callback {
    NSData *encodedMessage = nil;
    
    if ([data isKindOfClass:[ARTMessage class]]) {
        ARTMessage *message = (ARTMessage *)data;
        message.clientId = self.rest.auth.clientId;
        encodedMessage = [self.rest.defaultEncoder encodeMessage:message];
    } else if ([data isKindOfClass:[NSArray class]]) {
        encodedMessage = [self.rest.defaultEncoder encodeMessages:data];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[_basePath stringByAppendingPathComponent:@"messages"]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = encodedMessage;
    
    if (self.rest.defaultEncoding) {
        [request setValue:self.rest.defaultEncoding forHTTPHeaderField:@"Content-Type"];
    }
    
    [self.rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (callback) {
            callback(error);
        }
    }];
}

@end
