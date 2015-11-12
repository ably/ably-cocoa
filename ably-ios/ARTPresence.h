//
//  ARTPresence.h
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTPresenceMessage.h"

@protocol ARTSubscription;

@class ARTChannel;
@class ARTPaginatedResult;
@class ARTDataQuery;

ART_ASSUME_NONNULL_BEGIN

/**
 A class that provides access to presence operations and state for the associated Channel.
 */
@interface ARTPresence : NSObject

@property (readonly, getter=getChannel) ARTChannel *channel;

- (instancetype)initWithChannel:(ARTChannel *)channel;

/**
 Get the presence state for one channel
 */
- (void)get:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *__art_nullable result, NSError *__art_nullable error))callback;

/**
 Obtain recent presence history for one channel
 */
- (void)history:(art_nullable ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *__art_nullable result, NSError *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
