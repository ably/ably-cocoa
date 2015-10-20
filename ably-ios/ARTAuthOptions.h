//
//  ARTAuthOptions.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTAuthTokenDetails;

ART_ASSUME_NONNULL_BEGIN

@interface ARTAuthOptions : NSObject<NSCopying>

/**
 Full Ably key string as obtained from dashboard.
 */
@property (nonatomic, copy, art_nullable) NSString *key;

/**
 An authentication token issued for this application against a specific key and `TokenParams`.
 */
@property (nonatomic, copy, art_nullable) NSString *token;

/**
 An authentication token issued for this application against a specific key and `TokenParams`.
 */
@property (nonatomic, strong, art_nullable) ARTAuthTokenDetails *tokenDetails;

/**
 A callback to call to obtain a signed token request.
 
 This enables a client to obtain token requests from another entity, so tokens can be renewed without the client requiring access to keys.
 */
@property (nonatomic, copy, art_nullable) ARTAuthCallback authCallback;

/**
 A URL to queryto obtain a signed token request.
 
 This enables a client to obtain token requests from another entity, so tokens can be renewed without the client requiring access to keys.
 */
@property (nonatomic, strong, art_nullable) NSURL *authUrl;

/**
 The HTTP verb to be used when a request is made by the library to the authUrl. Defaults to GET, supports GET and POST.
 */
@property (nonatomic, copy, art_null_resettable) NSString *authMethod;

/**
 Headers to be included in any request made by the library to the authURL.
 */
@property (nonatomic, copy, art_nullable) __GENERIC(NSDictionary, NSString *, NSString *) *authHeaders;

/**
 Additional params to be included in any request made by the library to the authUrl, either as query params in the case of GET or in the body in the case of POST.
 */
@property (nonatomic, copy, art_nullable) __GENERIC(NSArray, NSURLQueryItem *) *authParams;

/**
 This may be set in instances that the library is to sign token requests based on a given key.
 If true, the library will query the Ably system for the current time instead of relying on a locally-available time of day.
 */
@property (nonatomic, assign, nonatomic) BOOL queryTime;

/**
 Forces authentication with token.
 */
@property (readwrite, assign, nonatomic) BOOL useTokenAuth;

/**
 Indicates that a new token should be requested.
 */
@property (readwrite, assign, nonatomic) BOOL force;

/**
 The id of the client represented by this instance.
 The clientId is relevant to presence operations, where the clientId is the principal identifier of the client in presence update messages. The clientId is also relevant to authentication; a token issued for a specific client may be used to authenticate the bearer of that token to the service.
 */
@property (readwrite, strong, nonatomic, art_nullable) NSString *clientId;

- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initDefaults;

- (NSString *)description;

- (ARTAuthOptions *)mergeWith:(ARTAuthOptions *)precedenceOptions;

- (BOOL)isBasicAuth;
- (BOOL)isMethodGET;
- (BOOL)isMethodPOST;

@end

ART_ASSUME_NONNULL_END
