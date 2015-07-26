//
//  ARTRealtime.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTStatus.h"
#import "ARTTypes.h"
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTPaginatedResult.h"


#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

@class ARTPresenceMap;
@class ARTRealtimeChannelPresenceSubscription;
@class ARTEventEmitter;

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

@protocol ARTSubscription

- (void)unsubscribe;

@end

@class ARTPresence;
@interface ARTRealtimeChannel : NSObject

- (void)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb;
- (void)publish:(id)payload cb:(ARTStatusCallback)cb;

- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;



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

@interface ARTPresence : NSObject
- (instancetype) initWithChannel:(ARTRealtimeChannel *) channel;
- (id<ARTCancellable>)get:(ARTPaginatedResultCb) cb;
- (id<ARTCancellable>)getWithParams:(NSDictionary *) queryParams cb:(ARTPaginatedResultCb) cb;
- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;

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


@interface ARTRealtime : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithKey:(NSString *) key;
- (instancetype)initWithOptions:(ARTClientOptions *) options;

- (void) close;
- (BOOL) connect;

- (ARTRealtimeConnectionState)state;
- (NSString *)connectionId;
- (NSString *)connectionKey;
- (NSString *)recoveryKey;
- (ARTAuth *) auth;
- (NSDictionary *) channels;
- (id<ARTCancellable>)time:(void(^)(ARTStatus *status, NSDate *time))cb;

- (ARTErrorInfo *)connectionErrorReason;

typedef void (^ARTRealtimePingCb)(ARTStatus *);
- (void)ping:(ARTRealtimePingCb) cb;
- (id<ARTCancellable>)stats:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)statsWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;

- (ARTRealtimeChannel *)channel:(NSString *)channelName;
- (ARTRealtimeChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams;



@property (nonatomic, weak) ARTLog * logger;
@property (readonly, strong, nonatomic) ARTEventEmitter *eventEmitter;

@end

@interface ARTEventEmitter : NSObject
-(instancetype) initWithRealtime:(ARTRealtime *) realtime;

typedef void (^ARTRealtimeConnectionStateCb)(ARTRealtimeConnectionState);
- (id<ARTSubscription>)on:(ARTRealtimeConnectionStateCb)cb;

@end