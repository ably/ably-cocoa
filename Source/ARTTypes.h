//
//  ARTTypes.h
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTStatus.h>
#import <Ably/ARTEventEmitter.h>

@class ARTStatus;
@class ARTHttpResponse;
@class ARTErrorInfo;
@class ARTMessage;
@class ARTPresenceMessage;
@class ARTTokenParams;
@class ARTTokenRequest;
@class ARTTokenDetails;
@class ARTPaginatedResult<ItemType>;
@class ARTStats;

// More context
typedef NSDictionary<NSString *, id> ARTJsonObject;
typedef NSString ARTDeviceId;
typedef NSString ARTDeviceSecret;
typedef NSData ARTDeviceToken;
typedef ARTJsonObject ARTPushRecipient;

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

NSString *_Nonnull ARTRealtimeConnectionStateToStr(ARTRealtimeConnectionState state);


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

NSString *_Nonnull ARTRealtimeConnectionEventToStr(ARTRealtimeConnectionEvent event);


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

NSString *_Nonnull ARTRealtimeChannelStateToStr(ARTRealtimeChannelState state);


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

NSString *_Nonnull ARTChannelEventToStr(ARTChannelEvent event);


typedef NS_ENUM(NSInteger, ARTDataQueryError) {
    ARTDataQueryErrorLimit = 1,
    ARTDataQueryErrorTimestampRange = 2,
    ARTDataQueryErrorMissingRequiredFields = 3,
    ARTDataQueryErrorInvalidParameters = 4,
    ARTDataQueryErrorDeviceInactive = 5,
};

typedef NS_ENUM(NSInteger, ARTRealtimeHistoryError) {
    ARTRealtimeHistoryErrorNotAttached = ARTDataQueryErrorTimestampRange + 1
};

typedef NS_ENUM(NSInteger, ARTCustomRequestError) {
    ARTCustomRequestErrorInvalidMethod = 1,
    ARTCustomRequestErrorInvalidBody = 2,
    ARTCustomRequestErrorInvalidPath = 3,
};

NS_ASSUME_NONNULL_BEGIN

/// Decompose API key
NSArray<NSString *> *decomposeKey(NSString *key);

NSString *encodeBase64(NSString *value);
NSString *decodeBase64(NSString *base64);

uint64_t dateToMilliseconds(NSDate *date);
uint64_t timeIntervalToMilliseconds(NSTimeInterval seconds);
NSTimeInterval millisecondsToTimeInterval(uint64_t msecs);

NSString *generateNonce(void);

@protocol ARTCancellable
- (void)cancel;
@end

#pragma mark - ARTConnectionStateChange

@interface ARTConnectionStateChange : NSObject

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                          event:(ARTRealtimeConnectionEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason;

- (instancetype)initWithCurrent:(ARTRealtimeConnectionState)current
                       previous:(ARTRealtimeConnectionState)previous
                          event:(ARTRealtimeConnectionEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason
                        retryIn:(NSTimeInterval)retryIn;

@property (readonly, nonatomic) ARTRealtimeConnectionState current;
@property (readonly, nonatomic) ARTRealtimeConnectionState previous;
@property (readonly, nonatomic) ARTRealtimeConnectionEvent event;
@property (readonly, nonatomic, nullable) ARTErrorInfo *reason;
@property (readonly, nonatomic) NSTimeInterval retryIn;

@end

#pragma mark - ARTChannelStateChange

@interface ARTChannelStateChange : NSObject

- (instancetype)initWithCurrent:(ARTRealtimeChannelState)current
                       previous:(ARTRealtimeChannelState)previous
                          event:(ARTChannelEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason;

- (instancetype)initWithCurrent:(ARTRealtimeChannelState)current
                       previous:(ARTRealtimeChannelState)previous
                          event:(ARTChannelEvent)event
                         reason:(ARTErrorInfo *_Nullable)reason
                        resumed:(BOOL)resumed;

@property (readonly, nonatomic) ARTRealtimeChannelState current;
@property (readonly, nonatomic) ARTRealtimeChannelState previous;
@property (readonly, nonatomic) ARTChannelEvent event;
@property (readonly, nonatomic, nullable) ARTErrorInfo *reason;
@property (readonly, nonatomic) BOOL resumed;

@end

#pragma mark - ARTJsonCompatible

@protocol ARTJsonCompatible <NSObject>
- (NSDictionary *_Nullable)toJSON:(NSError *_Nullable *_Nullable)error;
- (NSString *_Nullable)toJSONString;
@end

@interface NSString (ARTEventIdentification) <ARTEventIdentification>
@end

@interface NSString (ARTJsonCompatible) <ARTJsonCompatible>
@end

@interface NSString (ARTUtilities)
- (NSString *)art_shortString NS_SWIFT_NAME(shortString());
- (NSString *)art_base64Encoded NS_SWIFT_NAME(base64Encoded());
@end

@interface NSDate (ARTUtilities)
+ (NSDate *)art_dateWithMillisecondsSince1970:(uint64_t)msecs NS_SWIFT_NAME(date(withMillisecondsSince1970:));
@end

@interface NSDictionary (ARTJsonCompatible) <ARTJsonCompatible>
@end

@interface NSURL (ARTLog)
@end

@interface NSDictionary (ARTURLQueryItemAdditions)
@property (nonatomic, readonly) NSArray<NSURLQueryItem *> *art_asURLQueryItems;
@end

@interface NSMutableArray (ARTQueueAdditions)
- (void)art_enqueue:(id)object;
- (id)art_dequeue;
- (id)art_peek;
@end

@interface NSURLSessionTask (ARTCancellable) <ARTCancellable>
@end

/**
 Signature of a generic completion handler which, when called, will either
 present with nil result or nil error, but never both nil.
 */
typedef void (^ARTCompletionHandler)(id result, NSError * error);

/**
 Wraps the given callback in an ARTCancellable, offering the following
 protections:
 
 1) If the cancel method is called on the returned instance then the callback
    will not be invoked.
 2) The callback will only ever be invoked once.
 
 To make use of these benefits the caller needs to use the returned wrapper
 to invoke the callback. The wrapper will only work for as long as the returned
 instance remains allocated (i.e. has a strong reference to it somewhere).
 */
NSObject<ARTCancellable> * artCancellableFromCallback(ARTCompletionHandler callback, _Nonnull ARTCompletionHandler *_Nonnull wrapper);

NS_ASSUME_NONNULL_END
