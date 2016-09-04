//
//  ARTAuthOptions.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTAuthOptions+Private.h"
#import "ARTTokenDetails.h"
#import "ARTClientOptions.h"

@implementation ARTAuthOptions

NSString *const ARTAuthOptionsMethodDefault = @"GET";

- (instancetype)init {
    self = [super init];
    if (self) {
        return [self initDefaults];
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        if (key != nil && decomposeKey(key).count != 2) {
            [NSException raise:@"Invalid key" format:@"%@ should be of the form <keyName>:<keySecret>", key];
        }
        else if (key != nil) {
            _key = [key copy];            
        }
        return [self initDefaults];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)token {
    self = [super init];
    if (self) {
        [self setToken:token];
        return [self initDefaults];
    }
    return self;
}

- (instancetype)initWithTokenDetails:(ARTTokenDetails *)tokenDetails {
    self = [super init];
    if (self) {
        _tokenDetails = tokenDetails;
        return [self initDefaults];
    }
    return self;
}

- (instancetype)initDefaults {
    _authMethod = ARTAuthOptionsMethodDefault;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTAuthOptions *options = [[[self class] allocWithZone:zone] init];
    
    options.key = self.key;
    options.token = self.token;
    options.authCallback = self.authCallback;
    options.authUrl = self.authUrl;
    options.authMethod = self.authMethod;
    options.authHeaders = self.authHeaders;
    options.authParams = self.authParams;
    options.queryTime = self.queryTime;
    options.useTokenAuth = self.useTokenAuth;
    options.force = self.force;

    return options;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@: key=%@ token=%@ authUrl=%@ authMethod=%@ hasAuthCallback=%d",
            NSStringFromClass([self class]), self.key, self.token, self.authUrl, self.authMethod, self.authCallback != nil];
}

- (NSString *)token {
    if (self.tokenDetails) {
        return self.tokenDetails.token;
    }
    return nil;
}

- (void)setToken:(NSString *)token {
    if (token && ![token isEqualToString:@""]) {
        self.tokenDetails = [[ARTTokenDetails alloc] initWithToken:token];
    }
}

- (void)setAuthMethod:(NSString *)authMethod {
    // HTTP Method
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
    if (precedenceOptions.useTokenAuth)
        merged.useTokenAuth = precedenceOptions.useTokenAuth;
    if (precedenceOptions.force)
        merged.force = precedenceOptions.force;
    
    return merged;
}

- (ARTAuthOptions *)replaceWith:(ARTAuthOptions *)options {
    ARTAuthOptions *replaced = [self copy];

    @synchronized (self) {
        if (options != nil) {
            if ([replaced isKindOfClass: [ARTClientOptions class]] && [options isKindOfClass: [ARTClientOptions class]]) {
                ((ARTClientOptions*)replaced).restHost = ((ARTClientOptions *)options).restHost;
                ((ARTClientOptions*)replaced).realtimeHost = ((ARTClientOptions *)options).realtimeHost;
                ((ARTClientOptions*)replaced).port = ((ARTClientOptions *)options).port;
                ((ARTClientOptions*)replaced).tlsPort = ((ARTClientOptions *)options).tlsPort;
                ((ARTClientOptions*)replaced).environment = ((ARTClientOptions *)options).environment;
                ((ARTClientOptions*)replaced).tls = ((ARTClientOptions *)options).tls;
                ((ARTClientOptions*)replaced).logHandler = ((ARTClientOptions *)options).logHandler;
                ((ARTClientOptions*)replaced).logLevel = ((ARTClientOptions *)options).logLevel;
                ((ARTClientOptions*)replaced).queueMessages = ((ARTClientOptions *)options).queueMessages;
                ((ARTClientOptions*)replaced).echoMessages = ((ARTClientOptions *)options).echoMessages;
                ((ARTClientOptions*)replaced).useBinaryProtocol = ((ARTClientOptions *)options).useBinaryProtocol;
                ((ARTClientOptions*)replaced).autoConnect = ((ARTClientOptions *)options).autoConnect;
                ((ARTClientOptions*)replaced).recover = ((ARTClientOptions *)options).recover;
                ((ARTClientOptions*)replaced).clientId = ((ARTClientOptions *)options).clientId;
                ((ARTClientOptions*)replaced).defaultTokenParams = ((ARTClientOptions *)options).defaultTokenParams;
                ((ARTClientOptions*)replaced).disconnectedRetryTimeout = ((ARTClientOptions *)options).disconnectedRetryTimeout;
                ((ARTClientOptions*)replaced).suspendedRetryTimeout = ((ARTClientOptions *)options).suspendedRetryTimeout;
                ((ARTClientOptions*)replaced).httpOpenTimeout = ((ARTClientOptions *)options).httpOpenTimeout;
                ((ARTClientOptions*)replaced).httpRequestTimeout = ((ARTClientOptions *)options).httpRequestTimeout;
                ((ARTClientOptions*)replaced).httpMaxRetryCount = ((ARTClientOptions *)options).httpMaxRetryCount;
                ((ARTClientOptions*)replaced).httpMaxRetryDuration = ((ARTClientOptions *)options).httpMaxRetryDuration;
            }
            else {
                replaced.key = options.key;
                replaced.token = options.token;
                replaced.tokenDetails = options.tokenDetails;
                replaced.authCallback = options.authCallback;
                replaced.authUrl = options.authUrl;
                replaced.force = options.force;
                replaced.authMethod = options.authMethod;
                replaced.authHeaders = options.authHeaders;
                replaced.authParams = options.authParams;
                replaced.queryTime = options.queryTime;
                replaced.useTokenAuth = options.useTokenAuth;
                replaced.force = options.force;
            }
        }
    }

    return replaced;
}

- (BOOL)isMethodPOST {
    return [_authMethod isEqualToString:@"POST"];
}

- (BOOL)isMethodGET {
    return [_authMethod isEqualToString:@"GET"];
}

@end
