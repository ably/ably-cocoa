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
@class ARTTokenParams;
@class ARTTokenDetails;
@class ARTTokenRequest;

ART_ASSUME_NONNULL_BEGIN

#pragma mark - ARTAuth

@interface ARTAuth : NSObject

@property (art_nullable, readonly, getter=getClientId) NSString *clientId;

// FIXME: review (Why rest?)
- (instancetype)init:(ARTRest *)rest withOptions:(ARTClientOptions *)options;

/**
 # (RSA8) Auth#requestToken
 
 Implicitly creates a `TokenRequest` if required, and requests a token from Ably if required.
 
 `TokenParams` and `AuthOptions` are optional.
 When provided, the values supersede matching client library configured params and options.
 
 - Parameter tokenParams: Token params (optional).
 - Parameter authOptions: Authentication options (optional).
 - Parameter callback: Completion callback (ARTTokenDetails, NSError).
 */
- (void)requestToken:(art_nullable ARTTokenParams *)tokenParams withOptions:(art_nullable ARTAuthOptions *)authOptions
            callback:(void (^)(ARTTokenDetails *__art_nullable, NSError *__art_nullable))callback;

- (void)authorise:(art_nullable ARTTokenParams *)tokenParams options:(art_nullable ARTAuthOptions *)authOptions callback:(void (^)(ARTTokenDetails *__art_nullable, NSError *__art_nullable))callback;

- (void)createTokenRequest:(art_nullable ARTTokenParams *)tokenParams options:(art_nullable ARTAuthOptions *)options
                  callback:(void (^)(ARTTokenRequest *__art_nullable tokenRequest, NSError *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
