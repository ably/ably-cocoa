
//
//  ARTRealtimeChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtimeChannel.h"
#import "ARTEventEmitter.h"

@class ARTPresenceMap;
@class ARTProtocolMessage;

@interface ARTRealtimeChannel ()

@property (readonly, weak, nonatomic) ARTRealtime *realtime;
@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readwrite, strong, nonatomic) NSString *attachSerial;
@property (readonly, strong, nonatomic) NSMutableDictionary *subscriptions;
@property (readonly, strong, nonatomic) NSMutableArray *presenceSubscriptions;
@property (readonly, strong, nonatomic) NSMutableDictionary *presenceDict;
@property (readonly, getter=getClientId) NSString *clientId;
@property (readonly, strong, nonatomic) __GENERIC(ARTEventEmitter, NSNumber *, ARTErrorInfo *) *statesEventEmitter;
@property (readonly, strong, nonatomic) __GENERIC(ARTEventEmitter, NSString *, ARTMessage *) *messagesEventEmitter;
@property (readwrite, strong, nonatomic) ARTPresenceMap *presenceMap;
@property (readwrite, assign, nonatomic) ARTPresenceAction lastPresenceAction;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options;
+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options;

@end

@interface ARTRealtimeChannel (Private)

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status;

- (void)onChannelMessage:(ARTProtocolMessage *)message;
- (void)publishPresence:(ARTPresenceMessage *)pm cb:(ARTStatusCallback)cb;
- (void)publishProtocolMessage:(ARTProtocolMessage *)pm cb:(ARTStatusCallback)cb;

- (void)setAttached:(ARTProtocolMessage *)message;
- (void)setDetached:(ARTProtocolMessage *)message;
- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onPresence:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)error;

- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)status;

- (void)setSuspended:(ARTStatus *)error;
- (void)setFailed:(ARTStatus *)error;
- (void)throwOnDisconnectedOrFailed;

- (void)broadcastPresence:(ARTPresenceMessage *)pm;
- (void)detachChannel:(ARTStatus *) error;

- (void)requestContinueSync;

- (void)releaseChannel;

@end
