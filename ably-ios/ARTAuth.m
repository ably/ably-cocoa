//
//  ARTAuth.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTAuth.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#import "ARTRest.h"

@interface ARTAuthTokenCancellable : NSObject <ARTCancellable>

@property (readwrite, assign, nonatomic) BOOL isCancelled;
@property (readwrite, strong, nonatomic) id<ARTCancellable>(^cb)(ARTAuthToken *token);
@property (readwrite, strong, nonatomic) id<ARTCancellable> cancellable;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCb:(id<ARTCancellable>(^)(ARTAuthToken *token))cb;

- (void)onAuthToken:(ARTAuthToken *)token;

@end

@interface ARTAuth ()

@property (readonly, weak, nonatomic) ARTRest *rest;
@property (readwrite, strong, nonatomic) ARTAuthToken *authToken;
@property (readonly, assign, nonatomic) ARTAuthMethod authMethod;
@property (readonly, strong, nonatomic) NSString *basicCredentials;
@property (readonly, strong, nonatomic) NSString *keyId;
@property (readonly, strong, nonatomic) NSString *keyValue;
@property (readonly, strong, nonatomic) ARTAuthCb authTokenCb;
@property (readwrite, strong, nonatomic) NSMutableArray *tokenCbs;
@property (readwrite, strong, nonatomic) id<ARTCancellable> tokenRequest;

+ (NSString *)random;
/*
+ (ARTSignedTokenRequestCb)defaultSignedTokenRequestCallback:(ARTAuthOptions *)authOptions rest:(ARTRest *)rest;
+ (NSString *)hmacForData:(NSData *)data key:(NSData *)key;
*/
@end

@implementation ARTAuthToken

- (instancetype)initWithId:(NSString *)id expires:(int64_t)expires issuedAt:(int64_t)issuedAt capability:(NSString *)capability clientId:(NSString *)clientId {
    self = [super init];
    if (self) {
        _id = id;
        _expires = expires;
        _issuedAt = issuedAt;
        _capability = capability;
        _clientId = clientId;
    }
    return self;
}

+ (instancetype)authTokenWithId:(NSString *)id expires:(int64_t)expires issuedAt:(int64_t)issuedAt capability:(NSString *)capability clientId:(NSString *)clientId {
    return [[ARTAuthToken alloc] initWithId:id expires:expires issuedAt:issuedAt capability:capability clientId:clientId];
}

@end

@implementation ARTAuthTokenParams

- (instancetype)initWithId:(NSString *)id ttl:(int64_t)ttl capability:(NSString *)capability clientId:(NSString *)clientId timestamp:(int64_t)timestamp nonce:(NSString *)nonce mac:(NSString *)mac {
    self = [super init];
    if (self) {
        _id = id;
        _ttl = ttl;
        _capability = capability;
        _clientId = clientId;
        _timestamp = timestamp;
        _nonce = nonce;
        _mac = mac;
    }
    return self;
}

+ (instancetype)authTokenParamsWithId:(NSString *)id ttl:(int64_t)ttl capability:(NSString *)capability clientId:(NSString *)clientId timestamp:(int64_t)timestamp nonce:(NSString *)nonce mac:(NSString *)mac {
    return [[ARTAuthTokenParams alloc] initWithId:id ttl:ttl capability:capability clientId:clientId timestamp:timestamp nonce:nonce mac:mac];
}

@end

@implementation ARTAuthOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _authCallback = nil;
        _authUrl = nil;
        _keyId = nil;
        _keyValue = nil;
        _authToken = nil;
        _authHeaders = nil;
        _clientId = nil;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [self init];
    if (self) {
        NSArray *keyBits = [key componentsSeparatedByString:@":"];
        NSAssert(keyBits.count == 2, @"Invalid key");
        _keyId = keyBits[0];
        _keyValue = keyBits[1];
    }
    return self;
}

+ (instancetype)options {
    return [[ARTAuthOptions alloc] init];
}

+ (instancetype)optionsWithKey:(NSString *)key {
    return [[ARTAuthOptions alloc] initWithKey:key];
}

