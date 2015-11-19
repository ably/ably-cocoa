//
//  ARTRestPresence.m
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTRestPresence.h"

#import "ARTPresence.h"
#import "ARTRest+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTNSArray+ARTFunctional.h"

@implementation ARTRestPresence

- (instancetype)initWithChannel:(ARTRestChannel *)channel {
    return [super initWithChannel:channel];
}

- (ARTRestChannel *)channel {
    return (ARTRestChannel *)super.channel;
}

- (void)get:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *result, NSError *error))callback {
    NSURL *requestUrl = [NSURL URLWithString:[[self channel].basePath stringByAppendingPathComponent:@"presence"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [[self channel].rest.encoders objectForKey:response.MIMEType];
        NSArray *messages = [encoder decodePresenceMessages:data];
        return [messages artMap:^id(ARTPresenceMessage *pm) {
            return [pm decode:[self channel].payloadEncoder];
        }];
    };

    [ARTPaginatedResult executePaginated:[self channel].rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *result, NSError *error))callback {
    NSParameterAssert(query.limit < 1000);
    NSParameterAssert([query.start compare:query.end] != NSOrderedDescending);

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[[self channel].basePath stringByAppendingPathComponent:@"presence/history"]];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [[self channel].rest.encoders objectForKey:response.MIMEType];
        NSArray *messages = [encoder decodePresenceMessages:data];
        return [messages artMap:^id(ARTPresenceMessage *pm) {
            return [pm decode:[self channel].payloadEncoder];
        }];
    };

    [ARTPaginatedResult executePaginated:[self channel].rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
}

@end
