//
//  ARTAuth.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTAuth+Private.h"

#import "ARTRest.h"
#import "ARTRest+Private.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"
#import "ARTAuthOptions.h"
#import "ARTTokenDetails.h"
#import "ARTTokenParams+Private.h"
#import "ARTTokenRequest.h"
#import "ARTEncoder.h"
#import "ARTStatus.h"

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
        
        [self validate:options];
    }
    
    return self;
}

- (void)validate:(ARTClientOptions *)options {
    [self.logger debug:__FILE__ line:__LINE__ message:@"validating %@", options];
    if ([options isBasicAuth]) {
        if (!options.tls) {
            [NSException raise:@"ARTAuthException" format:@"Basic authentication only connects over HTTPS (tls)."];
        }
        // Basic
        [self.logger debug:__FILE__ line:__LINE__ message:@"setting up auth method Basic (anonymous)"];
        _method = ARTAuthMethodBasic;
    } else if (options.tokenDetails) {
        // TokenDetails
        [self.logger debug:__FILE__ line:__LINE__ message:@"setting up auth method Token with token details"];
        _method = ARTAuthMethodToken;
    } else if (options.token) {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"setting up auth method Token with supplied token only"];
        _method = ARTAuthMethodToken;
        options.tokenDetails = [[ARTTokenDetails alloc] initWithToken:options.token];
    } else if (options.authUrl && options.authCallback) {
        [NSException raise:@"ARTAuthException" format:@"Incompatible authentication configuration: please specify either authCallback and authUrl."];
    } else if (options.authUrl) {
        // Authentication url
        [self.logger debug:__FILE__ line:__LINE__ message:@"setting up auth method Token with authUrl"];
        _method = ARTAuthMethodToken;
    } else if (options.authCallback) {
        // Authentication callback
        [self.logger debug:__FILE__ line:__LINE__ message:@"setting up auth method Token with authCallback"];
        _method = ARTAuthMethodToken;
    } else if (options.key) {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"setting up auth method Token with key"];
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
    self.options.queryTime = customOptions.queryTime;
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
    
    return urlComponents.URL;
}

