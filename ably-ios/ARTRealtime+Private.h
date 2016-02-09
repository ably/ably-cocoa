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

#import "ARTRealtimeTransport.h"

@class ARTRest;
@class ARTErrorInfo;
@class ARTProtocolMessage;
@class ARTConnection;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRealtime ()

@property (readonly, strong, nonatomic) __GENERIC(ARTEventEmitter, NSNumber *, ARTConnectionStateChange *) *eventEmitter;

@end

/// ARTRealtime private methods that are used for whitebox testing.
@interface ARTRealtime (Private)

@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readonly, getter=getTransport) id<ARTRealtimeTransport> transport;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;

// Transport Events
- (void)onHeartbeat;
- (void)onConnected:(ARTProtocolMessage *)message;
- (void)onDisconnected;
- (void)onSuspended;
- (void)onError:(ARTProtocolMessage *)message;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message;

- (int64_t)connectionSerial;

// FIXME: Connection should manage the transport
- (void)setTransportClass:(Class)transportClass;
- (ARTConnection *)connection;

- (void)resetEventEmitter;

@end

ART_ASSUME_NONNULL_END