- (instancetype)clone {
    ARTAuthOptions *clone = [[ARTAuthOptions alloc] init];
    clone.authCallback = self.authCallback;
    clone.authUrl = self.authUrl;
    clone.keyId = self.keyId;
    clone.keyValue = self.keyValue;
    clone.authToken = self.authToken;
    clone.authHeaders = self.authHeaders;
    clone.clientId = self.clientId;
    return clone;
}

@end

@implementation ARTAuthTokenCancellable

- (instancetype)initWithCb:(id<ARTCancellable>(^)(ARTAuthToken *token))cb {
    self = [super init];
    if (self) {
        _cb = cb;
    }
    return self;
}

- (void)onAuthToken:(ARTAuthToken *)token {
    self.cancellable = self.cb(token);
}

- (void)cancel {
    self.isCancelled = YES;
    self.cb = nil;
    [self.cancellable cancel];
    self.cancellable = nil;
}

@end

@implementation ARTAuth

- (instancetype)initWithRest:(ARTRest *)rest options:(ARTAuthOptions *)options {
    self = [super init];
    if (self) {
        _rest = rest;
        _authToken = nil;
        _basicCredentials = nil;
        _authMethod = ARTAuthMethodBasic;
        _tokenCbs = nil;
        _tokenRequest = nil;

        if (nil != options.keyValue && nil == options.clientId) {
            _authMethod = ARTAuthMethodBasic;
            _basicCredentials = [NSString stringWithFormat:@"Basic %@", [[[NSString stringWithFormat:@"%@:%@", options.keyId, options.keyValue] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
            _keyId = options.keyId;
            _keyValue = options.keyValue;
        } else {
            _authMethod = ARTAuthMethodToken;
            _tokenCbs = [NSMutableArray array];

            if (options.authToken) {
                _authToken = [[ARTAuthToken alloc] initWithId:options.authToken expires:0 issuedAt:0 capability:nil clientId:nil];
            } else if (options.authCallback) {
                _authTokenCb = options.authCallback;
            } else {
                /* TODO
                ARTSignedTokenRequestCb strCb = options.signedTokenRequestCallback ? options.signedTokenRequestCallback : [ARTAuth defaultSignedTokenRequestCallback];
                _authTokenCb = ^(void(^cb)(ARTAuthToken *)){
                    ARTIndirectCancellable *ic = [[ARTIndirectCancellable alloc] init];
                    id<ARTCancellable> c = strCb(^(NSString *str) {
                        NSString *url = [NSString stringWithFormat:@"%@/keys/%@/requestToken"];
                    });
                    ic.cancellable = c;
                    return ic;
                };
                 */
            }
        }
    }
    return self;
}

- (id<ARTCancellable>)authHeaders:(id<ARTCancellable>(^)(NSDictionary *))cb {
    switch (self.authMethod) {
        case ARTAuthMethodBasic:
            return cb(@{@"Authorization": self.basicCredentials});
            return nil;
        case ARTAuthMethodToken:
            return [self authToken:^(ARTAuthToken *token) {
                return cb(@{@"Authorization": [NSString stringWithFormat:@"Bearer %@", token.id]});
            }];
        default:
            NSAssert(NO, @"Invalid auth method");
            return nil;
    }
}

- (id<ARTCancellable>)authParams:(id<ARTCancellable>(^)(NSDictionary *))cb {
    switch (self.authMethod) {
        case ARTAuthMethodBasic:
            return cb(@{@"key_id":self.keyId, @"key_value":self.keyValue});
        case ARTAuthMethodToken:
            return [self authToken:^(ARTAuthToken *token) {
                return cb(@{@"access_token": token.id});
            }];
        default:
            NSAssert(NO, @"Invalid auth method");
            return nil;
    }
}

- (id<ARTCancellable>)authToken:(id<ARTCancellable>(^)(ARTAuthToken *))cb {
    return [self authTokenForceReauth:NO cb:cb];
}

- (id<ARTCancellable>)authTokenForceReauth:(BOOL)force cb:(id<ARTCancellable>(^)(ARTAuthToken *))cb {
    if (self.authToken) {
        if (0 == self.authToken.expires || self.authToken.expires > [[NSDate date] timeIntervalSince1970]) {
            if (!force) {
                return cb(self.authToken);
            }
        }
        self.authToken = nil;
    }

    ARTAuthTokenCancellable *c = [[ARTAuthTokenCancellable alloc] initWithCb:cb];
    [self.tokenCbs addObject:c];

    if (!self.tokenRequest) {
        self.tokenRequest = self.authTokenCb(^(ARTAuthToken *token) {
            self.tokenRequest = nil;
            NSMutableArray *cbs = self.tokenCbs;
            self.tokenCbs = [NSMutableArray array];
            for (ARTAuthTokenCancellable *c in cbs) {
                [c onAuthToken:token];
            }
        });
    }

    return c;
}

+ (NSString *)random {
    // Generate two random numbers up to 8 digits long and concatenate them to produce a 16 digit random number
    NSUInteger r1 = arc4random_uniform(100000000);
    NSUInteger r2 = arc4random_uniform(100000000);
    return [NSString stringWithFormat:@"%08lu%08lu", (long)r1, (long)r2];
}
/* TODO
+ (ARTSignedTokenRequestCb)defaultSignedTokenRequestCallback:(ARTAuthOptions *)authOptions rest:(ARTRest *)rest {
    NSString *keyId = authOptions.keyId;
    NSString *keyValue = authOptions.keyValue;
    BOOL queryTime = authOptions.queryTime;

    __weak ARTRest *weakRest = rest;

    NSAssert(keyId && keyValue, @"keyId and keyValue must be set when using the default token auth");

    return ^(ARTAuthTokenParams *params, void(^cb)(NSString *)) {
        if (params.id && ![params.id isEqualToString:keyId]) {
            NSLog(@"Params id is not equal to authOptions id");
            cb(nil);
            return;
        }

        NSMutableDictionary *reqObj = [NSMutableDictionary dictionary];
        reqObj[@"id"] = keyId;
        NSString *ttlText = @"";
        if (params.ttl) {
            ttlText = [NSString stringWithFormat:@"%lld", params.ttl];
            reqObj[@"ttl"] = [NSNumber numberWithLongLong:params.ttl];
        }

        NSString *capability = params.capability ? params.capability : @"";
        reqObj[@"capability"] = capability;

        NSString *clientId = params.clientId ? params.clientId : @"";
        reqObj[@"client_id"] = clientId;

        NSString *nonce = params.nonce ? params.nonce : [ARTAuth random];
        reqObj[@"nonce"] = nonce;

        void (^timeCb)(void(^)(int64_t)) = nil;
        if (!params.timestamp) {
            if (queryTime) {
                timeCb = ^(void(^cb)(int64_t)) {
                    ARTRest *strongRest = weakRest;
                    if (strongRest) {
                        [strongRest time:^(ARTStatus status, NSDate *time) {
                            if (status == ARTStatusOk) {
                                cb((int64_t)([time timeIntervalSince1970] * 1000.0));
                            } else {
                                cb(0);
                            }
                        }];
                    } else {
                        cb(0);
                    }
                };
            } else {
                timeCb = ^(void(^cb)(int64_t)) {
                    cb((int64_t)([[NSDate date] timeIntervalSince1970] * 1000.0));
                };
            }
        } else {
            timeCb = ^(void(^cb)(int64_t) ) {
                cb(params.timestamp);
            };
        }

        ARTIndirectCancellable *ic = [[ARTIndirectCancellable alloc] init];
        timeCb(^(int64_t timestamp) {
            if ([ic isCancelled]) {
                return;
            }

            NSString *signText = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%lld\n%@\n", keyId, ttlText, capability, clientId, timestamp, nonce];

            reqObj[@"mac"] = params.mac ? params.mac : [ARTAuth hmacForData:[signText dataUsingEncoding:NSUTF8StringEncoding] key:[keyValue dataUsingEncoding:NSUTF8StringEncoding]];

            NSString *signedReq = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:reqObj options:0 error:nil] encoding:NSUTF8StringEncoding];

            cb(signedReq);
        });

        return ic;
    };
}

+ (NSString *)hmacForData:(NSData *)data key:(NSData *)key {
    const void *cKey = [key bytes];
    const void *cData = [data bytes];
    size_t keyLen = [key length];
    size_t dataLen = [data length];

    unsigned char hmac[CC_SHA256_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA256, cKey, keyLen, cData, dataLen, hmac);

    NSData *mac = [[NSData alloc] initWithBytes:hmac length:sizeof(hmac)];

    return [mac ablyBase64Encode];
}
 */

@end
