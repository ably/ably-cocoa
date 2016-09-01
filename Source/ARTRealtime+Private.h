//
//  ARTRealtime+Private.h
//  ably-ios
//
//  Created by vic on 24/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtime.h"
#import "ARTEventEmitter.h"
#import "ARTTypes.h"
#import "ARTQueuedMessage.h"
#import "ARTProtocolMessage.h"
#import "ARTReachability.h"

#import "ARTRealtimeTransport.h"

@class ARTRest;
@class ARTErrorInfo;
@class ARTProtocolMessage;
@class ARTConnection;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRealtime () <ARTRealtimeTransportDelegate>

@property (readonly, strong, nonatomic) __GENERIC(ARTEventEmitter, NSNumber *, ARTConnectionStateChange *) *internalEventEmitter;
@property (readonly, strong, nonatomic) __GENERIC(ARTEventEmitter, NSNull *, NSNull *) *connectedEventEmitter;

+ (NSString *)protocolStr:(ARTProtocolMessageAction)action;

// State properties
- (BOOL)shouldSendEvents;
- (BOOL)shouldQueueEvents;
- (ARTStatus *)defaultError;

// Message sending
- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)error;

@end

/// ARTRealtime private methods that are used for whitebox testing.
@interface ARTRealtime ()

@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readonly, getter=getTransport) id<ARTRealtimeTransport> transport;
@property (readonly, strong, nonatomic, art_nonnull) id<ARTReachability> reachability;
@property (readonly, getter=getLogger) ARTLog *logger;

/// Current protocol `msgSerial`. Starts at zero.
@property (readwrite, assign, nonatomic) int64_t msgSerial;

/// List of queued messages on a connection in the disconnected or connecting states.
@property (readwrite, strong, nonatomic) __GENERIC(NSMutableArray, ARTQueuedMessage*) *queuedMessages;

/// List of pending messages waiting for ACK/NACK action to confirm the success receipt and acceptance.
@property (readonly, strong, nonatomic) __GENERIC(NSMutableArray, ARTQueuedMessage*) *pendingMessages;

/// First `msgSerial` pending message.
@property (readwrite, assign, nonatomic) int64_t pendingMessageStartSerial;

/// Client is trying to resume the last connection
@property (readwrite, assign, nonatomic) BOOL resuming;

@property (readonly, getter=getClientOptions) ARTClientOptions *options;

@end

@interface ARTRealtime (Private)

- (BOOL)isActive;

// Transport Events
- (void)onHeartbeat;
- (void)onConnected:(ARTProtocolMessage *)message;
- (void)onDisconnected;
- (void)onClosed;
- (void)onSuspended;
- (void)onError:(ARTProtocolMessage *)message;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message;

- (void)setTransportClass:(Class)transportClass;
- (void)setReachabilityClass:(Class __art_nullable)reachabilityClass;

// Message sending
- (void)send:(ARTProtocolMessage *)msg callback:(art_nullable void (^)(ARTStatus *))cb;

@end

ART_ASSUME_NONNULL_END
