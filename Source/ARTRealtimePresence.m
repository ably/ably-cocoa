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
#import "ARTStatus.h"
#import "ARTPresence+Private.h"

@implementation ARTRealtimePresenceQuery

- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    self = [super initWithLimit:limit clientId:clientId connectionId:connectionId];
    if (self) {
        _waitForSync = true;
    }
    return self;
}

@end

@implementation ARTRealtimePresence

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel {
    return [super initWithChannel:channel];
}

- (ARTRealtimeChannel *)channel {
    return (ARTRealtimeChannel *)super.channel;
}

- (void)get:(ARTRealtimePresenceQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> * _Nullable, NSError * _Nullable))callback {
    [[self channel] throwOnDisconnectedOrFailed];
    [super get:query callback:callback];
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, NSError *))callback {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, NSError *))callback error:(NSError **)errorPtr {
    return [super history:query callback:callback error:errorPtr];
}

- (void)enter:(id)data {
    [self enter:data callback:nil];
}

- (void)enter:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    [self enterClient:[self channel].clientId data:data callback:cb];
}

- (void)enterClient:(NSString *)clientId data:(id)data {
    [self enterClient:clientId data:data callback:nil];
}

- (void)enterClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if(!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceEnter;
    msg.clientId = clientId;
    msg.data = data;

    msg.connectionId = [self channel].realtime.connection.id;
    [[self channel] publishPresence:msg callback:cb];
}

- (void)update:(id)data {
    [self update:data callback:nil];
}

- (void)update:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    [self updateClient:[self channel].clientId data:data callback:cb];
}

- (void)updateClient:(NSString *)clientId data:(id)data {
    [self updateClient:clientId data:data callback:nil];
}

- (void)updateClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceUpdate;
    msg.clientId = clientId;
    msg.data = data;
    msg.connectionId = [self channel].realtime.connection.id;

    [[self channel] publishPresence:msg callback:cb];
}

- (void)leave:(id)data {
    [self leave:data callback:nil];
}

- (void)leave:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    [self leaveClient:[self channel].clientId data:data callback:cb];
}

- (void)leaveClient:(NSString *)clientId data:(id)data {
    [self leaveClient:clientId data:data callback:nil];
}

- (void)leaveClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
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
    [[self channel] publishPresence:msg callback:cb];
}

- (BOOL)isSyncComplete {
    return [[self channel].presenceMap isSyncComplete];
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribe:(void (^)(ARTPresenceMessage * _Nonnull))callback {
    [[self channel] attach];
    return [[self channel].presenceEventEmitter on:callback];
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribe:(ARTPresenceAction)action callback:(void (^)(ARTPresenceMessage * _Nonnull))cb {
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
