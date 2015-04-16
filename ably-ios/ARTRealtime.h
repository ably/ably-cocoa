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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTPaginatedResult.h"

#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

typedef NS_ENUM(NSUInteger, ARTRealtimeChannelState) {
    ARTRealtimeChannelInitialised,
    ARTRealtimeChannelAttaching,
    ARTRealtimeChannelAttached,
    ARTRealtimeChannelDetaching,
    ARTRealtimeChannelDetached,
    ARTRealtimeChannelFailed
};

typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionState) {
    ARTRealtimeInitialized,
    ARTRealtimeConnecting,
    ARTRealtimeConnected,
    ARTRealtimeDisconnected,
    ARTRealtimeSuspended,
    ARTRealtimeClosed,
    ARTRealtimeFailed
};

@protocol ARTSubscription

- (void)unsubscribe;

@end

@interface ARTRealtimeChannel : NSObject



- (void)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb;
- (void)publish:(id)payload cb:(ARTStatusCallback)cb;

- (void)publishPresenceEnter:(id)data cb:(ARTStatusCallback)cb;
- (void)publishPresenceUpdate:(id)data cb:(ARTStatusCallback)cb;
- (void)publishPresenceLeave:(id) data cb:(ARTStatusCallback)cb;

- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;

-(id<ARTCancellable>) presence:(ARTPaginatedResultCb) cb;
-(id<ARTCancellable>) presenceWithParams:(NSDictionary *) queryParams cb:(ARTPaginatedResultCb) cb;
- (id<ARTCancellable>)presenceHistory:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)presenceHistoryWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;


typedef void (^ARTRealtimeChannelMessageCb)(ARTMessage *);
- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelMessageCb)cb;
- (id<ARTSubscription>)subscribeToName:(NSString *)name cb:(ARTRealtimeChannelMessageCb)cb ART_WARN_UNUSED_RESULT;
- (id<ARTSubscription>)subscribeToNames:(NSArray *)names cb:(ARTRealtimeChannelMessageCb)cb ART_WARN_UNUSED_RESULT;

typedef void (^ARTRealtimeChannelPresenceCb)(ARTPresenceMessage *);
- (id<ARTSubscription>)subscribeToPresence:(ARTRealtimeChannelPresenceCb)cb;

typedef void (^ARTRealtimeChannelStateCb)(ARTRealtimeChannelState, ARTStatus);
- (id<ARTSubscription>)subscribeToStateChanges:(ARTRealtimeChannelStateCb)cb;

- (void)attach;
- (void)detach;

@end

@interface ARTRealtime : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithOptions:(ARTOptions *)options;

- (void)close;
- (void)connect;
-(NSString *) getRecovery;

- (id<ARTCancellable>)time:(void(^)(ARTStatus status, NSDate *time))cb;
- (id<ARTCancellable>)stats:(ARTPaginatedResultCb)cb;
- (id<ARTCancellable>)statsWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb;

- (ARTRealtimeChannel *)channel:(NSString *)channelName;
- (ARTRealtimeChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams;

typedef void (^ARTRealtimeConnectionStateCb)(ARTRealtimeConnectionState);
- (id<ARTSubscription>)subscribeToStateChanges:(ARTRealtimeConnectionStateCb)cb;


@end
