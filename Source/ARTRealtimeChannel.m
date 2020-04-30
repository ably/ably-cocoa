//
//  ARTRealtimeChannel.m
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtimeChannel+Private.h"
#import "ARTChannel+Private.h"
#import "ARTDataQuery+Private.h"

#import "ARTRealtime+Private.h"
#import "ARTMessage.h"
#import "ARTBaseMessage+Private.h"
#import "ARTAuth.h"
#import "ARTRealtimePresence+Private.h"
#import "ARTChannel.h"
#import "ARTChannelOptions.h"
#import "ARTRealtimeChannelOptions.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTPresenceMap.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTStatus.h"
#import "ARTDefault.h"
#import "ARTRest.h"
#import "ARTClientOptions.h"
#import "ARTTypes.h"
#import "ARTGCD.h"
#import "ARTConnection+Private.h"
#import "ARTRestChannels+Private.h"
#import "ARTEventEmitter+Private.h"
#if TARGET_OS_IPHONE
#import "ARTPushChannel+Private.h"
#endif

@implementation ARTRealtimeChannel {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRealtimeChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (NSString *)name {
    return _internal.name;
}

- (ARTRealtimeChannelState)state {
    return _internal.state;
}

- (ARTErrorInfo *)errorReason {
    return _internal.errorReason;
}

- (ARTRealtimePresence *)presence {
    return [[ARTRealtimePresence alloc] initWithInternal:_internal.presence queuedDealloc:_dealloc];
}

#if TARGET_OS_IPHONE

- (ARTPushChannel *)push {
    return [[ARTPushChannel alloc] initWithInternal:_internal.push queuedDealloc:_dealloc];
}

#endif

- (void)publish:(nullable NSString *)name data:(nullable id)data {
    [_internal publish:name data:data];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback {
    [_internal publish:name data:data callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId {
    [_internal publish:name data:data clientId:clientId];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback {
    [_internal publish:name data:data clientId:clientId callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras {
    [_internal publish:name data:data extras:extras];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback {
    [_internal publish:name data:data extras:extras callback:callback];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras {
    [_internal publish:name data:data clientId:clientId extras:extras];
}

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback {
    [_internal publish:name data:data clientId:clientId extras:extras callback:callback];
}

- (void)publish:(NSArray<ARTMessage *> *)messages {
    [_internal publish:messages];
}

- (void)publish:(NSArray<ARTMessage *> *)messages callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback {
    [_internal publish:messages callback:callback];
}

- (void)history:(void(^)(ARTPaginatedResult<ARTMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback {
    [_internal history:callback];
}

- (BOOL)exceedMaxSize:(NSArray<ARTBaseMessage *> *)messages {
    return [_internal exceedMaxSize:messages];
}

- (void)attach {
    [_internal attach];
}

- (void)attach:(nullable void (^)(ARTErrorInfo *_Nullable))callback {
    [_internal attach:callback];
}

- (void)detach {
    [_internal detach];
}

- (void)detach:(nullable void (^)(ARTErrorInfo *_Nullable))callback {
    [_internal detach:callback];
}

- (ARTEventListener *_Nullable)subscribe:(void (^)(ARTMessage *message))callback {
    return [_internal subscribe:callback];
}

- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable void (^)(ARTErrorInfo *_Nullable))onAttach callback:(void (^)(ARTMessage *message))cb {
    return [_internal subscribeWithAttachCallback:onAttach callback:cb];
}

- (ARTEventListener *_Nullable)subscribe:(NSString *)name callback:(void (^)(ARTMessage *message))cb {
    return [_internal subscribe:name callback:cb];
}

- (ARTEventListener *_Nullable)subscribe:(NSString *)name onAttach:(nullable void (^)(ARTErrorInfo *_Nullable))onAttach callback:(void (^)(ARTMessage *message))cb {
    return [_internal subscribe:name onAttach:onAttach callback:cb];
}

- (void)unsubscribe {
    [_internal unsubscribe];
}

- (void)unsubscribe:(ARTEventListener *_Nullable)listener {
    [_internal unsubscribe:listener];
}

- (void)unsubscribe:(NSString *)name listener:(ARTEventListener *_Nullable)listener {
    [_internal unsubscribe:name listener:listener];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(void(^)(ARTPaginatedResult<ARTMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal history:query callback:callback error:errorPtr];
}

- (ARTEventListener *)on:(void (^)(ARTChannelStateChange * _Nullable))cb {
    return [_internal on:cb];
}

- (ARTEventListener *)once:(ARTChannelEvent)event callback:(void (^)(ARTChannelStateChange * _Nullable))cb {
    return [_internal once:event callback:cb];
}

- (ARTEventListener *)once:(void (^)(ARTChannelStateChange * _Nullable))cb {
    return [_internal once:cb];
}

- (void)off:(ARTChannelEvent)event listener:(ARTEventListener *)listener {
    [_internal off:event listener:listener];
}

- (void)off:(ARTEventListener *)listener {
    [_internal off:listener];
}

- (void)off {
    [_internal off];
}

- (nonnull ARTEventListener *)on:(ARTChannelEvent)event callback:(nonnull void (^)(ARTChannelStateChange * _Nullable))cb {
    return [_internal on:event callback:cb];
}

- (ARTRealtimeChannelOptions *)getOptions {
    return [_internal getOptions];
}

- (void)setOptions:(ARTRealtimeChannelOptions *_Nullable)options callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb {
    [_internal setOptions:options callback:cb];
}

@end

@interface ARTRealtimeChannelInternal () {
    ARTRealtimePresenceInternal *_realtimePresence;
    #if TARGET_OS_IPHONE
    ARTPushChannelInternal *_pushChannel;
    #endif
    CFRunLoopTimerRef _attachTimer;
    CFRunLoopTimerRef _detachTimer;
    __GENERIC(ARTEventEmitter, ARTEvent *, ARTErrorInfo *) *_attachedEventEmitter;
    __GENERIC(ARTEventEmitter, ARTEvent *, ARTErrorInfo *) *_detachedEventEmitter;
    NSString * _Nullable _lastPayloadMessageId;
    NSString * _Nullable _lastPayloadProtocolMessageChannelSerial;
    BOOL _decodeFailureRecoveryInProgress;
}

@end

@implementation ARTRealtimeChannelInternal {
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
    ARTErrorInfo *_errorReason;
}

- (instancetype)initWithRealtime:(ARTRealtimeInternal *)realtime andName:(NSString *)name withOptions:(ARTRealtimeChannelOptions *)options {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    self = [super initWithName:name andOptions:options rest:realtime.rest];
    if (self) {
        _realtime = realtime;
        _queue = realtime.rest.queue;
        _userQueue = realtime.rest.userQueue;
        _restChannel = [_realtime.rest.channels _getChannel:self.name options:options addPrefix:true];
        _state = ARTRealtimeChannelInitialized;
        _attachSerial = nil;
        _presenceMap = [[ARTPresenceMap alloc] initWithQueue:_queue logger:self.logger];
        _presenceMap.delegate = self;
        _statesEventEmitter = [[ARTPublicEventEmitter alloc] initWithRest:_realtime.rest];
        _messagesEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueues:_queue userQueue:_userQueue];
        _presenceEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_queue];
        _attachedEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_queue];
        _detachedEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_queue];
        _internalEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_queue];
    }
    return self;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

+ (instancetype)channelWithRealtime:(ARTRealtimeInternal *)realtime andName:(NSString *)name withOptions:(ARTRealtimeChannelOptions *)options {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    return [[ARTRealtimeChannelInternal alloc] initWithRealtime:realtime andName:name withOptions:options];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTRealtimeChannelState)state {
    __block ARTRealtimeChannelState ret;
dispatch_sync(_queue, ^{
    ret = [self state_nosync];
});
    return ret;
}

- (ARTErrorInfo *)errorReason {
    __block ARTErrorInfo * ret;
dispatch_sync(_queue, ^{
    ret = [self errorReason_nosync];
});
    return ret;
}

- (ARTRealtimeChannelState)state_nosync {
    return _state;
}

- (ARTErrorInfo *)errorReason_nosync {
    return _errorReason;
}

- (ARTLog *)getLogger {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _realtime.logger;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTRealtimePresenceInternal *)presence {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    if (!_realtimePresence) {
        _realtimePresence = [[ARTRealtimePresenceInternal alloc] initWithChannel:self];
    }
    return _realtimePresence;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

#if TARGET_OS_IPHONE
- (ARTPushChannelInternal *)push {
    if (!_pushChannel) {
        _pushChannel = [[ARTPushChannelInternal alloc] init:self.realtime.rest withChannel:self];
    }
    return _pushChannel;
}
#endif

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

    if (![data isKindOfClass:[NSArray class]]) {
        data = @[data];
    }

dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    if ([data isKindOfClass:[ARTMessage class]]) {
        ARTMessage *message = (ARTMessage *)data;
        if (message.clientId && self->_realtime.rest.auth.clientId_nosync && ![message.clientId isEqualToString:self->_realtime.rest.auth.clientId_nosync]) {
            callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
            return;
        }
    }
    else if ([data isKindOfClass:[NSArray class]]) {
        NSArray<ARTMessage *> *messages = (NSArray *)data;
        for (ARTMessage *message in messages) {
            if (message.clientId && self->_realtime.rest.auth.clientId_nosync && ![message.clientId isEqualToString:self->_realtime.rest.auth.clientId_nosync]) {
                callback([ARTErrorInfo createWithCode:ARTStateMismatchedClientId message:@"attempted to publish message with an invalid clientId"]);
                return;
            }
        }
    }

    if (!self.realtime.connection.isActive_nosync) {
        if (callback) callback([self.realtime.connection error_nosync]);
        return;
    }

    ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageMessage;
    msg.channel = self.name;
    msg.messages = data;

    [self publishProtocolMessage:msg callback:^void(ARTStatus *status) {
        if (callback) callback(status.errorInfo);
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (void)sync {
    [self sync:nil];
}

- (void)sync:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state) {
        case ARTRealtimeChannelInitialized:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached: {
            ARTErrorInfo *error = [ARTErrorInfo createWithCode:40000 message:@"unable to sync to channel; not attached"];
            [self.logger logWithError:error];
            if (callback) callback(error);
            return;
        }
        default:
            break;
    }

    [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) requesting a sync operation", _realtime, self, self.name];

    ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageSync;
    msg.channel = self.name;
    msg.channelSerial = self.presenceMap.syncChannelSerial;

    [self.presenceMap startSync];
    [self.realtime send:msg sentCallback:^(ARTErrorInfo *error) {
        if (error) {
            [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) SYNC request failed with %@", self->_realtime, self, self.name, error];
            [self.presenceMap endSync];
            callback(error);
        }
        else {
            [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) SYNC requested with success", self->_realtime, self, self.name];
            callback(nil);
        }
    } ackCallback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)requestContinueSync {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) requesting to continue sync operation after reconnect using msgSerial %lld and channelSerial %@", _realtime, self, self.name, self.presenceMap.syncMsgSerial, self.presenceMap.syncChannelSerial];

    ARTProtocolMessage * msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageSync;
    msg.msgSerial = [NSNumber numberWithLongLong:self.presenceMap.syncMsgSerial];
    msg.channelSerial = self.presenceMap.syncChannelSerial;
    msg.channel = self.name;

    [self.presenceMap startSync];
    [self.realtime send:msg sentCallback:^(ARTErrorInfo *error) {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) continue sync, error is %@", self->_realtime, self, self.name, error];
        if (error) {
            [self.presenceMap endSync];
        }
    } ackCallback:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)publishProtocolMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state_nosync) {
        case ARTRealtimeChannelSuspended:
        case ARTRealtimeChannelFailed: {
            if (cb) {
                ARTStatus *statusInvalidChannelState = [ARTStatus state:ARTStateError info:[ARTErrorInfo createWithCode:90001 message:[NSString stringWithFormat:@"channel operation failed (invalid channel state: %@)", ARTRealtimeChannelStateToStr(self.state_nosync)]]];
                cb(statusInvalidChannelState);
            }
            break;
        }
        case ARTRealtimeChannelInitialized:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached:
        case ARTRealtimeChannelAttaching:
        case ARTRealtimeChannelAttached: {
            [self.realtime send:pm sentCallback:nil ackCallback:^(ARTStatus *status) {
                if (cb) cb(status);
            }];
            break;
        }
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTPresenceMap *)presenceMap {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _presenceMap;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)throwOnDisconnectedOrFailed {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    if (self.realtime.connection.state_nosync == ARTRealtimeFailed || self.realtime.connection.state_nosync == ARTRealtimeDisconnected) {
        [ARTException raise:@"realtime cannot perform action in disconnected or failed state" format:@"state: %d", (int)self.realtime.connection.state_nosync];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribe:(void (^)(ARTMessage * _Nonnull))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [self subscribeWithAttachCallback:nil callback:callback];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribeWithAttachCallback:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTMessage * _Nonnull))cb {
    if (cb) {
        void (^userCallback)(ARTMessage *_Nonnull m) = cb;
        cb = ^(ARTMessage *_Nonnull m) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(m);
            });
        };
    }
    if (onAttach) {
        void (^userOnAttach)(ARTErrorInfo *_Nullable m) = onAttach;
        onAttach = ^(ARTErrorInfo *_Nullable e) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userOnAttach(e);
            });
        };
    }

    __block ARTEventListener *listener = nil;
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    if (self.state_nosync == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in FAILED state."]);
        [self.logger warn:@"R:%p C:%p (%@) subscribe has been ignored (attempted to subscribe while channel is in FAILED state)", self->_realtime, self, self.name];
        return;
    }
    [self _attach:onAttach];
    listener = [self.messagesEventEmitter on:cb];
    [self.logger verbose:@"R:%p C:%p (%@) subscribe to all events", self->_realtime, self, self.name];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
    return listener;
}

- (ARTEventListener *)subscribe:(NSString *)name callback:(void (^)(ARTMessage * _Nonnull))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [self subscribe:name onAttach:nil callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribe:(NSString *)name onAttach:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTMessage * _Nonnull))cb {
    if (cb) {
        void (^userCallback)(ARTMessage *_Nonnull m) = cb;
        cb = ^(ARTMessage *_Nonnull m) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(m);
            });
        };
    }
    if (onAttach) {
        void (^userOnAttach)(ARTErrorInfo *_Nullable m) = onAttach;
        onAttach = ^(ARTErrorInfo *_Nullable e) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userOnAttach(e);
            });
        };
    }

    __block ARTEventListener *listener = nil;
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    if (self.state_nosync == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in FAILED state."]);
        [self.logger warn:@"R:%p C:%p (%@) subscribe of '%@' has been ignored (attempted to subscribe while channel is in FAILED state)", self->_realtime, self, self.name, name];
        return;
    }
    [self _attach:onAttach];
    listener = [self.messagesEventEmitter on:name callback:cb];
    [self.logger verbose:@"R:%p C:%p (%@) subscribe to event '%@'", self->_realtime, self, self.name, name];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
    return listener;
}

