//
//  ARTRest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest+Private.h"

#import "ARTChannel+Private.h"
#import "ARTRestChannels.h"
#import "ARTDataQuery+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTAuth+Private.h"
#import "ARTHttp.h"
#import "ARTEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTJsonEncoder.h"
#import "ARTMsgPackEncoder.h"
#import "ARTMessage.h"
#import "ARTPresence.h"
#import "ARTPresenceMessage.h"
#import "ARTHttp.h"
#import "ARTClientOptions+Private.h"
#import "ARTDefault.h"
#import "ARTStats.h"
#import "ARTFallback.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTRestChannel.h"
#import "ARTTokenParams.h"
#import "ARTTokenDetails.h"
#import "ARTDefault.h"
#import "ARTFallback.h"
#import "ARTGCD.h"

@implementation ARTRest

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRest: No options provided");
        artDispatchSpecifyMainQueue();

        _options = [options copy];

        if (options.logHandler) {
            _logger = options.logHandler;
        }
        else {
            _logger = [[ARTLog alloc] init];
        }

        if (options.logLevel != ARTLogLevelNone) {
            _logger.logLevel = options.logLevel;
        }

        _http = [[ARTHttp alloc] init];
        [_logger debug:__FILE__ line:__LINE__ message:@"RS:%p %p alloc HTTP", self, _http];
        _httpExecutor = _http;
        _httpExecutor.logger = _logger;

        id<ARTEncoder> jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithRest:self delegate:[[ARTJsonEncoder alloc] init]];
        id<ARTEncoder> msgPackEncoder = [[ARTJsonLikeEncoder alloc] initWithRest:self delegate:[[ARTMsgPackEncoder alloc] init]];
        _encoders = @{
            [jsonEncoder mimeType]: jsonEncoder,
            [msgPackEncoder mimeType]: msgPackEncoder
        };
        _defaultEncoding = (_options.useBinaryProtocol ? [msgPackEncoder mimeType] : [jsonEncoder mimeType]);
        _fallbackCount = 0;

        _auth = [[ARTAuth alloc] init:self withOptions:_options];
        _channels = [[ARTRestChannels alloc] initWithRest:self];

        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p initialized", self];
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (instancetype)initWithToken:(NSString *)token {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithToken:token]];
}

- (void)dealloc {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p dealloc", self];
}

