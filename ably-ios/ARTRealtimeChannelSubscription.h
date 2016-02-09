//
//  ARTRealtimeChannelSubscription.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
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

- (void)excludeAction:(ARTPresenceAction)action;
- (void)excludeAllActionsExcept:(ARTPresenceAction)action;

- (void)unsubscribe;

@end


@interface ARTRealtimeChannelStateSubscription : NSObject <ARTSubscription>

@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;
@property (readonly, strong, nonatomic) ARTRealtimeChannelStateCb cb;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelStateCb)cb;

- (void)unsubscribe;

@end
