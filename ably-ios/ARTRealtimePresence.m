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
#import "ARTStatus.h"
#import "ARTPresence+Private.h"

@implementation ARTRealtimePresence

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel {
    return [super initWithChannel:channel];
}

- (ARTRealtimeChannel *)channel {
    return (ARTRealtimeChannel *)super.channel;
}

- (void)get:(ARTRealtimePresenceQuery *)query cb:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    [[self channel] throwOnDisconnectedOrFailed];
    [super get:query cb:callback];
}

- (NSError *)history:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    NSError *error = [[NSError alloc] init];
    [self historyWithError:&error callback:callback];
    return error;
}

- (NSError *)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    NSError *error = [[NSError alloc] init];
    [self history:query error:&error callback:callback];
    return error;
}

- (BOOL)historyWithError:(NSError *__autoreleasing  _Nullable *)errorPtr callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    return [self history:[[ARTRealtimeHistoryQuery alloc] init] error:errorPtr callback:callback];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query error:(NSError *__autoreleasing  _Nullable *)errorPtr callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    return [super history:query error:errorPtr callback:callback];
}

- (void)enter:(id)data {
    [self enter:data cb:nil];
}

- (void)enter:(id)data cb:(void (^)(ARTErrorInfo * _Nullable))cb {
    [self enterClient:[self channel].clientId data:data cb:cb];
}

- (void)enterClient:(NSString *)clientId data:(id)data {
    [self enterClient:clientId data:data cb:nil];
}

- (void)enterClient:(NSString *)clientId data:(id)data cb:(void (^)(ARTErrorInfo * _Nullable))cb {
    if(!clientId) {
        [NSException raise:@"Cannot publish presence without a clientId" format:@""];
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceEnter;
    msg.clientId = clientId;
    msg.data = data;

    msg.connectionId = [self channel].realtime.connection.id;
    [[self channel] publishPresence:msg cb:cb];
}

- (void)update:(id)data {
    [self update:data cb:nil];
}

- (void)update:(id)data cb:(void (^)(ARTErrorInfo * _Nullable))cb {
    [self updateClient:[self channel].clientId data:data cb:cb];
}

- (void)updateClient:(NSString *)clientId data:(id)data {
    [self updateClient:clientId data:data cb:nil];
}

- (void)updateClient:(NSString *)clientId data:(id)data cb:(void (^)(ARTErrorInfo * _Nullable))cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceUpdate;
    msg.clientId = clientId;
    msg.data = data;
    msg.connectionId = [self channel].realtime.connection.id;

    [[self channel] publishPresence:msg cb:cb];
}

- (void)leave:(id)data {
    [self leave:data cb:nil];
}

- (void)leave:(id)data cb:(void (^)(ARTErrorInfo * _Nullable))cb {
    [self leaveClient:[self channel].clientId data:data cb:cb];
}

- (void)leaveClient:(NSString *)clientId data:(id)data {
    [self leaveClient:clientId data:data cb:nil];
}

- (void)leaveClient:(NSString *)clientId data:(id)data cb:(void (^)(ARTErrorInfo * _Nullable))cb {

    if([clientId isEqualToString:[self channel].clientId]) {
        if([self channel].lastPresenceAction != ARTPresenceEnter && [self channel].lastPresenceAction != ARTPresenceUpdate) {
            [NSException raise:@"Cannot leave a channel before you've entered it" format:@""];
        }
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceLeave;
    msg.data = data;
    msg.clientId = clientId;
    msg.connectionId = [self channel].realtime.connection.id;
    [[self channel] publishPresence:msg cb:cb];
}

- (BOOL)isSyncComplete {
    return [[self channel].presenceMap isSyncComplete];
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribe:(void (^)(ARTPresenceMessage * _Nonnull))cb {
    [[self channel] attach];
    return [[self channel].presenceEventEmitter on:cb];
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribe:(ARTPresenceAction)action cb:(void (^)(ARTPresenceMessage * _Nonnull))cb {
    [[self channel] attach];
    return [[self channel].presenceEventEmitter on:[NSNumber numberWithUnsignedInteger:action] call:cb];
}

- (void)unsubscribe {
    [[self channel].presenceEventEmitter off];
}

- (void)unsubscribe:(ARTEventListener<ARTPresenceMessage *> *)listener {
    [[self channel].presenceEventEmitter off:listener];
}

- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener<ARTPresenceMessage *> *)listener {
    [[self channel].presenceEventEmitter off:[NSNumber numberWithUnsignedInteger:action] listener:listener];
}

@end
