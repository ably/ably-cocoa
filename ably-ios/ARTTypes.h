//
//  ARTTypes.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTStatus;
@class ARTHttpResponse;
@class ARTMessage;
@class ARTPresenceMessage;

typedef NS_ENUM(NSUInteger, ARTRealtimeConnectionState) {
    ARTRealtimeInitialized,
    ARTRealtimeConnecting,
    ARTRealtimeConnected,
    ARTRealtimeDisconnected,
    ARTRealtimeSuspended,
    ARTRealtimeClosing,
    ARTRealtimeClosed,
    ARTRealtimeFailed
};

typedef NS_ENUM(NSUInteger, ARTRealtimeChannelState) {
    ARTRealtimeChannelInitialised,
    ARTRealtimeChannelAttaching,
    ARTRealtimeChannelAttached,
    ARTRealtimeChannelDetaching,
    ARTRealtimeChannelDetached,
    ARTRealtimeChannelClosed,
    ARTRealtimeChannelFailed
};

typedef void (^ARTRealtimeChannelMessageCb)(ARTMessage *);

typedef void (^ARTRealtimeChannelStateCb)(ARTRealtimeChannelState, ARTStatus *);

typedef void (^ARTStatusCallback)(ARTStatus *status);

typedef void (^ARTHttpCb)(ARTHttpResponse *response);

typedef void (^ARTErrorCallback)(NSError *error);

typedef void (^ARTRealtimeConnectionStateCb)(ARTRealtimeConnectionState state);

typedef void (^ARTRealtimeChannelPresenceCb)(ARTPresenceMessage *);

// FIXME:
@protocol ARTCancellable

- (void)cancel;

@end

@interface ARTIndirectCancellable : NSObject <ARTCancellable>

@property (readwrite, strong, nonatomic) id<ARTCancellable> cancellable;
@property (readonly, assign, nonatomic) BOOL isCancelled;

- (instancetype)init;
- (instancetype)initWithCancellable:(id<ARTCancellable>)cancellable;
- (void)cancel;

@end
