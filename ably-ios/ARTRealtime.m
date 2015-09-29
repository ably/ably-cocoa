
//
//  ARTRealtime.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRealtime.h"
#import "ARTRealtimeTransport.h"
#import "ARTRest.h"
#import "ARTMessage.h"
#import "ARTPresenceMessage.h"
#import "ARTWebSocketTransport.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTRealtime+Private.h"
#import "ARTLog.h"
#import "ARTPresenceMap.h"
#import "ARTStatus.h"
#import "ARTDefault.h"

@interface ARTQueuedMessage : NSObject

@property (readonly, strong, nonatomic) ARTProtocolMessage *msg;
@property (readonly, strong, nonatomic) NSMutableArray *cbs;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb;
- (BOOL)mergeFrom:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb;

- (ARTStatusCallback)cb;

@end


@interface ARTRealtimeChannelSubscription : NSObject <ARTSubscription>

@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;
@property (readonly, strong, nonatomic) ARTRealtimeChannelMessageCb cb;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelMessageCb)cb;

- (void)unsubscribe;

@end


@interface ARTRealtimeChannelPresenceSubscription : NSObject <ARTSubscription>

@property (readonly, strong, nonatomic) NSMutableSet * excludedActions;
@property (readonly, assign, nonatomic) ARTPresenceMessageAction action;
@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;
@property (readonly, strong, nonatomic) ARTRealtimeChannelPresenceCb cb;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelPresenceCb)cb;

- (void)unsubscribe;

@end


@interface ARTRealtimeChannelStateSubscription : NSObject <ARTSubscription>

@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;
@property (readonly, strong, nonatomic) ARTRealtimeChannelStateCb cb;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelStateCb)cb;

- (void)unsubscribe;

@end


@interface ARTRealtimeConnectionStateSubscription : NSObject <ARTSubscription>

@property (readonly, weak, nonatomic) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) ARTRealtimeConnectionStateCb cb;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime cb:(ARTRealtimeConnectionStateCb)cb;

- (void)unsubscribe;

@end


@interface ARTPresence ()

@property (nonatomic, weak) ARTLog * logger;
@property (readonly, weak, nonatomic) ARTRealtimeChannel *channel;

@end

@interface ARTEventEmitter ()

@property (readonly, weak, nonatomic) ARTRealtime * realtime;

@end


#pragma mark - ARTRealtimeChannel interface

@interface ARTRealtimeChannel ()

@property (nonatomic, weak) ARTLog * logger;
@property (readonly, strong, nonatomic) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) NSString *name;
@property (readonly, strong, nonatomic) ARTRestChannel *restChannel;
@property (readwrite, assign, nonatomic)ARTRealtimeChannelState state;
@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readwrite, strong, nonatomic) NSString *attachSerial;
@property (readonly, strong, nonatomic) NSMutableDictionary *subscriptions;
@property (readonly, strong, nonatomic) NSMutableArray *presenceSubscriptions;
@property (readonly, strong, nonatomic) NSMutableDictionary *presenceDict;
@property (readonly, strong, nonatomic) NSString *clientId;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;
@property (readonly, strong, nonatomic) id<ARTPayloadEncoder> payloadEncoder;
@property (readwrite, strong, nonatomic) ARTPresenceMap * presenceMap;
@property (readwrite, assign, nonatomic) ARTPresenceMessageAction lastPresenceAction;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status;

- (void)onChannelMessage:(ARTProtocolMessage *)message;
- (void)publishMessages:(NSArray *)messages cb:(ARTStatusCallback)cb;
- (void)publishPresence:(ARTPresenceMessage *)pm cb:(ARTStatusCallback)cb;
- (void)publishProtocolMessage:(ARTProtocolMessage *)pm cb:(ARTStatusCallback)cb;

- (void)setAttached:(ARTProtocolMessage *)message;
- (void)setDetached:(ARTProtocolMessage *)message;
- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onPresence:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)error;
- (void)setSuspended:(ARTStatus *)error;

- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)status;

- (void)unsubscribe:(ARTRealtimeChannelSubscription *)subscription;
- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription;

- (void)broadcastPresence:(ARTPresenceMessage *)pm;

@end


#pragma mark - ARTRealtime interface

@interface ARTRealtime () <ARTRealtimeTransportDelegate>

@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readonly, strong, nonatomic) NSMutableDictionary *allChannels;
@property (readwrite, strong, nonatomic) id<ARTRealtimeTransport> transport;
@property (readwrite, assign, nonatomic) ARTRealtimeConnectionState state;

@property (readwrite, assign, nonatomic) CFRunLoopTimerRef connectTimeout;
@property (readwrite, assign, nonatomic) CFRunLoopTimerRef suspendTimeout;
@property (readwrite, assign, nonatomic) CFRunLoopTimerRef retryTimeout;
@property (readwrite, assign, nonatomic) CFRunLoopTimerRef closeTimeout;
@property (readwrite, assign, nonatomic) CFRunLoopTimerRef pingTimeout;

@property (readwrite, strong, nonatomic) NSString *connectionId;
@property (readwrite, strong, nonatomic) NSString *connectionKey; //for recovery
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (readwrite, assign, nonatomic) int64_t msgSerial;

@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readonly, strong, nonatomic) NSMutableArray *pendingMessages;
@property (readwrite, assign, nonatomic) int64_t pendingMessageStartSerial;
@property (readonly, strong, nonatomic) NSString *clientId;

@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;
@property (nonatomic, copy) ARTRealtimePingCb pingCb;
@property (readonly, weak, nonatomic) ARTClientOptions *options;
@property (readwrite, strong, nonatomic) ARTErrorInfo *errorReason;


- (void)transition:(ARTRealtimeConnectionState)state;

- (BOOL)connect;

