//
//  ARTRealtimeTransport.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ARTRealtimeTransport;

@class ARTProtocolMessage;
@class ARTStatus;
@class ARTErrorInfo;
@class ARTClientOptions;
@class ARTRest;

ART_ASSUME_NONNULL_BEGIN

@protocol ARTRealtimeTransportDelegate

- (void)realtimeTransport:(id<ARTRealtimeTransport>)transport didReceiveMessage:(ARTProtocolMessage *)message;

- (void)realtimeTransportAvailable:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportUnavailable:(id<ARTRealtimeTransport>)transport;

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportNeverConnected:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportRefused:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportTooBig:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withErrorInfo:(ARTErrorInfo *)errorInfo;

@end

@protocol ARTRealtimeTransport

- (instancetype)initWithRest:(ARTRest *)rest options:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial;

@property (readonly, strong, nonatomic) NSString *resumeKey;
@property (readonly, strong, nonatomic) NSNumber *connectionSerial;

@property (readwrite, weak, nonatomic) id<ARTRealtimeTransportDelegate> delegate;
- (void)send:(ARTProtocolMessage *)msg;
- (void)receive:(ARTProtocolMessage *)msg;
- (void)connect;
- (void)connectForcingNewToken:(BOOL)forceNewToken;
- (void)sendClose;
- (void)sendPing;
- (void)close;
- (void)abort:(ARTStatus *)reason;

@end

ART_ASSUME_NONNULL_END
