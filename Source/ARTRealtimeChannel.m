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

@interface ARTRealtimeChannel () {
    ARTRealtimePresence *_realtimePresence;
    CFRunLoopTimerRef _attachTimer;
    CFRunLoopTimerRef _detachTimer;
    __GENERIC(ARTEventEmitter, NSNull *, ARTErrorInfo *) *_attachedEventEmitter;
    __GENERIC(ARTEventEmitter, NSNull *, ARTErrorInfo *) *_detachedEventEmitter;
}

@end

@implementation ARTRealtimeChannel

- (instancetype)initWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options {
    self = [super initWithName:name andOptions:options andLogger:realtime.options.logHandler];
    if (self) {
        _realtime = realtime;
        _restChannel = [_realtime.rest.channels get:self.name options:options];
        _state = ARTRealtimeChannelInitialized;
        _queuedMessages = [NSMutableArray array];
        _attachSerial = nil;
        _presenceMap = [[ARTPresenceMap alloc] init];
        _lastPresenceAction = ARTPresenceAbsent;
        
        _statesEventEmitter = [[ARTEventEmitter alloc] init];
        _messagesEventEmitter = [[ARTEventEmitter alloc] init];
        _presenceEventEmitter = [[ARTEventEmitter alloc] init];

        _attachedEventEmitter = [[ARTEventEmitter alloc] init];
        _detachedEventEmitter = [[ARTEventEmitter alloc] init];
    }
    return self;
}

+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options {
    return [[ARTRealtimeChannel alloc] initWithRealtime:realtime andName:name withOptions:options];
}

- (ARTRealtimePresence *)getPresence {
    if (!_realtimePresence) {
        _realtimePresence = [[ARTRealtimePresence alloc] initWithChannel:self];
    }
    return _realtimePresence;
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
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
}

- (void)requestContinueSync {
    [self.logger info:@"R:%p C:%p ARTRealtime requesting to continue sync operation after reconnect", _realtime, self];
    
    ARTProtocolMessage * msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageSync;
    msg.msgSerial = self.presenceMap.syncMsgSerial;
    msg.channelSerial = self.presenceMap.syncChannelSerial;
    msg.channel = self.name;

    [self.realtime send:msg callback:^(ARTStatus *status) {}];
}

- (void)publishPresence:(ARTPresenceMessage *)msg callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb {
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
}

- (void)publishProtocolMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb {
    switch (_realtime.connection.state) {
        case ARTRealtimeClosing:
        case ARTRealtimeClosed: {
            if (cb) {
                ARTStatus *status = [ARTStatus state:ARTStateError info:[ARTErrorInfo createWithCode:90001 message:@"channel operation failed (invalid channel state)"]];
                cb(status);
            }
            return;
        }
        default:
            break;
    }
    switch (self.state) {
        case ARTRealtimeChannelInitialized:
            [self attach];
            // intentional fall-through
        case ARTRealtimeChannelAttaching:
        {
            [self addToQueue:pm callback:cb];
            break;
        }
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached:
        case ARTRealtimeChannelFailed:
        {
            if (cb) {
                ARTStatus *status = [ARTStatus state:ARTStateError info:[ARTErrorInfo createWithCode:90001 message:@"channel operation failed (invalid channel state)"]];
                cb(status);
            }
            break;
        }
        case ARTRealtimeChannelAttached:
        {
            if (_realtime.connection.state == ARTRealtimeConnected) {
                [self sendMessage:pm callback:cb];
            } else {
                [self addToQueue:pm callback:cb];

                [self.realtime.internalEventEmitter once:[NSNumber numberWithInteger:ARTRealtimeConnected] callback:^(ARTConnectionStateChange *__art_nullable change) {
                    [self sendQueuedMessages];
                }];
            }
            break;
        }
        default:
            NSAssert(NO, @"Invalid State");
    }
}

- (void)addToQueue:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb {
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
}

