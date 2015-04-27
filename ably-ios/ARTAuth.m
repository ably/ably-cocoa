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
#import "ARTPayload.h"
#import "ARTLog.h"


@interface ARTAuthTokenCancellable : NSObject <ARTCancellable>

@property (readwrite, assign, nonatomic) BOOL isCancelled;
@property (readwrite, strong, nonatomic) id<ARTCancellable>(^cb)(ARTTokenDetails*token);
@property (readwrite, strong, nonatomic) id<ARTCancellable> cancellable;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCb:(id<ARTCancellable>(^)(ARTTokenDetails*token))cb;

- (void)onAuthToken:(ARTTokenDetails *)token;

@end

@interface ARTAuth ()

@property (readonly, weak, nonatomic) ARTRest *rest;
@property (readwrite, strong, nonatomic) ARTTokenDetails *token;
@property (assign, nonatomic) ARTAuthMethod authMethod;
@property (readonly, strong, nonatomic) NSString *basicCredentials;
@property (readonly, strong, nonatomic) NSString *keyName;
@property (readonly, strong, nonatomic) NSString *keySecret;
@property (readonly, strong, nonatomic) ARTAuthCb authTokenCb;
@property (readwrite, strong, nonatomic) NSMutableArray *tokenCbs;
@property (readwrite, strong, nonatomic) id<ARTCancellable> tokenRequest;
+ (ARTSignedTokenRequestCb)defaultSignedTokenRequestCallback:(ARTAuthOptions *)authOptions rest:(ARTRest *)rest;
+ (NSString *)random;
@end

@implementation ARTTokenDetails

- (instancetype)initWithId:(NSString *)token expires:(int64_t)expires issued:(int64_t)issued capability:(NSString *)capability clientId:(NSString *)clientId {
    self = [super init];
    if (self) {
        
        NSData * tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
        _token  = [ARTBase64PayloadEncoder toBase64:tokenData];
        _expires = expires;
        _issued = issued;
        _capability = capability;
        _clientId = clientId;
    }
    return self;
}

+ (instancetype)authTokenWithId:(NSString *)id expires:(int64_t)expires issued:(int64_t)issued capability:(NSString *)capability clientId:(NSString *)clientId {
    return [[ARTTokenDetails alloc] initWithId:id expires:expires issued:issued capability:capability clientId:clientId];
}

@end

@implementation ARTAuthTokenParams

