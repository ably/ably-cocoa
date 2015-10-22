//
//  ARTRealtimeChannel.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"
#import "ARTPresenceMessage.h"

@protocol ARTSubscription;
@protocol ARTPayloadEncoder;

@class ARTChannel;
@class ARTRealtime;
@class ARTDataQuery;
@class ARTPresence;
@class ARTPresenceMap;
@class ARTMessage;
@class ARTPaginatedResult;
@class ARTProtocolMessage;
@class ARTRealtimeChannelSubscription;
@class ARTRealtimeChannelStateSubscription;

@interface ARTRealtimeChannel : NSObject

@property (nonatomic, weak) ARTLog *logger;
@property (readonly, strong, nonatomic) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) NSString *name;
@property (readonly, strong, nonatomic) ARTChannel *restChannel; //FIXME: ?!
@property (readwrite, assign, nonatomic) ARTRealtimeChannelState state;
@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readwrite, strong, nonatomic) NSString *attachSerial;
@property (readonly, strong, nonatomic) NSMutableDictionary *subscriptions;
@property (readonly, strong, nonatomic) NSMutableArray *presenceSubscriptions;
@property (readonly, strong, nonatomic) NSMutableDictionary *presenceDict;
@property (readonly, strong, nonatomic) NSString *clientId;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;
@property (readonly, strong, nonatomic) id<ARTPayloadEncoder> payloadEncoder;
@property (readwrite, strong, nonatomic) ARTPresenceMap * presenceMap;
@property (readwrite, assign, nonatomic) ARTPresenceAction lastPresenceAction;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status;

- (void)onChannelMessage:(ARTProtocolMessage *)message;
- (void)publishMessages:(NSArray *)messages cb:(ARTStatusCallback)cb;
- (void)publishPresence:(ARTPresenceMessage *)pm cb:(ARTStatusCallback)cb;
- (void)publishProtocolMessage:(ARTProtocolMessage *)pm cb:(ARTStatusCallback)cb;

- (void)setAttached:(ARTProtocolMessage *)message;
- (void)setDetached:(ARTProtocolMessage *)message;
- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onPresence:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)error;
- (void)setSuspended:(ARTStatus *)error;

- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)status;

- (void)unsubscribe:(ARTRealtimeChannelSubscription *)subscription;
- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription;

- (void)broadcastPresence:(ARTPresenceMessage *)pm;


- (void)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb;
- (void)publish:(id)payload cb:(ARTStatusCallback)cb;

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTStatus *status, ARTPaginatedResult /* <ARTMessage *> */ *result))callback;

- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelMessageCb)cb;
- (id<ARTSubscription>)subscribeToName:(NSString *)name cb:(ARTRealtimeChannelMessageCb)cb;
- (id<ARTSubscription>)subscribeToNames:(NSArray *)names cb:(ARTRealtimeChannelMessageCb)cb;
- (id<ARTSubscription>)subscribeToStateChanges:(ARTRealtimeChannelStateCb)cb;

- (BOOL)attach;
- (BOOL)detach;

- (void)releaseChannel; //ARC forbids implementation of release
- (ARTRealtimeChannelState)state;
- (ARTPresenceMap *)presenceMap;

@property (readonly, strong, nonatomic) ARTPresence *presence;

@end