- (void)sendMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb {
    __block BOOL gotFailure = false;
    NSString *oldConnectionId = self.realtime.connection.id;
    __block ARTEventListener *listener = [self.realtime.internalEventEmitter on:^(ARTConnectionStateChange *stateChange) {
        if (!(stateChange.current == ARTRealtimeClosed || stateChange.current == ARTRealtimeFailed
              || (stateChange.current == ARTRealtimeConnected && ![oldConnectionId isEqual:self.realtime.connection.id] /* connection state lost */))) {
            return;
        }
        gotFailure = true;
        [self.realtime.internalEventEmitter off:listener];
        if (!cb) return;
        ARTErrorInfo *reason = stateChange.reason ? stateChange.reason : [ARTErrorInfo createWithCode:0 message:@"connection broken before receiving publishing acknowledgement."];
        cb([ARTStatus state:ARTStateError info:reason]);
    }];

    for (ARTMessage *msg in pm.messages) {
        msg.connectionId = _realtime.connection.id;
    }

    [self.realtime send:pm callback:^(ARTStatus *status) {
        [self.realtime.internalEventEmitter off:listener];
        if (cb && !gotFailure) cb(status);
    }];
}

- (ARTPresenceMap *)presenceMap {
    return _presenceMap;
}

- (void)throwOnDisconnectedOrFailed {
    if (self.realtime.connection.state == ARTRealtimeFailed || self.realtime.connection.state == ARTRealtimeDisconnected) {
        [NSException raise:@"realtime cannot perform action in disconnected or failed state" format:@"state: %d", (int)self.realtime.connection.state];
    }
}

- (ARTEventListener<ARTMessage *> *)subscribe:(void (^)(ARTMessage * _Nonnull))callback {
    return [self subscribeWithAttachCallback:nil callback:callback];
}

- (ARTEventListener<ARTMessage *> *)subscribeWithAttachCallback:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTMessage * _Nonnull))cb {
    if (self.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [self attach:onAttach];
    return [self.messagesEventEmitter on:cb];
}

- (ARTEventListener<ARTMessage *> *)subscribe:(NSString *)name callback:(void (^)(ARTMessage * _Nonnull))cb {
    return [self subscribe:name onAttach:nil callback:cb];
}

- (ARTEventListener<ARTMessage *> *)subscribe:(NSString *)name onAttach:(void (^)(ARTErrorInfo * _Nullable))onAttach callback:(void (^)(ARTMessage * _Nonnull))cb {
    if (self.state == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:0 message:@"attempted to subscribe while channel is in Failed state."]);
        return nil;
    }
    [self attach:onAttach];
    return [self.messagesEventEmitter on:name callback:cb];
}

- (void)unsubscribe {
    [self.messagesEventEmitter off];
}

- (void)unsubscribe:(ARTEventListener<ARTMessage *> *)listener {
    [self.messagesEventEmitter off:listener];
}

- (void)unsubscribe:(NSString *)name listener:(ARTEventListener<ARTMessage *> *)listener {
    [self.messagesEventEmitter off:name listener:listener];
}

- (__GENERIC(ARTEventListener, ARTErrorInfo *) *)on:(ARTChannelEvent)event callback:(void (^)(ARTErrorInfo *))cb {
    return [self.statesEventEmitter on:[NSNumber numberWithInt:event] callback:cb];
}

- (__GENERIC(ARTEventListener, ARTErrorInfo *) *)on:(void (^)(ARTErrorInfo *))cb {
    return [self.statesEventEmitter on:cb];
}

- (__GENERIC(ARTEventListener, ARTErrorInfo *) *)once:(ARTChannelEvent)event callback:(void (^)(ARTErrorInfo *))cb {
    return [self.statesEventEmitter once:[NSNumber numberWithInt:event] callback:cb];
}

- (__GENERIC(ARTEventListener, ARTErrorInfo *) *)once:(void (^)(ARTErrorInfo *))cb {
    return [self.statesEventEmitter once:cb];
}

