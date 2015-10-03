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

#pragma mark - ARTAuthTokenParams

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


#pragma mark - ARTAuthTokenParams

@interface ARTAuthTokenParams : NSObject

@property (nonatomic, assign) NSTimeInterval ttl;
@property (nonatomic, copy) NSString *capability;
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, strong, null_resettable) NSDate *timestamp;

- (instancetype)init;

- (NSMutableArray *)toArray; //X7: NSArray<NSURLQueryItem *>
- (NSArray *)toArrayWithUnion:(NSArray *)items; //X7: NSArray<NSURLQueryItem *>
- (NSDictionary *)toDictionaryWithUnion:(NSArray *)items;

@end


#pragma mark - ARTAuthTokenRequest

@interface ARTAuthTokenRequest : ARTAuthTokenParams

@property (nonatomic, readonly, copy) NSString *keyName;
@property (nonatomic, readonly, copy) NSString *nonce;
@property (nonatomic, readonly, copy) NSString *mac;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithTokenParams:(ARTAuthTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac;

@end


#pragma mark - ARTAuthTokenParams

@interface ARTAuthTokenParams(SignedRequest)

- (ARTAuthTokenRequest *)sign:(NSString *)key;

@end


#pragma mark - ARTAuthOptions

typedef void (^ARTAuthCallback)(ARTAuthTokenParams *tokenParams, void(^callback)(ARTAuthTokenRequest *__nullable tokenRequest, NSError *__nullable error));

typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};

@interface ARTAuthOptions : NSObject<NSCopying>

/**
 Full Ably key string as obtained from dashboard.
 */
@property (nonatomic, copy, nullable) NSString *key;

/**
 An authentication token issued for this application against a specific key and `TokenParams`.
 */
@property (nonatomic, copy, nullable) NSString *token;

/**
 An authentication token issued for this application against a specific key and `TokenParams`.
 */
@property (nonatomic, strong, nullable) ARTAuthTokenDetails *tokenDetails;

/**
 A callback to call to obtain a signed token request.
 
 This enables a client to obtain token requests from another entity, so tokens can be renewed without the client requiring access to keys.
 */
@property (nonatomic, copy, nullable) ARTAuthCallback authCallback;

/**
 A URL to queryto obtain a signed token request.
 
 This enables a client to obtain token requests from another entity, so tokens can be renewed without the client requiring access to keys.
 */
@property (nonatomic, strong, nullable) NSURL *authUrl;

/**
 The HTTP verb to be used when a request is made by the library to the authUrl. Defaults to GET, supports GET and POST.
 */
@property (nonatomic, copy, null_resettable) NSString *authMethod;

/**
 Headers to be included in any request made by the library to the authURL.
 */
@property (nonatomic, copy, nullable) NSDictionary *authHeaders; //X7: NSDictionary<NSString *, NSString *> *authHeaders;

/**
  Additional params to be included in any request made by the library to the authUrl, either as query params in the case of GET or in the body in the case of POST.
 */
@property (nonatomic, copy, nullable) NSArray *authParams; //X7: NSArray<NSURLQueryItem *> *authParams;

/**
 This may be set in instances that the library is to sign token requests based on a given key.
 If true, the library will query the Ably system for the current time instead of relying on a locally-available time of day.
 */
@property (nonatomic, assign, nonatomic) BOOL queryTime;

@property (nonatomic, assign) BOOL useTokenAuth;

- (instancetype)initWithKey:(NSString *)key;

- (NSString *)description;

- (ARTAuthOptions *)mergeWith:(ARTAuthOptions *)precedenceOptions;

- (BOOL)isMethodGET;
- (BOOL)isMethodPOST;

@end


#pragma mark - ARTAuth

@interface ARTAuth : NSObject

@property (nonatomic, weak) ARTLog *logger;
@property (nonatomic, readonly, strong) ARTAuthOptions *options;
@property (nonatomic, readonly, assign) ARTAuthMethod authMethod;
@property (nonatomic, readonly, strong) ARTAuthTokenDetails *currentToken;

- (instancetype)init:(ARTRest *)rest withOptions:(ARTAuthOptions *)options;

/**
 # (RSA8) Auth#requestToken
 
 Implicitly creates a `TokenRequest` if required, and requests a token from Ably if required.
 
 `TokenParams` and `AuthOptions` are optional.
 When provided, the values supersede matching client library configured params and options.
 
 - Parameter tokenParams: Token params (optional).
 - Parameter authOptions: Authentication options (optional).
 - Parameter callback: Completion callback (ARTAuthTokenDetails, NSError).
 */
- (void)requestToken:(nullable ARTAuthTokenParams *)tokenParams withOptions:(nullable ARTAuthOptions *)authOptions
            callback:(void (^)(ARTAuthTokenDetails *__nullable tokenDetails, NSError *__nullable error))callback;

- (void)authorise:(nullable ARTAuthTokenParams *)tokenParams options:(nullable ARTAuthOptions *)options force:(BOOL)force
         callback:(void (^)(ARTAuthTokenDetails *__nullable tokenDetails, NSError *__nullable error))callback;

- (void)createTokenRequest:(nullable ARTAuthTokenParams *)tokenParams options:(nullable ARTAuthOptions *)options
                  callback:(void (^)(ARTAuthTokenRequest *__nullable tokenRequest, NSError *__nullable error))callback;

@end

NS_ASSUME_NONNULL_END