// Timer starters
- (void)startConnectTimer;
- (void)startSuspendTimer;
- (void)startRetryTimer:(NSTimeInterval)timeout;
- (void)startCloseTimer;
- (void)startPingTimer;

// Timer cancellers
- (void)cancelConnectTimer;
- (void)cancelSuspendTimer;
- (void)cancelRetryTimer;
- (void)cancelPingTimer;
- (void)cancelCloseTimer;

// Timer events
- (void)onConnectTimerFired;
- (void)onSuspendTimerFired;
- (void)onRetryTimerFired;
- (void)onCloseTimerFired;

// State properties
- (BOOL)shouldSendEvents;
- (BOOL)shouldQueueEvents;
- (NSTimeInterval)retryInterval;
- (ARTStatus *)defaultError;
- (BOOL)isActive;

// Message sending
- (void)send:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb;
- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)error;
- (void)ack:(int64_t)serial count:(int64_t)count;
- (void)nack:(int64_t)serial count:(int64_t)count;

// util
- (id<ARTRealtimeTransport>)createTransport;
- (CFRunLoopTimerRef)startTimer:(void(^)())onTimeout interval:(NSTimeInterval)interval;
- (void)cancelTimer:(CFRunLoopTimerRef)timer;

- (void)unsubscribeState:(ARTRealtimeConnectionStateSubscription *)subscription;

@end


#pragma mark - ARTQueuedMessage

@implementation ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb {
    self = [super init];
    if (self) {
        _msg = msg;
        _cbs = [NSMutableArray array];
        if (cb) {
            [_cbs addObject:cb];
        }
    }
    return self;
}

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb {
    if ([self.msg mergeFrom:msg]) {
        if (cb) {
            [self.cbs addObject:cb];
        }
        return YES;
    }
    return NO;
}

- (ARTStatusCallback)cb {
    return ^(ARTStatus * status) {
        for (ARTStatusCallback cb in self.cbs) {
            cb(status);
        }
    };
}

@end


#pragma mark - ARTRealtimeChannelSubscription

@implementation ARTRealtimeChannelSubscription

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelMessageCb)cb {
    self = [super init];
    if (self) {
        _channel = channel;
        _cb = cb;
    }
    return self;
}

- (void)unsubscribe {
    [self.channel unsubscribe:self];
}

@end


#pragma mark - ARTRealtimeChannelPresenceSubscription

@implementation ARTRealtimeChannelPresenceSubscription

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelPresenceCb)cb {
    self = [super init];
    if (self) {
        _channel = channel;
        _cb = cb;
        _action = ARTPresenceMessageLast;
        _excludedActions = [NSMutableSet set];
    }
    return self;
}

- (void)excludeAction:(ARTPresenceMessageAction) action {
    [_excludedActions addObject:[NSNumber numberWithInt:(int) action]];
}
- (void)excludeAllActionsExcept:(ARTPresenceMessageAction) action {
    for(int i=0; i<(int) ARTPresenceMessageLast; i++) {
        if(i != (int) action) {
            [_excludedActions addObject:[NSNumber numberWithInt:(int) i]];
        }
    }
}

- (void)includeAction:(ARTPresenceMessageAction) action {
    [_excludedActions removeObject:[NSNumber numberWithInt:(int) action]];
}

- (void)unsubscribe {
    [self.channel.presence unsubscribe:self];
}

@end


#pragma mark - ARTRealtimeChannelStateSubscription

@implementation ARTRealtimeChannelStateSubscription

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelStateCb)cb {
    self = [super init];
    if (self) {
        _channel = channel;
        _cb = cb;
    }
    return self;
}

- (void)unsubscribe {
    [self.channel unsubscribeState:self];
}

@end


#pragma mark - ARTRealtimeConnectionStateSubscription

@implementation ARTRealtimeConnectionStateSubscription

- (instancetype)initWithRealtime:(ARTRealtime *)realtime cb:(ARTRealtimeConnectionStateCb)cb {
    self = [super init];
    if (self) {
        _realtime = realtime;
        _cb = cb;
    }
    return self;
}

- (void)unsubscribe {
    [self.realtime unsubscribeState:self];
}

@end


#pragma mark - ARTRealtimeChannel

@implementation ARTRealtimeChannel

- (instancetype)initWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams {
    self = [super init];
    if (self) {
        self.logger = realtime.logger;
        _presence = [[ARTPresence alloc] initWithChannel:self];
        _realtime = realtime;
        _name = name;
        _restChannel = [realtime.rest channel:name];
        _state = ARTRealtimeChannelInitialised;
        _queuedMessages = [NSMutableArray array];
        _attachSerial = nil;
        _subscriptions = [NSMutableDictionary dictionary];
        _presenceSubscriptions = [NSMutableArray array];
        _stateSubscriptions = [NSMutableArray array];
        _clientId = realtime.clientId;
        _payloadEncoder = [ARTPayload defaultPayloadEncoder:cipherParams];
        _presenceMap =[[ARTPresenceMap alloc] init];
        _lastPresenceAction = ArtPresenceMessageAbsent;
    }
    return self;
}

+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams {
    return [[ARTRealtimeChannel alloc] initWithRealtime:realtime name:name cipherParams:cipherParams];
}

- (void)publish:(id)payload cb:(ARTStatusCallback)cb {
    if([payload isKindOfClass:[NSArray class]]) {
        NSArray * messages = [ARTMessage messagesWithPayloads:(NSArray *) payload];
        [self publishMessages:messages cb:cb];
    }
    else {
        [self publish:payload withName:nil cb:cb];
    }
}

- (void)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb {
    NSArray *messages = [NSArray arrayWithObject:[ARTMessage messageWithPayload:payload name:name]];
    [self publishMessages:messages cb:cb];
}

