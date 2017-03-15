//
//  ARTRealtimeTransport.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

@protocol ARTRealtimeTransport;

@class ARTProtocolMessage;
@class ARTStatus;
@class ARTErrorInfo;
@class ARTClientOptions;
@class ARTRest;

ART_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARTRealtimeTransportErrorType) {
    ARTRealtimeTransportErrorTypeHostUnreachable,
    ARTRealtimeTransportErrorTypeNoInternet,
    ARTRealtimeTransportErrorTypeTimeout,
    ARTRealtimeTransportErrorTypeBadResponse,
    ARTRealtimeTransportErrorTypeOther
};

typedef NS_ENUM(NSUInteger, ARTRealtimeTransportState) {
    ARTRealtimeTransportStateOpening,
    ARTRealtimeTransportStateOpened,
    ARTRealtimeTransportStateClosing,
    ARTRealtimeTransportStateClosed,
};

@interface ARTRealtimeTransportError : NSObject

@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) ARTRealtimeTransportErrorType type;
@property (nonatomic, assign) NSInteger badResponseCode;
@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithError:(NSError *)error type:(ARTRealtimeTransportErrorType)type url:(NSURL *)url;
- (instancetype)initWithError:(NSError *)error badResponseCode:(NSInteger)badResponseCode url:(NSURL *)url;

- (NSString *)description;

@end

@protocol ARTRealtimeTransportDelegate

- (void)realtimeTransport:(id<ARTRealtimeTransport>)transport didReceiveMessage:(ARTProtocolMessage *)message;

- (void)realtimeTransportAvailable:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportUnavailable:(id<ARTRealtimeTransport>)transport;

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport withError:(art_nullable ARTRealtimeTransportError *)error;
- (void)realtimeTransportNeverConnected:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportRefused:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportTooBig:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error;

@end

@protocol ARTRealtimeTransport

- (instancetype)initWithRest:(ARTRest *)rest options:(ARTClientOptions *)options resumeKey:(nullable NSString *)resumeKey connectionSerial:(nullable NSNumber *)connectionSerial;

@property (readonly, strong, nonatomic) NSString *resumeKey;
@property (readonly, strong, nonatomic) NSNumber *connectionSerial;
@property (readonly, assign, nonatomic) ARTRealtimeTransportState state;
@property (nullable, readwrite, strong, nonatomic) id<ARTRealtimeTransportDelegate> delegate;

- (void)send:(ARTProtocolMessage *)msg;
- (void)receive:(ARTProtocolMessage *)msg;
- (void)connectWithKey:(NSString *)key;
- (void)connectWithToken:(NSString *)token;
- (void)sendClose;
- (void)sendPing;
- (void)close;
- (void)abort:(ARTStatus *)reason;
- (NSString *)host;
- (void)setHost:(NSString *)host;
- (ARTRealtimeTransportState)state;

@end

ART_ASSUME_NONNULL_END
