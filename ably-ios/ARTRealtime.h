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
#import "ARTRealtimeChannels.h"

@class ARTStatus;
@class ARTMessage;
@class ARTClientOptions;
@class ARTStatsQuery;
@class ARTRealtimeChannel;
@class ARTPresenceMessage;
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
@class ARTRealtimeChannels;

ART_ASSUME_NONNULL_BEGIN

#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

#pragma mark - ARTRealtime

@interface ARTRealtime : NSObject

@property (nonatomic, strong, readonly) ARTRealtimeChannels *channels;

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
- (art_nullable NSString *)connectionId;
- (art_nullable NSString *)connectionKey;
- (NSString *)recoveryKey;
- (ARTAuth *)auth;
- (void)time:(ARTTimeCallback)cb;

typedef void (^ARTRealtimePingCb)(ARTStatus *);
- (void)ping:(ARTRealtimePingCb)cb;

- (BOOL)stats:(ARTStatsQuery *)query callback:(ARTStatsCallback)completion error:(NSError **)errorPtr;

// Message sending
- (void)send:(ARTProtocolMessage *)msg cb:(art_nullable ARTStatusCallback)cb;

- (void)unsubscribeState:(ARTRealtimeConnectionStateSubscription *)subscription;

@property (readonly, strong, nonatomic) ARTEventEmitter *eventEmitter;
@property (readonly, getter=getLogger) ARTLog *logger;

@end

ART_ASSUME_NONNULL_END
