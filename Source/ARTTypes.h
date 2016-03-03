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
@class ARTTokenParams;
@class ARTTokenRequest;
@class ARTTokenDetails;
@class __GENERIC(ARTPaginatedResult, ItemType);
@class ARTStats;

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
    ARTRealtimeChannelFailed
};

typedef NS_ENUM(NSUInteger, ARTChannelEvent) {
    ARTChannelEventInitialised,
    ARTChannelEventAttaching,
    ARTChannelEventAttached,
    ARTChannelEventDetaching,
    ARTChannelEventDetached,
    ARTChannelEventFailed,
    ARTChannelEventError
};

typedef NS_ENUM(NSInteger, ARTDataQueryError) {
    ARTDataQueryErrorLimit = 1,
    ARTDataQueryErrorTimestampRange = 2,
};

typedef NS_ENUM(NSInteger, ARTRealtimeHistoryError) {
    ARTRealtimeHistoryErrorNotAttached = ARTDataQueryErrorTimestampRange + 1
};

ART_ASSUME_NONNULL_BEGIN

/// Decompose API key
__GENERIC(NSArray, NSString *) *decomposeKey(NSString *key);

NSString *encodeBase64(NSString *value);
NSString *decodeBase64(NSString *base64);

uint64_t dateToMiliseconds(NSDate *date);
uint64_t timeIntervalToMiliseconds(NSTimeInterval seconds);

NSString *generateNonce();

// MARK: Callbacks definitions

typedef void (^ARTTimeCallback)(NSDate *__art_nullable time, NSError *__art_nullable error);

typedef void (^ARTAuthCallback)(ARTTokenParams *tokenParams, void(^callback)(ARTTokenDetails *__art_nullable tokenDetails, NSError *__art_nullable error));

typedef void (^ARTTokenCallback)(ARTTokenDetails *__art_nullable tokenDetails, NSError *__art_nullable error);

// FIXME: review
@protocol ARTCancellable
- (void)cancel;
@end

// FIXME: review
@interface ARTIndirectCancellable : NSObject <ARTCancellable>

@property (readwrite, strong, nonatomic) id<ARTCancellable> cancellable;
@property (readonly, assign, nonatomic) BOOL isCancelled;

- (instancetype)init;
- (instancetype)initWithCancellable:(id<ARTCancellable>)cancellable;
- (void)cancel;

@end

@interface ARTConnectionStateChange : NSObject

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                         reason:(ARTErrorInfo *__art_nullable)reason;

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                         reason:(ARTErrorInfo *__art_nullable)reason
                        retryIn:(NSTimeInterval)retryIn;

@property (readonly, nonatomic) ARTRealtimeConnectionState current;
@property (readonly, nonatomic) ARTRealtimeConnectionState previous;
@property (readonly, nonatomic, art_nullable) ARTErrorInfo *reason;
@property (readonly, nonatomic) NSTimeInterval retryIn;

@end

ART_ASSUME_NONNULL_END
