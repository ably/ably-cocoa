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
@property (readonly, strong, nonatomic) ARTAuth *auth;
@property (readonly, strong, nonatomic) NSDictionary *encoders;
@property (readonly, strong, nonatomic) NSString *defaultEncoding;

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb;

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
        // TODO cipher params!
        _payloadEncoder = [ARTPayload defaultPayloadEncoder:cipherParams];
    }
    return self;
}

+ (instancetype)channelWithRest:(ARTRest *)rest name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams {
    return [[ARTRestChannel alloc] initWithRest:rest name:name cipherParams:cipherParams];
}

- (id<ARTCancellable>)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb {
    
    [ARTLog debug:[NSString stringWithFormat:@"ARTRestChannel: publishing %@ to channel %@", payload, name]];
    ARTMessage *message = [[ARTMessage alloc] init];
    message.name = name;
    message.payload =[ARTPayload payloadWithPayload:payload encoding:@""];
    message = [message encode:self.payloadEncoder];

    NSData *encodedMessage = [self.rest.defaultEncoder encodeMessage:message];
    NSDictionary *headers = @{@"Content-Type":self.rest.defaultEncoding};
    NSString *path = [NSString stringWithFormat:@"%@/messages", self.basePath];
    return [self.rest post:path headers:headers body:encodedMessage authenticated:YES cb:^(ARTHttpResponse *response) {
        ARTStatus status = response.status >= 200 && response.status < 300 ? ARTStatusOk : ARTStatusError;
        cb(status);
    }];
}

- (id<ARTCancellable>)publish:(id)payload cb:(ARTStatusCallback)cb {
    return [self publish:payload withName:nil cb:cb];
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

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[ARTOptions optionsWithKey:key]];
}

- (instancetype)initWithOptions:(ARTOptions *)options {
    self = [super init];
    if (self) {
        NSLog(@"WTFFFF");
        _http = [[ARTHttp alloc] init];
        _baseUrl = [options restUrl];
        _channels = [NSMutableDictionary dictionary];
        _auth = [[ARTAuth alloc] initWithRest:self options:options.authOptions];

        id<ARTEncoder> defaultEncoder = [[ARTJsonEncoder alloc] init];
        //msgpack not supported yet.
 //       id<ARTEncoder> msgpackEncoder  = [[ARTMsgPackEncoder alloc] init];
        _encoders = @{
            [defaultEncoder mimeType]: defaultEncoder,
   //         [msgpackEncoder mimeType] : msgpackEncoder
        };
        
        _defaultEncoding = [defaultEncoder mimeType];
    }
    return self;
}

- (id<ARTCancellable>)time:(void (^)(ARTStatus, NSDate *))cb {
    return [self get:@"/time" authenticated:NO cb:^(ARTHttpResponse *response) {
        NSDate *date = nil;
        if (response.status == 200) {
            date = [self.defaultEncoder decodeTime:response.body];
        }
        if (date) {
            cb(ARTStatusOk, date);
        } else {
            cb(ARTStatusError, nil);
        }
    }];
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

- (id<ARTCancellable>)makeRequestWithMethod:(NSString *)method relUrl:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb {
    NSURL *url = [self resolveUrl:relUrl];
    headers = [self withAcceptHeader:headers];

    if (authenticated) {
        return [self withAuthHeaders:^(NSDictionary *authHeaders) {
            NSMutableDictionary *allHeaders = [NSMutableDictionary dictionary];
            [allHeaders addEntriesFromDictionary:headers];
            [allHeaders addEntriesFromDictionary:authHeaders];
            return [self.http makeRequestWithMethod:method url:url headers:allHeaders body:body cb:cb];
        }];
    } else {
        return [self.http makeRequestWithMethod:method url:url headers:headers body:body cb:cb];
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

- (id<ARTCancellable>)post:(NSString *)relUrl headers:(NSDictionary *)headers body:(NSData *)body authenticated:(BOOL)authenticated cb:(ARTHttpCb)cb {
    return [self makeRequestWithMethod:@"POST" relUrl:relUrl headers:headers body:body authenticated:authenticated cb:cb];
}

- (id<ARTCancellable>)withAuthHeaders:(id<ARTCancellable>(^)(NSDictionary *))cb {
    return [self.auth authHeaders:cb];
}

- (id<ARTCancellable>)withAuthParams:(id<ARTCancellable>(^)(NSDictionary *))cb {
    return [self.auth authParams:cb];
}

@end