- (void)unsubscribe {
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    [self _unsubscribe];
    [self.logger verbose:@"R:%p C:%p (%@) unsubscribe to all events", self->_realtime, self, self.name];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (void)_unsubscribe {
    [self.messagesEventEmitter off];
}

- (void)unsubscribe:(ARTEventListener *)listener {
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    [self.messagesEventEmitter off:listener];
    [self.logger verbose:@"RT:%p C:%p (%@) unsubscribe to all events", self->_realtime, self, self.name];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (void)unsubscribe:(NSString *)name listener:(ARTEventListener *)listener {
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    [self.messagesEventEmitter off:name listener:listener];
    [self.logger verbose:@"RT:%p C:%p (%@) unsubscribe to event '%@'", self->_realtime, self, self.name, name];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (ARTEventListener *)on:(ARTChannelEvent)event callback:(void (^)(ARTChannelStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [self.statesEventEmitter on:[ARTEvent newWithChannelEvent:event] callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)on:(void (^)(ARTChannelStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [self.statesEventEmitter on:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)once:(ARTChannelEvent)event callback:(void (^)(ARTChannelStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [self.statesEventEmitter once:[ARTEvent newWithChannelEvent:event] callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)once:(void (^)(ARTChannelStateChange *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [self.statesEventEmitter once:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)off {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.statesEventEmitter off];
} ART_TRY_OR_MOVE_TO_FAILED_END
}


- (void)off_nosync {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [(ARTPublicEventEmitter *)self.statesEventEmitter off_nosync];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)off:(ARTChannelEvent)event listener:listener {
    [self.statesEventEmitter off:[ARTEvent newWithChannelEvent:event] listener:listener];
}

- (void)off:(ARTEventListener *)listener {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.statesEventEmitter off:listener];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)emit:(ARTChannelEvent)event with:(ARTChannelStateChange *)data {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.statesEventEmitter emit:[ARTEvent newWithChannelEvent:event] with:data];
    [self.internalEventEmitter emit:[ARTEvent newWithChannelEvent:event] with:data];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) channel state transitions from %tu - %@ to %tu - %@", _realtime, self, self.name, self.state_nosync, ARTRealtimeChannelStateToStr(self.state_nosync), state, ARTRealtimeChannelStateToStr(state)];
    ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:state previous:self.state_nosync event:(ARTChannelEvent)state reason:status.errorInfo];
    self.state = state;

    if (status.storeErrorInfo) {
        _errorReason = status.errorInfo;
    }

    ARTEventListener *channelRetryListener = nil;
    switch (state) {
        case ARTRealtimeChannelSuspended:
            [_attachedEventEmitter emit:nil with:status.errorInfo];
            if (self.realtime.shouldSendEvents) {
                channelRetryListener = [self unlessStateChangesBefore:self.realtime.options.channelRetryTimeout do:^{
                    [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) reattach initiated by retry timeout", self->_realtime, self, self.name];
                    [self reattachWithReason:nil callback:^(ARTErrorInfo *errorInfo) {
                        if (errorInfo) {
                            ARTStatus *status = [ARTStatus state:ARTStateError info:errorInfo];
                            [self setSuspended:status];
                        }
                    }];
                }];
            }
            break;
        case ARTRealtimeChannelDetached:
            [self.presenceMap failsSync:status.errorInfo];
            break;
        case ARTRealtimeChannelFailed:
            [_attachedEventEmitter emit:nil with:status.errorInfo];
            [_detachedEventEmitter emit:nil with:status.errorInfo];
            [self.presenceMap failsSync:status.errorInfo];
            break;
        default:
            break;
    }

    [self emit:stateChange.event with:stateChange];

    if (channelRetryListener) {
        [channelRetryListener startTimer];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)(void))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [[self.internalEventEmitter once:^(ARTChannelStateChange *stateChange) {
        // Any state change cancels the timeout.
    }] setTimer:deadline onTimeout:^{
        if (callback) {
            callback();
        }
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

/**
 Checks that a channelSerial is the final serial in a sequence of sync messages,
 by checking that there is nothing after the colon
 */
- (bool)isLastChannelSerial:(NSString *)channelSerial {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    NSArray * a = [channelSerial componentsSeparatedByString:@":"];
    if([a count] >1 && ![[a objectAtIndex:1] isEqualToString:@""] ) {
        return false;
    }
    return true;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) received channel message %tu - %@", _realtime, self, self.name, message.action, ARTProtocolMessageActionToStr(message.action)];
    switch (message.action) {
        case ARTProtocolMessageAttached:
            [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) %@", _realtime, self, self.name, message.description];
            [self setAttached:message];
            break;
        case ARTProtocolMessageDetach:
        case ARTProtocolMessageDetached:
            [self setDetached:message];
            break;
        case ARTProtocolMessageMessage:
            if (_decodeFailureRecoveryInProgress) {
                [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) message decode recovery in progress, message skipped: %@", _realtime, self, self.name, message.description];
                break;
            }
            [self onMessage:message];
            break;
        case ARTProtocolMessagePresence:
            [self onPresence:message];
            break;
        case ARTProtocolMessageError:
            [self onError:message];
            break;
        case ARTProtocolMessageSync:
            [self onSync:message];
            break;
        default:
            [self.logger warn:@"R:%p C:%p (%@) unknown ARTProtocolMessage action: %tu", _realtime, self, self.name, message.action];
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setAttached:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state_nosync) {
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelFailed:
            // Ignore
            return;
        default:
            break;
    }

    if (message.resumed) {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) channel has resumed", _realtime, self, self.name];
    }

    self.attachSerial = message.channelSerial;

    if (message.hasPresence) {
        [self.presenceMap startSync];
    }
    else if ([self.presenceMap.members count] > 0 || [self.presenceMap.localMembers count] > 0) {
        if (!message.resumed) {
            // When an ATTACHED message is received without a HAS_PRESENCE flag and PresenceMap has existing members
            [self.presenceMap startSync];
            [self.presenceMap endSync];
            [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p (%@) PresenceMap has been reset", _realtime, self, self.name];
        }
    }

    if (self.state_nosync == ARTRealtimeChannelAttached) {
        if (message.error != nil) {
            _errorReason = message.error;
        }
        ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:self.state_nosync previous:self.state_nosync event:ARTChannelEventUpdate reason:message.error resumed:message.resumed];
        [self emit:stateChange.event with:stateChange];
        return;
    }

    ARTStatus *status = message.error ? [ARTStatus state:ARTStateError info:message.error] : [ARTStatus state:ARTStateOk];
    [self transition:ARTRealtimeChannelAttached status:status];
    [_attachedEventEmitter emit:nil with:nil];

    [self.presence sendPendingPresence];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setDetached:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state_nosync) {
        case ARTRealtimeChannelAttached:
        case ARTRealtimeChannelSuspended:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) reattach initiated by DETACHED message", _realtime, self, self.name];
            [self reattachWithReason:message.error callback:nil];
            return;
        case ARTRealtimeChannelAttaching: {
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) reattach initiated by DETACHED message but it is currently attaching", _realtime, self, self.name];
            ARTStatus *status = message.error ? [ARTStatus state:ARTStateError info:message.error] : [ARTStatus state:ARTStateOk];
            status.storeErrorInfo = false;
            [self setSuspended:status];
            return;
        }
        case ARTRealtimeChannelFailed:
            return;
        default:
            break;
    }

    self.attachSerial = nil;

    ARTErrorInfo *errorInfo = message.error ? message.error : [ARTErrorInfo createWithCode:0 message:@"channel has detached"];
    ARTStatus *reason = [ARTStatus state:ARTStateNotAttached info:errorInfo];
    [self detachChannel:reason];
    [_detachedEventEmitter emit:nil with:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)detachChannel:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.presence failPendingPresence:status];
    [self transition:ARTRealtimeChannelDetached status:status];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setFailed:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.presence failPendingPresence:status];
    [self transition:ARTRealtimeChannelFailed status:status];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setSuspended:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.presence failPendingPresence:status];
    [self transition:ARTRealtimeChannelSuspended status:status];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onMessage:(ARTProtocolMessage *)pm {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    int i = 0;

    ARTMessage *firstMessage = pm.messages.firstObject;
    if (firstMessage.extras) {
        NSError *extrasDecodeError;
        NSDictionary *const extras = [firstMessage.extras toJSON:&extrasDecodeError];
        if (extrasDecodeError) {
            [self.logger error:@"R:%p C:%p (%@) message extras %@ decode error: %@", _realtime, self, self.name, firstMessage.extras, extrasDecodeError];
        }
        else {
            NSString *const deltaFrom = [[extras objectForKey:@"delta"] objectForKey:@"from"];
            if (deltaFrom && _lastPayloadMessageId && ![deltaFrom isEqualToString:_lastPayloadMessageId]) {
                ARTErrorInfo *incompatibleIdError = [ARTErrorInfo createWithCode:40018 message:[NSString stringWithFormat:@"previous id '%@' is incompatible with message delta %@", _lastPayloadMessageId, firstMessage]];
                [self.logger error:@"R:%p C:%p (%@) %@", _realtime, self, self.name, incompatibleIdError.message];
                for (int j = i + 1; j < pm.messages.count; j++) {
                    [self.logger verbose:@"R:%p C:%p (%@) message skipped %@", _realtime, self, self.name, pm.messages[j]];
                }
                [self startDecodeFailureRecoveryWithChannelSerial:_lastPayloadProtocolMessageChannelSerial error:incompatibleIdError];
                return;
            }
        }
    }

    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTMessage *m in pm.messages) {
        ARTMessage *msg = m;

        if (msg.data && dataEncoder) {
            NSError *decodeError = nil;
            msg = [msg decodeWithEncoder:dataEncoder error:&decodeError];
            if (decodeError) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:decodeError] prepend:@"Failed to decode data: "];
                [self.logger error:@"R:%p C:%p (%@) %@", _realtime, self, self.name, errorInfo.message];
                _errorReason = errorInfo;
                ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:self.state_nosync previous:self.state_nosync event:ARTChannelEventUpdate reason:errorInfo];
                [self emit:stateChange.event with:stateChange];

                if (decodeError.code == 40018) {
                    [self startDecodeFailureRecoveryWithChannelSerial:_lastPayloadProtocolMessageChannelSerial error:errorInfo];
                    return;
                }
            }
        }

        if (!msg.timestamp) {
            msg.timestamp = pm.timestamp;
        }
        if (!msg.id) {
            msg.id = [NSString stringWithFormat:@"%@:%d", pm.id, i];
        }

        _lastPayloadMessageId = msg.id;

        [self.messagesEventEmitter emit:msg.name with:msg];

        ++i;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onPresence:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) handle PRESENCE message", _realtime, self, self.name];
    int i = 0;
    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTPresenceMessage *p in message.presence) {
        ARTPresenceMessage *presence = p;
        if (presence.data && dataEncoder) {
            NSError *error = nil;
            presence = [p decodeWithEncoder:dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:@"Failed to decode data: "];
                [self.logger error:@"RT:%p C:%p (%@) %@", _realtime, self, self.name, errorInfo.message];
            }
        }

        if (!presence.timestamp) {
            presence.timestamp = message.timestamp;
        }

        if (!presence.id) {
            presence.id = [NSString stringWithFormat:@"%@:%d", message.id, i];
        }

        if ([self.presenceMap add:presence]) {
            [self broadcastPresence:presence];
        }

        ++i;
    }

    _lastPayloadProtocolMessageChannelSerial = pm.channelSerial;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onSync:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    self.presenceMap.syncMsgSerial = [message.msgSerial longLongValue];
    self.presenceMap.syncChannelSerial = message.channelSerial;

    if (!self.presenceMap.syncInProgress) {
        [self.presenceMap startSync];
    }
    else {
        [self.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) PresenceMap sync is in progress", _realtime, self, self.name];
    }

    for (int i=0; i<[message.presence count]; i++) {
        ARTPresenceMessage *presence = [message.presence objectAtIndex:i];
        if ([self.presenceMap add:presence]) {
            [self broadcastPresence:presence];
        }
    }

    if ([self isLastChannelSerial:message.channelSerial]) {
        [self.presenceMap endSync];
        self.presenceMap.syncChannelSerial = nil;
        [self.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) PresenceMap sync ended", _realtime, self, self.name];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)broadcastPresence:(ARTPresenceMessage *)pm {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.presenceEventEmitter emit:[ARTEvent newWithPresenceAction:pm.action] with:pm];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onError:(ARTProtocolMessage *)msg {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self transition:ARTRealtimeChannelFailed status:[ARTStatus state:ARTStateError info:msg.error]];
    [self.presence failPendingPresence:[ARTStatus state:ARTStateError info: msg.error]];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)attach {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self attach:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)attach:(void (^)(ARTErrorInfo *))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
