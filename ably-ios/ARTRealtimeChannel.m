//
//  ARTRealtimeChannel.m
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtimeChannel.h"
#import "ARTChannel+Private.h"

#import "ARTRealtime+Private.h"
#import "ARTMessage.h"
#import "ARTAuth.h"
#import "ARTRealtimePresence.h"
#import "ARTChannel.h"
#import "ARTChannelOptions.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTRealtimeChannelSubscription.h"
#import "ARTPresenceMap.h"
#import "ARTQueuedMessage.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTStatus.h"

@interface ARTRealtimeChannel () {
    ARTRealtimePresence *_realtimePresence;
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
        _subscriptions = [NSMutableDictionary dictionary];
        _presenceSubscriptions = [NSMutableArray array];
        _stateSubscriptions = [NSMutableArray array];
        _presenceMap =[[ARTPresenceMap alloc] init];
        _lastPresenceAction = ARTPresenceAbsent;
    }
    return self;
}

+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options {
    return [[ARTRealtimeChannel alloc] initWithRealtime:realtime andName:name withOptions:options];
}

- (ARTRealtimePresence *)presence {
    if (!_realtimePresence) {
        _realtimePresence = [[ARTRealtimePresence alloc] initWithChannel:self];
    }
    return _realtimePresence;
}

- (void)publish:(id)data cb:(ARTStatusCallback)cb {
    if([data isKindOfClass:[NSArray class]]) {
        NSArray * messages = [ARTMessage messagesWithData:(NSArray *) data];
        [self publishMessages:messages cb:cb];
    }
    else {
        [self publish:data withName:nil cb:cb];
    }
}

- (void)publish:(id)data withName:(NSString *)name cb:(ARTStatusCallback)cb {
    NSArray *messages = [NSArray arrayWithObject:[ARTMessage messageWithData:data name:name]];
    [self publishMessages:messages cb:cb];
}

- (void)publishMessages:(NSArray *)messages cb:(ARTStatusCallback)cb {
    ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageMessage;
    msg.channel = self.name;
    msg.messages = [messages artMap:^id(ARTMessage *message) {
        return [self encodeMessageIfNeeded:message];
    }];
    [self publishProtocolMessage:msg cb:cb];
}

- (void)requestContinueSync {
    [self.logger info:@"ARTRealtime requesting to continue sync operation after reconnect"];
    
    ARTProtocolMessage * msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageSync;
    msg.msgSerial = self.presenceMap.syncSerial;
    msg.channel = self.name;


    [self.realtime send:msg cb:^(ARTStatus *status) {}];
}

- (void)publishPresence:(ARTPresenceMessage *)msg cb:(ARTStatusCallback)cb {
    if (!msg.clientId) {
        msg.clientId = self.clientId;
    }
    if (!msg.clientId) {
        cb([ARTStatus state:ARTStateNoClientId]);
        return;
    }
    _lastPresenceAction = msg.action;
    
    if (msg.data && self.dataEncoder) {
        ARTDataEncoderOutput *encoded = [self.dataEncoder encode:msg.data];
        if (encoded.status.state != ARTStateOk) {
            [self.logger warn:@"bad status encoding presence message %d",(int) encoded.status];
        }
        msg.data = encoded.data;
        msg.encoding = encoded.encoding;
    }
    
    ARTProtocolMessage *pm = [[ARTProtocolMessage alloc] init];
    pm.action = ARTProtocolMessagePresence;
    pm.channel = self.name;
    pm.presence = @[msg];
    
    [self publishProtocolMessage:pm cb:cb];
}

- (void)publishProtocolMessage:(ARTProtocolMessage *)pm cb:(ARTStatusCallback)cb {
    switch (self.state) {
        case ARTRealtimeChannelInitialised:
            [self attach];
            // intentional fall-through
        case ARTRealtimeChannelAttaching:
        {
            ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:pm cb:cb];
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
            [self.realtime send:pm cb:cb];
            break;
        }
        default:
            NSAssert(NO, @"Invalid State");
    }
}

