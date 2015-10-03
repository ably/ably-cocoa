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
#import "ARTRest+Private.h"
#import "ARTEncoder.h"
#import "ARTLog.h"
#import "ARTPayload.h"

//X7: NSArray<NSString *>
static NSArray *decomposeKey(NSString *key) {
    return [key componentsSeparatedByString:@":"];
}

@implementation ARTAuthTokenDetails

- (instancetype)initWithToken:(NSString *)token expires:(NSDate *)expires issued:(NSDate *)issued capability:(NSString *)capability clientId:(NSString *)clientId {
    if (self = [super init]) {
        _token  = [token copy];
        _expires = expires;
        _issued = issued;
        _capability = [capability copy];
        _clientId = [clientId copy];
    }
    
    return self;
}

- (instancetype)initWithToken:(NSString *)token {
    if (self = [super init]) {
        _token = [token copy];
    }
    
    return self;
}

@end


#pragma mark - ARTAuthTokenParams

@implementation ARTAuthTokenParams

- (instancetype)init {
    if (self = [super init]) {
        _ttl = 60 * 60;
        _timestamp = [NSDate date];
        _capability = @"{ \"*\": [ \"*\" ] }"; // allow all
    }
    
    return self;
}

- (void)setTimestamp:(NSDate *)timestamp {
    if (timestamp == nil) {
        timestamp = [NSDate date];
    }
    
    _timestamp = timestamp;
}

- (NSMutableArray *)toArray {
    NSMutableArray *params = [[NSMutableArray alloc] init];

    if (self.clientId)
        [params addObject:[NSURLQueryItem queryItemWithName:@"clientId" value:self.clientId]];
    if (self.ttl > 0)
        [params addObject:[NSURLQueryItem queryItemWithName:@"ttl" value:[NSString stringWithFormat:@"%f", self.ttl]]];
    if (self.capability)
        [params addObject:[NSURLQueryItem queryItemWithName:@"capability" value:self.capability]];
    if (self.timestamp > 0)
        [params addObject:[NSURLQueryItem queryItemWithName:@"timestamp" value:[NSString stringWithFormat:@"%f", self.timestamp.timeIntervalSince1970]]];
    
    return params;
}

- (NSMutableDictionary *)toDictionary {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (self.clientId)
        params[@"clientId"] = self.clientId;
    if (self.ttl > 0)
        params[@"ttl"] = [NSString stringWithFormat:@"%f", self.ttl];
    if (self.capability)
        params[@"capability"] = self.capability;
    if (self.timestamp > 0)
        params[@"timestamp"] = [NSString stringWithFormat:@"%f", self.timestamp.timeIntervalSince1970];
    
    return params;
}

- (NSArray *)toArrayWithUnion:(NSArray *)items {
    NSMutableArray *tokenParams = [self toArray];
    BOOL add = YES;

    for (NSURLQueryItem *item in items) {
        for (NSURLQueryItem *param in tokenParams) {
            // Check if exist
            if ([param.name isEqualToString:item.name]) {
                add = NO;
                break;
            }
        }
        if (add) {
            [tokenParams addObject:item];
        }
        add = YES;
    }
    
    return tokenParams;
}

- (NSDictionary *)toDictionaryWithUnion:(NSArray *)items {
    NSMutableDictionary *tokenParams = [self toDictionary];
    BOOL add = YES;
    
    for (NSURLQueryItem *item in items) {
        for (NSString *key in tokenParams.allKeys) {
            // Check if exist
            if ([key isEqualToString:item.name]) {
                add = NO;
                break;
            }
        }
        if (add) {
            tokenParams[item.name] = item.value;
        }
        add = YES;
    }

    return tokenParams;
}

static NSString *generateNonce() {
    // Generate two random numbers up to 8 digits long and concatenate them to produce a 16 digit random number
    NSUInteger r1 = arc4random_uniform(100000000);
    NSUInteger r2 = arc4random_uniform(100000000);
    return [NSString stringWithFormat:@"%08lu%08lu", (long)r1, (long)r2];
}

