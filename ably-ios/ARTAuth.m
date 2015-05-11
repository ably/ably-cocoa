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
#import "ARTTokenDetails+Private.h"


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
@property (readwrite, strong, nonatomic) ARTAuthOptions *options;

+ (ARTSignedTokenRequestCb)defaultSignedTokenRequestCallback:(ARTAuthOptions *)authOptions rest:(ARTRest *)rest;
+ (NSString *)random;
@end

@implementation ARTTokenDetails

- (instancetype)initWithId:(NSString *)token expires:(int64_t)expires issued:(int64_t)issued capability:(NSString *)capability clientId:(NSString *)clientId {
    self = [super init];
    if (self) {
        
        _token  = token;
        _expires = expires;
        _issued = issued;
        _capability = capability;
        _clientId = clientId;
    }
    return self;
}

@end

@implementation ARTTokenDetails (Private)

-(void) setExpiresTime:(int64_t)time {
    _expires = time;
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



-(NSDictionary *) asDictionary {
    NSMutableDictionary *reqObj = [NSMutableDictionary dictionary];
    reqObj[@"keyName"] = self.keyName ? self.keyName : @"";
    reqObj[@"capability"] = self.capability ? self.capability : @"";
    reqObj[@"ttl"] = [NSNumber numberWithLongLong:self.ttl];
    reqObj[@"clientId"] = self.clientId ? self.clientId : @"";
    reqObj[@"nonce"] = self.nonce ? self.nonce : @"";
    reqObj[@"timestamp"] = [NSNumber numberWithLongLong:self.timestamp];
    reqObj[@"mac"] = self.mac ? self.mac : @"";
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
        _queryTime = true;
        _tokenDetails = nil;
        _nonce =nil;
        _ttl = 3600000;

    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [self init];
    if (self) {
        NSArray *keyBits = [key componentsSeparatedByString:@":"];
        if(keyBits.count !=2) {
            [NSException raise:@"Invalid key" format:@"%@ should be of the form <keyName>:<keySecret>", key];
        }
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
    clone.signedTokenRequestCallback = self.signedTokenRequestCallback;
    clone.authUrl = self.authUrl;
    clone.keyName = self.keyName;
    clone.keySecret = self.keySecret;
    clone.token = self.token;
    clone.capability = self.capability;
    clone.nonce = self.nonce;
    clone.ttl = self.ttl;
    clone.authHeaders = self.authHeaders;
    clone.clientId = self.clientId;
    clone.queryTime = self.queryTime;
    clone.useTokenAuth =self.useTokenAuth;
    clone.tokenDetails = self.tokenDetails;
    return clone;
}

@end

@implementation ARTAuthOptions (Private)

-(void) setKeySecretTo:(NSString *)keySecret {
    _keySecret = keySecret;
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


+(void) authWithRest:(ARTRest *) rest options:(ARTAuthOptions *) options cb:(void(^)(ARTAuth *auth)) cb {
    ARTAuth * auth = [[ARTAuth alloc] initBasicWithRest:rest options:options];
    [auth prepConnection:^() {
        cb(auth);
    }];
}


-(instancetype) initBasicWithRest:(ARTRest *) rest options:(ARTAuthOptions *) options {
    self = [super init];
    if(self) {
        _rest = rest;
        _token = nil;
        _basicCredentials = nil;
        _authMethod = ARTAuthMethodBasic;
        _tokenCbs = nil;
        _tokenRequest = nil;
        _options = options;
        if (options.keyName != nil) {
            [ARTLog debug:@"ARTAuth: setting up auth method Basic"];
            _basicCredentials = [NSString stringWithFormat:@"Basic %@",
                                 [[[NSString stringWithFormat:@"%@:%@", options.keyName, options.keySecret] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
            _keyName = options.keyName;
            _keySecret = options.keySecret;
        }
    }
    return self;
}


-(bool) canRequestToken {
    if(self.options.keyName && self.options.keySecret) {
        [ARTLog verbose:@"ARTAuth can request token via key"];
        return true;
    }
    if(self.options.authCallback) {
        [ARTLog verbose:@"ARTAuth can request token via authCb"];
        return true;
    }
    if(self.options.authUrl) {
        [ARTLog verbose:@"ARTAuth can request token via authURL"];
        return true;
    }
    [ARTLog verbose:@"ARTAuth cannot request token"];
    return false;
}

-(void) prepConnection:(void (^)()) cb {
    if(![self shouldUseTokenAuth:self.options]) {
        cb();
        return;
    }
    _authMethod = ARTAuthMethodToken;
    [ARTLog debug:@"ARTAuth: setting up auth method Token"];
    _tokenCbs = [NSMutableArray array];
    
    if (self.options.token) {
        [ARTLog debug:[NSString stringWithFormat:@"ARTAuth:using provided authToken %@", self.options.token]];
        _token = [[ARTTokenDetails alloc] initWithId:self.options.token
                                             expires:self.options.tokenDetails.expires
                                              issued:self.options.tokenDetails.issued
                                          capability:self.options.capability
                                            clientId:self.options.clientId];
    }
    if (self.options.authCallback) {
        [ARTLog debug:@"ARTAuth: using provided authCallback"];
        _authTokenCb = self.options.authCallback;
        cb();
        return;
    }
    
    [ARTLog debug:@"ARTAuth: signed token request."];
    
    ARTSignedTokenRequestCb strCb = (self.options.signedTokenRequestCallback ? self.options.signedTokenRequestCallback : [ARTAuth defaultSignedTokenRequestCallback:self.options rest:self.rest]);
    __weak ARTAuth * weakSelf = self;
    _authTokenCb = ^(void(^authCb)(ARTStatus *,ARTTokenDetails *)) {
        ARTIndirectCancellable *ic = [[ARTIndirectCancellable alloc] init];
        ARTAuth * s = weakSelf;
        ARTAuthTokenParams * params = nil;
        if(s) {
            
          /*  if(![s canRequestToken]) {
                [ARTLog error:@"ARTAuth cannot request a token because it does not have either an API key, an authCallback or an auth URL"];
                authCb(ARTStatus *Error, nil);
                return ic;
            }
           */
            params =[[ ARTAuthTokenParams alloc] initWithId:s.options.keyName
                                                        ttl:s.options.ttl
                                                 capability:s.options.capability
                                                   clientId:s.options.clientId
                                                  timestamp:0
                                                      nonce:s.options.nonce
                                                        mac:nil];
        }
        id<ARTCancellable> c = strCb(params,^( ARTAuthTokenParams *params) {
            [ARTLog debug:[NSString stringWithFormat:@"ARTAuth tokenRequest strCb got %@", [params asDictionary]]];
            ARTAuth * s = weakSelf;
            if(s) {
                [s.rest token:params tokenCb:^(ARTStatus * status, ARTTokenDetails * tokenDetails) {
                    ARTAuth * s = weakSelf;
                    if(s) {
                        //TOOD set one of these and delete the others.
                        s.token = tokenDetails;
                        s.options.token = tokenDetails.token;
                        s.options.tokenDetails = tokenDetails;
                    }
                    else {
                        [ARTLog error:@"ARTAuth became nil during token request. Can't assign token"];
                    }

                    authCb(status, tokenDetails);
                }];
            }
            else {
                [ARTLog error:@"ARTAuth has no ARTRest to use to request a token"];
            }
        });
        ic.cancellable = c;
        return ic;
    };
    cb();
}

-(void) attemptTokenFetch:(void (^)()) cb {
    if(self.authTokenCb) {
        self.authTokenCb(^(ARTStatus * status, ARTTokenDetails * details){
            cb();
        });
    }
    else {
        cb();
    }
}

-(bool) shouldUseTokenAuth:(ARTAuthOptions *) options {
    return options.useTokenAuth ||
    options.clientId     ||
    options.token        ||
    options.authUrl      ||
    options.authCallback;
}


-(ARTAuthOptions *) getAuthOptions {
    return self.options;
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
        if (0 == self.token.expires || self.token.expires > [[NSDate date] timeIntervalSince1970] * 1000) {
            if (!force) {
                return cb(self.token);
            }
            else {
                [ARTLog debug:@"ARTAuth forcing new token request"];
            }
        }
        else {
            [ARTLog debug:[NSString stringWithFormat:@"ARTAuth token expired %f milliseconds ago",  ([[NSDate date] timeIntervalSince1970]*1000)- self.token.expires]];
        }
        self.token = nil;
    }
    else {
        [ARTLog debug:@"ARTAuth has no token. Requesting one now"];
    }
    
    ARTAuthTokenCancellable *c = [[ARTAuthTokenCancellable alloc] initWithCb:cb];
    [self.tokenCbs addObject:c];
    if (!self.tokenRequest) {
        self.tokenRequest = self.authTokenCb(^(ARTStatus * status, ARTTokenDetails *token) {
            if(status.status != ARTStatusOk) {
                [ARTLog error:@"ARTAuth: error fetching token"];
                cb(nil);
                return;
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
    

    
    __weak ARTRest *weakRest = rest;
    return ^id<ARTCancellable>(ARTAuthTokenParams *params, void(^cb)(ARTAuthTokenParams *)) {
        NSString *keySecret = authOptions.keySecret;
        BOOL queryTime = authOptions.queryTime;

        if (params.keyName && ![params.keyName isEqualToString:authOptions.keyName]) {
            [NSException raise:@"ARTAuthParams keyName is not equal to ARTAuthOptions keyName" format:@"'%@' != '%@'", params.keyName, authOptions.keyName];
        }

        int64_t ttl = params.ttl ? params.ttl :  3600000;
        NSString * ttlText = [NSString stringWithFormat:@"%lld", ttl];
        NSString * keyName = params.keyName;
        NSString * nonce = params.nonce ? params.nonce : [ARTAuth random];
        NSString * capability = params.capability ? params.capability : @"";
        NSString * clientId = params.clientId ? params.clientId : @"";
        void (^timeCb)(void(^)(int64_t)) = nil;
        if (!params.timestamp) {
            if (queryTime) {
                [ARTLog debug:@"ARTAuth: query time is being used"];
                timeCb = ^(void(^cb)(int64_t)) {
                    ARTRest *strongRest = weakRest;
                    if (strongRest) {
                        [strongRest time:^(ARTStatus * status, NSDate *time) {
                            if (status.status == ARTStatusOk) {
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
                    [ARTLog debug:@"ARTAuth: client time is being used"];
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
            NSString * mac =params.mac ? params.mac : [ARTAuth hmacForData:[signText dataUsingEncoding:NSUTF8StringEncoding] key:[keySecret dataUsingEncoding:NSUTF8StringEncoding]];
            
            ARTAuthTokenParams * p = [[ARTAuthTokenParams alloc] initWithId:keyName ttl:ttl capability:capability clientId:clientId timestamp:timestamp nonce:nonce mac:mac];
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