//
//  ARTRealtimeChannelSubscription.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtimeChannelSubscription.h"

#import "ARTRealtime.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimePresence.h"

#pragma mark - ARTRealtimeChannelPresenceSubscription

@implementation ARTRealtimeChannelPresenceSubscription

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelPresenceCb)cb {
    self = [super init];
    if (self) {
        _channel = channel;
        _cb = cb;
        _action = ARTPresenceLast;
        _excludedActions = [NSMutableSet set];
    }
    return self;
}

- (void)excludeAction:(ARTPresenceAction)action {
    [_excludedActions addObject:[NSNumber numberWithInt:(int) action]];
}

- (void)excludeAllActionsExcept:(ARTPresenceAction)action {
    for(int i=0; i<(int) ARTPresenceLast; i++) {
        if(i != (int) action) {
            [_excludedActions addObject:[NSNumber numberWithInt:(int) i]];
        }
    }
}

- (void)includeAction:(ARTPresenceAction) action {
    [_excludedActions removeObject:[NSNumber numberWithInt:(int) action]];
}

- (void)unsubscribe {
    [self.channel.presence unsubscribe:self];
}

@end
