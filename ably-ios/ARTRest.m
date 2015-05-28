//
//  ARTRest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest.h"
#import "ARTRest+Private.h"

#import "ARTAuth.h"
#import "ARTHttp.h"
#import "ARTEncoder.h"
#import "ARTJsonEncoder.h"
#import "ARTMsgPackEncoder.h"
#import "ARTMessage.h"
#import "ARTHttpPaginatedResult.h"
#import "ARTStats.h"
#import "ARTPresenceMessage.h"

#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSArray+ARTFunctional.h"

#import "ARTLog.h"
#import "ARTHttp.h"
#import "ARTDefault.h"

// TODO base accept headers on encoders

@interface ARTRestChannel ()

@property (readonly, weak, nonatomic) ARTRest *rest;
@property (readonly, strong, nonatomic) NSString *name;
@property (readonly, strong, nonatomic) NSString *basePath;

@property (readonly, strong, nonatomic) id<ARTPayloadEncoder> payloadEncoder;

- (instancetype)initWithRest:(ARTRest *)rest name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)channelWithRest:(ARTRest *)rest name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;

@end

@interface ARTRest ()

@property (readonly, strong, nonatomic) ARTHttp *http;
@property (readonly, strong, nonatomic) ARTOptions * options;
@property (readonly, strong, nonatomic) NSMutableDictionary *channels;
@property ( strong, nonatomic) ARTAuth *auth;
@property (readonly, strong, nonatomic) NSDictionary *encoders;
@property (readonly, strong, nonatomic) NSString *defaultEncoding;
@property (readwrite, assign, nonatomic) int fallbackCount;
@property (readwrite, strong, nonatomic) NSURL *baseUrl;


- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb;

- (NSDictionary *)withAcceptHeader:(NSDictionary *)headers;
- (void)throwOnHighLimitCheck:(NSDictionary *) params;
@end

@implementation ARTRestChannel

- (instancetype)initWithRest:(ARTRest *)rest name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams {
    self = [super init];
    if (self) {

        [ARTLog debug:[NSString stringWithFormat:@"ARTRestChannel: instantiating under %@", name]];
        _rest = rest;
        _name = name;
        _basePath = [NSString stringWithFormat:@"/channels/%@", [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
        _payloadEncoder = [ARTPayload defaultPayloadEncoder:cipherParams];
    }
    return self;
}

+ (instancetype)channelWithRest:(ARTRest *)rest name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams {
    return [[ARTRestChannel alloc] initWithRest:rest name:name cipherParams:cipherParams];
}



- (id<ARTCancellable>)publishMessages:(NSArray *)messages cb:(ARTStatusCallback)cb {
    NSMutableArray * encodedMessages = [NSMutableArray array];
    for(int i=0; i < [messages count]; i++) {
        ARTPayload *encodedPayload = nil;

        ARTPayload * p = [ARTPayload payloadWithPayload:[messages objectAtIndex:i] encoding:self.rest.defaultEncoding];
        ARTStatus * status = [self.payloadEncoder encode:p output:&encodedPayload];
        if (status.status != ARTStatusOk) {
            [ARTLog warn:[NSString stringWithFormat:@"ARTRest publishMessages could not encode message %d", i]];
        }
        [encodedMessages addObject:encodedPayload.payload];
    }
    
    //ARTPayload * finalPayload = [ARTPayload payloadWithPayload:encodedMessages encoding:@""];
    ARTMessage * bigMessage = [ARTMessage messageWithPayload:encodedMessages name:nil];
    return [self publishMessage:bigMessage cb:cb];
}

-(id<ARTCancellable>) publishMessage:(ARTMessage *) message cb:(ARTStatusCallback) cb {
    NSData *encodedMessage = [self.rest.defaultEncoder encodeMessage:message];
    NSString * defaultEncoding = self.rest.defaultEncoding ? self.rest.defaultEncoding :@"";
    NSDictionary *headers = @{@"Content-Type":defaultEncoding};
    NSString *path = [NSString stringWithFormat:@"%@/messages", self.basePath];
    return [self.rest post:path headers:headers body:encodedMessage authenticated:ARTAuthenticationOn cb:^(ARTHttpResponse *response) {
        ARTStatus *status = [ARTStatus state:(response.status >= 200 && response.status < 300 ? ARTStatusOk : ARTStatusError) info:response.error];
        cb(status);
    }];
}
- (id<ARTCancellable>)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb {
    [ARTLog debug:[NSString stringWithFormat:@"ARTRestChannel: publishing '%@' to channel with name '%@'", payload, name]];
    ARTMessage *message = [ARTMessage messageWithPayload:payload name:name];//[[ARTMessage alloc] init];
    message = [message encode:self.payloadEncoder];
    return [self publishMessage:message cb:cb];
}

- (id<ARTCancellable>)publish:(id)payload cb:(ARTStatusCallback)cb {
    if([payload isKindOfClass:[NSArray class]]) {
        return [self publishMessages:payload cb:cb];
    }
    else {
        return [self publish:payload withName:nil cb:cb];
    }
}

- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb {
    return [self historyWithParams:nil cb:cb];
}

- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
    [self.rest throwOnHighLimitCheck:queryParams];
    return [self.rest withAuthHeaders:^(NSDictionary *authHeaders) {
        NSString *relUrl = [NSString stringWithFormat:@"%@/messages", self.basePath];
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[self.rest resolveUrl:relUrl queryParams:queryParams] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:self.rest.http request:req responseProcessor:^(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [self.rest.encoders objectForKey:response.contentType];
            NSArray *messages = [encoder decodeMessages:response.body];
            return [messages artMap:^id(ARTMessage *message) {
                return [message decode:self.payloadEncoder];
            }];
        } cb:cb];
    }];
}