- (void)publishMessages:(NSArray *)messages cb:(ARTStatusCallback)cb {
    if (self.payloadEncoder) {
        messages = [messages artMap:^id(ARTMessage *message) {
            ARTPayload *encodedPayload = nil;
            ARTStatus * status = [self.payloadEncoder encode:message.payload output:&encodedPayload];
            if (status.state != ARTStateOk) {
                [self.logger error:[NSString stringWithFormat:@"ARTRealtime: error decoding payload, status: %tu", status]];
            }
            return [message messageWithPayload:encodedPayload];
        }];
    }
    ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
    msg.action = ARTProtocolMessageMessage;
    msg.channel = self.name;
    msg.messages = messages;
    [self publishProtocolMessage:msg cb:cb];
}

- (void) requestContinueSync {
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
    if(!msg.clientId) {
        cb([ARTStatus state:ARTStateNoClientId]);
        return;
    }
    _lastPresenceAction = msg.action;

    if (msg.payload && self.payloadEncoder) {
        ARTPayload *encodedPayload = nil;
        ARTStatus * status = [self.payloadEncoder encode:msg.payload output:&encodedPayload];
        if (status.state != ARTStateOk) {
            [self.logger warn:[NSString stringWithFormat:@"bad status encoding presence message %d",(int) status]];
        }
        msg.payload = encodedPayload;
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
                ARTStatus *status = [ARTStatus state:ARTStateError];
                [status.errorInfo setCode:90001 message:@"invalid channel state"];
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

-(void) throwOnDisconnectedOrFailed {
    if(self.realtime.state == ARTRealtimeFailed || self.realtime.state == ARTRealtimeDisconnected) {
        [NSException raise:@"realtime cannot perform action in disconnected or failed state" format:@"state: %d", (int)self.realtime.state];
    }
}

- (id<ARTCancellable>)history:(ARTPaginatedResultCallback)callback {
    [self throwOnDisconnectedOrFailed];
    return [self.restChannel history:callback];
}

- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCallback)callback {
    [self throwOnDisconnectedOrFailed];
    if([queryParams objectForKey:@"until_attach"] != nil  && self.state != ARTRealtimeChannelAttached) {
        [NSException raise:@"Cannot ask for history with param untilAttach when not attached" format:@""];
    }
    return [self.restChannel historyWithParams:queryParams cb:callback];
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
    self.state = state;

    for (ARTRealtimeChannelStateSubscription *subscription in self.stateSubscriptions) {
        subscription.cb(state, status);
    }
}

/**
 Checks that a channelSerial is the final serial in a sequence of sync messages,
 by checking that there is nothing after the colon
 */
-(bool) isLastChannelSerial:(NSString *) channelSerial {
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
            [self.logger warn:[NSString stringWithFormat:@"ARTRealtime, unknown ARTProtocolMessage action: %tu", message.action]];
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
    [self transition:ARTRealtimeChannelAttached status:ARTStateOk];
}

- (void)setDetached:(ARTProtocolMessage *)message {
    self.attachSerial = nil;

    ARTStatus *reason =  [ARTStatus state:ARTStateNotAttached info:message.error];
    [self detachChannel:reason];
}

- (void)releaseChannel {
    [self detachChannel:ARTStateOk];
    [self.realtime.allChannels removeObjectForKey:self.name];
}

- (void) detachChannel:(ARTStatus *) error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelDetached status:error];
}

-(void) setFailed:(ARTStatus *) error {
    [self failQueuedMessages:error];
    [self transition:ARTRealtimeChannelFailed status:error];
}

-(void) setClosed:(ARTStatus *) error  {
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
    id<ARTPayloadEncoder> payloadEncoder = self.payloadEncoder;
    for (ARTMessage *m in message.messages) {
        ARTMessage *msg = m;
        if (payloadEncoder) {
            msg = [msg decode:payloadEncoder];
        }

        if (!msg.timestamp) {
            msg.timestamp = message.timestamp;
        }
        if (!msg.id) {
            msg.id = [NSString stringWithFormat:@"%@:%d", message.id, i];
        }

        // Notify subscribers that are interested in everything
        for (ARTRealtimeChannelSubscription *subscription in blanketSubscriptions) {
            subscription.cb(msg);
        }

        if (msg.name && msg.name.length) {
            // Notify subscribers that are interested in this message
            NSArray *nameSubscriptions = [self.subscriptions objectForKey:msg.name];
            for (ARTRealtimeChannelSubscription *subscription in nameSubscriptions) {
                subscription.cb(msg);
            }
        }

        ++i;
    }
}

