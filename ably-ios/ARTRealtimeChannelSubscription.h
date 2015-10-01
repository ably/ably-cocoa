//
//  ARTRealtimeChannelSubscription.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ably.h"

#import "ARTSubscription.h"
#import "ARTPresenceMessage.h"

@class ARTRealtime;
@class ARTRealtimeChannel;

@interface ARTRealtimeChannelSubscription : NSObject <ARTSubscription>

@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;
@property (readonly, strong, nonatomic) ARTRealtimeChannelMessageCb cb;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelMessageCb)cb;

- (void)unsubscribe;

@end


@interface ARTRealtimeChannelPresenceSubscription : NSObject <ARTSubscription>

@property (readonly, strong, nonatomic) NSMutableSet *excludedActions;
@property (readonly, assign, nonatomic) ARTPresenceAction action;
@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;
@property (readonly, strong, nonatomic) ARTRealtimeChannelPresenceCb cb;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelPresenceCb)cb;

- (void)unsubscribe;

@end


@interface ARTRealtimeChannelStateSubscription : NSObject <ARTSubscription>

@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;
@property (readonly, strong, nonatomic) ARTRealtimeChannelStateCb cb;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelStateCb)cb;

- (void)unsubscribe;

@end


@interface ARTRealtimeConnectionStateSubscription : NSObject <ARTSubscription>

@property (readonly, weak, nonatomic) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) ARTRealtimeConnectionStateCb cb;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime cb:(ARTRealtimeConnectionStateCb)cb;

- (void)unsubscribe;

@end
