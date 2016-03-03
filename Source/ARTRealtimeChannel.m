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
#import "ARTRealtimePresence.h"
#import "ARTChannel.h"
#import "ARTChannelOptions.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTPresenceMap.h"
#import "ARTQueuedMessage.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTStatus.h"
#import "ARTDefault.h"

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
    self = [super initWithName:name withOptions:options andRest:realtime.rest];
    if (self) {
        _realtime = realtime;
        _state = ARTRealtimeChannelInitialised;
        _queuedMessages = [NSMutableArray array];
        _attachSerial = nil;
        _presenceMap =[[ARTPresenceMap alloc] init];
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

- (void)publish:(NSString *)name data:(id)data callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    NSArray *messages = [NSArray arrayWithObject:[[ARTMessage alloc] initWithName:name data:data]];
    [self publish:messages callback:cb];
}

-(void)publish:(NSArray<ARTMessage *> *)messages callback:(void (^)(ARTErrorInfo * _Nullable))cb {
    ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageMessage;
    msg.channel = self.name;
    msg.messages = [messages artMap:^id(ARTMessage *message) {
        return [self encodeMessageIfNeeded:message];
    }];
    [self publishProtocolMessage:msg callback:^void(ARTStatus *status) {
        if (cb) cb(status.errorInfo);
    }];
}

- (void)requestContinueSync {
    [self.logger info:@"ARTRealtime requesting to continue sync operation after reconnect"];
    
    ARTProtocolMessage * msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageSync;
    msg.msgSerial = self.presenceMap.syncSerial;
    msg.channel = self.name;


    [self.realtime send:msg callback:^(ARTStatus *status) {}];
}