static NSString *hmacForDataAndKey(NSData *data, NSData *key) {
    const void *cKey = [key bytes];
    const void *cData = [data bytes];
    size_t keyLen = [key length];
    size_t dataLen = [data length];
    
    unsigned char hmac[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, keyLen, cData, dataLen, hmac);
    NSData *mac = [[NSData alloc] initWithBytes:hmac length:sizeof(hmac)];
    NSString *str = [ARTBase64PayloadEncoder toBase64:mac];
    return str;
}

- (ARTAuthTokenRequest *)sign:(NSString *)key {
    //X7: NSArray<NSString *>
    NSArray *keyComponents = decomposeKey(key);
    NSString *keyName = keyComponents[0];
    NSString *keySecret = keyComponents[1];
    NSString *nonce = generateNonce();
    
    NSString *signText = [NSString stringWithFormat:@"%@\n%lld\n%@\n%@\n%lld\n%@\n", keyName, (int64_t)(self.ttl * 1000), self.capability, self.clientId, (int64_t)(self.timestamp.timeIntervalSince1970 * 1000), nonce];
    NSString *mac = hmacForDataAndKey([signText dataUsingEncoding:NSUTF8StringEncoding], [keySecret dataUsingEncoding:NSUTF8StringEncoding]);
    
    return [[ARTAuthTokenRequest alloc] initWithTokenParams:self keyName:keyName nonce:nonce mac:mac];
}

@end


#pragma mark - ARTAuthTokenRequest

@implementation ARTAuthTokenRequest

@dynamic timestamp;

