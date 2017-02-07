//
//  ARTAuth+Private.h
//  ably
//
//  Created by Ricardo Pereira on 03/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTAuth.h"
#import "ARTEventEmitter+Private.h"

typedef NS_ENUM(NSUInteger, ARTAuthorizationState) {
    ARTAuthorizationSucceeded, //ItemType: nil
    ARTAuthorizationFailed //ItemType: NSError
};

ART_ASSUME_NONNULL_BEGIN

/// Messages related to the ARTAuth
@protocol ARTAuthDelegate <NSObject>
@property (nonatomic, readonly) ARTEventEmitter<ARTEvent *, id> *authorizationEmitter;
- (void)auth:(ARTAuth *)auth didAuthorize:(ARTTokenDetails *)tokenDetails;
@end

@interface ARTAuth ()

- (NSString *)clientId_nosync;

@property (nonatomic, readonly, strong) ARTClientOptions *options;
@property (nonatomic, readonly, assign) ARTAuthMethod method;

@property (nonatomic, weak) ARTLog *logger;
@property (art_nullable, nonatomic, readonly, strong) ARTTokenDetails *tokenDetails;
@property (nonatomic, readonly, assign) NSTimeInterval timeOffset;

@property (art_nullable, weak) id<ARTAuthDelegate> delegate;
@property (readonly, assign) BOOL authorizing;

- (void)_authorize:(art_nullable ARTTokenParams *)tokenParams options:(art_nullable ARTAuthOptions *)authOptions
         callback:(void (^)(ARTTokenDetails *__art_nullable, NSError *__art_nullable))callback;

- (void)_requestToken:(ARTTokenParams *__art_nullable)tokenParams withOptions:(ARTAuthOptions *__art_nullable)authOptions callback:(void (^)(ARTTokenDetails *__art_nullable, NSError *__art_nullable))callback;

@end

@interface ARTAuth (Private)

- (instancetype)init:(ARTRest *)rest withOptions:(ARTClientOptions *)options;

- (ARTAuthOptions *)mergeOptions:(ARTAuthOptions *)customOptions;
- (ARTTokenParams *)mergeParams:(ARTTokenParams *)customParams;

- (NSURL *)buildURL:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params;
- (NSMutableURLRequest *)buildRequest:(nullable ARTAuthOptions *)options withParams:(nullable ARTTokenParams *)params;

// Execute the received ARTTokenRequest
- (void)executeTokenRequest:(ARTTokenRequest *)tokenRequest callback:(void (^)(ARTTokenDetails *__art_nullable tokenDetails, NSError *__art_nullable error))callback;

// CONNECTED ProtocolMessage may contain a clientId
- (void)setProtocolClientId:(NSString *)clientId;

// Discard the cached local clock offset
- (void)discardTimeOffset;

// Configured options does have a means to renew the token automatically.
- (BOOL)canRenewTokenAutomatically:(ARTAuthOptions *)options;

/// Does the client have a means to renew the token automatically.
- (BOOL)tokenIsRenewable;

/// Does the client have a valid token (i.e. not expired).
- (BOOL)tokenRemainsValid;

// Private TokenDetails setter for testing only
- (void)setTokenDetails:(ARTTokenDetails *)tokenDetails;

// Private TimeOffset setter for testing only
- (void)setTimeOffset:(NSTimeInterval)offset;

- (NSString *_Nullable)getClientId;

- (NSString *_Nullable)appId;

@end

#pragma mark - ARTEvent

@interface ARTEvent (AuthorizationState)
- (instancetype)initWithAuthorizationState:(ARTAuthorizationState)value;
+ (instancetype)newWithAuthorizationState:(ARTAuthorizationState)value;
@end

ART_ASSUME_NONNULL_END
