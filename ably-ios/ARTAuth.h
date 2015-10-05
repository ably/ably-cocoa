//
//  ARTAuth.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ably.h"

@class ARTRest;
@class ARTLog;
@class ARTClientOptions;
@class ARTAuthOptions;
@class ARTAuthTokenParams;
@class ARTAuthTokenDetails;
@class ARTAuthTokenRequest;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ARTAuth

typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};

@interface ARTAuth : NSObject

@property (nonatomic, weak) ARTLog *logger;
@property (nonatomic, readonly, strong) ARTAuthOptions *options;
@property (nonatomic, readonly, assign) ARTAuthMethod method;
@property (nonatomic, readonly, strong) ARTAuthTokenDetails *tokenDetails;

- (instancetype)init:(ARTRest *)rest withOptions:(ARTClientOptions *)options;

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
