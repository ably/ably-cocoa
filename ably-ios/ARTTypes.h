//
//  ARTTypes.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

@class ARTStatus;
@class ARTHttpResponse;
@class ARTErrorInfo;
@class ARTMessage;
@class ARTPresenceMessage;
@class ARTAuthTokenParams;
@class ARTAuthTokenRequest;
@class ARTAuthTokenDetails;
@class ARTPaginatedResult;

typedef NS_ENUM(NSUInteger, ARTAuthentication) {
    ARTAuthenticationOff,
    ARTAuthenticationOn,
    ARTAuthenticationUseBasic,
    ARTAuthenticationNewToken
};

typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};

typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionState) {
    ARTRealtimeInitialized,
    ARTRealtimeConnecting,
    ARTRealtimeConnected,
    ARTRealtimeDisconnected,
    ARTRealtimeSuspended,
    ARTRealtimeClosing,
    ARTRealtimeClosed,
    ARTRealtimeFailed
};

typedef NS_ENUM(NSUInteger, ARTRealtimeChannelState) {
    ARTRealtimeChannelInitialised,
    ARTRealtimeChannelAttaching,
    ARTRealtimeChannelAttached,
    ARTRealtimeChannelDetaching,
    ARTRealtimeChannelDetached,
    ARTRealtimeChannelClosed,
    ARTRealtimeChannelFailed
};

ART_ASSUME_NONNULL_BEGIN

/// Decompose API key
__GENERIC(NSArray, NSString *) *decomposeKey(NSString *key);

NSString *encodeBase64(NSString *value);
NSString *decodeBase64(NSString *base64);

uint64_t dateToMiliseconds(NSDate *date);
uint64_t timeIntervalToMiliseconds(NSTimeInterval seconds);

// MARK: Callbacks definitions

typedef void (^ARTRealtimeChannelMessageCb)(ARTMessage * message, ARTErrorInfo *__art_nullable errorInfo);

typedef void (^ARTRealtimeChannelStateCb)(ARTRealtimeChannelState, ARTStatus *);

typedef void (^ARTRealtimeConnectionStateCb)(ARTRealtimeConnectionState state, ARTErrorInfo *__art_nullable errorInfo);

typedef void (^ARTRealtimeChannelPresenceCb)(ARTPresenceMessage *);

typedef void (^ARTRealtimePingCb)(ARTStatus *);

typedef void (^ARTStatusCallback)(ARTStatus *status);

typedef void (^ARTHttpCb)(ARTHttpResponse *response);

typedef void (^ARTErrorCallback)(NSError *__art_nullable error);

typedef void (^ARTHttpRequestCallback)(NSHTTPURLResponse *__art_nullable response, NSData *__art_nullable data, NSError *__art_nullable error);

typedef void (^ARTStatsCallback)(ARTPaginatedResult *__art_nullable result, NSError *__art_nullable error);

typedef void (^ARTTimeCallback)(NSDate *__art_nullable time, NSError *__art_nullable error);

// FIXME: review
typedef void (^ARTAuthCallback)(ARTAuthTokenParams *tokenParams, void(^callback)(ARTAuthTokenRequest *__art_nullable tokenRequest, NSError *__art_nullable error));

typedef void (^ARTTokenCallback)(ARTAuthTokenDetails *__art_nullable tokenDetails, NSError *__art_nullable error);

// FIXME: review
@protocol ARTCancellable
- (void)cancel;
@end

@protocol ARTSubscription
- (void)unsubscribe;
@end

// FIXME: review
@interface ARTIndirectCancellable : NSObject <ARTCancellable>

@property (readwrite, strong, nonatomic) id<ARTCancellable> cancellable;
@property (readonly, assign, nonatomic) BOOL isCancelled;

- (instancetype)init;
- (instancetype)initWithCancellable:(id<ARTCancellable>)cancellable;
- (void)cancel;

@end

ART_ASSUME_NONNULL_END