dispatch_sync(_queue, ^{
    [self _attach:callback];
});
}

- (void)_attach:(void (^)(ARTErrorInfo *__art_nullable))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state_nosync) {
        case ARTRealtimeChannelAttaching:
            [self.realtime.logger verbose:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) already attaching", _realtime, self, self.name];
            if (callback) [_attachedEventEmitter once:callback];
            return;
        case ARTRealtimeChannelAttached:
            [self.realtime.logger verbose:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) already attached", _realtime, self, self.name];
            if (callback) callback(nil);
            return;
        default:
            break;
    }
    [self internalAttach:callback withReason:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)reattachWithReason:(ARTErrorInfo *)reason callback:(void (^)(ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state_nosync) {
        case ARTRealtimeChannelAttached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) attached and will reattach", _realtime, self, self.name];
            break;
        case ARTRealtimeChannelSuspended:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) suspended and will reattach", _realtime, self, self.name];
            break;
        case ARTRealtimeChannelAttaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) already attaching", _realtime, self, self.name];
            if (callback) [_attachedEventEmitter once:callback];
            return;
        default:
            break;
    }
    [self internalAttach:callback withReason:reason];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)internalAttach:(void (^)(ARTErrorInfo *))callback withReason:(ARTErrorInfo *)reason {
    [self internalAttach:callback reason:reason storeErrorInfo:false channelSerial:nil];
}

