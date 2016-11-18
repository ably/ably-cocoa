//
//  ARTAuth.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTAuth+Private.h"

#ifdef TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "ARTRest+Private.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"
#import "ARTAuthOptions.h"
#import "ARTTokenDetails.h"
#import "ARTTokenParams+Private.h"
#import "ARTTokenRequest.h"
#import "ARTEncoder.h"
#import "ARTStatus.h"
#import "ARTJsonEncoder.h"
#import "ARTGCD.h"

@implementation ARTAuth {
    __weak ARTRest *_rest;
    ARTTokenParams *_tokenParams;
    // Dedicated to Protocol Message
    NSString *_protocolClientId;
}

- (instancetype)init:(ARTRest *)rest withOptions:(ARTClientOptions *)options {
    if (self = [super init]) {
        _rest = rest;
        _tokenDetails = options.tokenDetails;
        _options = options;
        _logger = rest.logger;
        _protocolClientId = nil;
        _tokenParams = options.defaultTokenParams ? : [[ARTTokenParams alloc] initWithOptions:self.options];
        [self validate:options];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveCurrentLocaleDidChangeNotification:)
                                                     name:NSCurrentLocaleDidChangeNotification
                                                   object:nil];

        #ifdef TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveApplicationSignificantTimeChangeNotification:)
                                                     name:UIApplicationSignificantTimeChangeNotification
                                                   object:nil];
        #endif
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSCurrentLocaleDidChangeNotification object:nil];
    #ifdef TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
    #endif
}

- (void)didReceiveCurrentLocaleDidChangeNotification:(NSNotification *)notification {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p NSCurrentLocaleDidChangeNotification received", _rest];
    [self discardTimeOffset];
}

- (void)didReceiveApplicationSignificantTimeChangeNotification:(NSNotification *)notification {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p UIApplicationSignificantTimeChangeNotification received", _rest];
    [self discardTimeOffset];
}

- (void)validate:(ARTClientOptions *)options {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p validating %@", _rest, options];
    if ([options isBasicAuth]) {
        if (!options.tls) {
            [NSException raise:@"ARTAuthException" format:@"Basic authentication only connects over HTTPS (tls)."];
        }
        // Basic
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Basic (anonymous)", _rest];
        _method = ARTAuthMethodBasic;
    } else if (options.tokenDetails) {
        // TokenDetails
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with token details", _rest];
        _method = ARTAuthMethodToken;
    } else if (options.token) {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with supplied token only", _rest];
        _method = ARTAuthMethodToken;
        options.tokenDetails = [[ARTTokenDetails alloc] initWithToken:options.token];
    } else if (options.authUrl && options.authCallback) {
        [NSException raise:@"ARTAuthException" format:@"Incompatible authentication configuration: please specify either authCallback and authUrl."];
    } else if (options.authUrl) {
        // Authentication url
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with authUrl", _rest];
        _method = ARTAuthMethodToken;
    } else if (options.authCallback) {
        // Authentication callback
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with authCallback", _rest];
        _method = ARTAuthMethodToken;
    } else if (options.key) {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with key", _rest];
        _method = ARTAuthMethodToken;
    } else {
        [NSException raise:@"ARTAuthException" format:@"Could not setup authentication method with given options."];
    }
    
    if ([options.clientId isEqual:@"*"]) {
        [NSException raise:@"ARTAuthException" format:@"Invalid clientId: cannot contain only a wilcard \"*\"."];
    }
}

- (ARTAuthOptions *)mergeOptions:(ARTAuthOptions *)customOptions {
    return customOptions ? [self.options mergeWith:customOptions] : self.options;
}

- (void)storeOptions:(ARTAuthOptions *)customOptions {
    self.options.key = customOptions.key;
    self.options.tokenDetails = [customOptions.tokenDetails copy];
    self.options.authCallback = [customOptions.authCallback copy];
    self.options.authUrl = [customOptions.authUrl copy];
    self.options.authHeaders = [customOptions.authHeaders copy];
    self.options.authMethod = customOptions.authMethod;
    self.options.authParams = [customOptions.authParams copy];
    self.options.useTokenAuth = customOptions.useTokenAuth;
    self.options.queryTime = false;
    self.options.force = false;
}

