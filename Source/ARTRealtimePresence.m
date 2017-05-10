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
ART_TRY_OR_MOVE_TO_FAILED_START(channel.realtime) {
    if (self = [super init]) {
        _channel = channel;
    }
    return self;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)get:(void (^)(NSArray<ARTPresenceMessage *> *, ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self get:[[ARTRealtimePresenceQuery alloc] init] callback:callback];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)get:(ARTRealtimePresenceQuery *)query callback:(void (^)(NSArray<ARTPresenceMessage *> *, ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if (callback) {
        void (^userCallback)(NSArray<ARTPresenceMessage *> *, ARTErrorInfo *) = callback;
        callback = ^(NSArray<ARTPresenceMessage *> *m, ARTErrorInfo *e) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(m, e);
        };
    }

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
            return;
        }
        if (_channel.presenceMap.syncInProgress && query.waitForSync) {
            [_channel.presenceMap onceSyncEnds:^(NSArray<ARTPresenceMessage *> *members) {
                callback(members, nil);
            }];
            [_channel.presenceMap onceSyncFails:^(ARTErrorInfo *error) {
                callback(nil, error);
            }];
        } else {
            callback(_channel.presenceMap.members.allValues, nil);
        }
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
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
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)enter:(id)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self enter:data callback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)enter:(id)data callback:(void (^)(ARTErrorInfo *))cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = cb;
        cb = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self enterAfterChecks:nil data:data callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)enterClient:(NSString *)clientId data:(id)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self enterClient:clientId data:data callback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)enterClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = cb;
        cb = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if(!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self enterAfterChecks:clientId data:data callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)enterAfterChecks:(NSString *__art_nullable)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceEnter;
    msg.clientId = clientId;
    msg.data = data;

    msg.connectionId = _channel.realtime.connection.id;
    [_channel publishPresence:msg callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)update:(id)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self update:data callback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)update:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = cb;
        cb = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self updateAfterChecks:nil data:data callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)updateClient:(NSString *)clientId data:(id)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self updateClient:clientId data:data callback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)updateClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = cb;
        cb = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if (!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self updateAfterChecks:clientId data:data callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)updateAfterChecks:(NSString *__art_nullable)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceUpdate;
    msg.clientId = clientId;
    msg.data = data;
    msg.connectionId = _channel.realtime.connection.id;

    [_channel publishPresence:msg callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)leave:(id)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self leave:data callback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)leave:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = cb;
        cb = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if (!_channel.clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self leaveAfterChecks:nil data:data callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)leaveClient:(NSString *)clientId data:(id)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [self leaveClient:clientId data:data callback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)leaveClient:(NSString *)clientId data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = cb;
        cb = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if (!clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    [self leaveAfterChecks:clientId data:data callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)leaveAfterChecks:(NSString *__art_nullable)clientId data:(id)data callback:(void (^)(ARTErrorInfo *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if (!clientId || [clientId isEqualToString:_channel.clientId]) {
        if(_channel.lastPresenceAction != ARTPresenceEnter && _channel.lastPresenceAction != ARTPresenceUpdate) {
            [ARTException raise:@"Cannot leave a channel before you've entered it" format:@""];
        }
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceLeave;
    msg.data = data;
    msg.clientId = clientId;
    msg.connectionId = _channel.realtime.connection.id;
    [_channel publishPresence:msg callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)getSyncComplete {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    return _channel.presenceMap.syncComplete;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribe:(void (^)(ARTPresenceMessage * _Nonnull))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    return [self subscribeWithAttachCallback:nil callback:callback];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribeWithAttachCallback:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTPresenceMessage * _Nonnull))cb {
    if (cb) {
        void (^userCallback)(ARTPresenceMessage *__art_nullable m) = cb;
        cb = ^(ARTPresenceMessage *__art_nullable m) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(m);
        };
    }
    if (onAttach) {
        void (^userOnAttach)(ARTErrorInfo *__art_nullable m) = onAttach;
        onAttach = ^(ARTErrorInfo *__art_nullable m) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userOnAttach(m);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if (_channel.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [_channel attach:onAttach];
    return [_channel.presenceEventEmitter on:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribe:(ARTPresenceAction)action callback:(void (^)(ARTPresenceMessage * _Nonnull))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    return [self subscribe:action onAttach:nil callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribe:(ARTPresenceAction)action onAttach:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTPresenceMessage * _Nonnull))cb {
    if (cb) {
        void (^userCallback)(ARTPresenceMessage *__art_nullable m) = cb;
        cb = ^(ARTPresenceMessage *__art_nullable m) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userCallback(m);
        };
    }
    if (onAttach) {
        void (^userOnAttach)(ARTErrorInfo *__art_nullable m) = onAttach;
        onAttach = ^(ARTErrorInfo *__art_nullable m) {
            ART_EXITING_ABLY_CODE(_channel.realtime.rest);
            userOnAttach(m);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    if (_channel.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [_channel attach:onAttach];
    return [_channel.presenceEventEmitter on:[ARTEvent newWithPresenceAction:action] callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)unsubscribe {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [_channel.presenceEventEmitter off];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)unsubscribe:(ARTEventListener *)listener {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [_channel.presenceEventEmitter off:listener];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener *)listener {
ART_TRY_OR_MOVE_TO_FAILED_START(_channel.realtime) {
    [_channel.presenceEventEmitter off:[ARTEvent newWithPresenceAction:action] listener:listener];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

@end
