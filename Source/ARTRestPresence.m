//
//  ARTRestPresence.m
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTRestPresence+Private.h"

#import "ARTPresence+Private.h"
#import "ARTRest+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTChannel+Private.h"
#import "ARTBaseMessage+Private.h"

#import "ARTChannel.h"
#import "ARTDataQuery.h"

@implementation ARTPresenceQuery

- (instancetype)init {
    return [self initWithClientId:nil connectionId:nil];
}

- (instancetype)initWithClientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    return [self initWithLimit:100 clientId:clientId connectionId:connectionId];
}

- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    self = [super init];
    if (self) {
        _limit = limit;
        _clientId = clientId;
        _connectionId = connectionId;
    }
    return self;
}

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [NSMutableArray array];

    if (self.clientId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"clientId" value:self.clientId]];
    }
    if (self.connectionId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"connectionId" value:self.connectionId]];
    }

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%lu", (unsigned long)self.limit]]];

    return items;
}

@end

@implementation ARTRestPresence {
    __weak ARTRestChannel *_channel;
}

- (instancetype)initWithChannel:(ARTRestChannel *)channel {
    if (self = [super init]) {
        _channel = channel;
    }
    return self;
}

- (void)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback {
    [self get:[[ARTPresenceQuery alloc] init] callback:callback error:nil];
}

- (BOOL)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
    return [self get:[[ARTPresenceQuery alloc] init] callback:callback error:errorPtr];
}

- (BOOL)get:(ARTPresenceQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
    if (query.limit > 1000) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorLimit
                                        userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        }
        return NO;
    }

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_channel.basePath stringByAppendingPathComponent:@"presence"]];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [_channel.rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodePresenceMessages:data] artMap:^(ARTPresenceMessage *message) {
            // FIXME: This should be refactored to be done by ART{Json,...}Encoder.
            // The ART{Json,...}Encoder should take a ARTDataEncoder and use it every
            // time it is enc/decoding a message. This also applies for REST and Realtime
            // ARTMessages.
            message = [message decodeWithEncoder:_channel.dataEncoder error:nil];
            return message;
        }];
    };

    [ARTPaginatedResult executePaginated:_channel.rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
    return YES;
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback {
    [self history:[[ARTDataQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTDataQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
    if (query.limit > 1000) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorLimit
                                        userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        }
        return NO;
    }
    if ([query.start compare:query.end] == NSOrderedDescending) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorTimestampRange
                                        userInfo:@{NSLocalizedDescriptionKey:@"Start must be equal to or less than end"}];
        }
        return NO;
    }

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_channel.basePath stringByAppendingPathComponent:@"presence/history"]];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [_channel.rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodePresenceMessages:data] artMap:^(ARTPresenceMessage *message) {
            NSError *error;
            message = [message decodeWithEncoder:_channel.dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:(ARTErrorInfo *)error.userInfo[NSLocalizedFailureReasonErrorKey] prepend:@"Failed to decode data: "];
                [_channel.logger error:@"RS:%p %@", _channel.rest, errorInfo.message];
            }
            return message;
        }];
    };

    [ARTPaginatedResult executePaginated:_channel.rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
    return YES;
}

@end
