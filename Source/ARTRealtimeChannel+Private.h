
//
//  ARTRealtimeChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRestChannel.h"
#import "ARTRealtimeChannel.h"
#import "ARTPresenceMap.h"
#import "ARTEventEmitter.h"

@class ARTProtocolMessage;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannel () <ARTPresenceMapDelegate>

@property (readonly, weak, nonatomic) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) ARTRestChannel *restChannel;
@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readwrite, strong, nonatomic, art_nullable) NSString *attachSerial;
@property (readonly, getter=getClientId) NSString *clientId;
@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTChannelStateChange *> *internalEventEmitter;
@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTChannelStateChange *> *statesEventEmitter;
@property (readonly, strong, nonatomic) ARTEventEmitter<id<ARTEventIdentification>, ARTMessage *> *messagesEventEmitter;
@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTPresenceMessage *> *presenceEventEmitter;
@property (readwrite, strong, nonatomic) ARTPresenceMap *presenceMap;
@property (readwrite, assign, nonatomic) ARTPresenceAction lastPresenceAction;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options;
+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options;

- (bool)isLastChannelSerial:(NSString *)channelSerial;

@end

@interface ARTRealtimeChannel (Private)

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status;

- (void)onChannelMessage:(ARTProtocolMessage *)message;
- (void)publishPresence:(ARTPresenceMessage *)pm callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;
- (void)publishProtocolMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb;

- (void)setAttached:(ARTProtocolMessage *)message;
- (void)setDetached:(ARTProtocolMessage *)message;

- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onPresence:(ARTProtocolMessage *)message;
- (void)onSync:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)error;

- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)status;
- (void)sendMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb;

- (void)setSuspended:(ARTStatus *)status;
- (void)setFailed:(ARTStatus *)status;
- (void)throwOnDisconnectedOrFailed;

- (void)broadcastPresence:(ARTPresenceMessage *)pm;
- (void)detachChannel:(ARTStatus *)status;

- (void)requestContinueSync;

@end

ART_ASSUME_NONNULL_END