- (ARTTokenParams *)mergeParams:(ARTTokenParams *)customParams {
    return customParams ? customParams : [[ARTTokenParams alloc] initWithOptions:self.options];
}

- (void)storeParams:(ARTTokenParams *)customOptions {
    _options.clientId = customOptions.clientId;
    _options.defaultTokenParams = customOptions;
}

- (NSURL *)buildURL:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:options.authUrl resolvingAgainstBaseURL:YES];
    
    if ([options isMethodGET]) {
        // TokenParams take precedence over any configured authParams when a name conflict occurs
        NSArray *unitedParams = [params toArrayWithUnion:options.authParams];
        // When GET, use query string params
        if (!urlComponents.queryItems) urlComponents.queryItems = @[];
        urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObjectsFromArray:unitedParams];
    }

    urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObjectsFromArray:@[[NSURLQueryItem queryItemWithName:@"format" value:[_rest.defaultEncoder formatAsString]]]];
    
    return urlComponents.URL;
}

- (NSMutableURLRequest *)buildRequest:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params {
    if (!params.timestamp) params.timestamp = [self currentDate];
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
        [request setValue:[_rest.defaultEncoder mimeType] forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", (unsigned int)bodyData.length] forHTTPHeaderField:@"Content-Length"];
    }
    else {
        [request setValue:[_rest.defaultEncoder mimeType] forHTTPHeaderField:@"Accept"];
    }
    
    for (NSString *key in options.authHeaders) {
        [request setValue:options.authHeaders[key] forHTTPHeaderField:key];
    }
    
    return request;
}

- (void)requestToken:(ARTTokenParams *)tokenParams withOptions:(ARTAuthOptions *)authOptions
            callback:(void (^)(ARTTokenDetails *, NSError *))callback {
    
    // The values replace all corresponding.
    ARTAuthOptions *replacedOptions = authOptions ? authOptions : self.options;
    ARTTokenParams *currentTokenParams = tokenParams ? tokenParams : _tokenParams;
    currentTokenParams.timestamp = [self currentDate];

    if (replacedOptions.key == nil && replacedOptions.authCallback == nil && replacedOptions.authUrl == nil) {
        callback(nil, [ARTErrorInfo createWithCode:ARTStateRequestTokenFailed message:@"no means to renew the token is provided (either an API key, authCallback or authUrl)"]);
        return;
    }

    void (^checkerCallback)(ARTTokenDetails *__art_nullable, NSError *__art_nullable) = ^(ARTTokenDetails *tokenDetails, NSError *error) {
        if (error) {
            callback(nil, error);
            return;
        }
        if (self.clientId && tokenDetails.clientId && ![tokenDetails.clientId isEqualToString:@"*"] && ![self.clientId isEqual:tokenDetails.clientId]) {
            if (callback) callback(nil, [ARTErrorInfo createWithCode:40102 message:@"incompatible credentials"]);
            return;
        }
        callback(tokenDetails, nil);
    };

    if (replacedOptions.authUrl) {
        NSMutableURLRequest *request = [self buildRequest:replacedOptions withParams:currentTokenParams];
        
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p using authUrl (%@ %@)", _rest, request.HTTPMethod, request.URL];
        
        [_rest executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                checkerCallback(nil, error);
            } else {
                [self.logger debug:@"RS:%p ARTAuth: authUrl response %@", _rest, response];
                [self handleAuthUrlResponse:response withData:data completion:checkerCallback];
            }
        }];
    } else {
        void (^tokenDetailsFactory)(ARTTokenParams *, void(^)(ARTTokenDetails *__art_nullable, NSError *__art_nullable));
        if (replacedOptions.authCallback) {
            tokenDetailsFactory = ^(ARTTokenParams *tokenParams, void(^callback)(ARTTokenDetails *__art_nullable, NSError *__art_nullable)) {
                replacedOptions.authCallback(tokenParams, ^(id<ARTTokenDetailsCompatible> tokenDetailsCompat, NSError *error) {
                    artDispatchMainQueue(^{
                        if (error) {
                            callback(nil, error);
                        } else {
                            [tokenDetailsCompat toTokenDetails:self callback:callback];
                        }
                    });
                });
            };
            [self.logger debug:@"RS:%p ARTAuth: using authCallback", _rest];
        } else {
            tokenDetailsFactory = ^(ARTTokenParams *tokenParams, void(^callback)(ARTTokenDetails *__art_nullable, NSError *__art_nullable)) {
                // Create a TokenRequest and execute it
                [self createTokenRequest:currentTokenParams options:replacedOptions callback:^(ARTTokenRequest *tokenRequest, NSError *error) {
                    if (error) {
                        callback(nil, error);
                    } else {
                        [self executeTokenRequest:tokenRequest callback:callback];
                    }
                }];
            };
        };

        tokenDetailsFactory(currentTokenParams, checkerCallback);
    }
}

