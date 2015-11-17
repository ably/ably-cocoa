//
//  ARTRealtimePresence.m
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTRealtimePresence.h"

#import "ARTRealtime.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTPresenceMap.h"
#import "ARTPresenceMessage.h"
#import "ARTRealtimeChannelSubscription.h"

@implementation ARTRealtimePresence

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel {
    return [super initWithChannel:channel];
}

- (ARTRealtimeChannel *)channel {
    return (ARTRealtimeChannel *)super.channel;
}

- (void)get:(void (^)(ARTPaginatedResult *result, NSError *error))callback {
    [[self channel] throwOnDisconnectedOrFailed];
    [super get:callback];
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult *result, NSError *error))callback {
    [[self channel] throwOnDisconnectedOrFailed];
    [super history:query callback:callback];
}

- (void)enter:(id)data cb:(ARTStatusCallback)cb {
    [self enterClient:[self channel].clientId data:data cb:cb];
}

- (void)enterClient:(NSString *)clientId data:(id)data cb:(ARTStatusCallback)cb {
    if(!clientId) {
        [NSException raise:@"Cannot publish presence without a clientId" format:@""];
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceEnter;
    msg.clientId = clientId;
    if(data) {
        msg.payload = [ARTPayload payloadWithPayload:data encoding:@""];
    }

    msg.connectionId = [self channel].realtime.connectionId;
    [[self channel] publishPresence:msg cb:cb];
}

- (void)update:(id)data cb:(ARTStatusCallback)cb {
    [self updateClient:[self channel].clientId data:data cb:cb];
}

- (void)updateClient:(NSString *)clientId data:(id)data cb:(ARTStatusCallback)cb {
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
    msg.connectionId = [self channel].realtime.connectionId;

    [[self channel] publishPresence:msg cb:cb];
}

- (void)leave:(id) data cb:(ARTStatusCallback)cb {
    [self leaveClient:[self channel].clientId data:data cb:cb];
}

- (void) leaveClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb {

    if([clientId isEqualToString:[self channel].clientId]) {
        if([self channel].lastPresenceAction != ARTPresenceEnter && [self channel].lastPresenceAction != ARTPresenceUpdate) {
            [NSException raise:@"Cannot leave a channel before you've entered it" format:@""];
        }
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceLeave;

    if(data) {
        msg.payload= [ARTPayload payloadWithPayload:data encoding:@""];
    }
    msg.clientId = clientId;
    msg.connectionId = [self channel].realtime.connectionId;
    if(!msg.clientId) {
        cb([ARTStatus state:ARTStateNoClientId]);
        return;
    }
    [[self channel] publishPresence:msg cb:cb];
}

- (BOOL)isSyncComplete {
    return [[self channel].presenceMap isSyncComplete];
}

- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelPresenceCb)cb {
    ARTRealtimeChannelPresenceSubscription *subscription = [[ARTRealtimeChannelPresenceSubscription alloc] initWithChannel:[self channel] cb:cb];
    [[self channel].presenceSubscriptions addObject:subscription];
    [[self channel] attach];
    return subscription;
}

- (id<ARTSubscription>)subscribe:(ARTPresenceAction)action cb:(ARTRealtimeChannelPresenceCb)cb {
    ARTRealtimeChannelPresenceSubscription *subscription = (ARTRealtimeChannelPresenceSubscription *) [self subscribe:cb];
    [subscription excludeAllActionsExcept:action];
    return subscription;
}

- (void)unsubscribe:(id<ARTSubscription>)subscription action:(ARTPresenceAction) action {
    ARTRealtimeChannelPresenceSubscription * s = (ARTRealtimeChannelPresenceSubscription *)subscription;
    [s excludeAction:action];
}

- (void)unsubscribe:(ARTRealtimeChannelPresenceSubscription *)subscription {
    ARTRealtimeChannelPresenceSubscription *s = (ARTRealtimeChannelPresenceSubscription *)subscription;
    [[self channel].presenceSubscriptions removeObject:s];
}

@end
