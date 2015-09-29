//
//  ARTRealtime.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTStatus.h>
#import <ably/ARTTypes.h>
#import <ably/ARTMessage.h>
#import <ably/ARTClientOptions.h>
#import <ably/ARTPresenceMessage.h>
#import <ably/ARTPaginatedResult.h>
#import <ably/ARTStats.h>


#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

@class ARTPresence;
@class ARTPresenceMap;
@class ARTRealtimeChannelPresenceSubscription;
@class ARTEventEmitter;


#pragma mark - Enumerations

typedef NS_ENUM(NSUInteger, ARTRealtimeChannelState) {
    ARTRealtimeChannelInitialised,
    ARTRealtimeChannelAttaching,
    ARTRealtimeChannelAttached,
    ARTRealtimeChannelDetaching,
    ARTRealtimeChannelDetached,
    ARTRealtimeChannelClosed,
    ARTRealtimeChannelFailed
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


#pragma mark - Protocols

@protocol ARTSubscription

- (void)unsubscribe;

@end


#pragma mark - ARTRealtimeChannel

@interface ARTRealtimeChannel : NSObject

- (void)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb;
- (void)publish:(id)payload cb:(ARTStatusCallback)cb;

- (id<ARTCancellable>)history:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCallback)callback;

typedef void (^ARTRealtimeChannelMessageCb)(ARTMessage *);
- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelMessageCb)cb;
- (id<ARTSubscription>)subscribeToName:(NSString *)name cb:(ARTRealtimeChannelMessageCb)cb;
- (id<ARTSubscription>)subscribeToNames:(NSArray *)names cb:(ARTRealtimeChannelMessageCb)cb;

typedef void (^ARTRealtimeChannelStateCb)(ARTRealtimeChannelState, ARTStatus *);
- (id<ARTSubscription>)subscribeToStateChanges:(ARTRealtimeChannelStateCb)cb;

- (BOOL)attach;
- (BOOL)detach;
- (void)releaseChannel; //ARC forbids implementation of release
- (ARTRealtimeChannelState)state;
- (ARTPresenceMap *) presenceMap;

@property (readonly, strong, nonatomic) ARTPresence *presence;

@end


#pragma mark - ARTPresence

@interface ARTPresence : NSObject

- (instancetype) initWithChannel:(ARTRealtimeChannel *) channel;
- (id<ARTCancellable>)get:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)getWithParams:(NSDictionary *) queryParams cb:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)history:(ARTPaginatedResultCallback)callback;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCallback)callback;

- (void)enter:(id)data cb:(ARTStatusCallback)cb;
- (void)update:(id)data cb:(ARTStatusCallback)cb;
- (void)leave:(id) data cb:(ARTStatusCallback)cb;


- (void)enterClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb;
- (void)updateClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb;
- (void)leaveClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb;
- (BOOL)isSyncComplete;

typedef void (^ARTRealtimeChannelPresenceCb)(ARTPresenceMessage *);
- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelPresenceCb)cb;
- (id<ARTSubscription>)subscribe:(ARTPresenceMessageAction) action cb:(ARTRealtimeChannelPresenceCb)cb;
- (void)unsubscribe:(id<ARTSubscription>)subscription;
- (void)unsubscribe:(id<ARTSubscription>)subscription action:(ARTPresenceMessageAction) action;

@end


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
:param options: see {@link io.ably.types.ClientOptions} for options
*/
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options;

- (void)close;
- (BOOL)connect;

- (ARTRealtimeConnectionState)state;
- (NSString *)connectionId;
- (NSString *)connectionKey;
- (NSString *)recoveryKey;
- (ARTAuth *)auth;
- (NSDictionary *) channels;
- (id<ARTCancellable>)time:(void(^)(ARTStatus *status, NSDate *time))cb;

- (ARTErrorInfo *)connectionErrorReason;

typedef void (^ARTRealtimePingCb)(ARTStatus *);
- (void)ping:(ARTRealtimePingCb) cb;

- (id<ARTCancellable>)stats:(ARTStatsQuery *)query callback:(ARTPaginatedResultCallback)callback;

- (ARTRealtimeChannel *)channel:(NSString *)channelName;
- (ARTRealtimeChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams;

@property (readonly, strong, nonatomic) ARTEventEmitter *eventEmitter;
@property (readonly, getter=getLogger) ARTLog *logger;

@end


#pragma mark - ARTEventEmitter

@interface ARTEventEmitter : NSObject

-(instancetype) initWithRealtime:(ARTRealtime *) realtime;

typedef void (^ARTRealtimeConnectionStateCb)(ARTRealtimeConnectionState);
- (id<ARTSubscription>)on:(ARTRealtimeConnectionStateCb)cb;

@end
