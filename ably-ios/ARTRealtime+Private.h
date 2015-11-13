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
@class ARTErrorInfo;
@class ARTProtocolMessage;

ART_ASSUME_NONNULL_BEGIN

/// ARTRealtime private methods that are used for whitebox testing.
@interface ARTRealtime (Private)

@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readwrite, strong, nonatomic) id<ARTRealtimeTransport> transport;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;

// Transport Events
- (void)onHeartbeat:(ARTProtocolMessage *)message;
- (void)onConnected:(ARTProtocolMessage *)message withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;
- (void)onDisconnected:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)message withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;

- (void)onSuspended;

- (int64_t)connectionSerial;

- (void)transition:(ARTRealtimeConnectionState)state;
- (void)transition:(ARTRealtimeConnectionState)state withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;

// FIXME: Connection should manage the transport
- (void)setTransportClass:(Class)transportClass;

@end

ART_ASSUME_NONNULL_END