- (instancetype)initWithId:(NSString *)keyName ttl:(int64_t)ttl capability:(NSString *)capability clientId:(NSString *)clientId timestamp:(int64_t)timestamp nonce:(NSString *)nonce mac:(NSString *)mac {
    self = [super init];
    if (self) {
        _keyName = keyName;
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


-(NSDictionary *) asDictionary {
    NSMutableDictionary *reqObj = [NSMutableDictionary dictionary];
    reqObj[@"keyName"] = self.keyName;
    reqObj[@"capability"] = self.capability;
    reqObj[@"ttl"] = [NSNumber numberWithLongLong:self.ttl];
    reqObj[@"clientId"] = self.clientId;
    reqObj[@"nonce"] = self.nonce;
    reqObj[@"timestamp"] = [NSNumber numberWithLongLong:self.timestamp];
    reqObj[@"mac"] = self.mac;
    return reqObj;
}

@end

@implementation ARTAuthOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _authCallback = nil;
        _authUrl = nil;
        _keyName = nil;
        _keySecret = nil;
        _token = nil;
        _authHeaders = nil;
        _clientId = nil;
        _capability = nil;
        _useTokenAuth = false;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [self init];
    if (self) {
        NSArray *keyBits = [key componentsSeparatedByString:@":"];
        NSAssert(keyBits.count == 2, @"Invalid key");
        _keyName = keyBits[0];
        _keySecret = keyBits[1];
            
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
    clone.keyName = self.keyName;
    clone.keySecret = self.keySecret;
    clone.token = self.token;
    clone.authHeaders = self.authHeaders;
    clone.clientId = self.clientId;
    clone.useTokenAuth =self.useTokenAuth;
    return clone;
}

@end

@implementation ARTAuthTokenCancellable

- (instancetype)initWithCb:(id<ARTCancellable>(^)(ARTTokenDetails *token))cb {
    self = [super init];
    if (self) {
        _cb = cb;
    }
    return self;
}

- (void)onAuthToken:(ARTTokenDetails *)token {
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

-(bool) shouldUseTokenAuth:(ARTAuthOptions *) options
{
    if(options.useTokenAuth){
        return true;
    }
    if(options.clientId) {
        return true;
    }
    if(options.token) {
        return true;
    }
    if(options.authUrl) {
        return true;
    }
    if(options.authCallback) {
        return true;
    }
    if(options.keyName) {
        return true;
    }
    return false;
}

- (instancetype)initWithRest:(ARTRest *)rest options:(ARTAuthOptions *)options {
    self = [super init];
    if (self) {
        _rest = rest;
        _token = nil;
        _basicCredentials = nil;
        _authMethod = ARTAuthMethodBasic;
        _tokenCbs = nil;
        _tokenRequest = nil;

        //create BasicAuth, which will either be used directly,
        //or only used to set up TokenAuth
        if (options.keyName != nil) {
            [ARTLog debug:@"ARTAuth: setting up auth method Basic"];
            _basicCredentials = [NSString stringWithFormat:@"Basic %@", [[[NSString stringWithFormat:@"%@:%@", options.keyName, options.keySecret] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
            _keyName = options.keyName;
            _keySecret = options.keySecret;
        }
        else {
            [ARTLog warn:@"ARTAuth Error: cannot set up basic auth without a valid ArtAuthOptions keyValue. "];
        }
        if(options.useTokenAuth) {
            _authMethod= ARTAuthMethodToken;
            [ARTLog debug:@"ARTAuth: setting up auth method Token"];
            _tokenCbs = [NSMutableArray array];

            if (options.token) {
                [ARTLog debug:[NSString stringWithFormat:@"ARTAuth:using provided authToken %@", options.token]];
                _token = [[ARTTokenDetails alloc] initWithId:options.token expires:0 issued:0 capability:options.capability clientId:options.clientId];
            } else if (options.authCallback) {
                [ARTLog debug:@"ARTAuth: using provided authCallback"];
                _authTokenCb = options.authCallback;
            } else {
                [ARTLog debug:@"ARTAuth: signed token request."];
                ARTSignedTokenRequestCb strCb = (options.signedTokenRequestCallback ? options.signedTokenRequestCallback : [ARTAuth defaultSignedTokenRequestCallback:options rest:rest]);
                __weak ARTRest * weakRest = self.rest;
                _authTokenCb = ^(void(^cb)(ARTStatus,ARTTokenDetails *)) {
                    
                    ARTIndirectCancellable *ic = [[ARTIndirectCancellable alloc] init];

                    id<ARTCancellable> c = strCb(nil,^( ARTAuthTokenParams *params) {
                        [ARTLog debug:[NSString stringWithFormat:@"ARTAuth tokenRequest strCb got %@", [params asDictionary]]];
                        ARTRest * r = weakRest;
                        if(r) {
                            [r token:params tokenCb:^(ARTStatus status, ARTTokenDetails * token) {
                                cb(status, token);
                            }];
                        }
                        else {
                            [ARTLog debug:@"ARTAuth has no ARTRest"];
                        }
                    });
                    ic.cancellable = c;
                    return ic;
                };
            }
        }
    }
    return self;
}
- (ARTAuthMethod) getAuthMethod {
    return self.authMethod;
}
- (id<ARTCancellable>)authHeadersUseBasic:(BOOL)useBasic cb:(id<ARTCancellable>(^)(NSDictionary *))cb {

    if(useBasic || self.authMethod == ARTAuthMethodBasic) {
        return cb(@{@"Authorization": self.basicCredentials});
    }
    else if(self.authMethod == ARTAuthMethodToken) {
        return [self authToken:^(ARTTokenDetails *token) {
            return cb(@{@"Authorization": [NSString stringWithFormat:@"Bearer %@", token.token]});
        }];
    }
    else {
        NSAssert(NO, @"Invalid auth method");
        return nil;
    }
}

- (id<ARTCancellable>)authParams:(id<ARTCancellable>(^)(NSDictionary *))cb {
    switch (self.authMethod) {
        case ARTAuthMethodBasic:
            return cb(@{@"key_id":self.keyName, @"key_value":self.keySecret});
        case ARTAuthMethodToken:
            return [self authToken:^(ARTTokenDetails *token) {
                return cb(@{@"access_token:": token.token});
            }];
        default:
            NSAssert(NO, @"Invalid auth method");
            return nil;
    }
}

- (id<ARTCancellable>)authToken:(id<ARTCancellable>(^)(ARTTokenDetails *))cb {
    return [self authTokenForceReauth:NO cb:cb];
}

- (id<ARTCancellable>)authTokenForceReauth:(BOOL)force cb:(id<ARTCancellable>(^)(ARTTokenDetails *))cb {
    if (self.token) {
        if (0 == self.token.expires || self.token.expires > [[NSDate date] timeIntervalSince1970]) {
            if (!force) {
                return cb(self.token);
            }
        }
        self.token = nil;
    }

    ARTAuthTokenCancellable *c = [[ARTAuthTokenCancellable alloc] initWithCb:cb];
    [self.tokenCbs addObject:c];

    if (!self.tokenRequest) {
        self.tokenRequest = self.authTokenCb(^(ARTStatus status, ARTTokenDetails *token) {
            if(status != ARTStatusOk) {
                [ARTLog error:@"ARTAuth: error fetching token"];
            }
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

+ (ARTSignedTokenRequestCb)defaultSignedTokenRequestCallback:(ARTAuthOptions *)authOptions rest:(ARTRest *)rest {
    
    NSString *keyName = authOptions.keyName;
    NSString *keySecret = authOptions.keySecret;
    BOOL queryTime = authOptions.queryTime;
    NSString * clientId = authOptions.clientId;
    NSString *capability =authOptions.capability;
    __weak ARTRest *weakRest = rest;

    NSAssert(keyName && keySecret, @"keyName and keySecret must be set when using the default token auth");

    return ^id<ARTCancellable>(ARTAuthTokenParams *params, void(^cb)(ARTAuthTokenParams *)) {

        if (params.keyName && ![params.keyName isEqualToString:keyName]) {
            [ARTLog error:[NSString stringWithFormat:@"ARTAuth params keyname %@ is not equal to authOptions id %@", params.keyName, keyName]];
            cb(nil);
            return nil;
        }

        int64_t ttl =params.ttl ? params.ttl :  3600000;
        NSString *ttlText = [NSString stringWithFormat:@"%lld", ttl];

        NSString *nonce = params.nonce ? params.nonce : [ARTAuth random];

        void (^timeCb)(void(^)(int64_t)) = nil;
        if (!params.timestamp) {
            if (queryTime) {
                timeCb = ^(void(^cb)(int64_t)) {
                    ARTRest *strongRest = weakRest;
                    if (strongRest) {
                        [strongRest time:^(ARTStatus status, NSDate *time) {
                            if (status == ARTStatusOk) {
                                cb((int64_t)([time timeIntervalSince1970] *1000.0));
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
                    cb((int64_t)([[NSDate date] timeIntervalSince1970] *1000.0 ));
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

            NSString *signText = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%lld\n%@\n", keyName, ttlText, capability, clientId, timestamp, nonce];
            NSString * theMac =params.mac ? params.mac : [ARTAuth hmacForData:[signText dataUsingEncoding:NSUTF8StringEncoding] key:[keySecret dataUsingEncoding:NSUTF8StringEncoding]];
            ARTAuthTokenParams * p = [[ARTAuthTokenParams alloc] initWithId:keyName ttl:ttl capability:capability clientId:clientId timestamp:timestamp nonce:nonce mac:theMac];
            cb(p);
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
    NSString * str = [ARTBase64PayloadEncoder toBase64:mac];
    return str;
}


 

@end