- (void)internalAttach:(void (^)(ARTErrorInfo *))callback channelSerial:(NSString *)channelSerial reason:(ARTErrorInfo *)reason {
    [self internalAttach:callback reason:reason storeErrorInfo:false channelSerial:channelSerial];
}

- (void)internalAttach:(void (^)(ARTErrorInfo *))callback reason:(ARTErrorInfo *)reason storeErrorInfo:(BOOL)storeErrorInfo channelSerial:(NSString *)channelSerial {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state_nosync) {
        case ARTRealtimeChannelDetaching: {
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) attach after the completion of Detaching", _realtime, self, self.name];
            [_detachedEventEmitter once:^(ARTErrorInfo *error) {
                [self _attach:callback];
            }];
            return;
        }
        default:
            break;
    }

    _errorReason = nil;

    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) can't attach when not in an active state", _realtime, self, self.name];
        if (callback) callback([ARTErrorInfo createWithCode:90000 message:@"Can't attach when not in an active state"]);
        return;
    }

    if (callback) [_attachedEventEmitter once:callback];
    // Set state: Attaching
    ARTStatus *status = reason ? [ARTStatus state:ARTStateError info:reason] : [ARTStatus state:ARTStateOk];
    status.storeErrorInfo = storeErrorInfo;
    [self transition:ARTRealtimeChannelAttaching status:status];

    [self attachAfterChecks:callback channelSerial:channelSerial];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)attachAfterChecks:(void (^)(ARTErrorInfo * _Nullable))callback channelSerial:(NSString *)channelSerial {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    ARTProtocolMessage *attachMessage = [[ARTProtocolMessage alloc] init];
    attachMessage.action = ARTProtocolMessageAttach;
    attachMessage.channel = self.name;
    attachMessage.channelSerial = channelSerial;
    attachMessage.params = self.options_nosync.params;
    attachMessage.flags = self.options_nosync.modes;

    [self.realtime send:attachMessage sentCallback:^(ARTErrorInfo *error) {
        if (error) {
            return;
        }
        // Set attach timer after the connection is active
        [[self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
            // Timeout
            ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateAttachTimedOut message:@"attach timed out"];
            ARTStatus *status = [ARTStatus state:ARTStateAttachTimedOut info:errorInfo];
            [self setSuspended:status];
        }] startTimer];
    } ackCallback:nil];

    if (![self.realtime shouldQueueEvents]) {
        ARTEventListener *reconnectedListener = [self.realtime.connectedEventEmitter once:^(NSNull *n) {
            // Disconnected and connected while attaching, re-attach.
            [self attachAfterChecks:callback channelSerial:channelSerial];
        }];
        [_attachedEventEmitter once:^(ARTErrorInfo *err) {
            [self.realtime.connectedEventEmitter off:reconnectedListener];
        }];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)detach:(void (^)(ARTErrorInfo * _Nullable))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
