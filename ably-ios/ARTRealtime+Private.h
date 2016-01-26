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
@class ARTConnection;

ART_ASSUME_NONNULL_BEGIN

/// ARTRealtime private methods that are used for whitebox testing.
@interface ARTRealtime (Private)

@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readonly, getter=getTransport) id<ARTRealtimeTransport> transport;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;

// Transport Events
- (void)onHeartbeat;
- (void)onConnected:(ARTProtocolMessage *)message withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;
- (void)onDisconnected;
- (void)onSuspended;
- (void)onError:(ARTProtocolMessage *)message withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;

- (int64_t)connectionSerial;

- (void)transition:(ARTRealtimeConnectionState)state;
- (void)transition:(ARTRealtimeConnectionState)state withErrorInfo:(art_nullable ARTErrorInfo *)errorInfo;

// FIXME: Connection should manage the transport
- (void)setTransportClass:(Class)transportClass;
- (ARTConnection *)connection;

@end

ART_ASSUME_NONNULL_END
