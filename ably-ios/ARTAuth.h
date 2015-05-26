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


@interface ARTTokenDetails : NSObject

@property (readonly, strong, nonatomic) NSString *token;
@property (readonly, assign, nonatomic) int64_t expires;
@property (readonly, assign, nonatomic) int64_t issued;
@property (readonly, strong, nonatomic) NSString *capability;
@property (readonly, strong, nonatomic) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithId:(NSString *)id expires:(int64_t)expires issued:(int64_t)issued capability:(NSString *)capability clientId:(NSString *)clientId;

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

-(NSDictionary *) asDictionary;
@end

typedef id<ARTCancellable>(^ARTAuthCb)(void(^continuation)(ARTStatus *,ARTTokenDetails *));
typedef id<ARTCancellable>(^ARTSignedTokenRequestCb)(ARTAuthTokenParams *, void(^continuation)(ARTAuthTokenParams *));
typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};

@interface ARTAuthOptions : NSObject

@property (readwrite, strong, nonatomic) ARTAuthCb authCallback;
@property (readwrite, strong, nonatomic) ARTSignedTokenRequestCb signedTokenRequestCallback;
@property (readwrite, strong, nonatomic) NSURL *authUrl;
@property (readwrite, strong, nonatomic) NSString *keyName;
@property (readwrite, strong, nonatomic) NSString *keySecret;
@property (readwrite, strong, nonatomic) NSString *token;
@property (readwrite, strong, nonatomic) NSString *capability;
@property (readwrite, strong, nonatomic) NSString *nonce;
@property (readwrite, assign, nonatomic) int64_t ttl;
@property (readwrite, strong, nonatomic) NSDictionary *authHeaders;
@property (readwrite, strong, nonatomic) NSString *clientId;
@property (readwrite, assign, nonatomic) BOOL queryTime;
@property (readwrite, assign, nonatomic) BOOL useTokenAuth;
@property (readwrite, assign, nonatomic) ARTTokenDetails * tokenDetails;


- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key;

+ (instancetype)options;
+ (instancetype)optionsWithKey:(NSString *)key;

- (instancetype)clone;

@end

@interface ARTAuth : NSObject

-(ARTAuthOptions *) getAuthOptions;
- (ARTAuthMethod) getAuthMethod;
- (id<ARTCancellable>)authHeadersUseBasic:(BOOL)useBasic cb:(id<ARTCancellable>(^)(NSDictionary *))cb;
- (id<ARTCancellable>)authParams:(id<ARTCancellable>(^)(NSDictionary *))cb;
- (id<ARTCancellable>)authToken:(id<ARTCancellable>(^)(ARTTokenDetails *))cb;
- (id<ARTCancellable>)authTokenForceReauth:(BOOL)force cb:(id<ARTCancellable>(^)(ARTTokenDetails *))cb;
- (void) attemptTokenFetch:(void (^)()) cb;
-(bool) canRequestToken;
+ (void) authWithRest:(ARTRest *) rest options:(ARTAuthOptions *) options cb:(void(^)(ARTAuth * auth)) cb;
@end