dispatch_sync(_queue, ^{
    [self _detach:callback];
});
}

- (void)_detach:(void (^)(ARTErrorInfo * _Nullable))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state_nosync) {
        case ARTRealtimeChannelInitialized:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) can't detach when not attached", _realtime, self, self.name];
            if (callback) callback(nil);
            return;
        case ARTRealtimeChannelAttaching: {
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) waiting for the completion of the attaching operation", _realtime, self, self.name];
            [_attachedEventEmitter once:^(ARTErrorInfo *errorInfo) {
                if (callback && errorInfo) {
                    callback(errorInfo);
                    return;
                }
                [self _detach:callback];
            }];
            return;
        }
        case ARTRealtimeChannelDetaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) already detaching", _realtime, self, self.name];
            if (callback) [_detachedEventEmitter once:callback];
            return;
        case ARTRealtimeChannelDetached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) already detached", _realtime, self, self.name];
            if (callback) callback(nil);
            return;
        case ARTRealtimeChannelSuspended:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) transitions immediately to the detached", _realtime, self, self.name];
            [self transition:ARTRealtimeChannelDetached status:[ARTStatus state:ARTStateOk]];
            if (callback) callback(nil);
            return;
        case ARTRealtimeChannelFailed:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) can't detach when in a failed state", _realtime, self, self.name];
            if (callback) callback([ARTErrorInfo createWithCode:90000 message:@"can't detach when in a failed state"]);
            return;
        default:
            break;
    }

    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) can't detach when not in an active state", _realtime, self, self.name];
        if (callback) callback([ARTErrorInfo createWithCode:90000 message:@"Can't detach when not in an active state"]);
        return;
    }

    if (callback) [_detachedEventEmitter once:callback];
    // Set state: Detaching
    [self transition:ARTRealtimeChannelDetaching status:[ARTStatus state:ARTStateOk]];

    [self detachAfterChecks:callback];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)detachAfterChecks:(void (^)(ARTErrorInfo * _Nullable))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    ARTProtocolMessage *detachMessage = [[ARTProtocolMessage alloc] init];
    detachMessage.action = ARTProtocolMessageDetach;
    detachMessage.channel = self.name;

    [self.realtime send:detachMessage sentCallback:nil ackCallback:nil];

    [[self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
        if (!self.realtime) {
            return;
        }
        // Timeout
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateDetachTimedOut message:@"detach timed out"];
        ARTStatus *status = [ARTStatus state:ARTStateDetachTimedOut info:errorInfo];
        [self transition:ARTRealtimeChannelAttached status:status];
        [self->_detachedEventEmitter emit:nil with:errorInfo];
    }] startTimer];

    if (![self.realtime shouldQueueEvents]) {
        ARTEventListener *reconnectedListener = [self.realtime.connectedEventEmitter once:^(NSNull *n) {
            // Disconnected and connected while detaching, re-detach.
            [self detachAfterChecks:callback];
        }];
        [_detachedEventEmitter once:^(ARTErrorInfo *err) {
            [self.realtime.connectedEventEmitter off:reconnectedListener];
        }];
    }

    if (self.presenceMap.syncInProgress) {
        [self.presenceMap failsSync:[ARTErrorInfo createWithCode:90000 message:@"channel is being DETACHED"]];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)detach {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self detach:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)getClientId {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return self.realtime.auth.clientId;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)clientId_nosync {
    return self.realtime.auth.clientId_nosync;
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    query.realtimeChannel = self;
    return [_restChannel history:query callback:callback error:errorPtr];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)startDecodeFailureRecoveryWithChannelSerial:(NSString *)channelSerial error:(ARTErrorInfo *)error {
    if (_decodeFailureRecoveryInProgress) {
        return;
    }

    [self.logger warn:@"R:%p C:%p (%@) starting delta decode failure recovery process", _realtime, self, self.name];
    _decodeFailureRecoveryInProgress = true;
    [self internalAttach:^(ARTErrorInfo *e) {
        self->_decodeFailureRecoveryInProgress = false;
    } channelSerial:channelSerial reason:error];
}

