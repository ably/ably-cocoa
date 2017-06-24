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
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTPresenceMap.h"
#import "ARTQueuedMessage.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTStatus.h"
#import "ARTDefault.h"
#import "ARTRest.h"
#import "ARTClientOptions.h"
#import "ARTTypes.h"
#import "ARTGCD.h"

@interface ARTRealtimeChannel () {
    ARTRealtimePresence *_realtimePresence;
    CFRunLoopTimerRef _attachTimer;
    CFRunLoopTimerRef _detachTimer;
    __GENERIC(ARTEventEmitter, ARTEvent *, ARTErrorInfo *) *_attachedEventEmitter;
    __GENERIC(ARTEventEmitter, ARTEvent *, ARTErrorInfo *) *_detachedEventEmitter;
}

@end

@implementation ARTRealtimeChannel {
    _Nonnull dispatch_queue_t _eventQueue;
    _Nonnull dispatch_queue_t _stateChangesQueue;
}

- (instancetype)initWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    self = [super initWithName:name andOptions:options andLogger:realtime.options.logHandler];
    if (self) {
        _eventQueue = dispatch_queue_create("io.ably.realtime.channel", DISPATCH_QUEUE_SERIAL);
        _stateChangesQueue = dispatch_queue_create("io.ably.realtime.channel.stateChanges", DISPATCH_QUEUE_SERIAL);
        _realtime = realtime;
        _restChannel = [_realtime.rest.channels get:self.name options:options];
        _state = ARTRealtimeChannelInitialized;
        _queuedMessages = [NSMutableArray array];
        _attachSerial = nil;
        _presenceMap = [[ARTPresenceMap alloc] initWithQueue:_eventQueue logger:self.logger];
        _presenceMap.delegate = self;
        _lastPresenceAction = ARTPresenceAbsent;
        _statesEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
        _messagesEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
        _presenceEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
        _attachedEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
        _detachedEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
        _internalEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
    }
    return self;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    return [[ARTRealtimeChannel alloc] initWithRealtime:realtime andName:name withOptions:options];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTLog *)getLogger {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _realtime.logger;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTRealtimePresence *)getPresence {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    if (!_realtimePresence) {
        _realtimePresence = [[ARTRealtimePresence alloc] initWithChannel:self];
    }
    return _realtimePresence;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *__art_nullable error) = callback;
        callback = ^(ARTErrorInfo *__art_nullable error) {
            ART_EXITING_ABLY_CODE(_realtime.rest);
            userCallback(error);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageMessage;
    msg.channel = self.name;
    if (![data isKindOfClass:[NSArray class]]) {
        data = @[data];
    }
    msg.messages = data;
    [self publishProtocolMessage:msg callback:^void(ARTStatus *status) {
        if (callback) callback(status.errorInfo);
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)requestContinueSync {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p ARTRealtime requesting to continue sync operation after reconnect", _realtime, self];

    ARTProtocolMessage * msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageSync;
    msg.msgSerial = [NSNumber numberWithLongLong:self.presenceMap.syncMsgSerial];
    msg.channelSerial = self.presenceMap.syncChannelSerial;
    msg.channel = self.name;

    [self.realtime send:msg callback:^(ARTStatus *status) {}];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)publishPresence:(ARTPresenceMessage *)msg callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (_realtime.connection.state) {
        case ARTRealtimeConnected:
            break;
        case ARTRealtimeConnecting:
        case ARTRealtimeDisconnected:
            if (_realtime.options.queueMessages) {
                break;
            }
        default:
            if (cb) cb([ARTErrorInfo createWithCode:ARTStateBadConnectionState message:@"attempted to publish presence message in a bad connection state"]);
            return;
    }

    if (!msg.clientId && !_realtime.auth.clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    _lastPresenceAction = msg.action;
    
    if (msg.data && self.dataEncoder) {
        ARTDataEncoderOutput *encoded = [self.dataEncoder encode:msg.data];
        if (encoded.errorInfo) {
            [self.logger warn:@"R:%p C:%p error encoding presence message: %@", _realtime, self, encoded.errorInfo];
        }
        msg.data = encoded.data;
        msg.encoding = encoded.encoding;
    }
    
    ARTProtocolMessage *pm = [[ARTProtocolMessage alloc] init];
    pm.action = ARTProtocolMessagePresence;
    pm.channel = self.name;
    pm.presence = @[msg];
    
    [self publishProtocolMessage:pm callback:^void(ARTStatus *status) {
        if (cb) cb(status.errorInfo);
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)publishProtocolMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    __weak __typeof(self) weakSelf = self;
    ARTStatus *statusInvalidChannel = [ARTStatus state:ARTStateError info:[ARTErrorInfo createWithCode:90001 message:@"channel operation failed (invalid channel state)"]];

    switch (_realtime.connection.state) {
        case ARTRealtimeClosing:
        case ARTRealtimeClosed: {
            if (cb) {
                cb(statusInvalidChannel);
            }
            return;
        }
        default:
            break;
    }

    void (^queuedCallback)(ARTStatus *) = ^(ARTStatus *status) {
        switch ([weakSelf state]) {
            case ARTRealtimeChannelDetaching:
            case ARTRealtimeChannelDetached:
            case ARTRealtimeChannelFailed:
                if (cb) {
                    cb(status.state == ARTStateOk ? statusInvalidChannel : status);
                }
                return;
            default:
                break;
        }
        if (cb) {
            cb(status);
        }
    };

    switch (self.state) {
        case ARTRealtimeChannelInitialized:
            [self addToQueue:pm callback:queuedCallback];
            [self attach];
            break;
        case ARTRealtimeChannelAttaching:
            [self addToQueue:pm callback:queuedCallback];
            break;
        case ARTRealtimeChannelSuspended:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached:
        case ARTRealtimeChannelFailed:
        {
            if (cb) {
                cb(statusInvalidChannel);
            }
            break;
        }
        case ARTRealtimeChannelAttached:
        {
            if (_realtime.connection.state == ARTRealtimeConnected) {
                [self sendMessage:pm callback:cb];
            } else {
                [self addToQueue:pm callback:queuedCallback];

                [self.realtime.internalEventEmitter once:[ARTEvent newWithConnectionEvent:ARTRealtimeConnectionEventConnected] callback:^(ARTConnectionStateChange *__art_nullable change) {
                    [weakSelf sendQueuedMessages];
                }];
            }
            break;
        }
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)addToQueue:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    BOOL merged = NO;
    for (ARTQueuedMessage *queuedMsg in self.queuedMessages) {
        merged = [queuedMsg mergeFrom:msg callback:cb];
        if (merged) {
            break;
        }
    }
    if (!merged) {
        ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:msg callback:cb];
        [self.queuedMessages addObject:qm];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)sendMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    NSString *oldConnectionId = self.realtime.connection.id;
    ARTProtocolMessage *pmSent = (ARTProtocolMessage *)[pm copy];

    __block BOOL connectionStateHasChanged = false;
    __block ARTEventListener *listener = [self.realtime.internalEventEmitter on:^(ARTConnectionStateChange *stateChange) {
        if (!(stateChange.current == ARTRealtimeClosed ||
              stateChange.current == ARTRealtimeFailed ||
              (stateChange.current == ARTRealtimeConnected && ![oldConnectionId isEqual:self.realtime.connection.id] /* connection state lost */))) {
            // Ok
            return;
        }
        connectionStateHasChanged = true;
        [self.realtime.internalEventEmitter off:listener];
        if (!cb) return;

        if (stateChange.current == ARTRealtimeClosed && stateChange.reason == nil && pmSent.action == ARTProtocolMessageClose) {
            // No ack/nack is expected.
            cb([ARTStatus state:ARTStateOk]);
            return;
        }

        ARTErrorInfo *reason = stateChange.reason ? stateChange.reason : [ARTErrorInfo createWithCode:0 message:@"connection broken before receiving publishing acknowledgement."];
        cb([ARTStatus state:ARTStateError info:reason]);
    }];

    for (ARTMessage *msg in pm.messages) {
        msg.connectionId = _realtime.connection.id;
    }

    [self.realtime send:pm callback:^(ARTStatus *status) {
        // New state change can occur before receiving publishing acknowledgement.
        [self.realtime.internalEventEmitter off:listener];
        if (cb && !connectionStateHasChanged) cb(status);
    }];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTPresenceMap *)presenceMap {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _presenceMap;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)throwOnDisconnectedOrFailed {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    if (self.realtime.connection.state == ARTRealtimeFailed || self.realtime.connection.state == ARTRealtimeDisconnected) {
        [ARTException raise:@"realtime cannot perform action in disconnected or failed state" format:@"state: %d", (int)self.realtime.connection.state];
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
        void (^userCallback)(ARTMessage *__art_nullable m) = cb;
        cb = ^(ARTMessage *__art_nullable m) {
            ART_EXITING_ABLY_CODE(_realtime.rest);
            userCallback(m);
        };
    }
    if (onAttach) {
        void (^userOnAttach)(ARTErrorInfo *__art_nullable m) = onAttach;
        onAttach = ^(ARTErrorInfo *__art_nullable m) {
            ART_EXITING_ABLY_CODE(_realtime.rest);
            userOnAttach(m);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    if (self.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [self _attach:onAttach];
    return [self.messagesEventEmitter on:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribe:(NSString *)name callback:(void (^)(ARTMessage * _Nonnull))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return [self subscribe:name onAttach:nil callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)subscribe:(NSString *)name onAttach:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTMessage * _Nonnull))cb {
    if (cb) {
        void (^userCallback)(ARTMessage *__art_nullable m) = cb;
        cb = ^(ARTMessage *__art_nullable m) {
            ART_EXITING_ABLY_CODE(_realtime.rest);
            userCallback(m);
        };
    }

ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    if (self.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [self _attach:onAttach];
    return [self.messagesEventEmitter on:name callback:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)unsubscribe {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.messagesEventEmitter off];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)unsubscribe:(ARTEventListener *)listener {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.messagesEventEmitter off:listener];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)unsubscribe:(NSString *)name listener:(ARTEventListener *)listener {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.messagesEventEmitter off:name listener:listener];
} ART_TRY_OR_MOVE_TO_FAILED_END
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
    artDispatchSync(_stateChangesQueue, ^{
        [self.logger debug:__FILE__ line:__LINE__ message:@"channel state transitions to %tu - %@", state, ARTRealtimeChannelStateToStr(state)];
        ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:state previous:self.state event:(ARTChannelEvent)state reason:status.errorInfo];
        self.state = state;

        if (status.storeErrorInfo) {
            _errorReason = status.errorInfo;
        }

        switch (state) {
            case ARTRealtimeChannelSuspended:
                [_attachedEventEmitter emit:nil with:status.errorInfo];
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
    });
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)dealloc {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_statesEventEmitter off];
    [_internalEventEmitter off];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)())callback {
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
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p received channel message %tu - %@", _realtime, self, message.action, ARTProtocolMessageActionToStr(message.action)];
    switch (message.action) {
        case ARTProtocolMessageAttached:
            [self setAttached:message];
            break;
        case ARTProtocolMessageDetach:
        case ARTProtocolMessageDetached:
            [self setDetached:message];
            break;
        case ARTProtocolMessageMessage:
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
            [self.logger warn:@"R:%p C:%p ARTRealtime, unknown ARTProtocolMessage action: %tu", _realtime, self, message.action];
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTRealtimeChannelState)state {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _state;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setAttached:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state) {
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelFailed:
            // Ignore
            return;
        default:
            break;
    }

    self.attachSerial = message.channelSerial;

    if (message.hasPresence) {
        [self.presenceMap startSync];
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p PresenceMap Sync started", _realtime, self];
    }
    else if ([self.presenceMap.members count] > 0 || [self.presenceMap.localMembers count] > 0) {
        if (!message.resumed) {
            // When an ATTACHED message is received without a HAS_PRESENCE flag and PresenceMap has existing members
            [self.presenceMap startSync];
            [self.presenceMap endSync];
        }
    }

    if (self.state == ARTRealtimeChannelAttached) {
        if (message.error != nil) {
            _errorReason = message.error;
        }
        ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:self.state previous:self.state event:ARTChannelEventUpdate reason:message.error resumed:message.resumed];
        [self emit:stateChange.event with:stateChange];
        return;
    }

    [self sendQueuedMessages];

    ARTStatus *status = message.error ? [ARTStatus state:ARTStateError info:message.error] : [ARTStatus state:ARTStateOk];
    [self transition:ARTRealtimeChannelAttached status:status];
    [_attachedEventEmitter emit:nil with:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setDetached:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state) {
        case ARTRealtimeChannelAttached:
        case ARTRealtimeChannelSuspended:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p reattach initiated by DETACHED message", _realtime, self];
            [self reattachWithReason:message.error callback:nil];
            return;
        case ARTRealtimeChannelAttaching: {
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p reattach initiated by DETACHED message but it is currently attaching", _realtime, self];
            ARTStatus *status = message.error ? [ARTStatus state:ARTStateError info:message.error] : [ARTStatus state:ARTStateOk];
            status.storeErrorInfo = false;
            [self setSuspended:status retryIn:0];
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
    [self failQueuedMessages:status];
    [self transition:ARTRealtimeChannelDetached status:status];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setFailed:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self failQueuedMessages:status];
    [self transition:ARTRealtimeChannelFailed status:status];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setSuspended:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self setSuspended:status retryIn:self.realtime.options.channelRetryTimeout];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setSuspended:(ARTStatus *)status retryIn:(NSTimeInterval)retryTimeout {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self failQueuedMessages:status];
    [self transition:ARTRealtimeChannelSuspended status:status];
    __weak __typeof(self) weakSelf = self;
    [[self unlessStateChangesBefore:retryTimeout do:^{
        [weakSelf reattachWithReason:nil callback:^(ARTErrorInfo *errorInfo) {
            ARTStatus *status = [ARTStatus state:ARTStateError info:errorInfo];
            [weakSelf setSuspended:status];
        }];
    }] startTimer];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onMessage:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    int i = 0;
    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTMessage *m in message.messages) {
        ARTMessage *msg = m;
        if (msg.data && dataEncoder) {
            NSError *error = nil;
            msg = [msg decodeWithEncoder:dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:@"Failed to decode data: "];
                [self.logger error:@"R:%p C:%p %@", _realtime, self, errorInfo.message];
                _errorReason = errorInfo;
                ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:self.state previous:self.state event:ARTChannelEventUpdate reason:errorInfo];
                [self emit:stateChange.event with:stateChange];
            }
        }
        
        if (!msg.timestamp) {
            msg.timestamp = message.timestamp;
        }
        if (!msg.id) {
            msg.id = [NSString stringWithFormat:@"%@:%d", message.id, i];
        }
        
        [self.messagesEventEmitter emit:msg.name with:msg];
        
        ++i;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onPresence:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"handle PRESENCE message"];
    int i = 0;
    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTPresenceMessage *p in message.presence) {
        ARTPresenceMessage *presence = p;
        if (presence.data && dataEncoder) {
            NSError *error = nil;
            presence = [p decodeWithEncoder:dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:@"Failed to decode data: "];
                [self.logger error:@"R:%p C:%p %@", _realtime, self, errorInfo.message];
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
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onSync:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    self.presenceMap.syncMsgSerial = [message.msgSerial longLongValue];
    self.presenceMap.syncChannelSerial = message.channelSerial;

    if (!self.presenceMap.syncInProgress) {
        [self.presenceMap startSync];
    }

    for (int i=0; i<[message.presence count]; i++) {
        ARTPresenceMessage *presence = [message.presence objectAtIndex:i];
        if ([self.presenceMap add:presence]) {
            [self broadcastPresence:presence];
        }
    }

    if ([self isLastChannelSerial:message.channelSerial]) {
        [self.presenceMap endSync];
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p PresenceMap Sync ended", _realtime, self];
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
    [self failQueuedMessages:[ARTStatus state:ARTStateError info: msg.error]];
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
            ART_EXITING_ABLY_CODE(_realtime.rest);
            userCallback(error);
        };
    }
    [self _attach:callback];
}

