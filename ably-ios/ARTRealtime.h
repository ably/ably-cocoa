//
//  ARTRealtime.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"

@class ARTStatus;
@class ARTMessage;
@class ARTClientOptions;
@class ARTStatsQuery;
@class ARTRealtimeChannel;
@class ARTPresenceMessage;
@class ARTPaginatedResult;
@class ARTErrorInfo;
@class ARTCipherParams;
@class ARTPresence;
@class ARTPresenceMap;
@class ARTRealtimeChannelPresenceSubscription;
@class ARTRealtimeConnectionStateSubscription;
@class ARTEventEmitter;
@class ARTRealtimeChannel;
@class ARTAuth;
@class ARTProtocolMessage;

ART_ASSUME_NONNULL_BEGIN

#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

#pragma mark - ARTRealtime

@interface ARTRealtime : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/** 
Instance the Ably library using a key only. This is simply a convenience constructor for the simplest case of instancing the library with a key for basic authentication and no other options.
:param key; String key (obtained from application dashboard)
*/
- (instancetype)initWithKey:(NSString *)key;

/**
Instance the Ably library with the given options.
:param options: see ARTClientOptions for options
*/
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options;

// FIXME: consistent names like Connect/Disconnect, Open/Close
- (void)close;
- (BOOL)connect;
- (BOOL)isActive;

- (ARTRealtimeConnectionState)state;
- (NSString *)connectionId;
- (NSString *)connectionKey;
- (NSString *)recoveryKey;
- (ARTAuth *)auth;
- (__GENERIC(NSDictionary, NSString *, ARTRealtimeChannel *) *)channels;
- (void)time:(void(^)(NSDate *time, NSError *error))cb;

- (ARTErrorInfo *)connectionErrorReason;

typedef void (^ARTRealtimePingCb)(ARTStatus *);
- (void)ping:(ARTRealtimePingCb) cb;

- (void)stats:(ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult *result, NSError *error))completion;

- (ARTRealtimeChannel *)channel:(NSString *)channelName;
- (ARTRealtimeChannel *)channel:(NSString *)channelName cipherParams:(art_nullable ARTCipherParams *)cipherParams;
- (void)removeChannel:(NSString *)name;

// Message sending
- (void)send:(ARTProtocolMessage *)msg cb:(art_nullable ARTStatusCallback)cb;

- (void)unsubscribeState:(ARTRealtimeConnectionStateSubscription *)subscription;

@property (readonly, strong, nonatomic) ARTEventEmitter *eventEmitter;
@property (readonly, getter=getLogger) ARTLog *logger;
@property (art_nullable, readwrite, strong, nonatomic) ARTErrorInfo *errorReason;

@end

ART_ASSUME_NONNULL_END
