//
//  ARTAuth.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTHttp.h>
#import <ably/ARTTypes.h>

@class ARTRest;
@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTAuthTokenDetails : NSObject

@property (nonatomic, readonly, copy) NSString *token;
@property (nonatomic, readonly, strong, nullable) NSDate *expires;
@property (nonatomic, readonly, strong, nullable) NSDate *issued;
@property (nonatomic, readonly, copy, nullable) NSString *capability;
@property (nonatomic, readonly, copy, nullable) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithToken:(NSString *)token;

- (instancetype)initWithToken:(NSString *)token expires:(NSDate *)expires issued:(NSDate *)issued capability:(NSString *)capability clientId:(NSString *)clientId;

@end

@interface ARTAuthTokenParams : NSObject

@property (nonatomic, assign) NSTimeInterval ttl;
@property (nonatomic, copy) NSString *capability;
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, strong, null_resettable) NSDate *timestamp;

- (instancetype)init;

@end

@interface ARTAuthTokenRequest : ARTAuthTokenParams

@property (nonatomic, readonly, copy) NSString *keyName;
@property (nonatomic, readonly, copy) NSString *nonce;
@property (nonatomic, readonly, copy) NSString *mac;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithTokenParams:(ARTAuthTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac;

@end

@interface ARTAuthTokenParams(SignedRequest)

- (ARTAuthTokenRequest *)sign:(NSString *)key;

@end

typedef void (^ARTAuthCallback)(ARTAuthTokenParams *tokenParams, void(^callback)(ARTAuthTokenRequest *__nullable tokenRequest, NSError *__nullable error));

typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};

@interface ARTAuthOptions : NSObject<NSCopying>

@property (nonatomic, copy, nullable) NSString *key;

@property (nonatomic, copy, nullable) NSString *token;
@property (nonatomic, strong, nullable) ARTAuthTokenDetails *tokenDetails;
@property (nonatomic, assign) BOOL useTokenAuth;

@property (nonatomic, copy, nullable) ARTAuthCallback authCallback;

@property (nonatomic, strong, nullable) NSURL *authUrl;
@property (nonatomic, copy, null_resettable) NSString *authMethod;
@property (nonatomic, copy, nullable) NSDictionary *authHeaders; //X7: NSDictionary<NSString *, NSString *> *authHeaders;
@property (nonatomic, copy, nullable) NSArray *authParams; //X7: NSArray<NSURLQueryItem *> *authParams;

@property (nonatomic, assign, nonatomic) BOOL queryTime;

- (instancetype)initWithKey:(NSString *)key;

@end

@interface ARTAuth : NSObject

@property (nonatomic, weak) ARTLog *logger;
@property (nonatomic, readonly, strong) ARTAuthOptions *options;
@property (nonatomic, readonly, assign) ARTAuthMethod authMethod;
@property (nonatomic, readonly, strong) ARTAuthTokenDetails *currentToken;

- (instancetype)initWithRest:(ARTRest *)rest options:(ARTAuthOptions *)options;

- (void)requestToken:(nullable ARTAuthTokenParams *)tokenParams options:(nullable ARTAuthOptions *)options
            callback:(void (^)(ARTAuthTokenDetails *__nullable tokenDetails, NSError *__nullable error))callback;

- (void)authorise:(nullable ARTAuthTokenParams *)tokenParams options:(nullable ARTAuthOptions *)options force:(BOOL)force
         callback:(void (^)(ARTAuthTokenDetails *__nullable tokenDetails, NSError *__nullable error))callback;

- (void)createTokenRequest:(nullable ARTAuthTokenParams *)tokenParams options:(nullable ARTAuthOptions *)options
                  callback:(void (^)(ARTAuthTokenRequest *__nullable tokenRequest, NSError *__nullable error))callback;

@end

NS_ASSUME_NONNULL_END
