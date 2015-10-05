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

NS_ASSUME_NONNULL_BEGIN

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

- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initDefaults;

- (NSString *)description;

- (ARTAuthOptions *)mergeWith:(ARTAuthOptions *)precedenceOptions;

- (BOOL)isMethodGET;
- (BOOL)isMethodPOST;

@end

NS_ASSUME_NONNULL_END