- (instancetype)initWithTokenParams:(ARTAuthTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac {
    if (self = [super init]) {
        self.ttl = tokenParams.ttl;
        self.capability = tokenParams.capability;
        self.clientId = tokenParams.clientId;
        self.timestamp = tokenParams.timestamp;
        _keyName = [keyName copy];
        _nonce = [nonce copy];
        _mac = [mac copy];
    }
    
    return self;
}

- (NSDictionary *)asDictionary {
    return nil;
}

@end


#pragma mark - ARTAuthOptions

@implementation ARTAuthOptions

NSString *const ARTAuthOptionsMethodDefault = @"GET";

- (instancetype)init {
    self = [super init];
    if (self) {
        _authMethod = ARTAuthOptionsMethodDefault;
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [self init];
    if (self) {
        if (decomposeKey(key).count != 2) {
            [NSException raise:@"Invalid key" format:@"%@ should be of the form <keyName>:<keySecret>", key];
        }
        _key = [key copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTAuthOptions *options = [[ARTAuthOptions allocWithZone:zone] init];
    
    options.key = self.key;
    options.token = self.token;
    options.useTokenAuth = self.useTokenAuth;
    options.authCallback = self.authCallback;
    options.authUrl = self.authUrl;
    options.authMethod = self.authMethod;
    options.authHeaders = self.authHeaders;
    options.authParams = self.authParams;
    options.queryTime = self.queryTime;
    
    return options;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTAuthOptions: key=%@ token=%@ authUrl=%@ authMethod=%@ hasAuthCallback=%d",
            self.key, self.token, self.authUrl, self.authMethod, self.authCallback != nil];
}

- (NSString *)token {
    return self.tokenDetails.token;
}

- (void)setToken:(NSString *)token {
    self.tokenDetails = [[ARTAuthTokenDetails alloc] initWithToken:token];
}

- (void)setAuthMethod:(NSString *)authMethod {
    if (authMethod == nil || authMethod.length == 0) {
        authMethod = ARTAuthOptionsMethodDefault;
    }
    
    _authMethod = [authMethod copy];
}

- (ARTAuthOptions *)mergeWith:(ARTAuthOptions *)precedenceOptions {
    ARTAuthOptions *merged = [self copy];
    
    if (precedenceOptions.key)
        merged.key = precedenceOptions.key;
    if (precedenceOptions.authCallback)
        merged.authCallback = precedenceOptions.authCallback;
    if (precedenceOptions.authUrl)
        merged.authUrl = precedenceOptions.authUrl;
    if (precedenceOptions.authMethod)
        merged.authMethod = precedenceOptions.authMethod;
    if (precedenceOptions.authHeaders)
        merged.authHeaders = precedenceOptions.authHeaders;
    if (precedenceOptions.authParams)
        merged.authParams = precedenceOptions.authParams;
    if (precedenceOptions.queryTime)
        merged.queryTime = precedenceOptions.queryTime;
    
    return merged;
}

- (BOOL)isMethodPOST {
    return [_authMethod isEqualToString:@"POST"];
}

- (BOOL)isMethodGET {
    return [_authMethod isEqualToString:@"GET"];
}

@end


#pragma mark - ARTAuth implementation

@implementation ARTAuth {
    __weak ARTRest *_rest;
}

- (instancetype)init:(ARTRest *)rest withOptions:(ARTAuthOptions *)options {
    if (self = [super init]) {
        _rest = rest;
        _currentToken = options.tokenDetails;
        _options = options;
        _logger = rest.logger;
        
        // REV: options.useTokenAuth
        
        if (options.key != nil && !options.useTokenAuth) {
            [self.logger debug:@"ARTAuth: setting up auth method Basic"];
            _authMethod = ARTAuthMethodBasic;
        } else if (options.tokenDetails) {
            [self.logger debug:@"ARTAuth: setting up auth method Token with supplied token only"];
            _authMethod = ARTAuthMethodToken;
        } else if (options.authUrl) {
            [self.logger debug:@"ARTAuth: setting up auth method Token with authUrl"];
            _authMethod = ARTAuthMethodToken;
        } else if (options.authCallback) {
            [self.logger debug:@"ARTAuth: setting up auth method Token with authCallback"];
            _authMethod = ARTAuthMethodToken;
        } else {
            [NSException raise:@"ARTAuthException" format:@"Could not setup authentication method with given options."];
        }
    }
    
    return self;
}

- (ARTAuthOptions *)mergeOptions:(ARTAuthOptions *)customOptions {
    return customOptions ? [self.options mergeWith:customOptions] : self.options;
}

- (ARTAuthTokenParams *)mergeParams:(ARTAuthTokenParams *)customParams {
    return customParams ? customParams : [[ARTAuthTokenParams alloc] init];
}

- (NSURL *)buildURL:(ARTAuthOptions *)options withParams:(ARTAuthTokenParams *)params {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:options.authUrl resolvingAgainstBaseURL:YES];
    
    if ([options isMethodGET]) {
        // TokenParams take precedence over any configured authParams when a name conflict occurs
        NSArray *unitedParams = [params toArrayWithUnion:options.authParams];
        // When GET, use query string params
        urlComponents.queryItems = @[];
        urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObjectsFromArray:unitedParams];
    }
    
    return urlComponents.URL;
}

- (NSMutableURLRequest *)buildRequest:(ARTAuthOptions *)options withParams:(ARTAuthTokenParams *)params {
    NSURL *url = [self buildURL:options withParams:params];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = options.authMethod;
    
    // HTTP Header Fields
    if ([options isMethodPOST]) {
        // TokenParams take precedence over any configured authParams when a name conflict occurs
        NSDictionary *unitedParams = [params toDictionaryWithUnion:options.authParams];
        // When POST, use body of the POST request
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:unitedParams options:0 error:nil];
        request.HTTPBody = bodyData;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", (unsigned int)bodyData.length] forHTTPHeaderField:@"Content-Length"];
    }
    else {
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    
    for (NSString *key in options.authHeaders) {
        [request setValue:options.authHeaders[key] forHTTPHeaderField:key];
    }
    
    return request;
}

- (void)requestToken:(ARTAuthTokenParams *)tokenParams withOptions:(ARTAuthOptions *)authOptions
            callback:(void (^)(ARTAuthTokenDetails *, NSError *))callback {
    
    // The values supersede matching client library configured params and options.
    ARTAuthOptions *mergedOptions = [self mergeOptions:authOptions];
    ARTAuthTokenParams *currentTokenParams = [self mergeParams:tokenParams];
    
    if (mergedOptions.authUrl) {
        NSMutableURLRequest *request = [self buildRequest:mergedOptions withParams:currentTokenParams];
        
        [_rest.logger debug:@"%@ %@", request.HTTPMethod, request.URL];
        
        [_rest.httpExecutor executeRequest:request callback:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                callback(nil, error);
            } else {
                // The token retrieved is assumed by the library to be a token string if the response has Content-Type "text/plain", or taken to be a TokenRequest or TokenDetails object if the response has Content-Type "application/json".

                // TODO
                NSAssert(false, @"Token string or TokenDetails object not implemented");
            }
        }];
    } else {
        ARTAuthCallback tokenRequestFactory = mergedOptions.authCallback? : ^(ARTAuthTokenParams *tokenParams, void(^callback)(ARTAuthTokenRequest *tokenRequest, NSError *error)) {
            [self createTokenRequest:currentTokenParams options:mergedOptions callback:callback];
        };
        
        tokenRequestFactory(currentTokenParams, ^(ARTAuthTokenRequest *tokenRequest, NSError *error) {
            if (error) {
                callback(nil, error);
            } else {
                [self requestToken:tokenRequest callback:callback];
            }
        });
    }
}

