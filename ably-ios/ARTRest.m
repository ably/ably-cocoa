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
@property (readonly, strong, nonatomic) NSURL *baseUrl;
@property (readonly, strong, nonatomic) NSMutableDictionary *channels;
@property ( strong, nonatomic) ARTAuth *auth;
@property (readonly, strong, nonatomic) NSDictionary *encoders;
@property (readonly, strong, nonatomic) NSString *defaultEncoding;

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb;

- (NSDictionary *)withAcceptHeader:(NSDictionary *)headers;

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

        /*messages = [messages artMap:^id(ARTMessage *message) {
            ARTPayload *encodedPayload = nil;
            ARTStatus * status = [self.payloadEncoder encode:message.payload output:&encodedPayload];
            if (status != ARTStatusOk) {
                [ARTLog error:[NSString stringWithFormat:@"ARTRealtime: error decoding payload, status: %tu", status]];
            }
            return [message messageWithPayload:encodedPayload];
        }];
         */

    //TODO finish.
    ARTMessage * bigMessage = [ARTMessage messageWithPayload:messages name:nil];


    return [self publishMessage:bigMessage cb:cb];
}

-(id<ARTCancellable>) publishMessage:(ARTMessage *) message cb:(ARTStatusCallback) cb {
    NSData *encodedMessage = [self.rest.defaultEncoder encodeMessage:message];
    NSString * defaultEncoding = self.rest.defaultEncoding ? self.rest.defaultEncoding :@"";
    NSDictionary *headers = @{@"Content-Type":defaultEncoding};
    NSString *path = [NSString stringWithFormat:@"%@/messages", self.basePath];
    return [self.rest post:path headers:headers body:encodedMessage authenticated:ARTAuthenticationOn cb:^(ARTHttpResponse *response) {
        ARTStatus *status = [ARTStatus state:(response.status >= 200 && response.status < 300 ? ARTStatusOk : ARTStatusError)];
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
        NSArray * messages = [ARTMessage messagesWithPayloads:(NSArray *) payload];
        return [self publishMessages:messages cb:cb];
    }
    else {
        return [self publish:payload withName:nil cb:cb];
    }
}





- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb {
    return [self historyWithParams:nil cb:cb];
}

- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
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
    return [self presenceWithParams:nil cb:cb];
}

- (id<ARTCancellable>)presenceWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
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
        _baseUrl = [options restUrl];
        [self setup];
    }
    return self;
}

+ (void)restWithKey:(NSString *) key cb:(ARTRestConstructorCb) cb {
    ARTOptions * options  = [[ARTOptions alloc] initWithKey:key];
    [ARTRest restWithOptions:options cb:cb];
    
}

+ (void)restWithOptions:(ARTOptions *) options cb:(ARTRestConstructorCb) cb {
    if(!options.authOptions.token && (!options.authOptions.keyName || !options.authOptions.keySecret)) {
        [NSException raise:@"Either a token must be provided, or keyName and keySecret must be set" format:@""];
    }
    if(![ARTRest isValidKey:[NSString stringWithFormat:@"%@:%@", options.authOptions.keyName, options.authOptions.keySecret]]) {
        [NSException raise:@"Invalid keyName or keySecret" format:@"keyName '%@', keySecret '%@", options.authOptions.keyName, options.authOptions.keySecret];
    }
    ARTRest * r = [[ARTRest alloc] initNoAuth:options];
    [r setupAuth:options cb:^ {
        cb(r);
    }];
}

- (void)setupAuth:(ARTOptions *) options cb:(void(^)()) cb {
    [ARTAuth authWithRest:self options:options.authOptions cb:^(ARTAuth *auth ) {
        _auth = auth;
        //auth needs rest to have a valid basic self.auth before it can attempt the token fetch, so we do it here.
        [_auth attemptTokenFetch:^() {
            cb();
        }];

    }];
}

- (void) setup {
    _http = [[ARTHttp alloc] init];
    _channels = [NSMutableDictionary dictionary];
    id<ARTEncoder> defaultEncoder = [[ARTJsonEncoder alloc] init];
    _encoders = @{
                  [defaultEncoder mimeType]: defaultEncoder,
                  };
    
    _defaultEncoding = [defaultEncoder mimeType];
    
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
    NSDictionary * paramsDict = [params asDictionary];
    
    NSData * dictData = [NSJSONSerialization dataWithJSONObject:paramsDict options:0 error:nil];
    
    NSDictionary *headers = @{@"Content-Type":self.defaultEncoding};
    return [self post:keyPath headers:headers body:dictData authenticated:ARTAuthenticationUseBasic cb:^(ARTHttpResponse *response) {
        
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
            cb([ARTStatus state:ARTStatusError], nil);
        }
    }];
}

- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp)) cb {
    //TODO which url should i use here.
    [self.http makeRequestWithMethod:@"GET" url:[NSURL URLWithString:@"http://google.com"] headers:nil body:nil cb:^(ARTHttpResponse *response) {
        cb(response.status == 200);
    }];
    return nil;
     
}

- (id<ARTCancellable>)stats:(ARTPaginatedResultCb)cb {
    return [self statsWithParams:nil cb:cb];
}

- (id<ARTCancellable>)statsWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
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

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(ARTAuthentication)authenticated cb:(ARTHttpCb)cb {
    
    
    __weak ARTRest * weakSelf = self;
    ARTHttpCb errorCheckingCb = ^(ARTHttpResponse * response){
        switch (response.status) {
            case 400:
            case 401:
            case 403:
            case 404:
            case 405:
            case 500:{
                ARTErrorInfo * error = [self.defaultEncoder decodeError:response.body];
                response.error = error;
                [ARTLog info:[NSString stringWithFormat:@"ARTRest received an error: \n status %d  \n code %d \n message: %@", error.statusCode, error.code, error.message]];
                break;
            }
            default:
                break;
        }
        if(response.error && response.error.code == 40140) {

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
        cb(ARTStatusOk);
    }];
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
    return [NSURL URLWithString:relUrl relativeToURL:self.baseUrl];
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