- (id<ARTCancellable>)presence:(ARTPaginatedResultCb)cb {
    return [self presenceGetWithParams:nil cb:cb];
}

- (id<ARTCancellable>)presenceGetWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
    [self.rest throwOnHighLimitCheck:queryParams];
    return [self.rest withAuthHeaders:^(NSDictionary *authHeaders) {
        NSString *relUrl = [NSString stringWithFormat:@"%@/presence", self.basePath];
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[self.rest resolveUrl:relUrl queryParams:queryParams] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:self.rest.http request:req responseProcessor:^id(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [self.rest.encoders objectForKey:response.contentType];
            NSArray *messages = [encoder decodePresenceMessages:response.body];
            return [messages artMap:^id(ARTPresenceMessage *pm) {
                return [pm decode:self.payloadEncoder];
            }];
        } cb:cb];
    }];
}

- (id<ARTCancellable>)presenceHistory:(ARTPaginatedResultCb)cb {
    return [self presenceHistoryWithParams:nil cb:cb];
}

- (id<ARTCancellable>)presenceHistoryWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
    return [self.rest withAuthHeaders:^(NSDictionary *authHeaders) {
        NSString *relUrl = [NSString stringWithFormat:@"%@/presence/history", self.basePath];
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[self.rest resolveUrl:relUrl queryParams:queryParams] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:self.rest.http request:req responseProcessor:^id(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [self.rest.encoders objectForKey:response.contentType];
            NSArray *messages = [encoder decodePresenceMessages:response.body];
            return [messages artMap:^id(ARTPresenceMessage *pm) {
                return [pm decode:self.payloadEncoder];
            }];
        } cb:cb];
    }];
}

@end

@implementation ARTRest


- (instancetype)initNoAuth:(ARTOptions *) options {
    self = [super init];
    if(self) {
        _options = options;
        self.baseUrl = [options restUrl];
        [self setup];
    }
    return self;
}

-(instancetype) initWithKey:(NSString *) key {
    return [self initWithOptions:[ARTOptions optionsWithKey:key]];
}

