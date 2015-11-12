//
//  ARTPresence.m
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPresence.h"

#import "ARTLog.h"
#import "ARTRealtime.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTPresenceMap.h"
#import "ARTStatus.h"
#import "ARTRealtimeChannelSubscription.h"
#import "ARTDataQuery+Private.h"
#import "ARTRest.h"
#import "ARTAuth.h"

@interface ARTPresence ()

@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;

@end

@implementation ARTPresence

- (instancetype) initWithChannel:(ARTRealtimeChannel *) channel {
    if (self = [super init]) {
        _channel = channel;
    }
    return self;
}

- (void)get:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *result, NSError *error))callback {
    [self.channel throwOnDisconnectedOrFailed];
    [self.channel.presence get:callback];
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *result, NSError *error))callback {
    [self.channel throwOnDisconnectedOrFailed];
    [self.channel.presence history:query callback:callback];
}

- (void)enter:(id)data cb:(ARTStatusCallback)cb {
    [self enterClient:self.channel.clientId data:data cb:cb];
}

- (void)enterClient:(NSString *)clientId data:(id)data cb:(ARTStatusCallback)cb {
    if (!clientId) {
        [NSException raise:@"Cannot publish presence without a clientId" format:@""];
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceEnter;
    msg.clientId = clientId;
    if(data) {
        msg.payload = [ARTPayload payloadWithPayload:data encoding:@""];
    }
    
    msg.connectionId = self.channel.realtime.connectionId;
    [self.channel publishPresence:msg cb:cb];
}

- (void)update:(id)data cb:(ARTStatusCallback)cb {
    [self updateClient:self.channel.clientId data:data cb:cb];
}

- (void)updateClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceUpdate;
    msg.clientId = clientId;
    if(!msg.clientId) {
        cb([ARTStatus state:ARTStateNoClientId]);
        return;
    }
    if(data) {
        msg.payload = [ARTPayload payloadWithPayload:data encoding:@""];
    }
    msg.connectionId = self.channel.realtime.connectionId;
    
    [self.channel publishPresence:msg cb:cb];
    
}

- (void)leave:(id) data cb:(ARTStatusCallback)cb {
    [self leaveClient:self.channel.clientId data:data cb:cb];
}

- (void) leaveClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb {
    
    if([clientId isEqualToString:self.channel.clientId]) {
        if(self.channel.lastPresenceAction != ARTPresenceEnter && self.channel.lastPresenceAction != ARTPresenceUpdate) {
            [NSException raise:@"Cannot leave a channel before you've entered it" format:@""];
        }
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceLeave;
    
    if(data) {
        msg.payload= [ARTPayload payloadWithPayload:data encoding:@""];
    }
    msg.clientId = clientId;
    msg.connectionId = self.channel.realtime.connectionId;
    if(!msg.clientId) {
        cb([ARTStatus state:ARTStateNoClientId]);
        return;
    }
    [self.channel publishPresence:msg cb:cb];
    
}

- (BOOL)isSyncComplete {
    return [self.channel.presenceMap isSyncComplete];
}

- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelPresenceCb)cb {
    ARTRealtimeChannelPresenceSubscription *subscription = [[ARTRealtimeChannelPresenceSubscription alloc] initWithChannel:self.channel cb:cb];
    [self.channel.presenceSubscriptions addObject:subscription];
    [self.channel attach];
    return subscription;
}

- (id<ARTSubscription>)subscribe:(ARTPresenceAction) action cb:(ARTRealtimeChannelPresenceCb)cb {
    ARTRealtimeChannelPresenceSubscription *subscription = (ARTRealtimeChannelPresenceSubscription *) [self subscribe:cb];
    [subscription excludedActions];
    //[subscription excludeAllActionsExcept:action];
    return subscription;
}

- (void)unsubscribe:(id<ARTSubscription>)subscription action:(ARTPresenceAction) action {
    ARTRealtimeChannelPresenceSubscription * s = (ARTRealtimeChannelPresenceSubscription *) subscription;
    [s excludedActions];
    //[s excludeAction:action];
}

- (void)unsubscribe:(ARTRealtimeChannelPresenceSubscription *)subscription {
    ARTRealtimeChannelPresenceSubscription *s = (ARTRealtimeChannelPresenceSubscription *) subscription;
    [self.channel.presenceSubscriptions removeObject:s];
}

@end
