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
ART_TRY_OR_REPORT_CRASH_START(rest) {
    if (self = [super initWithName:name andOptions:options andLogger:rest.logger]) {
        _rest = rest;
        _basePath = [NSString stringWithFormat:@"/channels/%@", [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p instantiating under '%@'", self, name];
    }
    return self;
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTLog *)getLogger {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return _rest.logger;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *)getBasePath {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return _basePath;
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTRestPresence *)getPresence {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (!_restPresence) {
        _restPresence = [[ARTRestPresence alloc] initWithChannel:self];
    }
    return _restPresence;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self history:[[ARTDataQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)history:(ARTDataQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (callback) {
        void (^userCallback)(__GENERIC(ARTPaginatedResult, ARTMessage *) *result, ARTErrorInfo *error) = callback;
        callback = ^(__GENERIC(ARTPaginatedResult, ARTMessage *) *result, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(_rest);
            userCallback(result, error);
        };
    }

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

    ARTPaginatedResultResponseProcessor responseProcessor = ^NSArray<ARTMessage *> *(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
        id<ARTEncoder> encoder = [_rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodeMessages:data error:errorPtr] artMap:^(ARTMessage *message) {
            NSError *error;
            message = [message decodeWithEncoder:self.dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:@"Failed to decode data: "];
                [self.logger error:@"RS:%p %@", _rest, errorInfo.message];
            }
            return message;
        }];
    };

    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p stats request %@", _rest, request];
    [ARTPaginatedResult executePaginated:_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
    return YES;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_rest);
            userCallback(error);
        };
    }

ART_TRY_OR_REPORT_CRASH_START(_rest) {
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
        NSError *encodeError = nil;
        encodedMessage = [self.rest.defaultEncoder encodeMessage:message error:&encodeError];
        if (encodeError) {
            callback([ARTErrorInfo createFromNSError:encodeError]);
            return;
        }
    } else if ([data isKindOfClass:[NSArray class]]) {
        __GENERIC(NSArray, ARTMessage *) *messages = (NSArray *)data;
        for (ARTMessage *message in messages) {
            if (message.clientId && self.rest.auth.clientId && ![message.clientId isEqualToString:self.rest.auth.clientId]) {
                callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
                return;
            }
        }
        NSError *encodeError = nil;
        encodedMessage = [self.rest.defaultEncoder encodeMessages:data error:&encodeError];
        if (encodeError) {
            callback([ARTErrorInfo createFromNSError:encodeError]);
            return;
        }
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
            ARTErrorInfo *errorInfo = error ? [ARTErrorInfo createFromNSError:error] : nil;
            callback(errorInfo);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
}

@end