-(instancetype) initWithOptions:(ARTOptions *) options {
    ARTRest * r = [[ARTRest alloc] initNoAuth:options];
    _auth =[[ARTAuth alloc] initWithRest:self options:options.authOptions];
    return r;
}

- (void) setup {
    _http = [[ARTHttp alloc] init];
    _channels = [NSMutableDictionary dictionary];
    id<ARTEncoder> defaultEncoder = [[ARTJsonEncoder alloc] init];
    _encoders = @{
                  [defaultEncoder mimeType]: defaultEncoder,
                  };
    
    _defaultEncoding = [defaultEncoder mimeType];
    _fallbackCount = 0;
    
}

+ (BOOL) isValidKey:(NSString *) key {
    NSArray *keyBits = [key componentsSeparatedByString:@":"];
    return keyBits.count == 2;
}

- (id<ARTCancellable>) token:(ARTAuthTokenParams *) params tokenCb:(void (^)(ARTStatus *status, ARTTokenDetails *)) cb {

    [ARTLog debug:@"ARTRest is requesting a fresh token"];
    if(![self.auth canRequestToken]) {
        cb([ARTStatus state:ARTStatusError], nil);
        id<ARTCancellable> c = nil;
        return c;
    }

    NSString * keyPath = [NSString stringWithFormat:@"/keys/%@/requestToken",params.keyName];
    if([self.auth getAuthOptions].authUrl) {
        keyPath = [[self.auth getAuthOptions].authUrl absoluteString];
        [ARTLog info:[NSString stringWithFormat:@"ARTRest is bypassing the default token request URL for this authURL:%@",keyPath]];
    }
    NSDictionary * paramsDict = [params asDictionary];
    
    NSData * dictData = [NSJSONSerialization dataWithJSONObject:paramsDict options:0 error:nil];
    
    NSDictionary *headers = @{@"Content-Type":self.defaultEncoding};
    return [self post:keyPath headers:headers body:dictData authenticated:ARTAuthenticationUseBasic cb:^(ARTHttpResponse *response) {
        if(!response.body) {
            cb([ARTStatus state:ARTStatusError info:response.error], nil);
            return;
        }
        NSString * str = [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding];
        [ARTLog verbose:[NSString stringWithFormat:@"ARTRest token is %@", str]];
        if(response.status == 201) {
            ARTTokenDetails * token =[self.defaultEncoder decodeAccessToken:response.body];
            cb(ARTStatusOk, token);
        }
        else {

            ARTErrorInfo * e = [self.defaultEncoder decodeError:response.body];
            [ARTLog error:[NSString stringWithFormat:@"ARTRest: requestToken Error code: %d, Status %d, Message %@", e.code, e.statusCode, e.message]];
            cb([ARTStatus state:ARTStatusError info:e], nil);
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
            cb([ARTStatus state:ARTStatusOk], date);
        } else {
            cb([ARTStatus state:ARTStatusError info:response.error], nil);
        }
    }];
}

- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp)) cb {
    //TODO use ablys internetisup check
    [self.http makeRequestWithMethod:@"GET" url:[NSURL URLWithString:@"http://google.com"] headers:nil body:nil cb:^(ARTHttpResponse *response) {
        cb(response.status == 200);
    }];
    return nil;
     
}

- (id<ARTCancellable>)stats:(ARTPaginatedResultCb)cb {
    return [self statsWithParams:nil cb:cb];
}

-(void) throwOnHighLimitCheck:(NSDictionary *) params {
    NSString * limit = [params valueForKey:@"limit"];
    if(!limit) {
        return;
    }
    int value = [limit intValue];
    if(value > 1000) {
        [NSException raise:@"cannot set a limit over 1000" format:@"%d", value];
    }
}