- (void)onPresence:(ARTProtocolMessage *)message {
    int i = 0;
    id<ARTPayloadEncoder> payloadEncoder = self.payloadEncoder;
    for (ARTPresenceMessage *p in message.presence) {
        ARTPresenceMessage *pm = p;
        if (payloadEncoder) {
            pm = [pm decode:payloadEncoder];
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


- (BOOL)attach {
    switch (self.state) {
        case ARTRealtimeChannelAttaching:
        case ARTRealtimeChannelAttached:
            [self.realtime.errorReason setCode:90000 message:@"Already attached"];
            return false;
        default:
            break;
    }

    if (![self.realtime isActive]) {
        [self.realtime.errorReason setCode:90000 message:@"Can't attach when not in an active state"];
        return false;
    }

    ARTProtocolMessage *attachMessage = [[ARTProtocolMessage alloc] init];
    attachMessage.action = ARTProtocolMessageAttach;
    attachMessage.channel = self.name;

    // TODO should queueEvents be forced?
    [self.realtime send:attachMessage cb:nil];

    [self transition:ARTRealtimeChannelAttaching status:ARTStateOk];
    return true;
}

- (BOOL)detach {
    switch (self.state) {
        case ARTRealtimeChannelInitialised:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached:
            [self.realtime.errorReason setCode:90000 message:@"Can't detach when not attahed"];
            return false;
        default:
            break;
    }
    
    if (![self.realtime isActive]) {
        [self.realtime.errorReason setCode:90000 message:@"Can't detach when not in an active state"];
        return false;
    }
    
    ARTProtocolMessage *detachMessage = [[ARTProtocolMessage alloc] init];
    detachMessage.action = ARTProtocolMessageDetach;
    detachMessage.channel = self.name;
    
    [self.realtime send:detachMessage cb:nil];
    [self transition:ARTRealtimeChannelDetaching status:ARTStateOk];
    return true;
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

@end


#pragma mark - ARTRealtime

@implementation ARTRealtime

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    return [self initWithLogger:[[ARTLog alloc] init] andOptions:options];
}

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[ARTClientOptions optionsWithKey:key]];
}

- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRealtime: No options provided");
        
        _rest = [[ARTRest alloc] initWithLogger:logger andOptions:options];
        _eventEmitter = [[ARTEventEmitter alloc] initWithRealtime:self];
        _allChannels = [NSMutableDictionary dictionary];
        _transport = nil;
        self.state = ARTRealtimeInitialized;
        _connectTimeout = NULL;
        _suspendTimeout = NULL;
        _retryTimeout = NULL;
        _connectionId = nil;
        _msgSerial = 0;
        _queuedMessages = [NSMutableArray array];
        _pendingMessages = [NSMutableArray array];
        _pendingMessageStartSerial = 0;
        _clientId = options.clientId;
        _options = options;
        _stateSubscriptions = [NSMutableArray array];
        _errorReason = [[ARTErrorInfo alloc] init];
        
        if (options.autoConnect) {
            [self connect];
        }
    }
    return self;
}

- (ARTLog *)getLogger {
    return _rest.logger;
}

- (ARTErrorInfo *)connectionErrorReason {
    return self.errorReason;
}

- (int64_t)connectionSerial {
    return _connectionSerial;
}

- (NSString *)getRecoveryString {
    NSString * recStr = self.connectionKey;
    NSString * str = [recStr stringByAppendingString:[NSString stringWithFormat:@":%lld", self.connectionSerial]];
    return str;
}

- (NSString *)recoveryKey {
    switch(self.state) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended:
            return [self getRecoveryString];
        default:
            return nil;
    }
}

- (ARTAuth *)auth {
    return self.rest.auth;
}

- (NSDictionary *)channels {
    return _allChannels;
}

- (void)dealloc {
    // Custom dealloc required to release CoreFoundation objects
    [self cancelConnectTimer];
    [self cancelSuspendTimer];
    [self cancelRetryTimer];

    self.transport.delegate = nil;
}

- (BOOL)connect {
    if(self.state == ARTRealtimeClosing) {
        return false;
    }
    [self transition:ARTRealtimeConnecting];
    return true;

}

- (void)close {
    [self transition:ARTRealtimeClosing];
}

- (id<ARTCancellable>)time:(void(^)(ARTStatus * status, NSDate *time))cb {
    return [self.rest time:cb];
}

- (void)ping:(ARTRealtimePingCb) cb {
    if(self.state == ARTRealtimeClosed || self.state == ARTRealtimeFailed) {
        [NSException raise:@"Can't ping a closed or failed connection" format:@"%@:", [ARTRealtime ARTRealtimeStateToStr:self.state]];
    }
    self.pingCb = cb;
    [self startPingTimer];
    [self.transport sendPing];
}

- (id<ARTCancellable>)stats:(ARTStatsQuery *)query callback:(ARTPaginatedResultCallback)callback {
    return [self.rest stats:query callback:callback];
}

- (ARTRealtimeChannel *)channel:(NSString *)channelName {
    return [self channel:channelName cipherParams:nil];
}