- (void)publishPresence:(ARTPresenceMessage *)msg callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb {
    if (!msg.clientId) {
        msg.clientId = self.clientId;
    }
    if (!msg.clientId) {
        if (cb) cb([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"attempted to publish presence message without clientId"]);
        return;
    }
    _lastPresenceAction = msg.action;
    
    if (msg.data && self.dataEncoder) {
        ARTDataEncoderOutput *encoded = [self.dataEncoder encode:msg.data];
        if (encoded.errorInfo) {
            [self.logger warn:@"error encoding presence message: %@", encoded.errorInfo];
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

- (void)publishProtocolMessage:(ARTProtocolMessage *)pm callback:(ARTStatusCallback)cb {
    switch (self.state) {
        case ARTRealtimeChannelInitialised:
            [self attach];
            // intentional fall-through
        case ARTRealtimeChannelAttaching:
        {
            ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:pm callback:cb];
            [self.queuedMessages addObject:qm];
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
            [self sendMessage:pm callback:cb];
            break;
        }
        default:
            NSAssert(NO, @"Invalid State");
    }
}


- (void)sendMessage:(ARTProtocolMessage *)pm callback:(ARTStatusCallback)cb {
    __block BOOL gotFailure = false;
    NSString *oldConnectionId = self.realtime.connection.id;
    __block ARTEventListener *listener = [self.realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        if (!(stateChange.current == ARTRealtimeClosed || stateChange.current == ARTRealtimeFailed
              || (stateChange.current == ARTRealtimeConnected && ![oldConnectionId isEqual:self.realtime.connection.id] /* connection state lost */))) {
            return;
        }
        gotFailure = true;
        [self.realtime.connection off:listener];
        if (!cb) return;
        ARTErrorInfo *reason = stateChange.reason ? stateChange.reason : [ARTErrorInfo createWithCode:0 message:@"connection broken before receiving publishing acknowledgement."];
        cb([ARTStatus state:ARTStateError info:reason]);
    }];

    [self.realtime send:pm callback:^(ARTStatus *status) {
        [self.realtime.connection off:listener];
        if (cb && !gotFailure) cb(status);
    }];
}

- (ARTPresenceMap *) presenceMap {
    return _presenceMap;
}

- (void)throwOnDisconnectedOrFailed {
    if(self.realtime.connection.state == ARTRealtimeFailed || self.realtime.connection.state == ARTRealtimeDisconnected) {
        [NSException raise:@"realtime cannot perform action in disconnected or failed state" format:@"state: %d", (int)self.realtime.connection.state];
    }
}

- (ARTEventListener<ARTMessage *> *)subscribe:(void (^)(ARTMessage * _Nonnull))cb {
    return [self subscribeWithAttachCallback:nil callback:cb];
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
    return [self.messagesEventEmitter on:name call:cb];
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

- (__GENERIC(ARTEventListener, ARTErrorInfo *) *)on:(ARTChannelEvent)event call:(void (^)(ARTErrorInfo *))cb {
    return [self.statesEventEmitter on:[NSNumber numberWithInt:event] call:cb];
}

- (__GENERIC(ARTEventListener, ARTErrorInfo *) *)on:(void (^)(ARTErrorInfo *))cb {
    return [self.statesEventEmitter on:cb];
}

- (__GENERIC(ARTEventListener, ARTErrorInfo *) *)once:(ARTChannelEvent)event call:(void (^)(ARTErrorInfo *))cb {
    return [self.statesEventEmitter once:[NSNumber numberWithInt:event] call:cb];
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

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status {
    [self cancelAttachTimer];
    [self cancelDetachTimer];
    if (self.state == state) {
        return;
    }

    self.state = state;
    _errorReason = status.errorInfo;

    [self emit:(ARTChannelEvent)state with:status.errorInfo];
}

- (void)cancelAttachTimer {
    [self.realtime cancelTimer:_attachTimer];
    _attachTimer = nil;
}

- (void)cancelDetachTimer {
    [self.realtime cancelTimer:_detachTimer];
    _detachTimer = nil;
}

- (void)dealloc {
    [self cancelAttachTimer];
    [self cancelDetachTimer];
}

/**
 Checks that a channelSerial is the final serial in a sequence of sync messages,
 by checking that there is nothing after the colon
 */
- (bool)isLastChannelSerial:(NSString *) channelSerial {
    NSArray * a = [channelSerial componentsSeparatedByString:@":"];
    if([a count] >1 && ![[a objectAtIndex:1] isEqualToString:@""] ) {
        return false;
    }
    return true;
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
    
    if(message.action ==ARTProtocolMessageAttached && [message isSyncEnabled]) {
        [self.presenceMap startSync];
    }
    else if(message.action == ARTProtocolMessageSync || message.action == ARTProtocolMessagePresence) {
        [self.logger info:@"ARTRealtime sync message received"];
        self.presenceMap.syncSerial = message.connectionSerial;
        for(int i=0; i< [message.presence count]; i++) {
            [self.presenceMap put:[message.presence objectAtIndex:i]];
        }
        NSString * channelSerial = message.channelSerial;
        if([self isLastChannelSerial:channelSerial]) {
            [self.presenceMap endSync];
        }
    }
    
    switch (message.action) {
        case ARTProtocolMessageAttached:
            [self setAttached:message];
            break;
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
            [self.presenceMap syncMessageProcessed];
            break;
        default:
            [self.logger warn:@"ARTRealtime, unknown ARTProtocolMessage action: %tu", message.action];
            break;
    }
}

- (ARTRealtimeChannelState)state {
    return _state;
}

- (void)setAttached:(ARTProtocolMessage *)message {
    self.attachSerial = message.channelSerial;
    [self sendQueuedMessages];
    
    for (ARTPresenceMessage *pm in message.presence) {
        [self.presenceDict setObject:pm forKey:pm.clientId];
    }
    [self transition:ARTRealtimeChannelAttached status:[ARTStatus state:ARTStateOk]];
    [_attachedEventEmitter emit:[NSNull null] with:nil];
}

- (void)setDetached:(ARTProtocolMessage *)message {
    self.attachSerial = nil;
    
    ARTStatus *reason = [ARTStatus state:ARTStateNotAttached info:message.error];
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
        if (dataEncoder) {
            NSError *error = nil;
            msg = [msg decodeWithEncoder:dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:(ARTErrorInfo *)error.userInfo[NSLocalizedFailureReasonErrorKey] prepend:@"Failed to decode data: "];
                [self.logger error:@"%@", errorInfo.message];
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
        ARTPresenceMessage *pm = p;
        if (dataEncoder) {
            NSError *error = nil;
            pm = [pm decodeWithEncoder:dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:(ARTErrorInfo *)error.userInfo[NSLocalizedFailureReasonErrorKey] prepend:@"Failed to decode data: "];
                [self.logger error:@"%@", errorInfo.message];
            }
        }
        
        if (!pm.timestamp) {
            pm.timestamp = message.timestamp;
        }
        
        if (!pm.id) {
            pm.id = [NSString stringWithFormat:@"%@:%d", message.id, i];
        }
        
        [self.presenceDict setObject:pm forKey:pm.clientId];
        [self broadcastPresence:pm];
        
        ++i;
    }
}

- (void)broadcastPresence:(ARTPresenceMessage *)pm {
    [self.presenceEventEmitter emit:[NSNumber numberWithUnsignedInteger:pm.action] with:pm];
}

- (void)onError:(ARTProtocolMessage *)msg {
    [self failQueuedMessages:[ARTStatus state:ARTStateError info: msg.error]];
    [self transition:ARTRealtimeChannelFailed status:[ARTStatus state:ARTStateError info: msg.error]];
}

- (void)attach {
    [self attach:nil];
}

- (void)attach:(void (^)(ARTErrorInfo * _Nullable))cb {
    switch (self.state) {
        case ARTRealtimeChannelAttaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"already attaching"];
            if (cb) [_attachedEventEmitter once:cb];
            return;
        case ARTRealtimeChannelAttached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"already attached"];
            if (cb) cb(nil);
            return;
        default:
            break;
    }
    
    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"can't attach when not in an active state"];
        if (cb) cb([ARTErrorInfo createWithCode:90000 message:@"Can't attach when not in an active state"]);
        return;
    }

    ARTProtocolMessage *attachMessage = [[ARTProtocolMessage alloc] init];
    attachMessage.action = ARTProtocolMessageAttach;
    attachMessage.channel = self.name;

    __block BOOL timeouted = false;

    [self.realtime send:attachMessage callback:nil];
    if (cb) [_attachedEventEmitter once:cb];
    // Set state: Attaching
    [self transition:ARTRealtimeChannelAttaching status:[ARTStatus state:ARTStateOk]];

    _attachTimer = [self.realtime startTimer:^{
        timeouted = true;
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateAttachTimedOut message:@"attach timed out"];
        ARTStatus *status = [ARTStatus state:ARTStateAttachTimedOut info:errorInfo];
        _errorReason = errorInfo;
        [self transition:ARTRealtimeChannelFailed status:status];
        [_attachedEventEmitter emit:[NSNull null] with:errorInfo];
    } interval:[ARTDefault realtimeRequestTimeout]];
}