// FIXME: need revision
- (void)requestToken:(ARTAuthTokenRequest *)tokenRequest callback:(void (^)(ARTAuthTokenDetails *, NSError *))callback {
    NSURL *requestUrl = [NSURL URLWithString:[NSString stringWithFormat:@"/keys/%@/requestToken", tokenRequest.keyName]
                               relativeToURL:_rest.baseUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"POST";
    
    id<ARTEncoder> defaultEncoder = _rest.defaultEncoder;

    request.HTTPBody = [defaultEncoder encodeTokenRequest:tokenRequest];
    [request setValue:[defaultEncoder mimeType] forHTTPHeaderField:@"Accept"];
    [request setValue:[defaultEncoder mimeType] forHTTPHeaderField:@"Content-Type"];
    
    [_rest.httpExecutor executeRequest:request callback:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            callback([defaultEncoder decodeAccessToken:data], nil);
        }
    }];
}

- (void)authorise:(ARTAuthTokenParams *)tokenParams options:(ARTAuthOptions *)options force:(BOOL)force
         callback:(void (^)(ARTAuthTokenDetails *, NSError *))callback {
    if (!force && self.currentToken && [self.currentToken.expires timeIntervalSinceNow] > 0) {
        [self.logger verbose:@"ARTAuth authorise not forced and current token is not expired yet, reuse current token."];
        callback(self.currentToken, nil);
    } else {
        [self.logger verbose:@"ARTAuth authorise requesting new token."];
        [self requestToken:tokenParams withOptions:options callback:^(ARTAuthTokenDetails *tokenDetails, NSError *error) {
            if (error) {
                callback(nil, error);
            } else {
                _currentToken = tokenDetails;
                _authMethod = ARTAuthMethodToken;
                callback(tokenDetails, nil);
            }
        }];
    }
}

- (void)createTokenRequest:(ARTAuthTokenParams *)tokenParams options:(ARTAuthOptions *)options callback:(void (^)(ARTAuthTokenRequest *, NSError *))callback {
    ARTAuthOptions *mergedOptions = options;
    if (mergedOptions.queryTime) {
        ARTAuthTokenParams *newParams = [[ARTAuthTokenParams alloc] init];
        newParams.ttl = tokenParams.ttl;
        newParams.capability = tokenParams.capability;
        newParams.clientId = tokenParams.clientId;
        [_rest time:^(NSDate *time, NSError *error) {
            if (error) {
                callback(nil, error);
            } else {
                newParams.timestamp = time;
                callback([newParams sign:mergedOptions.key], nil);
            }
        }];
    } else {
        callback([tokenParams sign:mergedOptions.key], nil);
    }
}

- (BOOL)canRequestToken {
    if (self.options.authCallback) {
        [self.logger verbose:@"ARTAuth can request token via authCallback"];
        return YES;
    } else if (self.options.authUrl) {
        [self.logger verbose:@"ARTAuth can request token via authURL"];
        return YES;
    } else if (self.options.key) {
        [self.logger verbose:@"ARTAuth can request token via key"];
        return YES;
    } else {
        [self.logger error:@"ARTAuth cannot request token"];
        return NO;
    }
}

@end
