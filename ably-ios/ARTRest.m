//
//  ARTRest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest.h"
#import "ARTRest+Private.h"
#import "ARTChannels+Private.h"
#import "ARTDataQuery+Private.h"

#import "ARTAuth.h"
#import "ARTHttp.h"
#import "ARTEncoder.h"
#import "ARTJsonEncoder.h"
#import "ARTMsgPackEncoder.h"
#import "ARTMessage.h"
#import "ARTHttpPaginatedResult.h"
#import "ARTStats.h"

#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSArray+ARTFunctional.h"

#import "ARTLog.h"
#import "ARTHttp.h"
#import "ARTDefault.h"
#import "ARTFallback.h"

@interface ARTRest ()

@property (readonly, strong, nonatomic) ARTHttp *http;
@property (strong, nonatomic) ARTAuth *auth;
@property (readonly, strong, nonatomic) NSDictionary *encoders;
@property (readonly, strong, nonatomic) NSString *defaultEncoding;
@property (readwrite, assign, nonatomic) int fallbackCount;
@property (readwrite, copy, nonatomic) NSURL *baseUrl;

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb;

- (NSDictionary *)withAcceptHeader:(NSDictionary *)headers;

@end

@interface ARTRestPresence ()

- (instancetype)initWithChannel:(ARTRestChannel *)channel;

@end

@implementation ARTRestChannel {
@public
    __weak ARTRest *_rest;
    NSString *_basePath;
}

@dynamic presence;

- (instancetype)initWithRest:(ARTRest *)rest name:(NSString *)name options:(ARTChannelOptions *)options {
    if (self = [super initWithName:name presence:[[ARTRestPresence alloc] initWithChannel:self] options:options]) {
        _logger = rest.logger;
        [_logger debug:@"ARTRestChannel: instantiating under %@", name];
        _rest = rest;
        _basePath = [NSString stringWithFormat:@"/channels/%@", [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    }
    
    return self;
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTStatus *status, ARTPaginatedResult *__nullable result))callback {
    NSParameterAssert(query.limit < 1000);
    NSParameterAssert([query.start compare:query.end] != NSOrderedDescending);
    
    [_rest withAuthHeaders:^(NSDictionary *authHeaders) {
        NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_basePath stringByAppendingPathComponent:@"messages"]];
        requestUrl.queryItems = [query asQueryItems];
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[requestUrl URLRelativeToURL:_rest.baseUrl] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:_rest.http request:req responseProcessor:^(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [_rest.encoders objectForKey:response.contentType];
            return [[encoder decodeMessages:response.body] artMap:^(ARTMessage *message) {
                return [message decode:_payloadEncoder];
            }];
        } callback:callback];
    }];
}

- (void)_postMessages:(id)payload callback:(ARTStatusCallback)callback {
    NSData *encodedMessage = nil;
    if ([payload isKindOfClass:[ARTMessage class]]) {
        encodedMessage = [_rest.defaultEncoder encodeMessage:payload];
    } else if ([payload isKindOfClass:[NSArray class]]) {
        encodedMessage = [_rest.defaultEncoder encodeMessages:payload];
    }
    
    [_rest post:[_basePath stringByAppendingPathComponent:@"messages"]
        headers:@{ @"Content-Type": _rest.defaultEncoding ?: @"" }
           body:encodedMessage
  authenticated:ARTAuthenticationOn
             cb:^(ARTHttpResponse *response) {
                 if (callback) {
                     ARTState state = response.status >= 200 && response.status < 300 ? ARTStateOk : ARTStateError;
                     callback([ARTStatus state:state info:response.error]);
                 }
             }];
}

@end

@implementation ARTRestChannelCollection {
    __weak ARTRest *_rest;
}

- (instancetype)initWithRest:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
    }
    
    return self;
}

- (ARTChannel *)_createChannelWithName:(NSString *)name options:(ARTChannelOptions *)options {
    return [[ARTRestChannel alloc] initWithRest:_rest name:name options:options];
}

@end

@implementation ARTRestPresence {
    ARTRestChannel *_channel;
}

- (instancetype)initWithChannel:(ARTRestChannel *)channel {
    if (self = [super init]) {
        _channel = channel;
    }
    
    return self;
}

