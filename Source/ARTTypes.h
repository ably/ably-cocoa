//
//  ARTTypes.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTStatus.h"
#import "ARTEventEmitter.h"

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

typedef NSDictionary<NSString *, id> ARTJsonObject;

typedef NS_ENUM(NSUInteger, ARTAuthentication) {
    ARTAuthenticationOff,
    ARTAuthenticationOn,
    ARTAuthenticationUseBasic,
    ARTAuthenticationNewToken,
    ARTAuthenticationTokenRetry
};

typedef NS_ENUM(NSUInteger, ARTAuthMethod) {
    ARTAuthMethodBasic,
    ARTAuthMethodToken
};


#pragma mark - ARTRealtimeConnectionState

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

NSString *__art_nonnull ARTRealtimeConnectionStateToStr(ARTRealtimeConnectionState state);


#pragma mark - ARTRealtimeConnectionEvent

typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionEvent) {
    ARTRealtimeConnectionEventInitialized,
    ARTRealtimeConnectionEventConnecting,
    ARTRealtimeConnectionEventConnected,
    ARTRealtimeConnectionEventDisconnected,
    ARTRealtimeConnectionEventSuspended,
    ARTRealtimeConnectionEventClosing,
    ARTRealtimeConnectionEventClosed,
    ARTRealtimeConnectionEventFailed,
    ARTRealtimeConnectionEventUpdate
};

NSString *__art_nonnull ARTRealtimeConnectionEventToStr(ARTRealtimeConnectionEvent event);


#pragma mark - ARTRealtimeChannelState

typedef NS_ENUM(NSUInteger, ARTRealtimeChannelState) {
    ARTRealtimeChannelInitialized,
    ARTRealtimeChannelAttaching,
    ARTRealtimeChannelAttached,
    ARTRealtimeChannelDetaching,
    ARTRealtimeChannelDetached,
    ARTRealtimeChannelSuspended,
    ARTRealtimeChannelFailed
};

NSString *__art_nonnull ARTRealtimeChannelStateToStr(ARTRealtimeChannelState state);


#pragma mark - ARTChannelEvent

typedef NS_ENUM(NSUInteger, ARTChannelEvent) {
    ARTChannelEventInitialized,
    ARTChannelEventAttaching,
    ARTChannelEventAttached,
    ARTChannelEventDetaching,
    ARTChannelEventDetached,
    ARTChannelEventSuspended,
    ARTChannelEventFailed,
    ARTChannelEventUpdate
};

NSString *__art_nonnull ARTChannelEventToStr(ARTChannelEvent event);


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

uint64_t dateToMilliseconds(NSDate *date);
uint64_t timeIntervalToMilliseconds(NSTimeInterval seconds);
NSTimeInterval millisecondsToTimeInterval(uint64_t msecs);

NSString *generateNonce();

// FIXME: review
@protocol ARTCancellable
- (void)cancel;
@end

#pragma mark - ARTConnectionStateChange

@interface ARTConnectionStateChange : NSObject

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                          event:(ARTRealtimeConnectionEvent)event
                         reason:(ARTErrorInfo *__art_nullable)reason;

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                          event:(ARTRealtimeConnectionEvent)event
                         reason:(ARTErrorInfo *__art_nullable)reason
                        retryIn:(NSTimeInterval)retryIn;

@property (readonly, nonatomic) ARTRealtimeConnectionState current;
@property (readonly, nonatomic) ARTRealtimeConnectionState previous;
@property (readonly, nonatomic) ARTRealtimeConnectionEvent event;
@property (readonly, nonatomic, art_nullable) ARTErrorInfo *reason;
@property (readonly, nonatomic) NSTimeInterval retryIn;

@end

#pragma mark - ARTChannelStateChange

@interface ARTChannelStateChange : NSObject

- (instancetype)initWithCurrent:(ARTRealtimeChannelState)current
                       previous:(ARTRealtimeChannelState)previous
                          event:(ARTChannelEvent)event
                         reason:(ARTErrorInfo *__art_nullable)reason;

- (instancetype)initWithCurrent:(ARTRealtimeChannelState)current
                       previous:(ARTRealtimeChannelState)previous
                          event:(ARTChannelEvent)event
                         reason:(ARTErrorInfo *__art_nullable)reason
                        resumed:(BOOL)resumed;

@property (readonly, nonatomic) ARTRealtimeChannelState current;
@property (readonly, nonatomic) ARTRealtimeChannelState previous;
@property (readonly, nonatomic) ARTChannelEvent event;
@property (readonly, nonatomic, art_nullable) ARTErrorInfo *reason;
@property (readonly, nonatomic) BOOL resumed;

@end

#pragma mark - ARTJsonCompatible

@protocol ARTJsonCompatible <NSObject>
- (NSDictionary *__art_nullable)toJSON:(NSError *__art_nullable *__art_nullable)error;
@end

@interface NSString (ARTEventIdentification) <ARTEventIdentification>
@end

@interface NSString (ARTJsonCompatible) <ARTJsonCompatible>
@end

@interface NSDictionary (ARTJsonCompatible) <ARTJsonCompatible>
@end

@interface NSURL (ARTLog)
@end

@interface NSDictionary (URLQueryItemAdditions)
@property (nonatomic, readonly) NSArray<NSURLQueryItem *> *asURLQueryItems;
@end

@interface NSMutableArray (QueueAdditions)
- (void)enqueue:(id)object;
- (id)dequeue;
- (id)peek;
@end

ART_ASSUME_NONNULL_END