- (void)handleAuthUrlResponse:(NSHTTPURLResponse *)response withData:(NSData *)data completion:(void (^)(ARTTokenDetails *, NSError *))callback {
    // The token retrieved is assumed by the library to be a token string if the response has Content-Type "text/plain", or taken to be a TokenRequest or TokenDetails object if the response has Content-Type "application/json"
    if ([response.MIMEType isEqualToString:@"application/json"]) {
        NSError *decodeError = nil;
        ARTTokenDetails *tokenDetails = [_rest.encoders[@"application/json"] decodeTokenDetails:data error:&decodeError];
        if (decodeError) {
            callback(nil, decodeError);
        } else if (tokenDetails.token == nil) {
            ARTTokenRequest *tokenRequest = [_rest.encoders[@"application/json"] decodeTokenRequest:data error:&decodeError];
            if (decodeError) {
                callback(nil, decodeError);
            } else if (tokenRequest) {
                [tokenRequest toTokenDetails:self callback:callback];
            } else {
                callback(nil, [ARTErrorInfo createWithCode:ARTStateAuthUrlIncompatibleContent message:@"content response cannot be used for token request"]);
            }
        } else {
            callback(tokenDetails, nil);
        }
    }
    else if ([response.MIMEType isEqualToString:@"text/plain"]) {
        NSString *token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([token isEqualToString:@""]) {
            callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:@"authUrl: token is empty"}]);
            return;
        }
        ARTTokenDetails *tokenDetails = [[ARTTokenDetails alloc] initWithToken:token];
        callback(tokenDetails, nil);
    }
    else {
        callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:@"authUrl: invalid MIME type"}]);
    }
}

- (void)executeTokenRequest:(ARTTokenRequest *)tokenRequest callback:(void (^)(ARTTokenDetails *, NSError *))callback {
    id<ARTEncoder> encoder = _rest.defaultEncoder;

    NSURL *requestUrl = [NSURL URLWithString:[NSString stringWithFormat:@"/keys/%@/requestToken?format=%@", tokenRequest.keyName, [encoder formatAsString]]
                               relativeToURL:_rest.baseUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"POST";
    
    request.HTTPBody = [encoder encodeTokenRequest:tokenRequest];
    [request setValue:[encoder mimeType] forHTTPHeaderField:@"Accept"];
    [request setValue:[encoder mimeType] forHTTPHeaderField:@"Content-Type"];
    
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            NSError *decodeError = nil;
            ARTTokenDetails *tokenDetails = [encoder decodeTokenDetails:data error:&decodeError];
            if (decodeError) {
                callback(nil, decodeError);
            } else {
                callback(tokenDetails, nil);
            }
        }
    }];
}