- (void)_attach:(void (^)(ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state) {
        case ARTRealtimeChannelAttaching:
            [self.realtime.logger verbose:__FILE__ line:__LINE__ message:@"R:%p C:%p already attaching", _realtime, self];
            if (callback) [_attachedEventEmitter once:callback];
            return;
        case ARTRealtimeChannelAttached:
            [self.realtime.logger verbose:__FILE__ line:__LINE__ message:@"R:%p C:%p already attached", _realtime, self];
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
    switch (self.state) {
        case ARTRealtimeChannelAttached:
        case ARTRealtimeChannelSuspended:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p attached or suspended and will reattach", _realtime, self];
            break;
        case ARTRealtimeChannelAttaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p already attaching", _realtime, self];
            if (callback) [_attachedEventEmitter once:callback];
            return;
        default:
            break;
    }
    [self internalAttach:callback withReason:reason storeErrorInfo:true];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)internalAttach:(void (^)(ARTErrorInfo *))callback withReason:(ARTErrorInfo *)reason {
    [self internalAttach:callback withReason:reason storeErrorInfo:false];
}

- (void)internalAttach:(void (^)(ARTErrorInfo *))callback withReason:(ARTErrorInfo *)reason storeErrorInfo:(BOOL)storeErrorInfo {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state) {
        case ARTRealtimeChannelDetaching: {
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p %@", _realtime, self, @"attach after the completion of Detaching"];
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
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p can't attach when not in an active state", _realtime, self];
        if (callback) callback([ARTErrorInfo createWithCode:90000 message:@"Can't attach when not in an active state"]);
        return;
    }

    if (callback) [_attachedEventEmitter once:callback];
    // Set state: Attaching
    ARTStatus *status = reason ? [ARTStatus state:ARTStateError info:reason] : [ARTStatus state:ARTStateOk];
    status.storeErrorInfo = storeErrorInfo;
    [self transition:ARTRealtimeChannelAttaching status:status];

    [self attachAfterChecks:callback];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)attachAfterChecks:(void (^)(ARTErrorInfo * _Nullable))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    ARTProtocolMessage *attachMessage = [[ARTProtocolMessage alloc] init];
    attachMessage.action = ARTProtocolMessageAttach;
    attachMessage.channel = self.name;

    [self.realtime send:attachMessage callback:nil];

    [[self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
        // Timeout
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateAttachTimedOut message:@"attach timed out"];
        ARTStatus *status = [ARTStatus state:ARTStateAttachTimedOut info:errorInfo];
        [self setSuspended:status];
    }] startTimer];

    if (![self.realtime shouldQueueEvents]) {
        ARTEventListener *reconnectedListener = [self.realtime.connectedEventEmitter once:^(NSNull *n) {
            // Disconnected and connected while attaching, re-attach.
            [self attachAfterChecks:callback];
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
            ART_EXITING_ABLY_CODE(_realtime.rest);
            userCallback(error);
        };
    }
    [self _detach:callback];
}