- (void)off {
    [self.statesEventEmitter off];
}
- (void)off:(ARTChannelEvent)event listener:listener {
    [self.statesEventEmitter off:[NSNumber numberWithInt:event] listener:listener];
}

- (void)off:(__GENERIC(ARTEventListener, ARTErrorInfo *) *)listener {
    [self.statesEventEmitter off:listener];
}

- (void)emit:(ARTChannelEvent)event with:(ARTErrorInfo *)data {
    [self.statesEventEmitter emit:[NSNumber numberWithInt:event] with:data];
}

- (ARTEventListener *)timed:(ARTEventListener *)listener deadline:(NSTimeInterval)deadline onTimeout:(void (^)())onTimeout {
    return [self.statesEventEmitter timed:listener deadline:deadline onTimeout:onTimeout];
}

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status {
    self.state = state;
    _errorReason = status.errorInfo;

    if (state == ARTRealtimeChannelFailed) {
        [_attachedEventEmitter emit:[NSNull null] with:status.errorInfo];
        [_detachedEventEmitter emit:[NSNull null] with:status.errorInfo];
    }
    else if (state == ARTRealtimeChannelDetaching) {
        NSString *msg = @"channel is being DETACHED";
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p %@", _realtime, self, msg];
        [_attachedEventEmitter emit:[NSNull null] with:[ARTErrorInfo createWithCode:90000 message:msg]];
    }

    [self emit:(ARTChannelEvent)state with:status.errorInfo];
}

- (void)dealloc {
    if (self.statesEventEmitter) {
        [self.statesEventEmitter off];
    }
}

- (void)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)())callback {
    // Defer until next event loop execution so that any event emitted in the current
    // one doesn't cancel the timeout.
    ARTRealtimeChannelState state = self.state;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
        if (state != self.state) {
            // Already changed; do nothing.
            return;
        }
        [self timed:[self once:^(ARTErrorInfo *errorInfo) {
            // Any state change cancels the timeout.
        }] deadline:deadline onTimeout:callback];
    });
}

/**
 Checks that a channelSerial is the final serial in a sequence of sync messages,
 by checking that there is nothing after the colon
 */
- (bool)isLastChannelSerial:(NSString *)channelSerial {
    NSArray * a = [channelSerial componentsSeparatedByString:@":"];
    if([a count] >1 && ![[a objectAtIndex:1] isEqualToString:@""] ) {
        return false;
    }
    return true;
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
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
}

- (ARTRealtimeChannelState)state {
    return _state;
}

- (void)setAttached:(ARTProtocolMessage *)message {
    if (self.state == ARTRealtimeChannelFailed) {
        return;
    }
    self.attachSerial = message.channelSerial;

    if (self.state == ARTRealtimeChannelAttached) {
        if (message.error != nil) {
            _errorReason = message.error;
            [self emit:ARTChannelEventError with:message.error];
        }
        return;
    }

    if ([message isSyncEnabled]) {
        [self.presenceMap startSync];
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p PresenceMap Sync started", _realtime, self];
    }

    [self sendQueuedMessages];

    if (message.error) {
        _errorReason = message.error;
        [self transition:ARTRealtimeChannelAttached status:[ARTStatus state:ARTStateError info:message.error]];
    }
    else {
        [self transition:ARTRealtimeChannelAttached status:[ARTStatus state:ARTStateOk]];
    }
    [_attachedEventEmitter emit:[NSNull null] with:nil];
}

- (void)setDetached:(ARTProtocolMessage *)message {
    if (self.state == ARTRealtimeChannelFailed) {
        return;
    }
    self.attachSerial = nil;
    
    ARTErrorInfo *errorInfo;
    if (message.error) {
        errorInfo = message.error;
    } else {
        errorInfo = [ARTErrorInfo createWithCode:0 message:@"channel has detached"];
    }
    ARTStatus *reason = [ARTStatus state:ARTStateNotAttached info:errorInfo];
    [self detachChannel:reason];
    [_detachedEventEmitter emit:[NSNull null] with:nil];
}