- (ARTRealtimeChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams {
    ARTRealtimeChannel *channel = [self.allChannels objectForKey:channelName];
    if (!channel) {
        channel = [ARTRealtimeChannel channelWithRealtime:self name:channelName cipherParams:cipherParams];
        [self.allChannels setObject:channel forKey:channelName];
    }

    return channel;
}


- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription {
    [self.stateSubscriptions removeObject:subscription];
}


- (BOOL)isFromResume {
    return self.options.resumeKey != nil;
}


- (void)transition:(ARTRealtimeConnectionState)state {
    [self.logger verbose:[NSString stringWithFormat:@"Transition to %@ requested", [ARTRealtime ARTRealtimeStateToStr:state]]];

    // On exit logic
    switch (self.state) {
        case ARTRealtimeInitialized:
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
        case ARTRealtimeClosed:
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended:
        case ARTRealtimeFailed:
        case ARTRealtimeClosing:
            // Currently no on-exit logic
            break;
    }

    // Cancel timers
    [self cancelConnectTimer];
    [self cancelRetryTimer];

    ARTRealtimeConnectionState previousState = self.state;
    self.state = state;

    // On enter logic
    switch (self.state) {
        case ARTRealtimeConnecting:
            [self startSuspendTimer];
            [self startConnectTimer];

            // Create transport and initiate connection
            if(!self.transport) {
                if(previousState == ARTRealtimeFailed || previousState == ARTRealtimeDisconnected) {
                    self.options.connectionSerial = self.connectionSerial;
                    self.options.resumeKey = self.connectionKey;
                }
                self.transport.delegate = nil;
                self.transport = [self createTransport];
                self.transport.delegate = self;
                [self.transport connect];
            }
            break;
        case ARTRealtimeConnected:
            if([self isFromResume]) {
                if(![self.options.resumeKey isEqualToString:self.connectionKey] || self.options.connectionSerial != self.connectionSerial) {
                    [self.logger warn:[NSString stringWithFormat:@"ARTRealtime connection has reconnected, but resume failed. Detaching all channels"]];
                    for (NSString *channelName in self.allChannels) {
                        ARTRealtimeChannel *channel = [self.allChannels objectForKey:channelName];
                        ARTErrorInfo * info = [[ARTErrorInfo alloc] init];
                        [info setCode:80000 message:@"resume connection failed"];
                        [channel detachChannel:[ARTStatus state:ARTStateConnectionDisconnected info:info]];
                    }
                }
                self.options.resumeKey = nil;
                 for (NSString *channelName in self.allChannels) {
                     ARTRealtimeChannel *channel = [self.allChannels objectForKey:channelName];
                     if([channel.presenceMap stillSyncing]) {
                         [channel requestContinueSync];
                     }
                 }
            }
            self.msgSerial = 0;
            [self cancelSuspendTimer];
            break;
        case ARTRealtimeClosing:
            [self startCloseTimer];
            [self.transport sendClose];
            break;
        case ARTRealtimeClosed:
            [self cancelCloseTimer];
            self.transport.delegate = nil;
            self.transport = nil;
        case ARTRealtimeFailed:
            // reasonFailed doesn't need to be a property on self
            [self.transport abort:[ARTStatus state:ARTStateConnectionFailed]];
            self.transport.delegate = nil;
            self.transport = nil;
            break;
        case ARTRealtimeDisconnected:
            [self.transport abort:[ARTStatus state:ARTStateConnectionDisconnected]];
            self.transport.delegate = nil;
            self.transport = nil;
        case ARTRealtimeInitialized:
        case ARTRealtimeSuspended:
            break;
    }

    NSTimeInterval retryInterval = [self retryInterval];
    if (retryInterval) {
        [self startRetryTimer:retryInterval];
    }

    if ([self shouldSendEvents]) {
        [self sendQueuedMessages];
    } else if (![self shouldQueueEvents]) {
        [self failQueuedMessages:[self defaultError]];
        for (NSString *channelName in self.allChannels) {
            ARTRealtimeChannel *channel = [self.allChannels objectForKey:channelName];
            if(channel.state == ARTRealtimeChannelInitialised || channel.state == ARTRealtimeChannelAttaching || channel.state == ARTRealtimeChannelAttached) {
                if(state == ARTRealtimeClosing) {
                    //do nothing. Closed state is coming.
                }
                else if(state == ARTRealtimeClosed) {
                    [channel setClosed:[self defaultError]];
                }
                else if(state == ARTRealtimeSuspended) {
                    [channel detachChannel:[self defaultError]];
                }
                else {
                    [channel setFailed:[self defaultError]];
                }
            }
            else {
                [channel setSuspended:[self defaultError]];
            }
        }
    }

    for (ARTRealtimeConnectionStateSubscription *subscription in self.stateSubscriptions) {
        subscription.cb(state);
    }

    if(state == ARTRealtimeClosing) {
        [self transition:ARTRealtimeClosed];
    }
}

- (ARTRealtimeConnectionState)state {
    return _state;
}
- (void)startConnectTimer {
    if (!self.connectTimeout) {
        self.connectTimeout = [self startTimer:^{
            [self onConnectTimerFired];
        }interval:[ARTDefault connectTimeout]];
    }
}

-(void) startCloseTimer {
    if(!self.closeTimeout) {
        self.closeTimeout = [self startTimer:^{
            [self onCloseTimerFired];
        } interval:10];
    }
}
- (void)startSuspendTimer {
    
    if (!self.suspendTimeout) {
        self.suspendTimeout = [self startTimer:^{
            [self onSuspendTimerFired];
        }interval:[ARTDefault suspendTimeout]];
    }
}

- (void)startRetryTimer:(NSTimeInterval)timeout {
    if (!self.retryTimeout) {
        self.retryTimeout = [self startTimer:^{
            [self onRetryTimerFired];
        }interval:timeout];
    }
}

- (void) startPingTimer {
    if (!self.pingTimeout) {
        self.pingTimeout = [self startTimer:^{
            [self onPingTimerFired];
        } interval:10.0];
    }
}
- (void)cancelConnectTimer {
    [self cancelTimer:self.connectTimeout];
    self.connectTimeout = nil;
}

- (void)cancelSuspendTimer {
    [self cancelTimer:self.suspendTimeout];
    self.suspendTimeout = nil;
}

- (void)cancelRetryTimer {
    [self cancelTimer:self.retryTimeout];
    self.retryTimeout = nil;
}

- (void) cancelCloseTimer {
    [self cancelTimer:self.closeTimeout];
    self.closeTimeout = nil;
}

-(void) cancelPingTimer {
    [self cancelTimer:self.pingTimeout];
    self.pingTimeout = nil;
}

- (void)onHeartbeat:(ARTProtocolMessage *)message {
    [self.logger verbose:@"ARTRealtime heartbeat received"];
    if(self.pingCb) {
        [self cancelPingTimer];
        if(self.state != ARTRealtimeConnected) {
            [self.logger warn:[NSString stringWithFormat:@"ARTRealtime received a ping when in state %@", [ARTRealtime ARTRealtimeStateToStr:self.state]]];
            self.pingCb([ARTStatus state:ARTStateError]);
        }
        else {
            self.pingCb([ARTStatus state:ARTStateOk]);
        }
        self.pingCb = nil;
    }
}

- (void)onConnected:(ARTProtocolMessage *)message {
    self.connectionId = message.connectionId;
    switch (self.state) {
        case ARTRealtimeConnecting:
 
            self.connectionKey = message.connectionKey;
            if(![self isFromResume]) {
                self.connectionSerial = -1;
            }
            [self transition:ARTRealtimeConnected];
            break;
        default:
            // TODO - Invalid transition
            break;
    }
}

-(NSString *) connectionKey {
    return _connectionKey;
}

- (NSString *) connectionId {
    return _connectionId;
}
- (void)onDisconnected:(ARTProtocolMessage *)message {
    [self.logger info:@"ARTRealtime disconnected"];
    switch (self.state) {
        case ARTRealtimeConnected:
            self.connectionId = nil;
            self.msgSerial = 0;
            [self transition:ARTRealtimeDisconnected];
            break;
        default:
            // TODO - Invalid transition
            break;
    }
}

- (void)onError:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    
    if (message.channel) {
        [self onChannelMessage:message];
    } else {
        self.connectionId = nil;
        [self transition:ARTRealtimeFailed];
    }
}

