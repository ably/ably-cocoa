//
//  ARTRestChannel.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRestChannel+Private.h"

#import "ARTRest+Private.h"
#import "ARTRestPresence+Private.h"
#import "ARTChannel+Private.h"
#import "ARTChannelOptions.h"
#import "ARTMessage.h"
#import "ARTBaseMessage+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTAuth.h"
#import "ARTTokenDetails.h"
#import "ARTNSArray+ARTFunctional.h"

@implementation ARTRestChannel {
@private
    ARTRestPresence *_restPresence;
@public
    NSString *_basePath;
}

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRest *)rest {
    if (self = [super initWithName:name andOptions:options andLogger:rest.logger]) {
        _rest = rest;
        _basePath = [NSString stringWithFormat:@"/channels/%@", [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p instantiating under '%@'", self, name];
    }
    return self;
}

- (ARTLog *)getLogger {
    return _rest.logger;
}

- (NSString *)getBasePath {
    return _basePath;
}

- (ARTRestPresence *)getPresence {
    if (!_restPresence) {
        _restPresence = [[ARTRestPresence alloc] initWithChannel:self];
    }
    return _restPresence;
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback {
    [self history:[[ARTDataQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTDataQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
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

    NSURLComponents *componentsUrl = [NSURLComponents componentsWithString:[_basePath stringByAppendingPathComponent:@"messages"]];
    componentsUrl.queryItems = [query asQueryItems];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:componentsUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^NSArray *(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [_rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodeMessages:data] artMap:^(ARTMessage *message) {
            NSError *error;
            message = [message decodeWithEncoder:self.dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:(ARTErrorInfo *)error.userInfo[NSLocalizedFailureReasonErrorKey] prepend:@"Failed to decode data: "];
                [self.logger error:@"RS:%p %@", _rest, errorInfo.message];
            }
            return message;
        }];
    };

    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p stats request %@", _rest, request];
    [ARTPaginatedResult executePaginated:_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
    return YES;
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSData *encodedMessage = nil;
    
    if ([data isKindOfClass:[ARTMessage class]]) {
        ARTMessage *message = (ARTMessage *)data;
        if (message.clientId && self.rest.auth.clientId && ![message.clientId isEqualToString:self.rest.auth.clientId]) {
            callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
            return;
        }
        else {
            message.clientId = self.rest.auth.clientId;
        }
        encodedMessage = [self.rest.defaultEncoder encodeMessage:message];
    } else if ([data isKindOfClass:[NSArray class]]) {
        __GENERIC(NSArray, ARTMessage *) *messages = (NSArray *)data;
        for (ARTMessage *message in messages) {
            if (message.clientId && self.rest.auth.clientId && ![message.clientId isEqualToString:self.rest.auth.clientId]) {
                callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
                return;
            }
        }
        encodedMessage = [self.rest.defaultEncoder encodeMessages:data];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[_basePath stringByAppendingPathComponent:@"messages"]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = encodedMessage;
    
    if (self.rest.defaultEncoding) {
        [request setValue:self.rest.defaultEncoding forHTTPHeaderField:@"Content-Type"];
    }

    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p post message %@", _rest, [[NSString alloc] initWithData:encodedMessage encoding:NSUTF8StringEncoding]];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (callback) {
            ARTErrorInfo *errorInfo = error ? [ARTErrorInfo createWithNSError:error] : nil;
            callback(errorInfo);
        }
    }];
}

@end