- (NSMutableURLRequest *)buildRequest:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params {
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

- (void)requestToken:(ARTTokenParams *)tokenParams withOptions:(ARTAuthOptions *)authOptions
            callback:(void (^)(ARTTokenDetails *, NSError *))callback {
    
    // The values supersede matching client library configured params and options.
    ARTAuthOptions *mergedOptions = [self mergeOptions:authOptions];
    ARTTokenParams *currentTokenParams = [self mergeParams:tokenParams];
    tokenParams.timestamp = [NSDate date];

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

    if (mergedOptions.authUrl) {
        NSMutableURLRequest *request = [self buildRequest:mergedOptions withParams:currentTokenParams];
        
        [self.logger debug:__FILE__ line:__LINE__ message:@"using authUrl (%@ %@)", request.HTTPMethod, request.URL];
        
        [_rest executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                checkerCallback(nil, error);
            } else {
                [self.logger debug:@"ARTAuth: authUrl response %@", response];
                [self handleAuthUrlResponse:response withData:data completion:checkerCallback];
            }
        }];
    } else {
        void (^tokenDetailsFactory)(ARTTokenParams *, void(^)(ARTTokenDetails *__art_nullable, NSError *__art_nullable));
        if (mergedOptions.authCallback) {
            tokenDetailsFactory = ^(ARTTokenParams *tokenParams, void(^callback)(ARTTokenDetails *__art_nullable, NSError *__art_nullable)) {
                mergedOptions.authCallback(tokenParams, ^(id<ARTTokenDetailsCompatible> tokenDetailsCompat, NSError *error) {
                    [tokenDetailsCompat toTokenDetails:self callback:callback];
                });
            };
            [self.logger debug:@"ARTAuth: using authCallback"];
        } else {
            tokenDetailsFactory = ^(ARTTokenParams *tokenParams, void(^callback)(ARTTokenDetails *__art_nullable, NSError *__art_nullable)) {
                // Create a TokenRequest and execute it
                [self createTokenRequest:currentTokenParams options:mergedOptions callback:^(ARTTokenRequest *tokenRequest, NSError *error) {
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
        ARTTokenDetails *tokenDetails = [_rest.defaultEncoder decodeAccessToken:data error:&decodeError];
        if (decodeError) {
            callback(nil, decodeError);
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
    NSURL *requestUrl = [NSURL URLWithString:[NSString stringWithFormat:@"/keys/%@/requestToken", tokenRequest.keyName]
                               relativeToURL:_rest.baseUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"POST";
    
    id<ARTEncoder> defaultEncoder = _rest.defaultEncoder;

    request.HTTPBody = [defaultEncoder encodeTokenRequest:tokenRequest];
    [request setValue:[defaultEncoder mimeType] forHTTPHeaderField:@"Accept"];
    [request setValue:[defaultEncoder mimeType] forHTTPHeaderField:@"Content-Type"];
    
    [_rest executeRequest:request withAuthOption:ARTAuthenticationUseBasic completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            NSError *decodeError = nil;
            ARTTokenDetails *tokenDetails = [defaultEncoder decodeAccessToken:data error:&decodeError];
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
    ARTAuthOptions *mergedOptions = [self mergeOptions:authOptions];
    [self storeOptions:mergedOptions];
    ARTTokenParams *currentTokenParams = [self mergeParams:tokenParams];
    [self storeParams:currentTokenParams];

    // Reuse or not reuse the current token
    if (mergedOptions.force == NO && self.tokenDetails) {
        if (self.tokenDetails.expires == nil) {
            [self.logger verbose:@"ARTAuth: reuse current token."];
            requestNewToken = NO;
        }
        else if ([self.tokenDetails.expires timeIntervalSinceNow] > 0) {
            [self.logger verbose:@"ARTAuth: current token has not expired yet. Reusing token details."];
            requestNewToken = NO;
        }
        else {
            [self.logger verbose:@"ARTAuth: current token has expired. Requesting new token."];
            requestNewToken = YES;
        }
    }
    else {
        if (mergedOptions.force == YES)
            [self.logger verbose:@"ARTAuth: forced requesting new token."];
        else
            [self.logger verbose:@"ARTAuth: requesting new token."];
        requestNewToken = YES;
    }

    if (requestNewToken) {
        [self requestToken:currentTokenParams withOptions:mergedOptions callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
            if (error) {
                if (callback) {
                    callback(nil, error);
                }
            } else {
                _tokenDetails = tokenDetails;
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
    ARTAuthOptions *mergedOptions = [self mergeOptions:options];
    ARTTokenParams *mergedTokenParams = [self mergeParams:tokenParams];

    // Validate: Capability JSON text
    NSError *errorCapability;
    [NSJSONSerialization JSONObjectWithData:[mergedTokenParams.capability dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&errorCapability];

    if (errorCapability) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Capability: %@", errorCapability.localizedDescription] };
        callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:errorCapability.code userInfo:userInfo]);
        return;
    }

    if (mergedOptions.queryTime) {
        [_rest time:^(NSDate *time, NSError *error) {
            if (error) {
                callback(nil, error);
            } else {
                mergedTokenParams.timestamp = time;
                callback([mergedTokenParams sign:mergedOptions.key], nil);
            }
        }];
    } else {
        callback([mergedTokenParams sign:mergedOptions.key], nil);
    }
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

@end

@implementation NSString (ARTTokenDetailsCompatible)

- (void)toTokenDetails:(ARTAuth *)auth callback:(void (^)(ARTTokenDetails * _Nullable, NSError * _Nullable))callback {
    callback([[ARTTokenDetails alloc] initWithToken:self], nil);
}

@end