- (void)get:(void (^)(ARTStatus *status, ARTPaginatedResult *__nullable result))callback {
    [_channel->_rest withAuthHeaders:^(NSDictionary *authHeaders) {
        NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_channel->_basePath stringByAppendingPathComponent:@"presence"]];
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[requestUrl URLRelativeToURL:_channel->_rest.baseUrl] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:_channel->_rest.http request:req responseProcessor:^(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [_channel->_rest.encoders objectForKey:response.contentType];
            NSArray *messages = [encoder decodePresenceMessages:response.body];
            return [messages artMap:^id(ARTPresenceMessage *pm) {
                return [pm decode:_channel->_payloadEncoder];
            }];
        } callback:callback];
    }];
}

- (void)history:(nullable ARTDataQuery *)query callback:(void (^)(ARTStatus *status, ARTPaginatedResult *__nullable result))callback {
    NSParameterAssert(query.limit < 1000);
    NSParameterAssert([query.start compare:query.end] != NSOrderedDescending);
    
    [_channel->_rest withAuthHeaders:^(NSDictionary *authHeaders) {
        NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_channel->_basePath stringByAppendingPathComponent:@"presence/history"]];
        requestUrl.queryItems = [query asQueryItems];
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[requestUrl URLRelativeToURL:_channel->_rest.baseUrl] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:_channel->_rest.http request:req responseProcessor:^(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [_channel->_rest.encoders objectForKey:response.contentType];
            NSArray *messages = [encoder decodePresenceMessages:response.body];
            return [messages artMap:^id(ARTPresenceMessage *pm) {
                return [pm decode:_channel->_payloadEncoder];
            }];
        } callback:callback];
    }];
}

@end


#pragma mark - ARTRest

@implementation ARTRest

- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRest: No options provided");
        _options = options;
        
        if (logger) {
            _logger = logger;
        }
        else {
            _logger = [[ARTLog alloc] init];
        }
        
        self.baseUrl = [ARTClientOptions restUrl:self.options.restHost port:self.options.restPort];
        [self setup];
        _auth = [[ARTAuth alloc] initWithRest:self options:options.authOptions];
    }
    return self;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    return [self initWithLogger:[[ARTLog alloc] init] andOptions:options];
}

- (instancetype)initWithKey:(NSString *) key {
    return [self initWithOptions:[ARTClientOptions optionsWithKey:key]];
}

- (void)setup {
    _http = [[ARTHttp alloc] init];
    
    _channels = [[ARTRestChannelCollection alloc] initWithRest:self];
    
    id<ARTEncoder> defaultEncoder = [[ARTJsonEncoder alloc] init];
    _encoders = @{
                  [defaultEncoder mimeType]: defaultEncoder,
    };
    
    _defaultEncoding = [defaultEncoder mimeType];
    _fallbackCount = 0;
}

- (id<ARTCancellable>) token:(ARTAuthTokenParams *) params tokenCb:(void (^)(ARTStatus *status, ARTTokenDetails *)) cb {

    [self.logger debug:@"ARTRest is requesting a fresh token"];
    if(![self.auth canRequestToken]) {
        cb([ARTStatus state:ARTStateError], nil);
        id<ARTCancellable> c = nil;
        return c;
    }

    NSString * keyPath = [NSString stringWithFormat:@"/keys/%@/requestToken",params.keyName];
    if([self.auth getAuthOptions].authUrl) {
        keyPath = [[self.auth getAuthOptions].authUrl absoluteString];
        [self.logger info:@"ARTRest is bypassing the default token request URL for this authURL:%@",keyPath];
    }
    NSDictionary * paramsDict = [params asDictionary];
    
    NSData * dictData = [NSJSONSerialization dataWithJSONObject:paramsDict options:0 error:nil];
    
    NSDictionary *headers = @{@"Content-Type":self.defaultEncoding};
    return [self post:keyPath headers:headers body:dictData authenticated:ARTAuthenticationUseBasic cb:^(ARTHttpResponse *response) {
        if(!response.body) {
            cb([ARTStatus state:ARTStateError info:response.error], nil);
            return;
        }
        NSString * str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
        [self.logger verbose:@"ARTRest token is %@", str];
        if(response.status == 201) {
            ARTTokenDetails * token =[self.defaultEncoder decodeAccessToken:response.body];
            cb(ARTStateOk, token);
        }
        else {

            ARTErrorInfo * e = [self.defaultEncoder decodeError:response.body];
            [self.logger error:@"ARTRest: requestToken Error code: %d, Status %d, Message %@", e.code, e.statusCode, e.message];
            cb([ARTStatus state:ARTStateError info:e], nil);
        }
    }];
}