- (void)_detach:(void (^)(ARTErrorInfo * _Nullable))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    switch (self.state) {
        case ARTRealtimeChannelInitialized:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p can't detach when not attached", _realtime, self];
            if (callback) callback(nil);
            return;
        case ARTRealtimeChannelAttaching: {
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p waiting for the completion of the attaching operation", _realtime, self];
            [_attachedEventEmitter once:^(ARTErrorInfo *errorInfo) {
                if (callback && errorInfo) {
                    callback(errorInfo);
                }
                [self _detach:callback];
            }];
            return;
        }
        case ARTRealtimeChannelDetaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p already detaching", _realtime, self];
            if (callback) [_detachedEventEmitter once:callback];
            return;
        case ARTRealtimeChannelDetached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p already detached", _realtime, self];
            if (callback) callback(nil);
            return;
        case ARTRealtimeChannelSuspended:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p transitions immediately to the detached", _realtime, self];
            [self transition:ARTRealtimeChannelDetached status:[ARTStatus state:ARTStateOk]];
            if (callback) callback(nil);
            return;
        case ARTRealtimeChannelFailed:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p can't detach when in a failed state", _realtime, self];
            if (callback) callback([ARTErrorInfo createWithCode:90000 message:@"can't detach when in a failed state"]);
            return;
        default:
            break;
    }
    
    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p can't detach when not in an active state", _realtime, self];
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

    [self.realtime send:detachMessage callback:nil];

    [[self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
        // Timeout
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateDetachTimedOut message:@"detach timed out"];
        ARTStatus *status = [ARTStatus state:ARTStateDetachTimedOut info:errorInfo];
        [self transition:ARTRealtimeChannelAttached status:status];
        [_detachedEventEmitter emit:nil with:errorInfo];
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

- (void)sendQueuedMessages {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *qm in qms) {
        [self sendMessage:qm.msg callback:qm.cb];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)failQueuedMessages:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *qm in qms) {
        qm.cb(status);
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)getClientId {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return self.realtime.auth.clientId;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    query.realtimeChannel = self;
    @try {
        return [_restChannel history:query callback:callback error:errorPtr];
    }
    @catch (NSError *error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return NO;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

#pragma mark - ARTPresenceMapDelegate

- (NSString *)connectionId {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    return _realtime.connection.id;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)map:(ARTPresenceMap *)map didRemovedMemberNoLongerPresent:(ARTPresenceMessage *)presence {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    presence.action = ARTPresenceLeave;
    presence.id = nil;
    presence.timestamp = [NSDate date];
    [self broadcastPresence:presence];
    [self.logger debug:__FILE__ line:__LINE__ message:@"Member \"%@\" no longer present", presence.memberKey];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)map:(ARTPresenceMap *)map shouldReenterLocalMember:(ARTPresenceMessage *)presence {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [self.presence enterClient:presence.clientId data:presence.data callback:^(ARTErrorInfo *error) {
        NSString *message = [NSString stringWithFormat:@"Re-entering member \"%@\" as failed with code %ld (%@)", presence.clientId, (long)error.code, error.message];
        ARTErrorInfo *reenterError = [ARTErrorInfo createWithCode:91004 message:message];
        ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:self.state previous:self.state event:ARTChannelEventUpdate reason:reenterError resumed:true];
        [self emit:stateChange.event with:stateChange];
    }];
    [self.logger debug:__FILE__ line:__LINE__ message:@"Re-entering local member \"%@\"", presence.memberKey];
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
