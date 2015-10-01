//
//  ARTPresence.h
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ably.h"

#import "ARTPresenceMessage.h"

@protocol ARTSubscription;

@class ARTPaginatedResult;
@class ARTDataQuery;
@class ARTRealtimeChannel;

NS_ASSUME_NONNULL_BEGIN

/// Provides access to presence operations and state for the associated Channel
@interface ARTPresence : NSObject

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel;

/// Get the presence state for one channel
- (void)get:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *__nullable result, NSError *__nullable error))callback;

/// Obtain recent presence history for one channel
- (void)history:(nullable ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *__nullable result, NSError *__nullable error))callback;

- (void)enter:(id)data cb:(ARTStatusCallback)cb;
- (void)update:(id)data cb:(ARTStatusCallback)cb;
- (void)leave:(id) data cb:(ARTStatusCallback)cb;

- (void)enterClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb;
- (void)updateClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb;
- (void)leaveClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb;
- (BOOL)isSyncComplete;

- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelPresenceCb)cb;
- (id<ARTSubscription>)subscribe:(ARTPresenceAction)action cb:(ARTRealtimeChannelPresenceCb)cb;
- (void)unsubscribe:(id<ARTSubscription>)subscription;
- (void)unsubscribe:(id<ARTSubscription>)subscription action:(ARTPresenceAction)action;

@end

NS_ASSUME_NONNULL_END
