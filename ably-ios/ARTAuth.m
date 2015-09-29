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

@property (nonatomic, weak) ARTLog * logger;
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

+ (ARTSignedTokenRequestCb)defaultSignedTokenRequestCallback:(ARTAuthOptions *)authOptions forRest:(ARTRest *)rest withLogger:(ARTLog *)logger;
+ (NSString *)random;
+ (NSArray *)checkValidKey:(NSString *) key;

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


-(void) setTokenParams:(ARTAuthTokenParams *)tokenParams {
    _tokenParams =tokenParams;
    self.keyName = tokenParams.keyName;
}


- (instancetype)initWithKey:(NSString *)key {
    self = [self init];
    if (self) {
        NSArray * keyBits =[ARTAuth checkValidKey:key];
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


@implementation  ARTAuth (Private)

-(ARTAuthCb) getTheAuthCb {
    return self.authTokenCb;
}

@end
@implementation ARTAuth

- (instancetype)initWithRest:(ARTRest *) rest options:(ARTAuthOptions *) options {
    self = [super init];
    if(self) {
        _rest = rest;
        _token = nil;
        _basicCredentials = nil;
        _authMethod = ARTAuthMethodBasic;
        _tokenCbs = nil;
        _tokenRequest = nil;
        _options = options;
        self.logger = rest.logger;
        
        if (options.keyName != nil) {
            [self.logger debug:@"ARTAuth: setting up auth method Basic"];
            _basicCredentials = [NSString stringWithFormat:@"Basic %@",
                                 [[[NSString stringWithFormat:@"%@:%@", options.keyName, options.keySecret] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
            [ARTAuth checkValidKey:[NSString stringWithFormat:@"%@:%@", options.keyName, options.keySecret]];
            _keyName = options.keyName;
            _keySecret = options.keySecret;
        }
        else if(options.token == nil && options.tokenParams == nil) {
            [NSException raise:@"Either a token, token param, or a keyName and secret are required to connect to Ably" format:nil];
        }
        
        [self prepConnection];
    }
    return self;
}

+ (NSArray *)checkValidKey:(NSString *) key {
    NSArray *keyBits = [key componentsSeparatedByString:@":"];
    if(keyBits.count !=2) {
        [NSException raise:@"Invalid key" format:@"%@ should be of the form <keyName>:<keySecret>", key];
    }
    return keyBits;
}

-(bool) canRequestToken {
    if(self.options.keyName && self.options.keySecret) {
        [self.logger verbose:@"ARTAuth can request token via key"];
        return true;
    }
    if(self.options.authCallback) {
        [self.logger verbose:@"ARTAuth can request token via authCb"];
        return true;
    }
    if(self.options.authUrl) {
        [self.logger verbose:@"ARTAuth can request token via authURL"];
        return true;
    }
    if(self.options.tokenParams) {
        [self.logger verbose:@"ARTAuth can request token via tokenParams"];
        return true;
    }
    [self.logger verbose:@"ARTAuth cannot request token"];
    return false;
}


- (ARTAuthTokenParams *) getTokenParams {
    //TODO what if tokenParams is nil
    
    
    return self.options.tokenParams ? self.options.tokenParams: [[ ARTAuthTokenParams alloc] initWithId:self.options.keyName
                                               ttl:self.options.ttl
                                        capability:self.options.capability
                                          clientId:self.options.clientId
                                         timestamp:0
                                             nonce:self.options.nonce
                                               mac:nil];
}

-(void) prepConnection {
    if(![self shouldUseTokenAuth:self.options]) {
        return;
    }
    _authMethod = ARTAuthMethodToken;
    [self.logger debug:@"ARTAuth: setting up auth method Token"];
    _tokenCbs = [NSMutableArray array];
    
    if (self.options.token) {
        [self.logger debug:[NSString stringWithFormat:@"ARTAuth:using provided authToken %@", self.options.token]];
        _token = [[ARTTokenDetails alloc] initWithId:self.options.token
                                             expires:self.options.tokenDetails.expires
                                              issued:self.options.tokenDetails.issued
                                          capability:self.options.capability
                                            clientId:self.options.clientId];
    }
    if (self.options.authCallback) {
        [self.logger debug:@"ARTAuth: using provided authCallback"];
        _authTokenCb = self.options.authCallback;
        return;
    }
    
    [self.logger debug:@"ARTAuth: signed token request."];
    
    ARTSignedTokenRequestCb strCb = (self.options.signedTokenRequestCallback ? self.options.signedTokenRequestCallback : [ARTAuth defaultSignedTokenRequestCallback:self.options forRest:self.rest withLogger:self.logger]);
    
    __weak ARTAuth * weakSelf = self;
    _authTokenCb = ^(void(^authCb)(ARTStatus *,ARTTokenDetails *)) {
        ARTIndirectCancellable *ic = [[ARTIndirectCancellable alloc] init];
        ARTAuth * s = weakSelf;
        ARTAuthTokenParams * params = nil;
        if(s) {
            params =[s getTokenParams];
            s.options.tokenParams = params;
        }
        id<ARTCancellable> c = strCb(params,^( ARTAuthTokenParams *params) {
            [weakSelf.logger debug:[NSString stringWithFormat:@"ARTAuth tokenRequest strCb got %@", [params asDictionary]]];
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
                        [weakSelf.logger error:@"ARTAuth became nil during token request. Can't assign token"];
                    }
                    authCb(status, tokenDetails);
                }];
            }
            else {
                [weakSelf.logger error:@"ARTAuth has no ARTRest to use to request a token"];
            }
        });
        ic.cancellable = c;
        return ic;
    };
}

-(void) attemptTokenFetch:(void (^)()) cb {
    self.token = nil;

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
    options.authCallback ||
    options.tokenParams;
}


-(ARTAuthOptions *) getAuthOptions {
    return self.options;
}

- (ARTAuthMethod) getAuthMethod {
    return self.authMethod;
}

- (id<ARTCancellable>)authHeadersUseBasic:(BOOL)useBasic cb:(id<ARTCancellable>(^)(NSDictionary *))cb {
    if(useBasic || self.authMethod == ARTAuthMethodBasic) {
        [self.logger verbose:@"using auth basic"];
        return cb(@{@"Authorization": self.basicCredentials});
    }
    else if(self.authMethod == ARTAuthMethodToken) {
        [self.logger verbose:@"using auth token"];
        return [self requestToken:^(ARTTokenDetails *token) {
            [self.logger verbose:@"retrieved token via request token"];
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
            return [self requestToken:^(ARTTokenDetails *token) {
                return cb(@{@"access_token:": token.token});
            }];
        default:
            NSAssert(NO, @"Invalid auth method");
            return nil;
    }
}

- (id<ARTCancellable>)requestToken:(id<ARTCancellable>(^)(ARTTokenDetails *))cb {
    return [self authTokenForceReauth:NO cb:cb];
}

- (id<ARTCancellable>)authTokenForceReauth:(BOOL)force cb:(id<ARTCancellable>(^)(ARTTokenDetails *))cb {
    [self.logger verbose:@"ARTAuth authTokenForceReauth"];
    if (self.token) {
        if (0 == self.token.expires || self.token.expires > [[NSDate date] timeIntervalSince1970] * 1000) {
            if (!force) {
                [self.logger verbose:@"ARTAuth has a valid token to use"];
                return cb(self.token);
            }
            else {
                [self.logger debug:@"ARTAuth forcing new token request"];
            }
        }
        else {
            [self.logger debug:[NSString stringWithFormat:@"ARTAuth token expired %f milliseconds ago. Expiry: %lld",  ([[NSDate date] timeIntervalSince1970]*1000)- self.token.expires, self.token.expires]];
        }
        self.token = nil;
    }
    else {
        [self.logger debug:@"ARTAuth has no token. Requesting one now"];
    }
    
    ARTAuthTokenCancellable *c = [[ARTAuthTokenCancellable alloc] initWithCb:cb];
    [self.tokenCbs addObject:c];
    if (!self.tokenRequest) {
        self.tokenRequest = self.authTokenCb(^(ARTStatus * status, ARTTokenDetails *token) {
            if(status.state != ARTStateOk) {
                [self.logger error:@"ARTAuth: error fetching token"];
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

+ (ARTSignedTokenRequestCb)defaultSignedTokenRequestCallback:(ARTAuthOptions *)authOptions forRest:(ARTRest *)rest withLogger:(ARTLog *)logger {
    __weak ARTRest *weakRest = rest;
    [logger verbose:@"ARTAUTH creating signed token request callback"];
    
    return ^id<ARTCancellable>(ARTAuthTokenParams *params, void(^cb)(ARTAuthTokenParams *)) {
        [logger verbose:@"ARTAUTH signed token request callback called"];
        
        NSString *keySecret = authOptions.keySecret;
        BOOL queryTime = authOptions.queryTime;
        
        if (authOptions.keyName != nil &&  params.keyName && ![params.keyName isEqualToString:authOptions.keyName]) {
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
                [logger debug:@"ARTAuth: query time is being used"];
                timeCb = ^(void(^cb)(int64_t)) {
                    ARTRest *strongRest = weakRest;
                    if (strongRest) {
                        [strongRest time:^(ARTStatus * status, NSDate *time) {
                            if (status.state == ARTStateOk) {
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
                    [logger debug:@"ARTAuth: client time is being used"];
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