#pragma mark - ARTPresenceMapDelegate

- (NSString *)connectionId {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _realtime.connection.id_nosync;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)map:(ARTPresenceMap *)map didRemovedMemberNoLongerPresent:(ARTPresenceMessage *)presence {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    presence.action = ARTPresenceLeave;
    presence.id = nil;
    presence.timestamp = [NSDate date];
    [self broadcastPresence:presence];
    [self.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) member \"%@\" no longer present", _realtime, self, self.name, presence.memberKey];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)map:(ARTPresenceMap *)map shouldReenterLocalMember:(ARTPresenceMessage *)presence {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.presence enterClient:presence.clientId data:presence.data callback:^(ARTErrorInfo *error) {
        NSString *message = [NSString stringWithFormat:@"Re-entering member \"%@\" as failed with code %ld (%@)", presence.clientId, (long)error.code, error.message];
        ARTErrorInfo *reenterError = [ARTErrorInfo createWithCode:91004 message:message];
        ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:self.state_nosync previous:self.state_nosync event:ARTChannelEventUpdate reason:reenterError resumed:true];
        [self emit:stateChange.event with:stateChange];
    }];
    [self.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) re-entering local member \"%@\"", _realtime, self, self.name, presence.memberKey];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)exceedMaxSize:(NSArray<ARTBaseMessage *> *)messages {
    NSInteger size = 0;
    for (ARTMessage *message in messages) {
        size += [message messageSize];
    }
    NSInteger maxSize = [ARTDefault maxMessageSize];
    if (self.realtime.connection.maxMessageSize) {
        maxSize = self.realtime.connection.maxMessageSize;
    }
    return size > maxSize;
}

