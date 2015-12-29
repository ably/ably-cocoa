//
//  ARTAuth.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"

@class ARTRest;
@class ARTLog;
@class ARTClientOptions;
@class ARTAuthOptions;
@class ARTAuthTokenParams;
@class ARTAuthTokenDetails;
@class ARTAuthTokenRequest;

ART_ASSUME_NONNULL_BEGIN

#pragma mark - ARTAuth

@interface ARTAuth : NSObject

@property (nonatomic, readonly, strong) ARTAuthOptions *options;
@property (nonatomic, readonly, assign) ARTAuthMethod method;

@property (nonatomic, weak) ARTLog *logger;

@property (art_nullable, readonly, getter=getClientId) NSString *clientId;
@property (art_nullable, nonatomic, readwrite, strong) ARTAuthTokenDetails *tokenDetails;

// FIXME: review (Why rest?)
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
- (void)requestToken:(art_nullable ARTAuthTokenParams *)tokenParams withOptions:(art_nullable ARTAuthOptions *)authOptions
            callback:(ARTTokenCallback)callback;

- (void)authorise:(art_nullable ARTAuthTokenParams *)tokenParams options:(art_nullable ARTAuthOptions *)authOptions callback:(ARTTokenCallback)callback;

- (void)createTokenRequest:(art_nullable ARTAuthTokenParams *)tokenParams options:(art_nullable ARTAuthOptions *)options
                  callback:(void (^)(ARTAuthTokenRequest *__art_nullable tokenRequest, NSError *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