- (ARTPresenceMap *) presenceMap {
    return _presenceMap;
}

- (void)throwOnDisconnectedOrFailed {
    if(self.realtime.state == ARTRealtimeFailed || self.realtime.state == ARTRealtimeDisconnected) {
        [NSException raise:@"realtime cannot perform action in disconnected or failed state" format:@"state: %d", (int)self.realtime.state];
    }
}

- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelMessageCb)cb {
    // Empty string used for blanket subscriptions
    return [self subscribeToName:@"" cb:cb];
}

- (id<ARTSubscription>)subscribeToName:(NSString *)name cb:(ARTRealtimeChannelMessageCb)cb {
    return [self subscribeToNames:@[name] cb:cb];
}

- (id<ARTSubscription>)subscribeToNames:(NSArray *)names cb:(ARTRealtimeChannelMessageCb)cb {
    NSSet *nameSet = [NSSet setWithArray:names];
    
    ARTRealtimeChannelSubscription *subscription = [[ARTRealtimeChannelSubscription alloc] initWithChannel:self cb:cb];
    
    for (NSString *name in nameSet) {
        NSMutableArray *subscriptions = [self.subscriptions objectForKey:name];
        if (!subscriptions) {
            subscriptions = [NSMutableArray array];
            [self.subscriptions setValue:subscriptions forKey:name];
        }
        
        [subscriptions addObject:subscription];
    }
    
    // Trigger attach
    [self attach];
    
    return subscription;
}

- (void)unsubscribe:(ARTRealtimeChannelSubscription *)subscription {
    NSMutableArray *toRemove = [NSMutableArray array];
    for (NSString *name in self.subscriptions) {
        NSMutableArray *subscriptions = [self.subscriptions objectForKey:name];
        [subscriptions removeObject:subscription];
        if (subscriptions.count == 0) {
            [toRemove addObject:name];
        }
    }
    
    [self.subscriptions removeObjectsForKeys:toRemove];
}

- (id<ARTSubscription>)subscribeToStateChanges:(ARTRealtimeChannelStateCb)cb {
    ARTRealtimeChannelStateSubscription *subscription = [[ARTRealtimeChannelStateSubscription alloc] initWithChannel:self cb:cb];
    [self.stateSubscriptions addObject:subscription];
    return subscription;
}

- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription {
    [self.stateSubscriptions removeObject:subscription];
}

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status {
    if (self.state == state) {
        return;
    }

    self.state = state;
    
    for (ARTRealtimeChannelStateSubscription *subscription in self.stateSubscriptions) {
        subscription.cb(state, status);
    }
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
            break;
        default:
            [self.logger warn:@"ARTRealtime, unknown ARTProtocolMessage action: %tu", message.action];
            break;
    }
    
    if(message.action == ARTProtocolMessageSync) {
        [self.presenceMap syncMessageProcessed];
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
}

- (void)setDetached:(ARTProtocolMessage *)message {
    self.attachSerial = nil;
    
    ARTStatus *reason = [ARTStatus state:ARTStateNotAttached info:message.error];
    [self detachChannel:reason];
}

- (void)releaseChannel {
    [self detachChannel:ARTStateOk];
    [self.realtime removeChannel:self.name];
}

- (void)detachChannel:(ARTStatus *)error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelDetached status:error];
}

- (void)setFailed:(ARTStatus *)error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelFailed status:error];
}

- (void)setClosed:(ARTStatus *)error  {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelClosed status:error];
}

- (void)setSuspended:(ARTStatus *)error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelDetached status:error];
}