- (ARTRealtimeChannelOptions *)getOptions {
    return (ARTRealtimeChannelOptions *)[self options];
}

- (ARTRealtimeChannelOptions *)getOptions_nosync {
    return (ARTRealtimeChannelOptions *)[self options_nosync];
}

- (void)setOptions:(ARTRealtimeChannelOptions *_Nullable)options callback:(nullable void (^)(ARTErrorInfo *_Nullable))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *_Nullable error) = callback;
        callback = ^(ARTErrorInfo *_Nullable error) {
            ART_EXITING_ABLY_CODE(self->_realtime.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    dispatch_sync(_queue, ^{
        [self setOptions_nosync:options callback:callback];
    });
}

- (void)setOptions_nosync:(ARTRealtimeChannelOptions *_Nullable)options callback:(nullable void (^)(ARTErrorInfo *_Nullable))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self setOptions_nosync:options];

    if (!options.modes && !options.params) {
        callback(nil);
        return;
    }

    switch (self.state_nosync) {
        case ARTRealtimeChannelAttached:
        case ARTRealtimeChannelAttaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"RT:%p C:%p (%@) set options in %@ state", _realtime, self, self.name, ARTRealtimeChannelStateToStr(self.state_nosync)];
            [self internalAttach:callback withReason:nil];
            break;
        default:
            callback(nil);
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

@end

#pragma mark - ARTEvent

@implementation ARTEvent (ChannelEvent)

- (instancetype)initWithChannelEvent:(ARTChannelEvent)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTChannelEvent%@",ARTChannelEventToStr(value)]];
}

+ (instancetype)newWithChannelEvent:(ARTChannelEvent)value {
    return [[self alloc] initWithChannelEvent:value];
}

@end
