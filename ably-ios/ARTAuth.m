//
//  ARTAuth.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTAuth.h"

#import "ARTRest.h"
#import "ARTRest+Private.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"
#import "ARTAuthOptions.h"
#import "ARTAuthTokenDetails.h"
#import "ARTAuthTokenParams.h"
#import "ARTAuthTokenRequest.h"
#import "ARTEncoder.h"

@implementation ARTAuth {
    __weak ARTRest *_rest;
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
    if ([options isBasicAuth]) {
        if (!options.tls) {
            [NSException raise:@"ARTAuthException" format:@"Basic authentication only connects over HTTPS (tls)."];
        }
        // Basic
        [self.logger debug:@"ARTAuth: setting up auth method Basic (anonymous)"];
        _method = ARTAuthMethodBasic;
    } else if (options.tokenDetails) {
        // TokenDetails
        [self.logger debug:@"ARTAuth: setting up auth method Token with token details"];
        _method = ARTAuthMethodToken;
    } else if (options.token) {
        // Token
        [self.logger debug:@"ARTAuth: setting up auth method Token with supplied token only"];
        _method = ARTAuthMethodToken;
        options.tokenDetails = [[ARTAuthTokenDetails alloc] initWithToken:options.token];
    } else if (options.authUrl && options.authCallback) {
        [NSException raise:@"ARTAuthException" format:@"Incompatible authentication configuration: please specify either authCallback and authUrl."];
    } else if (options.authUrl) {
        // Authentication url
        [self.logger debug:@"ARTAuth: setting up auth method Token with authUrl"];
        _method = ARTAuthMethodToken;
    } else if (options.authCallback) {
        // Authentication callback
        [self.logger debug:@"ARTAuth: setting up auth method Token with authCallback"];
        _method = ARTAuthMethodToken;
    } else if (options.key) {
        // Token
        [self.logger debug:@"ARTAuth: setting up auth method Token with key"];
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

- (ARTAuthTokenParams *)mergeParams:(ARTAuthTokenParams *)customParams {
    return customParams ? customParams : [[ARTAuthTokenParams alloc] initWithClientId:self.options.clientId];
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
        
        [_rest executeRequest:request withAuthOption:ARTAuthenticationUseBasic completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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
                [self executeTokenRequest:tokenRequest callback:callback];
            }
        });
    }
}

- (void)executeTokenRequest:(ARTAuthTokenRequest *)tokenRequest callback:(void (^)(ARTAuthTokenDetails *, NSError *))callback {
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
            ARTAuthTokenDetails *tokenDetails = [defaultEncoder decodeAccessToken:data error:&decodeError];
            if (decodeError) {
                callback(nil, decodeError);
            } else {
                callback(tokenDetails, nil);
            }
        }
    }];
}

- (void)authorise:(ARTAuthTokenParams *)tokenParams options:(ARTAuthOptions *)options force:(BOOL)force callback:(void (^)(ARTAuthTokenDetails *, NSError *))callback {
    BOOL requestNewToken = NO;

    // Reuse or not reuse the current token
    if (!force && self.tokenDetails) {
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
        if (force)
            [self.logger verbose:@"ARTAuth: forced requesting new token."];
        else
            [self.logger verbose:@"ARTAuth: requesting new token."];
        requestNewToken = YES;
    }

    if (requestNewToken) {
        [self requestToken:tokenParams withOptions:options callback:^(ARTAuthTokenDetails *tokenDetails, NSError *error) {
            if (error) {
                if (callback) {
                    callback(nil, error);
                }
            } else {
                _tokenDetails = tokenDetails;
                if (callback) {
                    callback(tokenDetails, nil);
                }
            }
        }];
    } else {
        if (callback) {
            callback(self.tokenDetails, nil);
        }
    }
}

- (void)createTokenRequest:(ARTAuthTokenParams *)tokenParams options:(ARTAuthOptions *)options callback:(void (^)(ARTAuthTokenRequest *, NSError *))callback {
    ARTAuthOptions *mergedOptions = options;
    // FIXME: review
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

- (void)setProtocolClientId:(NSString *)clientId {
    _protocolClientId = clientId;
}

- (NSString *)getClientId {
    if (_protocolClientId) {
        // Check wildcard
        if ([_protocolClientId isEqual:@"*"])
            // Any client
            return nil;
        else
            return _protocolClientId;
    }
    else if (self.tokenDetails) {
        // Check wildcard
        if ([self.tokenDetails.clientId isEqual:@"*"])
            // Any client
            return nil;
        else
            return self.tokenDetails.clientId;
    }
    else if (self.options) {
        return self.options.clientId;
    }
    else {
        return nil;
    }
}

@end
