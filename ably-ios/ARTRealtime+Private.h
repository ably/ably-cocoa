//
//  ARTRealtime+Private.h
//  ably-ios
//
//  Created by vic on 24/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtime.h"

#import "ARTRealtimeTransport.h"

@class ARTRest;
@class ARTProtocolMessage;

/// ARTRealtime private methods that are used for whitebox testing.
@interface ARTRealtime (Private)

@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readwrite, strong, nonatomic) id<ARTRealtimeTransport> transport;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;

// Transport Events
- (void)onHeartbeat:(ARTProtocolMessage *)message;
- (void)onConnected:(ARTProtocolMessage *)message;
- (void)onDisconnected:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)message;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message;

- (void)onSuspended;

- (int64_t)connectionSerial;

- (void)transition:(ARTRealtimeConnectionState)state;

@end
