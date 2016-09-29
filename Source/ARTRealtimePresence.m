//
//  ARTRealtimePresence.m
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTRealtimePresence+Private.h"

#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTPresenceMap.h"
#import "ARTPresenceMessage.h"
#import "ARTStatus.h"
#import "ARTPresence+Private.h"
#import "ARTDataQuery+Private.h"

#pragma mark - ARTRealtimePresenceQuery

@implementation ARTRealtimePresenceQuery

- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    self = [super initWithLimit:limit clientId:clientId connectionId:connectionId];
    if (self) {
        _waitForSync = true;
    }
    return self;
}

@end

#pragma mark - ARTRealtimePresence

@implementation ARTRealtimePresence {
    __weak ARTRealtimeChannel *_channel;
}

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel {
    if (self = [super init]) {
        _channel = channel;
    }
    return self;
}

- (void)get:(void (^)(NSArray<ARTPresenceMessage *> *, ARTErrorInfo *))callback {
    [self get:[[ARTRealtimePresenceQuery alloc] init] callback:callback];
}

- (void)get:(ARTRealtimePresenceQuery *)query callback:(void (^)(NSArray<ARTPresenceMessage *> *, ARTErrorInfo *))callback {
    [_channel throwOnDisconnectedOrFailed];

    switch (_channel.state) {
        case ARTRealtimeChannelFailed:
        case ARTRealtimeChannelDetached:
            if (callback) callback(nil, [ARTErrorInfo createWithCode:0 message:@"invalid channel state"]);
            return;
        default:
            break;
    }

    [_channel attach:^(ARTErrorInfo *error) {
        if (error) {
            callback(nil, error);
        } else if (query.waitForSync) {
            [_channel.presenceMap onceSyncEnds:^(NSArray<ARTPresenceMessage *> *members) {
                callback(members, nil);
            }];
        } else {
            callback(_channel.presenceMap.members.allValues, nil);
        }
    }];
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
    query.realtimeChannel = _channel;
    @try {
        return [_channel.restChannel.presence history:query callback:callback error:errorPtr];
    }
    @catch (NSError *error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return false;
    }
}

- (void)enter:(id)data {
    [self enter:data callback:nil];
}

- (void)enter:(id)data callback:(void (^)(ARTErrorInfo *))cb {
    [self enterAfterChecks:nil data:data callback:cb];
}

- (void)enterClient:(NSString *)clientId data:(id)data {
    [self enterClient:clientId data:data callback:nil];
}

- (void)enterClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
    if(!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self enterAfterChecks:clientId data:data callback:cb];
}

- (void)enterAfterChecks:(NSString *__art_nullable)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceEnter;
    msg.clientId = clientId;
    msg.data = data;

    msg.connectionId = _channel.realtime.connection.id;
    [_channel publishPresence:msg callback:cb];
}

- (void)update:(id)data {
    [self update:data callback:nil];
}

- (void)update:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    [self updateAfterChecks:nil data:data callback:cb];
}

- (void)updateClient:(NSString *)clientId data:(id)data {
    [self updateClient:clientId data:data callback:nil];
}

- (void)updateClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self updateAfterChecks:clientId data:data callback:cb];
}

- (void)updateAfterChecks:(NSString *__art_nullable)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceUpdate;
    msg.clientId = clientId;
    msg.data = data;
    msg.connectionId = _channel.realtime.connection.id;

    [_channel publishPresence:msg callback:cb];
}

- (void)leave:(id)data {
    [self leave:data callback:nil];
}

- (void)leave:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (!_channel.clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self leaveAfterChecks:nil data:data callback:cb];
}

- (void)leaveClient:(NSString *)clientId data:(id)data {
    [self leaveClient:clientId data:data callback:nil];
}

- (void)leaveClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self leaveAfterChecks:clientId data:data callback:cb];
}

- (void)leaveAfterChecks:(NSString *__art_nullable)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
    if (!clientId || [clientId isEqualToString:_channel.clientId]) {
        if(_channel.lastPresenceAction != ARTPresenceEnter && _channel.lastPresenceAction != ARTPresenceUpdate) {
            [NSException raise:@"Cannot leave a channel before you've entered it" format:@""];
        }
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceLeave;
    msg.data = data;
    msg.clientId = clientId;
    msg.connectionId = _channel.realtime.connection.id;
    [_channel publishPresence:msg callback:cb];
}

- (BOOL)getSyncComplete {
    return _channel.presenceMap.syncComplete;
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribe:(void (^)(ARTPresenceMessage * _Nonnull))callback {
    return [self subscribeWithAttachCallback:nil callback:callback];
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribeWithAttachCallback:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTPresenceMessage * _Nonnull))cb {
    if (_channel.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [_channel attach:onAttach];
    return [_channel.presenceEventEmitter on:cb];
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribe:(ARTPresenceAction)action callback:(void (^)(ARTPresenceMessage * _Nonnull))cb {
    return [self subscribe:action onAttach:nil callback:cb];
}

- (ARTEventListener<ARTPresenceMessage *> *)subscribe:(ARTPresenceAction)action onAttach:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTPresenceMessage * _Nonnull))cb {
    if (_channel.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [_channel attach:onAttach];
    return [_channel.presenceEventEmitter on:[NSNumber numberWithUnsignedInteger:action] callback:cb];
}

- (void)unsubscribe {
    [_channel.presenceEventEmitter off];
}

- (void)unsubscribe:(ARTEventListener<ARTPresenceMessage *> *)listener {
    [_channel.presenceEventEmitter off:listener];
}

- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener<ARTPresenceMessage *> *)listener {
    [_channel.presenceEventEmitter off:[NSNumber numberWithUnsignedInteger:action] listener:listener];
}

@end