- (id<ARTCancellable>)statsWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
    [self throwOnHighLimitCheck:queryParams];
    return [self withAuthHeaders:^(NSDictionary *authHeaders) {
        ARTHttpRequest *req = [[ARTHttpRequest alloc] initWithMethod:@"GET" url:[self resolveUrl:@"/stats" queryParams:queryParams] headers:authHeaders body:nil];
        return [ARTHttpPaginatedResult makePaginatedRequest:self.http request:req responseProcessor:^(ARTHttpResponse *response) {
            id<ARTEncoder> encoder = [self.encoders objectForKey:response.contentType];
            return [encoder decodeStats:response.body];
        } cb:cb];
    }];
}

- (ARTRestChannel *)channel:(NSString *)channelName {
    return [self channel:channelName cipherParams:nil];
}

- (ARTRestChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams {
    ARTRestChannel *channel = [self.channels objectForKey:channelName];
    if (!channel) {
        channel = [ARTRestChannel channelWithRest:self name:channelName cipherParams:cipherParams];
        [self.channels setObject:channel forKey:channelName];
    }
    return channel;
}

-(bool) getNextFallbackHost  {
    NSArray * hosts = [ARTDefault fallbackHosts];
    if(self.fallbackCount >= [hosts count]) {
        self.fallbackCount =0;
        self.baseUrl = [self.options restUrl];
        return false;
    }
    NSString * host =[hosts objectAtIndex:self.fallbackCount++];
    self.baseUrl =[ARTOptions restUrl:host port:self.options.restPort];
    return true;
}

-(bool) isAnErrorStatus:(int) status {
    switch (status) {
        case 400:
        case 401:
        case 403:
        case 404:
        case 405:
        case 500:
            return true;
        default:
            return false;
    }
}

-(bool) shouldTryFallback:(ARTHttpResponse *) response {
    if(![self.options isFallbackPermitted]) {
        return false;
    }
    if(!response.body) { //we didnt hit anything ably. Either bad host or host is down
        return true;
    }
    switch(response.error.code) { //this ably server returned an internal error
        case 50000:
        case 50001:
        case 50002:
        case 50003:
            return true;
        default:
            return false;
    }
}

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb {
    __weak ARTRest * weakSelf = self;
    ARTHttpCb errorCheckingCb = ^(ARTHttpResponse * response) {
        ARTRest * s = weakSelf;
        [ARTLog verbose:[NSString stringWithFormat:@"ARTRest Http response is %d", response.status]];
        if([s isAnErrorStatus:response.status]) {
            if(response.body) {
                ARTErrorInfo * error = [s.defaultEncoder decodeError:response.body];
                response.error = error;
                [ARTLog info:[NSString stringWithFormat:@"ARTRest received an error: \n status %d  \n code %d \n message: %@", error.statusCode, error.code, error.message]];
            }
        }
        if([s shouldTryFallback:response]) {
            if([s getNextFallbackHost]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [s makeRequestWithMethod:method relUrl:relUrl headers:headers body:body authenticated:authenticated cb:cb];
                });
            }
            else {
                [ARTLog warn:@"ARTRest has no more fallback hosts to attempt. Giving up."];
                cb(response);
                return;
            }
        }
        else if(response && response.error && response.error.code == 40140) {
            [ARTLog info:@"requesting new token"];
            if(![_auth canRequestToken]) {
                cb(response);
                return;
            }
            [_auth attemptTokenFetch:^() {
                ARTRest * s = weakSelf;
                if(s) {
                    //TODO consider counting this. enough times we give up?
                    [ARTLog debug:@"ARTRest Token fetch complete. Now trying the same server call again with the new token"];
                    [s makeRequestWithMethod:method relUrl:relUrl headers:headers body:body authenticated:authenticated cb:cb];
                }
                else {
                    [ARTLog error:@"ARTRest is nil. Can't renew token"];
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
        cb([ARTStatus state:ARTStatusOk info:response.error]);
    }];
}

- (NSURL *) getBaseURL {
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
    [ARTLog verbose:@"ARTRest is treating the relative url as the base"];
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