- (void)executeRequest:(NSMutableURLRequest *)request withAuthOption:(ARTAuthentication)authOption completion:(void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback {
    request.URL = [NSURL URLWithString:request.URL.relativeString relativeToURL:self.baseUrl];
    
    switch (authOption) {
        case ARTAuthenticationOff:
            [self executeRequest:request completion:callback];
            break;
        case ARTAuthenticationOn:
            [self executeRequestWithAuthentication:request withMethod:self.auth.method force:NO completion:callback];
            break;
        case ARTAuthenticationNewToken:
            [self executeRequestWithAuthentication:request withMethod:self.auth.method force:YES completion:callback];
            break;
        case ARTAuthenticationUseBasic:
            [self executeRequestWithAuthentication:request withMethod:ARTAuthMethodBasic completion:callback];
            break;
    }
}

- (void)executeRequestWithAuthentication:(NSMutableURLRequest *)request withMethod:(ARTAuthMethod)method completion:(void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback {
    [self executeRequestWithAuthentication:request withMethod:method force:NO completion:callback];
}

- (void)executeRequestWithAuthentication:(NSMutableURLRequest *)request withMethod:(ARTAuthMethod)method force:(BOOL)force completion:(void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback {
    [self prepareAuthorisationHeader:method force:force completion:^(NSString *authorization, NSError *error) {
        if (error && callback) {
            callback(nil, nil, error);
        } else {
            // RFC7235
            [request setValue:authorization forHTTPHeaderField:@"Authorization"];
            [self executeRequest:request completion:callback];
        }
    }];
}

- (void)executeRequest:(NSMutableURLRequest *)request completion:(void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback {
    return [self executeRequest:request completion:callback fallbacks:nil retries:0];
}

- (void)executeRequest:(NSMutableURLRequest *)request completion:(void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback fallbacks:(ARTFallback *)fallbacks retries:(NSUInteger)retries {
    __block ARTFallback *blockFallbacks = fallbacks;

    NSString *accept = [[_encoders.allValues valueForKeyPath:@"mimeType"] componentsJoinedByString:@","];
    [request setValue:accept forHTTPHeaderField:@"Accept"];
    [request setValue:[ARTDefault version] forHTTPHeaderField:@"X-Ably-Version"];
    [request setValue:[ARTDefault libraryVersion] forHTTPHeaderField:@"X-Ably-Lib"];

    [request setTimeoutInterval:_options.httpRequestTimeout];

    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p executing request %@", self, request];
    [self.httpExecutor executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode >= 400) {
            NSError *dataError = [self->_encoders[response.MIMEType] decodeError:data];
            if (dataError.code >= 40140 && dataError.code < 40150) {
                // Send it again, requesting a new token (forward callback)
                [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p requesting new token", self];
                [self executeRequest:request withAuthOption:ARTAuthenticationNewToken completion:callback];
                return;
            } else {
                // Return error with HTTP StatusCode if ARTErrorStatusCode does not exist
                if (!dataError) {
                    dataError = [NSError errorWithDomain:ARTAblyErrorDomain code:response.statusCode userInfo:@{NSLocalizedDescriptionKey:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]}];
                }
                error = dataError;
            }
        }
        if (retries < _options.httpMaxRetryCount && [self shouldRetryWithFallback:request response:response error:error]) {
            if (!blockFallbacks && [request.URL.host isEqualToString:(_prioritizedHost ? _prioritizedHost : [ARTDefault restHost])]) {
                blockFallbacks = [[ARTFallback alloc] initWithFallbackHosts:_options.fallbackHosts];
            }
            if (blockFallbacks) {
                NSString *host = [blockFallbacks popFallbackHost];
                if (host != nil) {
                    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p host is down; retrying request at %@", self, host];
                    NSMutableURLRequest *newRequest = [request copy];
                    NSURL *url = request.URL;
                    NSString *urlStr = [NSString stringWithFormat:@"%@://%@:%@%@?%@", url.scheme, host, url.port, url.path, (url.query ? url.query : @"")];
                    newRequest.URL = [NSURL URLWithString:urlStr];
                    [self executeRequest:newRequest completion:callback fallbacks:blockFallbacks retries:retries + 1];
                    return;
                }
            }
        }
        if (callback) {
            // Error object that indicates why the request failed
            callback(response, data, error);
        }
    }];
}

- (BOOL)shouldRetryWithFallback:(NSMutableURLRequest *)request response:(NSHTTPURLResponse *)response error:(NSError *)error {
    if (response.statusCode >= 500 && response.statusCode <= 504) {
        return YES;
    }
    if (error && (error.domain == NSURLErrorDomain && (
        error.code == -1003 || // Unreachable
        error.code == -1001 // timed out
    ))) {
        return YES;
    }
    return NO;
}

- (void)prepareAuthorisationHeader:(ARTAuthMethod)method completion:(void (^)(NSString *authorization, NSError *error))callback {
    [self prepareAuthorisationHeader:method force:NO completion:callback];
}

- (void)prepareAuthorisationHeader:(ARTAuthMethod)method force:(BOOL)force completion:(void (^)(NSString *authorization, NSError *error))callback {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p calculating authorization %lu", self, (unsigned long)method];
    // FIXME: use encoder and should be managed on ARTAuth
    if (method == ARTAuthMethodBasic) {
        // Include key Base64 encoded in an Authorization header (RFC7235)
        NSData *keyData = [self.options.key dataUsingEncoding:NSUTF8StringEncoding];
        NSString *keyBase64 = [keyData base64EncodedStringWithOptions:0];
        if (callback) callback([NSString stringWithFormat:@"Basic %@", keyBase64], nil);
    }
    else {
        self.options.force = force;
        [self.auth authorise:nil options:self.options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
            if (error) {
                if (callback) callback(nil, error);
                return;
            }
            NSData *tokenData = [tokenDetails.token dataUsingEncoding:NSUTF8StringEncoding];
            NSString *tokenBase64 = [tokenData base64EncodedStringWithOptions:0];
            [self.logger verbose:@"RS:%p ARTRest: authorization bearer in Base64 %@", self, tokenBase64];
            if (callback) callback([NSString stringWithFormat:@"Bearer %@", tokenBase64], nil);
        }];
    }
}

- (void)time:(void(^)(NSDate *time, NSError *error))callback {
    NSURL *requestUrl = [NSURL URLWithString:@"/time" relativeToURL:self.baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"GET";
    NSString *accept = [[_encoders.allValues valueForKeyPath:@"mimeType"] componentsJoinedByString:@","];
    [request setValue:accept forHTTPHeaderField:@"Accept"];
    
    [self executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode >= 400) {
            callback(nil, [self->_encoders[response.MIMEType] decodeError:data]);
        } else {
            callback([self->_encoders[response.MIMEType] decodeTime:data], nil);
        }
    }];
}

- (id<ARTCancellable>)internetIsUp:(void (^)(BOOL isUp)) cb {
    NSURL *requestUrl = [NSURL URLWithString:@"http://internet-up.ably-realtime.com/is-the-internet-up.txt"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"GET";

    [self executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            cb(NO);
            return;
        }
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        cb(response.statusCode == 200 && str && [str isEqualToString:@"yes\n"]);
    }];
    return nil;
}

- (BOOL)stats:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *__art_nullable, ARTErrorInfo *__art_nullable))callback {
    return [self stats:[[ARTStatsQuery alloc] init] callback:callback error:nil];
}

- (BOOL)stats:(ARTStatsQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
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

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:@"/stats"];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[requestUrl URLRelativeToURL:self.baseUrl]];
    
    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data) {
        id<ARTEncoder> encoder = [self.encoders objectForKey:response.MIMEType];
        return [encoder decodeStats:data];
    };
    
    [ARTPaginatedResult executePaginated:self withRequest:request andResponseProcessor:responseProcessor callback:callback];
    return YES;
}

- (id<ARTEncoder>)defaultEncoder {
    return self.encoders[self.defaultEncoding];
}

- (NSURL *)getBaseUrl {
    NSURLComponents *components = [_options restUrlComponents];
    if (_prioritizedHost) {
        components.host = _prioritizedHost;
    }
    return components.URL;
}

@end