- (void)authorise:(ARTTokenParams *)tokenParams options:(ARTAuthOptions *)authOptions callback:(void (^)(ARTTokenDetails *, NSError *))callback {
    BOOL requestNewToken = NO;

    ARTAuthOptions *replacedOptions;
    if ([authOptions isOnlyForceTrue]) {
        replacedOptions = [self.options copy];
        replacedOptions.force = YES;
    }
    else {
        replacedOptions = [authOptions copy] ? : [self.options copy];
    }
    [self storeOptions:replacedOptions];

    ARTTokenParams *currentTokenParams = [self mergeParams:tokenParams];
    [self storeParams:currentTokenParams];

    // Reuse or not reuse the current token
    if (replacedOptions.force == NO && self.tokenDetails) {
        if (self.tokenDetails.expires == nil) {
            [self.logger verbose:@"RS:%p ARTAuth: reuse current token.", _rest];
            requestNewToken = NO;
        }
        else if ([self.tokenDetails.expires timeIntervalSinceDate:[self currentDate]] > 0) {
            [self.logger verbose:@"RS:%p ARTAuth: current token has not expired yet. Reusing token details.", _rest];
            requestNewToken = NO;
        }
        else {
            [self.logger verbose:@"RS:%p ARTAuth: current token has expired. Requesting new token.", _rest];
            requestNewToken = YES;
        }
    }
    else {
        if (replacedOptions.force == YES)
            [self.logger verbose:@"RS:%p ARTAuth: forced requesting new token.", _rest];
        else
            [self.logger verbose:@"RS:%p ARTAuth: requesting new token.", _rest];
        requestNewToken = YES;
    }

    if (requestNewToken) {
        [self requestToken:currentTokenParams withOptions:replacedOptions callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
            if (error) {
                [self.logger verbose:@"RS:%p ARTAuth: token request failed: %@", _rest, error];
                if (callback) {
                    callback(nil, error);
                }
            } else {
                _tokenDetails = tokenDetails;
                [self.logger verbose:@"RS:%p ARTAuth: token request succeeded: %@", _rest, tokenDetails];
                if (callback) {
                    callback(self.tokenDetails, nil);
                }
            }
        }];
    } else {
        if (callback) {
            callback(self.tokenDetails, nil);
        }
    }
}

- (void)createTokenRequest:(ARTTokenParams *)tokenParams options:(ARTAuthOptions *)options callback:(void (^)(ARTTokenRequest *, NSError *))callback {
    ARTAuthOptions *replacedOptions = options ? : self.options;
    ARTTokenParams *currentTokenParams = tokenParams ? : _tokenParams;
    currentTokenParams.timestamp = [self currentDate];

    // Validate: Capability JSON text
    NSError *errorCapability;
    [NSJSONSerialization JSONObjectWithData:[currentTokenParams.capability dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&errorCapability];

    if (errorCapability) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Capability: %@", errorCapability.localizedDescription] };
        callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:errorCapability.code userInfo:userInfo]);
        return;
    }
    
    if (replacedOptions.key == nil) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"no key provided for signing token requests" };
        callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:0 userInfo:userInfo]);
        return;
    }

    if (_timeOffset && !replacedOptions.queryTime) {
        currentTokenParams.timestamp = [self currentDate];
        callback([currentTokenParams sign:replacedOptions.key], nil);
    }
    else {
        if (replacedOptions.queryTime) {
            [_rest time:^(NSDate *time, NSError *error) {
                if (error) {
                    callback(nil, error);
                } else {
                    NSDate *serverTime = [self handleServerTime:time];
                    _timeOffset = [serverTime timeIntervalSinceNow];
                    currentTokenParams.timestamp = serverTime;
                    callback([currentTokenParams sign:replacedOptions.key], nil);
                }
            }];
        } else {
            callback([currentTokenParams sign:replacedOptions.key], nil);
        }
    }
}

- (NSDate *)handleServerTime:(NSDate *)time {
    return time;
}

- (void)setProtocolClientId:(NSString *)clientId {
    _protocolClientId = clientId;
}

- (NSString *)getClientId {
    if (_protocolClientId) {
       return _protocolClientId;
    }
    else if (self.tokenDetails && self.tokenDetails.clientId) {
        return self.tokenDetails.clientId;
    }
    if (self.options) {
        return self.options.clientId;
    }
    else {
        return nil;
    }
}

- (NSDate*)currentDate {
    return [[NSDate date] dateByAddingTimeInterval:_timeOffset];
}

- (void)discardTimeOffset {
    _timeOffset = 0;
}

- (void)setTokenDetails:(ARTTokenDetails *)tokenDetails {
    _tokenDetails = tokenDetails;
}

- (void)setTimeOffset:(NSTimeInterval)offset {
    _timeOffset = offset;
}

@end

@implementation NSString (ARTTokenDetailsCompatible)

- (void)toTokenDetails:(ARTAuth *)auth callback:(void (^)(ARTTokenDetails * _Nullable, NSError * _Nullable))callback {
    callback([[ARTTokenDetails alloc] initWithToken:self], nil);
}

@end