-(ARTAuth *) auth {
    return _auth;
}

- (id<ARTCancellable>)time:(void (^)(ARTStatus *, NSDate *))cb {
    return [self get:@"/time" authenticated:NO cb:^(ARTHttpResponse *response) {
        NSDate *date = nil;
        
        if (response.status == 200) {
            date = [self.defaultEncoder decodeTime:response.body];
        }
        if (date) {
            cb([ARTStatus state:ARTStateOk], date);
        } else {
            cb([ARTStatus state:ARTStateError info:response.error], nil);
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

- (void)stats:(ARTStatsQuery *)query callback:(void (^)(ARTStatus *status, ARTPaginatedResult *result))callback {
    NSParameterAssert(query.limit < 1000);
    NSParameterAssert([query.start compare:query.end] != NSOrderedDescending);
    
    [self withAuthHeaders:^(NSDictionary *authHeaders) {
        NSURLComponents *requestUrl = [NSURLComponents componentsWithString:@"/stats"];
        requestUrl.queryItems = [query asQueryItems];
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[requestUrl URLRelativeToURL:self.baseUrl] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:self.http request:req responseProcessor:^(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [self.encoders objectForKey:response.contentType];
            return [encoder decodeStats:response.body];
        } callback:callback];
    }];
}

-(bool) isAnErrorStatus:(int) status {
    return status >=400;
}

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated fb:(ARTFallback *) fb cb:(ARTHttpCb)cb {
    __weak ARTRest * weakSelf = self;
    ARTHttpCb errorCheckingCb = ^(ARTHttpResponse * response) {
        ARTRest * s = weakSelf;
        [self.logger verbose:@"ARTRest Http response is %d", response.status];
        if([s isAnErrorStatus:response.status]) {
            if(response.body) {
                ARTErrorInfo * error = [s.defaultEncoder decodeError:response.body];
                response.error = error;
                [self.logger info:@"ARTRest received an error: \n status %d  \n code %d \n message: %@", error.statusCode, error.code, error.message];
            }
        }
        if([ARTFallback shouldTryFallback:response options:self.options]) {
            ARTFallback * theFb = fb;
            if(theFb == nil) {
                theFb = [[ARTFallback alloc] init];
            }
            NSString * nextFallbackHost = [theFb popFallbackHost];
            if(nextFallbackHost != nil) {
                self.baseUrl = [ARTClientOptions restUrl:nextFallbackHost port:self.options.restPort];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [s makeRequestWithMethod:method relUrl:relUrl headers:headers body:body authenticated:authenticated fb:theFb cb:cb];
                });
            }
            else {
                [self.logger warn:@"ARTRest has no more fallback hosts to attempt. Giving up."];
                self.baseUrl = [ARTClientOptions restUrl:self.options.restHost port:self.options.restPort];
                cb(response);
                return;
            }
        }
        else if(response && response.error && response.error.code == 40140) {
            [self.logger info:@"requesting new token"];
            if(![_auth canRequestToken]) {
                cb(response);
                return;
            }
            [_auth attemptTokenFetch:^() {
                ARTRest * s = weakSelf;
                if(s) {
                    //TODO consider counting this. enough times we give up?
                    [self.logger debug:@"ARTRest Token fetch complete. Now trying the same server call again with the new token"];
                    [s makeRequestWithMethod:method relUrl:relUrl headers:headers body:body authenticated:authenticated cb:cb];
                }
                else {
                    [self.logger error:@"ARTRest is nil. Can't renew token"];
                    cb(response);
                }
            }];
        }
        else {
            cb(response);
        }
    };
    
    NSURL *url = [self resolveUrl:relUrl];
    headers = [self withAcceptHeader:headers];
    
    if (authenticated == ARTAuthenticationOff) {
        return [self.http makeRequestWithMethod:method url:url headers:headers body:body cb:errorCheckingCb];
    } else {
        bool useBasic = authenticated == ARTAuthenticationUseBasic;
        return [self withAuthHeadersUseBasic:useBasic cb:^(NSDictionary *authHeaders) {
            NSMutableDictionary *allHeaders = [NSMutableDictionary dictionary];
            [allHeaders addEntriesFromDictionary:headers];
            [allHeaders addEntriesFromDictionary:authHeaders];
            if(useBasic) {
                return [self.http makeRequestWithMethod:method url:url headers:allHeaders body:body cb:errorCheckingCb];
            }
            else {
                return [self.http makeRequestWithMethod:method url:url headers:allHeaders body:body cb:errorCheckingCb];
            }
        }];
    }
}

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb {
    
    return [self makeRequestWithMethod:method relUrl:relUrl headers:headers body:body authenticated:authenticated fb:nil cb:cb];
}

- (NSDictionary *)withAcceptHeader:(NSDictionary *)headers {
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:headers];

    NSMutableArray *mimeTypes = [NSMutableArray arrayWithObject:self.defaultEncoding];

    for (NSString *mimeType in self.encoders) {
        if (![mimeType isEqualToString:self.defaultEncoding]) {
            [mimeTypes addObject:mimeType];
        }
    }
    md[@"Accept"] = [mimeTypes componentsJoinedByString:@","];

    return md;
}