- (void)onAck:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    // TODO
    [self ack:message.msgSerial count:message.count];
}

- (void)onNack:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    [self nack:message.msgSerial count:message.count];
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    ARTRealtimeChannel *channel = [self.allChannels objectForKey:message.channel];
    [channel onChannelMessage:message];
}

- (void)onConnectTimerFired {
    switch (self.state) {
        case ARTRealtimeConnecting:
            [self.logger warn:@"ARTRealtime connecting timer fired."];
            
            NSLog(@"ARTRealtime connecting timer fired.");
            
            [self transition:ARTRealtimeFailed];
            break;
        default:
            // TODO invalid connection state
            break;
    }
}

- (void)onCloseTimerFired {
    [self transition:ARTRealtimeClosed];
}

- (void)onPingTimerFired {
    if(self.pingCb) {
        self.pingCb([ARTStatus state:ARTStateConnectionFailed]);
        self.pingCb = nil;
    }
}

- (void)onSuspended {
    [self transition:ARTRealtimeSuspended];
}

- (void)onSuspendTimerFired {
    switch (self.state) {
        case ARTRealtimeConnected:
            [self onSuspended];
            break;
        default:
            // TODO invalid connection state
            break;
    }
}

- (void)onRetryTimerFired {
    [self transition:ARTRealtimeConnecting];
}

- (BOOL)shouldSendEvents {
    switch (self.state) {
        case ARTRealtimeConnected:
            return true;
        default:
            return false;
    }
}

- (BOOL)shouldQueueEvents {
    if(!self.options.queueMessages) {
        return false;
    }
    switch (self.state) {
        case ARTRealtimeInitialized:
        case ARTRealtimeConnecting:
        case ARTRealtimeDisconnected:
            return true;
        default:
            return false;
    }
}

- (NSTimeInterval)retryInterval {
    switch (self.state) {
        case ARTRealtimeDisconnected:
            return [ARTDefault disconnectTimeout];
        case ARTRealtimeSuspended:
            return [ARTDefault suspendTimeout];
        default:
            return 0.0;
    }
}

- (ARTStatus *)defaultError {
    return [ARTStatus state:ARTStateError];
}

- (BOOL)isActive {
    return [self shouldQueueEvents] || [self shouldSendEvents];
}

- (void)sendImpl:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb {

    if (msg.ackRequired) {
        msg.msgSerial = self.msgSerial++;
        ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:msg cb:cb];
        [self.pendingMessages addObject:qm];
    }

    // TODO: ?? Add cb to the send call? No probably not
    // Wait, we have to do something with the cb!
    [self.transport send:msg];
}

- (void)send:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb {
    if ([self shouldSendEvents]) {
        [self sendImpl:msg cb:cb];
    } else if ([self shouldQueueEvents]) {
        BOOL merged = NO;
        if ([self.queuedMessages count]) {
            ARTQueuedMessage *lastQueued = [self.queuedMessages objectAtIndex:(self.queuedMessages.count) - 1];
            merged = [lastQueued mergeFrom:msg cb:cb];
        }
        if (!merged) {
            ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:msg cb:cb];
            [self.queuedMessages addObject:qm];
        }
    } else {
        // TODO review error code
        if (cb) {
            cb([ARTStatus state:ARTStateError]);
        }
    }
}

- (void)sendQueuedMessages {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];

    for (ARTQueuedMessage *message in qms) {
        [self sendImpl:message.msg cb:message.cb];
    }
}

- (void)failQueuedMessages:(ARTStatus *)error {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *message in qms) {
        message.cb(error);
    }
}

- (void)ack:(int64_t)serial count:(int64_t)count {
    [self.logger verbose:[NSString stringWithFormat:@"ARTRealtime ack: %lld , count %lld",  serial,  count]];
    NSArray *nackMessages = nil;
    NSArray *ackMessages = nil;

    if (serial < self.pendingMessageStartSerial) {
        // This is an error condition and shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
        serial = self.pendingMessageStartSerial;
    }

    if (serial > self.pendingMessageStartSerial) {
        // This counts as a nack of the messages earlier than serial,
        // as well as an ack
        int nCount = (int)(serial - self.pendingMessageStartSerial);
        NSRange nackRange = NSMakeRange(0, nCount);
        nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
        [self.pendingMessages removeObjectsInRange:nackRange];
        self.pendingMessageStartSerial = serial;
    }

    if (serial == self.pendingMessageStartSerial) {
        NSRange ackRange = NSMakeRange(0, (unsigned int) count);
        ackMessages = [self.pendingMessages subarrayWithRange:ackRange];
        [self.pendingMessages removeObjectsInRange:ackRange];
        // TODO what happens if count > pendingMessages.count
        self.pendingMessageStartSerial += count;
    }

    for (ARTQueuedMessage *msg in nackMessages) {
        msg.cb([ARTStatus state:ARTStateError]);
    }

    for (ARTQueuedMessage *msg in ackMessages) {
        msg.cb([ARTStatus state:ARTStateOk]);
    }
}

