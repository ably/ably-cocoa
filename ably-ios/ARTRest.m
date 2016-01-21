//
//  ARTRest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest+Private.h"

#import "ARTChannel+Private.h"
#import "ARTChannelCollection.h"
#import "ARTDataQuery+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTAuth+Private.h"
#import "ARTHttp.h"
#import "ARTEncoder.h"
#import "ARTJsonEncoder.h"
#import "ARTMessage.h"
#import "ARTPresence.h"
#import "ARTPresenceMessage.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"
#import "ARTDefault.h"
#import "ARTStats.h"
#import "ARTFallback.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTRestChannel.h"
#import "ARTAuthTokenParams.h"
#import "ARTAuthTokenDetails.h"

@interface ARTRest ()

@property (readonly, strong, nonatomic) id<ARTEncoder> defaultEncoder;
@property (readonly, strong, nonatomic) NSString *defaultEncoding; //Content-Type
@property (readonly, strong, nonatomic) NSDictionary *encoders;

@property (nonatomic, strong) id<ARTHTTPExecutor> httpExecutor;
@property (readonly, nonatomic, assign) Class channelClass;

@property (nonatomic, strong) NSURL *baseUrl;

// MARK: Not accessible by tests
@property (readonly, strong, nonatomic) ARTHttp *http;
@property (strong, nonatomic) ARTAuth *auth;
@property (readwrite, assign, nonatomic) int fallbackCount;

@end

@implementation ARTRest

- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRest: No options provided");
        _options = [options copy];
        _baseUrl = [options restUrl];
        
        if (logger) {
            _logger = logger;
        }
        else {
            _logger = [[ARTLog alloc] init];
        }
        
        if (options.logLevel != ARTLogLevelNone) {            
            _logger.logLevel = options.logLevel;
        }
        
        _http = [[ARTHttp alloc] init];
        [_logger debug:__FILE__ line:__LINE__ message:@"%p alloc HTTP", _http];
        _httpExecutor = _http;
        _httpExecutor.logger = _logger;
        _channelClass = [ARTRestChannel class];
        
        id<ARTEncoder> defaultEncoder = [[ARTJsonEncoder alloc] initWithLogger:self.logger];
        _encoders = @{ [defaultEncoder mimeType]: defaultEncoder };
        _defaultEncoding = [defaultEncoder mimeType];
        _fallbackCount = 0;
        
        _auth = [[ARTAuth alloc] init:self withOptions:_options];
        _channels = [[ARTChannelCollection alloc] initWithRest:self];

        [self.logger debug:__FILE__ line:__LINE__ message:@"initialised %p", self];
    }
    return self;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    return [self initWithLogger:[[ARTLog alloc] init] andOptions:options];
}

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (instancetype)initWithToken:(NSString *)token {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithToken:token]];
}

- (void)dealloc {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p dealloc", self];
}

- (void)executeRequest:(NSMutableURLRequest *)request withAuthOption:(ARTAuthentication)authOption completion:(ARTHttpRequestCallback)callback {
    request.URL = [NSURL URLWithString:request.URL.relativeString relativeToURL:self.baseUrl];
    
    NSString *accept = [[_encoders.allValues valueForKeyPath:@"mimeType"] componentsJoinedByString:@","];
    [request setValue:accept forHTTPHeaderField:@"Accept"];

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

- (void)executeRequestWithAuthentication:(NSMutableURLRequest *)request withMethod:(ARTAuthMethod)method completion:(ARTHttpRequestCallback)callback {
    [self executeRequestWithAuthentication:request withMethod:method force:NO completion:callback];
}

- (void)executeRequestWithAuthentication:(NSMutableURLRequest *)request withMethod:(ARTAuthMethod)method force:(BOOL)force completion:(ARTHttpRequestCallback)callback {
    [self calculateAuthorization:method force:force completion:^(NSString *authorization, NSError *error) {
        if (error && callback) {
            callback(nil, nil, error);
        } else {
            // RFC7235
            [request setValue:authorization forHTTPHeaderField:@"Authorization"];
            [self executeRequest:request completion:callback];
        }
    }];
}

- (void)executeRequest:(NSMutableURLRequest *)request completion:(ARTHttpRequestCallback)callback {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p executing request %@", self, request];
    [self.httpExecutor executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode >= 400) {
            NSError *dataError = [self->_encoders[response.MIMEType] decodeError:data];
            if (dataError.code >= 40140 && dataError.code < 40150) {
                // Send it again, requesting a new token (forward callback)
                [self.logger debug:__FILE__ line:__LINE__ message:@"requesting new token"];
                [self executeRequest:request withAuthOption:ARTAuthenticationNewToken completion:callback];
            } else if (callback) {
                // Return error with HTTP StatusCode if ARTErrorStatusCode does not exist
                if (!dataError) {
                    dataError = [NSError errorWithDomain:ARTAblyErrorDomain code:response.statusCode userInfo:@{NSLocalizedDescriptionKey:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]}];
                }
                callback(nil, nil, dataError);
            }
        } else if (callback) {
            // Error object that indicates why the request failed
            callback(response, data, error);
        }
    }];
}

- (void)calculateAuthorization:(ARTAuthMethod)method completion:(void (^)(NSString *authorization, NSError *error))callback {
    [self calculateAuthorization:method force:NO completion:callback];
}

- (void)calculateAuthorization:(ARTAuthMethod)method force:(BOOL)force completion:(void (^)(NSString *authorization, NSError *error))callback {
    [self.logger debug:__FILE__ line:__LINE__ message:@"calculating authorization %lu", (unsigned long)method];
    // FIXME: use encoder and should be managed on ARTAuth
    if (method == ARTAuthMethodBasic) {
        // Include key Base64 encoded in an Authorization header (RFC7235)
        NSData *keyData = [self.options.key dataUsingEncoding:NSUTF8StringEncoding];
        NSString *keyBase64 = [keyData base64EncodedStringWithOptions:0];
        if (callback) callback([NSString stringWithFormat:@"Basic %@", keyBase64], nil);
    }
    else {
        self.options.force = force;
        [self.auth authorise:nil options:self.options callback:^(ARTAuthTokenDetails *tokenDetails, NSError *error) {
            if (error) {
                if (callback) callback(nil, error);
                return;
            }
            NSData *tokenData = [tokenDetails.token dataUsingEncoding:NSUTF8StringEncoding];
            NSString *tokenBase64 = [tokenData base64EncodedStringWithOptions:0];
            [self.logger verbose:@"ARTRest: authorization bearer in Base64 %@", tokenBase64];
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

- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp)) cb {
    [self.http makeRequestWithMethod:@"GET" url:[NSURL URLWithString:@"http://internet-up.ably-realtime.com/is-the-internet-up.txt"] headers:nil body:nil cb:^(ARTHttpResponse *response) {
        NSString * str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
        cb(response.status == 200 && [str isEqualToString:@"yes\n"]);
    }];
    return nil;
}

- (BOOL)stats:(ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult *, NSError *))callback error:(NSError **)errorPtr {
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

@end