@end

@implementation ARTRest (Private)

- (id<ARTCancellable>) postTestStats:(NSArray *) stats cb:(void(^)(ARTStatus * status)) cb {
    NSDictionary *headers = @{@"Content-Type":self.defaultEncoding};
    NSData * statsData = [NSJSONSerialization dataWithJSONObject:stats options:0 error:nil];
    return [self post:@"/stats" headers:headers body:statsData authenticated:ARTAuthenticationOn cb:^(ARTHttpResponse *response) {
        cb([ARTStatus state:ARTStateOk info:response.error]);
    }];
}

- (NSURL *)getBaseURL {
    return self.baseUrl;
}

- (id<ARTEncoder>)defaultEncoder {
    return self.encoders[self.defaultEncoding];
}

- (NSString *)formatQueryParams:(NSDictionary *)queryParams {
    NSMutableArray *encodedParams = [NSMutableArray array];

    for (NSString *queryParamName in queryParams) {
        NSString *queryParamValue = [queryParams objectForKey:queryParamName];
        NSString *encoded = [NSString stringWithFormat:@"%@=%@", [queryParamName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], [queryParamValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        [encodedParams addObject:encoded];
    }

    return [encodedParams componentsJoinedByString:@"&"];
}

- (NSURL *)resolveUrl:(NSString *)relUrl {
    if([relUrl length] ==0) {
        return self.baseUrl;
    }
    if([[relUrl substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
        return [NSURL URLWithString:relUrl relativeToURL:self.baseUrl];
    }
    [self.logger verbose:@"ARTRest is treating the relative url as the base"];
    return [NSURL URLWithString:relUrl];

}

- (NSURL *)resolveUrl:(NSString *)relUrl queryParams:(NSDictionary *)queryParams {
    NSString *queryString = [self formatQueryParams:queryParams];

    if (queryString.length) {
        relUrl = [NSString stringWithFormat:@"%@?%@", relUrl, queryString];
    }

    return [self resolveUrl:relUrl];
}

- (id<ARTCancellable>)get:(NSString *)relUrl authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb {
    return [self get:relUrl headers:nil authenticated:authenticated cb:cb];
}

- (id<ARTCancellable>)get:(NSString *)relUrl headers:(NSDictionary *)headers authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb {
    return [self makeRequestWithMethod:@"GET" relUrl:relUrl headers:headers body:nil authenticated:authenticated cb:cb];
}

- (id<ARTCancellable>)post:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb {
    return [self makeRequestWithMethod:@"POST" relUrl:relUrl headers:headers body:body authenticated:authenticated cb:cb];
}

- (id<ARTCancellable>)withAuthHeaders:(id<ARTCancellable>(^)
     (NSDictionary *))cb {
    return [self withAuthHeadersUseBasic:false cb:cb];
}

- (id<ARTCancellable>)withAuthHeadersUseBasic:(BOOL) useBasic cb:(id<ARTCancellable>(^)(NSDictionary *))cb {
    return [self.auth authHeadersUseBasic:useBasic cb:cb];
}

- (id<ARTCancellable>)withAuthParams:(id<ARTCancellable>(^)(NSDictionary *))cb {
    return [self.auth authParams:cb];
}

@end