- (void)nack:(int64_t)serial count:(int64_t)count {
    [self.logger verbose:[NSString stringWithFormat:@"ARTRealtime Nack: %lld , count %lld",  serial,  count]];
    if (serial != self.pendingMessageStartSerial) {
        // This is an error condition and it shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
        serial = self.pendingMessageStartSerial;
    }

    NSRange nackRange = NSMakeRange(0, (unsigned int) count);
    NSArray *nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
    [self.pendingMessages removeObjectsInRange:nackRange];
    self.pendingMessageStartSerial = serial;

    for (ARTQueuedMessage *msg in nackMessages) {
        msg.cb([ARTStatus state:ARTStateError]);
    }
}

- (id<ARTRealtimeTransport>)createTransport {
    ARTWebSocketTransport *websocketTransport = [[ARTWebSocketTransport alloc] initWithRest:self.rest options:self.options];
    return websocketTransport;
}

- (CFRunLoopTimerRef)startTimer:(void(^)())onTimeout interval:(NSTimeInterval)interval {
    CFAbsoluteTime timeoutDate = CFAbsoluteTimeGetCurrent() + interval;

    CFRunLoopRef rl = CFRunLoopGetCurrent();
    CFRunLoopTimerRef timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, timeoutDate, 0, 0, 0, onTimeout);
    CFRunLoopAddTimer(rl, timer, kCFRunLoopDefaultMode);

    return timer;
}

- (void)cancelTimer:(CFRunLoopTimerRef)timer {
    if (timer) {
        CFRunLoopTimerInvalidate(timer);
        CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopDefaultMode);
        CFRelease(timer);
    }
}

- (void)realtimeTransport:(id)transport didReceiveMessage:(ARTProtocolMessage *)message {
    // TODO add in protocolListener

    [self.logger verbose:[NSString stringWithFormat:@"ARTRealtime didReceive Protocol Message %@", [ARTRealtime protocolStr:message.action]]];
    if(message.error) {
        self.errorReason = message.error;
    }
    NSAssert(transport == self.transport, @"Unexpected transport");
    if(message.hasConnectionSerial) {
        self.connectionSerial = message.connectionSerial;
    }
    switch (message.action) {
        case ARTProtocolMessageHeartbeat:
            [self onHeartbeat:message];
            break;
        case ARTProtocolMessageError:
            [self onError:message];
            break;
        case ARTProtocolMessageConnected:
            [self onConnected:message];
            break;
        case ARTProtocolMessageDisconnected:
            [self onDisconnected:message];
            break;
        case ARTProtocolMessageAck:
            [self onAck:message];
            break;
        case ARTProtocolMessageNack:
            [self onNack:message];
            break;
        case ARTProtocolMessageClosed:
            [self transition:ARTRealtimeClosed];
            break;
        default:
            [self onChannelMessage:message];
            break;
    }
}

- (void)realtimeTransportAvailable:(id<ARTRealtimeTransport>)transport {
    // Do nothing
}

- (void)realtimeTransportUnavailable:(id<ARTRealtimeTransport>)transport {
    [self transition:ARTRealtimeDisconnected];
}

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport {
    //Close succeeded. Nothing more to do.
    [self transition:ARTRealtimeClosed];
}

- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport {
    [self transition:ARTRealtimeDisconnected];
}

- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport {
    // TODO add error codes to these failed transitions
    [self transition:ARTRealtimeFailed];
}

- (void)realtimeTransportNeverConnected:(id<ARTRealtimeTransport>)transport {
    [self transition:ARTRealtimeFailed];
}

- (void)realtimeTransportRefused:(id<ARTRealtimeTransport>)transport {
    [self transition:ARTRealtimeFailed];
}

- (void)realtimeTransportTooBig:(id<ARTRealtimeTransport>)transport {
    [self transition:ARTRealtimeFailed];
}

+(NSString *) protocolStr:(ARTProtocolMessageAction ) action {
    switch(action) {
        case ARTProtocolMessageHeartbeat:
            return @"ARTProtocolMessageHeartbeat";
        case ARTProtocolMessageAck:
            return @"ARTProtocolMessageAck";
        case ARTProtocolMessageNack:
            return @"ARTProtocolMessageNack";
        case ARTProtocolMessageConnect:
            return @"ARTProtocolMessageConnect";
        case ARTProtocolMessageConnected:
            return @"ARTProtocolMessageConnected";
        case ARTProtocolMessageDisconnect:
            return @"ARTProtocolMessageDisconnect";
        case ARTProtocolMessageDisconnected:
            return @"ARTProtocolMessageDisconnected";
        case ARTProtocolMessageClose:
            return @"ARTProtocolMessageClose";
        case ARTProtocolMessageClosed:
            return @"ARTProtocolMessageClosed";
        case ARTProtocolMessageError:
            return @"ARTProtocolMessageError";
        case ARTProtocolMessageAttach:
            return @"ARTProtocolMessageAttach";
        case ARTProtocolMessageAttached:
            return @"ARTProtocolMessageAttached";
        case ARTProtocolMessageDetach:
            return @"ARTProtocolMessageDetach";
        case ARTProtocolMessageDetached:
            return @"ARTProtocolMessageDetached";
        case ARTProtocolMessagePresence:
            return @"ARTProtocolMessagePresence";
        case ARTProtocolMessageMessage:
            return @"ARTProtocolMessageMessage";
        case ARTProtocolMessageSync:
            return @"ARTProtocolMessageSync";
        default:
            return [NSString stringWithFormat: @"unknown protocol state %d", (int) action];
       
    }
}