- (void)onMessage:(ARTProtocolMessage *)message {
    NSArray *blanketSubscriptions = [self.subscriptions objectForKey:@""];
    
    int i = 0;
    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTMessage *m in message.messages) {
        ARTMessage *msg = m;
        if (dataEncoder) {
            ARTStatus *status = [msg decodeWithEncoder:dataEncoder output:&msg];
             if (status.state != ARTStateOk) {
                [self.logger error:@"ARTRealtimeChannel: error decoding data, status: %tu", status];
            }
        }
        
        if (!msg.timestamp) {
            msg.timestamp = message.timestamp;
        }
        if (!msg.id) {
            msg.id = [NSString stringWithFormat:@"%@:%d", message.id, i];
        }
        
        // Notify subscribers that are interested in everything
        for (ARTRealtimeChannelSubscription *subscription in blanketSubscriptions) {
            subscription.cb(msg, nil);
        }
        
        if (msg.name && msg.name.length) {
            // Notify subscribers that are interested in this message
            NSArray *nameSubscriptions = [self.subscriptions objectForKey:msg.name];
            for (ARTRealtimeChannelSubscription *subscription in nameSubscriptions) {
                subscription.cb(msg, nil);
            }
        }
        
        ++i;
    }
}

- (void)onPresence:(ARTProtocolMessage *)message {
    int i = 0;
    ARTDataEncoder *dataEncoder = self.dataEncoder;
    for (ARTPresenceMessage *p in message.presence) {
        ARTPresenceMessage *pm = p;
        if (dataEncoder) {
            ARTStatus *status = [pm decodeWithEncoder:dataEncoder output:&pm];
             if (status.state != ARTStateOk) {
                [self.logger error:@"ARTRealtimeChannel: error decoding data, status: %tu", status];
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
    for (ARTRealtimeChannelPresenceSubscription *subscription in self.presenceSubscriptions) {
        if(![[subscription excludedActions] containsObject:[NSNumber numberWithInt:(int) pm.action]]) {
            subscription.cb(pm);
        }
    }
}

- (void)onError:(ARTProtocolMessage *)msg {
    [self failQueuedMessages:[ARTStatus state:ARTStateError info: msg.error]];
    [self transition:ARTRealtimeChannelFailed status:[ARTStatus state:ARTStateError info: msg.error]];
}

- (ARTErrorInfo *)attach {
    switch (self.state) {
        case ARTRealtimeChannelAttaching:
        case ARTRealtimeChannelAttached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"already attached"];
            return [ARTErrorInfo createWithCode:90000 message:@"Already attached"];
        default:
            break;
    }
    
    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"can't attach when not in an active state"];
        return [ARTErrorInfo createWithCode:90000 message:@"Can't attach when not in an active state"];
    }

    ARTProtocolMessage *attachMessage = [[ARTProtocolMessage alloc] init];
    attachMessage.action = ARTProtocolMessageAttach;
    attachMessage.channel = self.name;

    [self.realtime send:attachMessage cb:nil];
    // Set state: Attaching
    [self transition:ARTRealtimeChannelAttaching status:[ARTStatus state:ARTStateOk]];
    return nil;
}

- (ARTErrorInfo *)detach {
    switch (self.state) {
        case ARTRealtimeChannelInitialised:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached:
            [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"can't detach when not attahed"];
            return [ARTErrorInfo createWithCode:90000 message:@"Can't detach when not attahed"];
        default:
            break;
    }
    
    if (![self.realtime isActive]) {
        [self.realtime.logger debug:__FILE__ line:__LINE__ message:@"can't detach when not in an active state"];
        return [ARTErrorInfo createWithCode:90000 message:@"Can't detach when not in an active state"];
    }

    ARTProtocolMessage *detachMessage = [[ARTProtocolMessage alloc] init];
    detachMessage.action = ARTProtocolMessageDetach;
    detachMessage.channel = self.name;
    
    [self.realtime send:detachMessage cb:nil];
    // Set state: Detaching
    [self transition:ARTRealtimeChannelDetaching status:[ARTStatus state:ARTStateOk]];
    return nil;
}

- (void)sendQueuedMessages {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *qm in qms) {
        [self.realtime send:qm.msg cb:qm.cb];
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

@end
