//
//  ARTRealtimePresence.h
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRestPresence.h"

@class ARTRealtimeChannel;

@interface ARTRealtimePresence : ARTRestPresence

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel;

- (void)enter:(id)data cb:(ARTStatusCallback)cb;
- (void)update:(id)data cb:(ARTStatusCallback)cb;
- (void)leave:(id)data cb:(ARTStatusCallback)cb;

- (void)enterClient:(NSString *)clientId data:(id)data cb:(ARTStatusCallback)cb;
- (void)updateClient:(NSString *)clientId data:(id)data cb:(ARTStatusCallback)cb;
- (void)leaveClient:(NSString *)clientId data:(id)data cb:(ARTStatusCallback)cb;
- (BOOL)isSyncComplete;

- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelPresenceCb)cb;
- (id<ARTSubscription>)subscribe:(ARTPresenceAction)action cb:(ARTRealtimeChannelPresenceCb)cb;
- (void)unsubscribe:(id<ARTSubscription>)subscription;
- (void)unsubscribe:(id<ARTSubscription>)subscription action:(ARTPresenceAction)action;

@end