+(NSString *) ARTRealtimeStateToStr:(ARTRealtimeConnectionState) state
{
    switch(state)
    {
        case ARTRealtimeInitialized:
            return @"ARTRealtimeInitialized";
        case ARTRealtimeConnecting:
            return @"ARTRealtimeConnecting";
        case ARTRealtimeConnected:
            return @"ARTRealtimeConnected";
        case ARTRealtimeDisconnected:
            return @"ARTRealtimeDisconnected";
        case ARTRealtimeSuspended:
            return @"ARTRealtimeSuspended";
        case ARTRealtimeClosing:
            return @"ARTRealtimeClosing";
        case ARTRealtimeClosed:
            return @"ARTRealtimeClosed";
        case ARTRealtimeFailed:
            return @"ARTRealtimeFailed";
        default:
            return @"unknown connectionstate";
        
    }
}

@end


#pragma mark - ARTPresence

@implementation ARTPresence

-(instancetype) initWithChannel:(ARTRealtimeChannel *) channel {
    self = [super init];
    if(self) {
        _channel = channel;
        self.logger = channel.logger;
    }
    return self;
}
-(id<ARTCancellable>) getWithParams:(NSDictionary *) queryParams cb:(ARTPaginatedResultCallback)callback {
    [self.channel throwOnDisconnectedOrFailed];
    return [self.channel.restChannel.presence getWithParams:queryParams cb:callback];
}

-(id<ARTCancellable>) get:(ARTPaginatedResultCallback)callback {
    [self.channel throwOnDisconnectedOrFailed];
    return [self.channel.restChannel.presence get:callback];
}
- (id<ARTCancellable>)history:(ARTPaginatedResultCallback)callback {
    [self.channel throwOnDisconnectedOrFailed];
    return [self.channel.restChannel.presence history:callback];
}

- (id<ARTCancellable>) historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCallback)callback {
    [self.channel throwOnDisconnectedOrFailed];
    return [self.channel.restChannel.presence historyWithParams:queryParams cb:callback];
}


- (void)enter:(id)data cb:(ARTStatusCallback)cb {
    [self  enterClient:self.channel.clientId data:data cb:cb];
}

- (void) enterClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb {
    if(!clientId) {
        [NSException raise:@"Cannot publish presence without a clientId" format:@""];
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceMessageEnter;
    msg.clientId = clientId;
    if(data) {
        msg.payload = [ARTPayload payloadWithPayload:data encoding:@""];
    }
    
    msg.connectionId = self.channel.realtime.connectionId;
    [self.channel publishPresence:msg cb:cb];
    
}

- (void)update:(id)data cb:(ARTStatusCallback)cb {
    [self updateClient:self.channel.clientId data:data cb:cb];
}

- (void)updateClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceMessageUpdate;
    msg.clientId = clientId;
    if(!msg.clientId) {
        cb([ARTStatus state:ARTStateNoClientId]);
        return;
    }
    if(data) {
        msg.payload = [ARTPayload payloadWithPayload:data encoding:@""];
    }
    msg.connectionId = self.channel.realtime.connectionId;
    
    [self.channel publishPresence:msg cb:cb];
    
}

- (void)leave:(id) data cb:(ARTStatusCallback)cb {
    [self leaveClient:self.channel.clientId data:data cb:cb];
}

- (void) leaveClient:(NSString *) clientId data:(id) data cb:(ARTStatusCallback) cb {
    
    if([clientId isEqualToString:self.channel.clientId]) {
        if(self.channel.lastPresenceAction != ARTPresenceMessageEnter && self.channel.lastPresenceAction != ARTPresenceMessageUpdate) {
            [NSException raise:@"Cannot leave a channel before you've entered it" format:@""];
        }
    }
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceMessageLeave;
    
    if(data) {
        msg.payload= [ARTPayload payloadWithPayload:data encoding:@""];
    }
    msg.clientId = clientId;
    msg.connectionId = self.channel.realtime.connectionId;
    if(!msg.clientId) {
        cb([ARTStatus state:ARTStateNoClientId]);
        return;
    }
    [self.channel publishPresence:msg cb:cb];
    
}

- (BOOL)isSyncComplete {
    return [self.channel.presenceMap isSyncComplete];
}

- (id<ARTSubscription>)subscribe:(ARTRealtimeChannelPresenceCb)cb {
    ARTRealtimeChannelPresenceSubscription *subscription = [[ARTRealtimeChannelPresenceSubscription alloc] initWithChannel:self.channel cb:cb];
    [self.channel.presenceSubscriptions addObject:subscription];
    [self.channel attach];
    return subscription;
}

- (id<ARTSubscription>)subscribe:(ARTPresenceMessageAction) action cb:(ARTRealtimeChannelPresenceCb)cb {
    ARTRealtimeChannelPresenceSubscription *subscription = (ARTRealtimeChannelPresenceSubscription *) [self subscribe:cb];
    [subscription excludeAllActionsExcept:action];
    return subscription;
}

- (void)unsubscribe:(id<ARTSubscription>)subscription action:(ARTPresenceMessageAction) action {
    ARTRealtimeChannelPresenceSubscription * s = (ARTRealtimeChannelPresenceSubscription *) subscription;
    [s excludeAction:action];
}

- (void)unsubscribe:(ARTRealtimeChannelPresenceSubscription *)subscription {
    ARTRealtimeChannelPresenceSubscription *s = (ARTRealtimeChannelPresenceSubscription *) subscription;
    [self.channel.presenceSubscriptions removeObject:s];
}

@end


#pragma mark - ARTEventEmitter

@implementation ARTEventEmitter

-(instancetype) initWithRealtime:(ARTRealtime *) realtime {
    self = [super init];
    if(self) {
        _realtime = realtime;
    }
    return self;
}

- (id<ARTSubscription>)on:(ARTRealtimeConnectionStateCb)cb {
    ARTRealtimeConnectionStateSubscription *subscription = [[ARTRealtimeConnectionStateSubscription alloc] initWithRealtime:self.realtime cb:cb];
    [self.realtime.stateSubscriptions addObject:subscription];
    cb(self.realtime.state);
    return subscription;
}

@end
