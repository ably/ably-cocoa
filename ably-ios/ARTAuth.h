//
//  ARTAuth.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTHttp.h"
#import "ARTTypes.h"

@class ARTRest;

@interface ARTAuthToken : NSObject

@property (readonly, strong, nonatomic) NSString *idB64;
@property (readonly, assign, nonatomic) int64_t expires;
@property (readonly, assign, nonatomic) int64_t issuedAt;
@property (readonly, strong, nonatomic) NSString *capability;
@property (readonly, strong, nonatomic) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithId:(NSString *)id expires:(int64_t)expires issuedAt:(int64_t)issuedAt capability:(NSString *)capability clientId:(NSString *)clientId;

+ (instancetype)authTokenWithId:(NSString *)id expires:(int64_t)expires issuedAt:(int64_t)issuedAt capability:(NSString *)capability clientId:(NSString *)clientId;

@end

@interface ARTAuthTokenParams : NSObject

@property (readonly, strong, nonatomic) NSString *keyName;
@property (readonly, assign, nonatomic) int64_t ttl;
@property (readonly, strong, nonatomic) NSString *capability;
@property (readonly, strong, nonatomic) NSString *clientId;
@property (readonly, assign, nonatomic) int64_t timestamp;
@property (readonly, strong, nonatomic) NSString *nonce;
@property (readonly, strong, nonatomic) NSString *mac;


- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithId:(NSString *)id ttl:(int64_t)ttl capability:(NSString *)capability clientId:(NSString *)clientId timestamp:(int64_t)timestamp nonce:(NSString *)nonce mac:(NSString *)mac;

+ (instancetype)authTokenParamsWithId:(NSString *)id ttl:(int64_t)ttl capability:(NSString *)capability clientId:(NSString *)clientId timestamp:(int64_t)timestamp nonce:(NSString *)nonce mac:(NSString *)mac;

-(NSDictionary *) asDictionary;
@end

typedef id<ARTCancellable>(^ARTAuthCb)(void(^continuation)(ARTAuthToken *));
typedef id<ARTCancellable>(^ARTSignedTokenRequestCb)(ARTAuthTokenParams *, void(^continuation)(ARTAuthTokenParams *));
typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};

@interface ARTAuthOptions : NSObject

@property (readwrite, strong, nonatomic) ARTAuthCb authCallback;
@property (readwrite, strong, nonatomic) ARTSignedTokenRequestCb signedTokenRequestCallback;
@property (readwrite, strong, nonatomic) NSURL *authUrl;
@property (readwrite, strong, nonatomic) NSString *keyId;
@property (readwrite, strong, nonatomic) NSString *keyValue;
@property (readwrite, strong, nonatomic) NSString *authToken;
@property (readwrite, strong, nonatomic) NSString *capability;
@property (readwrite, strong, nonatomic) NSDictionary *authHeaders;
@property (readwrite, strong, nonatomic) NSString *clientId;
@property (readwrite, assign, nonatomic) BOOL queryTime;
@property (readwrite, assign, nonatomic) BOOL useTokenAuth;


- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key;

+ (instancetype)options;
+ (instancetype)optionsWithKey:(NSString *)key;

- (instancetype)clone;

@end

@interface ARTAuth : NSObject

- (instancetype)initWithRest:(ARTRest *)rest options:(ARTAuthOptions *)options;


- (ARTAuthMethod) getAuthMethod;
- (id<ARTCancellable>)authHeadersUseBasic:(BOOL)useBasic cb:(id<ARTCancellable>(^)(NSDictionary *))cb;
- (id<ARTCancellable>)authParams:(id<ARTCancellable>(^)(NSDictionary *))cb;
- (id<ARTCancellable>)authToken:(id<ARTCancellable>(^)(ARTAuthToken *))cb;
- (id<ARTCancellable>)authTokenForceReauth:(BOOL)force cb:(id<ARTCancellable>(^)(ARTAuthToken *))cb;


@end