- (void)detach:(void (^)(ARTErrorInfo * _Nullable))cb {
    switch (self.state) {
        case ARTRealtimeChannelInitialised:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"can't detach when not attached"];
            if (cb) [_detachedEventEmitter once:cb];
            return;
        case ARTRealtimeChannelDetaching:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"already detaching"];
            if (cb) [_detachedEventEmitter once:cb];
            return;
        case ARTRealtimeChannelDetached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"already detached"];
            if (cb) cb(nil);
            return;
        default:
            break;
    }
    
    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"can't detach when not in an active state"];
        if (cb) cb([ARTErrorInfo createWithCode:90000 message:@"Can't detach when not in an active state"]);
        return;
    }

    ARTProtocolMessage *detachMessage = [[ARTProtocolMessage alloc] init];
    detachMessage.action = ARTProtocolMessageDetach;
    detachMessage.channel = self.name;
    
    __block BOOL timeouted = false;

    [self.realtime send:detachMessage callback:nil];
    if (cb) [_detachedEventEmitter once:cb];
    // Set state: Detaching
    [self transition:ARTRealtimeChannelDetaching status:[ARTStatus state:ARTStateOk]];

    _detachTimer = [self.realtime startTimer:^{
        timeouted = true;
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTStateDetachTimedOut message:@"detach timed out"];
        ARTStatus *status = [ARTStatus state:ARTStateDetachTimedOut info:errorInfo];
        _errorReason = errorInfo;
        [self transition:ARTRealtimeChannelFailed status:status];
        [_detachedEventEmitter emit:[NSNull null] with:errorInfo];
    } interval:[ARTDefault realtimeRequestTimeout]];

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

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, NSError *))callback {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, NSError *))callback error:(NSError **)errorPtr {
    query.realtimeChannel = self;
    @try {
        return [super history:query callback:callback error:errorPtr];
    }
    @catch (NSError *error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return false;
    }
}

@end