- (void)detachChannel:(ARTStatus *)error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelDetached status:error];
}

- (void)setFailed:(ARTStatus *)error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelFailed status:error];
}

- (void)setSuspended:(ARTStatus *)error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelDetached status:error];
}

- (void)onMessage:(ARTProtocolMessage *)message {
    int i = 0;
    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTMessage *m in message.messages) {
        ARTMessage *msg = m;
        if (msg.data && dataEncoder) {
            NSError *error = nil;
            msg = [msg decodeWithEncoder:dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:(ARTErrorInfo *)error.userInfo[NSLocalizedFailureReasonErrorKey] prepend:@"Failed to decode data: "];
                [self.logger error:@"R:%p C:%p %@", _realtime, self, errorInfo.message];
                _errorReason = errorInfo;
                [self emit:ARTChannelEventError with:errorInfo];
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
}

- (void)onPresence:(ARTProtocolMessage *)message {
    int i = 0;
    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTPresenceMessage *p in message.presence) {
        ARTPresenceMessage *presence = p;
        if (presence.data && dataEncoder) {
            NSError *error = nil;
            presence = [p decodeWithEncoder:dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:(ARTErrorInfo *)error.userInfo[NSLocalizedFailureReasonErrorKey] prepend:@"Failed to decode data: "];
                [self.logger error:@"R:%p C:%p %@", _realtime, self, errorInfo.message];
            }
        }
        
        if (!presence.timestamp) {
            presence.timestamp = message.timestamp;
        }
        
        if (!presence.id) {
            presence.id = [NSString stringWithFormat:@"%@:%d", message.id, i];
        }

        [self.presenceMap onceSyncEnds:^(__GENERIC(NSArray, ARTPresenceMessage *) *msgs) {
            [self.presenceMap put:presence];
            [self.presenceMap clean];

            [self broadcastPresence:presence];
        }];

        ++i;
    }
}

- (void)onSync:(ARTProtocolMessage *)message {
    self.presenceMap.syncMsgSerial = message.msgSerial;
    self.presenceMap.syncChannelSerial = message.channelSerial;

    if (message.action == ARTProtocolMessageSync)
        [self.logger info:@"R:%p C:%p ARTRealtime Sync message received", _realtime, self];

    for (int i=0; i<[message.presence count]; i++) {
        ARTPresenceMessage *presence = [message.presence objectAtIndex:i];
        [self.presenceMap put:presence];
        [self broadcastPresence:presence];
    }

    if ([self isLastChannelSerial:message.channelSerial]) {
        [self.presenceMap endSync];
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p PresenceMap Sync ended", _realtime, self];
    }
}

- (void)broadcastPresence:(ARTPresenceMessage *)pm {
    [self.presenceEventEmitter emit:[NSNumber numberWithUnsignedInteger:pm.action] with:pm];
}

- (void)onError:(ARTProtocolMessage *)msg {
    [self transition:ARTRealtimeChannelFailed status:[ARTStatus state:ARTStateError info: msg.error]];
    [self failQueuedMessages:[ARTStatus state:ARTStateError info: msg.error]];
}

- (void)attach {
    [self attach:nil];
}

- (void)attach:(void (^)(ARTErrorInfo * _Nullable))callback {
    switch (self.state) {
        case ARTRealtimeChannelAttaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p already attaching", _realtime, self];
            if (callback) [_attachedEventEmitter once:callback];
            return;
        case ARTRealtimeChannelAttached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p already attached", _realtime, self];
            if (callback) callback(nil);
            return;
        case ARTRealtimeChannelDetaching: {
            NSString *msg = @"can't attach when in DETACHING state";
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p %@", _realtime, self, msg];
            if (callback) callback([ARTErrorInfo createWithCode:90000 message:msg]);
            return;
        }
        case ARTRealtimeChannelFailed:
            _errorReason = nil;
            break;
        default:
            break;
    }
    
    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p can't attach when not in an active state", _realtime, self];
        if (callback) callback([ARTErrorInfo createWithCode:90000 message:@"Can't attach when not in an active state"]);
        return;
    }

    if (callback) [_attachedEventEmitter once:callback];
    // Set state: Attaching
    [self transition:ARTRealtimeChannelAttaching status:[ARTStatus state:ARTStateOk]];

    [self attachAfterChecks:callback];
}

- (void)attachAfterChecks:(void (^)(ARTErrorInfo * _Nullable))callback {
    ARTProtocolMessage *attachMessage = [[ARTProtocolMessage alloc] init];
    attachMessage.action = ARTProtocolMessageAttach;
    attachMessage.channel = self.name;

    __block BOOL timeouted = false;

    [self.realtime send:attachMessage callback:nil];

    [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
        timeouted = true;
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateAttachTimedOut message:@"attach timed out"];
        ARTStatus *status = [ARTStatus state:ARTStateAttachTimedOut info:errorInfo];
        _errorReason = errorInfo;
        [self transition:ARTRealtimeChannelFailed status:status];
        [_attachedEventEmitter emit:[NSNull null] with:errorInfo];
    }];

    if (![self.realtime shouldQueueEvents]) {
        ARTEventListener *reconnectedListener = [self.realtime.connectedEventEmitter once:^(NSNull *n) {
            // Disconnected and connected while attaching, re-attach.
            [self attachAfterChecks:callback];
        }];
        [_attachedEventEmitter once:^(ARTErrorInfo *err) {
            [self.realtime.connectedEventEmitter off:reconnectedListener];
        }];
    }
}

- (void)detach:(void (^)(ARTErrorInfo * _Nullable))callback {
    switch (self.state) {
        case ARTRealtimeChannelInitialized:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p can't detach when not attached", _realtime, self];
            if (callback) [_detachedEventEmitter once:callback];
            return;
        case ARTRealtimeChannelDetaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p already detaching", _realtime, self];
            if (callback) [_detachedEventEmitter once:callback];
            return;
        case ARTRealtimeChannelDetached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"R:%p C:%p already detached", _realtime, self];
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
}

- (void)detachAfterChecks:(void (^)(ARTErrorInfo * _Nullable))callback {
    ARTProtocolMessage *detachMessage = [[ARTProtocolMessage alloc] init];
    detachMessage.action = ARTProtocolMessageDetach;
    detachMessage.channel = self.name;

    __block BOOL timeouted = false;

    [self.realtime send:detachMessage callback:nil];

    [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
        timeouted = true;
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateDetachTimedOut message:@"detach timed out"];
        ARTStatus *status = [ARTStatus state:ARTStateDetachTimedOut info:errorInfo];
        _errorReason = errorInfo;
        [self transition:ARTRealtimeChannelFailed status:status];
        [_detachedEventEmitter emit:[NSNull null] with:errorInfo];
    }];

    if (![self.realtime shouldQueueEvents]) {
        ARTEventListener *reconnectedListener = [self.realtime.connectedEventEmitter once:^(NSNull *n) {
            // Disconnected and connected while attaching, re-detach.
            [self detachAfterChecks:callback];
        }];
        [_detachedEventEmitter once:^(ARTErrorInfo *err) {
            [self.realtime.connectedEventEmitter off:reconnectedListener];
        }];
    }
}

- (void)detach {
    [self detach:nil];
}

- (void)sendQueuedMessages {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *qm in qms) {
        [self sendMessage:qm.msg callback:qm.cb];
    }
}

- (void)failQueuedMessages:(ARTStatus *)status {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *qm in qms) {
        qm.cb(status);
    }
}

- (NSString *)getClientId {
    return self.realtime.auth.clientId;
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
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
}

@end
