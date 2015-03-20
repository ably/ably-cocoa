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
#import "NSArray+ARTFunctional.h"

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

@interface ARTRealtimeChannel ()

@property (readonly, strong, nonatomic) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) NSString *name;
@property (readonly, strong, nonatomic) ARTRestChannel *restChannel;
@property (readwrite, assign, nonatomic) ARTRealtimeChannelState state;
@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readwrite, strong, nonatomic) NSString *attachSerial;
@property (readonly, strong, nonatomic) NSMutableDictionary *subscriptions;
@property (readonly, strong, nonatomic) NSMutableArray *presenceSubscriptions;
@property (readonly, strong, nonatomic) NSMutableDictionary *presence;
@property (readonly, strong, nonatomic) NSString *clientId;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;
@property (readonly, strong, nonatomic) id<ARTPayloadEncoder> payloadEncoder;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams;

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus)status;

- (void)onChannelMessage:(ARTProtocolMessage *)message;
- (void)publishMessages:(NSArray *)messages cb:(ARTStatusCallback)cb;
- (void)publishPresence:(ARTPresenceMessage *)pm cb:(ARTStatusCallback)cb;
- (void)publishProtocolMessage:(ARTProtocolMessage *)pm cb:(ARTStatusCallback)cb;

- (void)setAttached:(ARTProtocolMessage *)message;
- (void)setDetached:(ARTProtocolMessage *)message;
- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onPresence:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)error;
- (void)setSuspended:(ARTStatus)error;

- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus)status;

- (void)unsubscribe:(ARTRealtimeChannelSubscription *)subscription;
- (void)unsubscribePresence:(ARTRealtimeChannelPresenceSubscription *)subscription;
- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription;

- (void)broadcastPresence:(ARTPresenceMessage *)pm;

@end

@interface ARTRealtime () <ARTRealtimeTransportDelegate>

@property (readonly, strong, nonatomic) ARTRest *rest;
@property (readonly, strong, nonatomic) NSMutableDictionary *channels;
@property (readwrite, strong, nonatomic) id<ARTRealtimeTransport> transport;
@property (readwrite, assign, nonatomic) ARTRealtimeConnectionState state;

@property (readwrite, assign, nonatomic) CFRunLoopTimerRef connectTimeout;
@property (readwrite, assign, nonatomic) CFRunLoopTimerRef suspendTimeout;
@property (readwrite, assign, nonatomic) CFRunLoopTimerRef retryTimeout;

@property (readwrite, strong, nonatomic) NSString *connectionId;
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (readwrite, assign, nonatomic) int64_t msgSerial;

@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readonly, strong, nonatomic) NSMutableArray *pendingMessages;
@property (readwrite, assign, nonatomic) int64_t pendingMessageStartSerial;
@property (readonly, strong, nonatomic) NSString *clientId;

@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;

@property (readonly, strong, nonatomic) ARTOptions *options;

- (void)transition:(ARTRealtimeConnectionState)state;

- (void)connect;

// Timer starters
- (void)startConnectTimer;
- (void)startSuspendTimer;
- (void)startRetryTimer:(NSTimeInterval)timeout;

// Timer cancellers
- (void)cancelConnectTimer;
- (void)cancelSuspendTimer;
- (void)cancelRetryTimer;

// Transport Events
- (void)onHeartbeat:(ARTProtocolMessage *)message;
- (void)onConnected:(ARTProtocolMessage *)message;
- (void)onDisconnected:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)message;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message;

// Timer events
- (void)onConnectTimerFired;
- (void)onSuspendTimerFired;
- (void)onRetryTimerFired;

// State properties
- (BOOL)shouldSendEvents;
- (BOOL)shouldQueueEvents;
- (NSTimeInterval)retryInterval;
- (ARTStatus)defaultError;
- (BOOL)isActive;

// Message sending
- (void)send:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb;
- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus)error;
- (void)ack:(int64_t)serial count:(int64_t)count;
- (void)nack:(int64_t)serial count:(int64_t)count;

// util
- (id<ARTRealtimeTransport>)createTransport;
- (CFRunLoopTimerRef)startTimer:(void(^)())onTimeout interval:(NSTimeInterval)interval;
- (void)cancelTimer:(CFRunLoopTimerRef)timer;

- (void)unsubscribeState:(ARTRealtimeConnectionStateSubscription *)subscription;

@end

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
    return ^(ARTStatus status) {
        for (ARTStatusCallback cb in self.cbs) {
            cb(status);
        }
    };
}

@end

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

@implementation ARTRealtimeChannelPresenceSubscription

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel cb:(ARTRealtimeChannelPresenceCb)cb {
    self = [super init];
    if (self) {
        _channel = channel;
        _cb = cb;
    }
    return self;
}

- (void)unsubscribe {
    [self.channel unsubscribePresence:self];
}

@end

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

@implementation ARTRealtimeChannel

- (instancetype)initWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams {
    self = [super init];
    if (self) {
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
    }
    return self;
}

+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime name:(NSString *)name cipherParams:(ARTCipherParams *)cipherParams {
    return [[ARTRealtimeChannel alloc] initWithRealtime:realtime name:name cipherParams:cipherParams];
}

- (void)publish:(id)payload cb:(ARTStatusCallback)cb {
    [self publish:payload withName:nil cb:cb];
}

- (void)publish:(id)payload withName:(NSString *)name cb:(ARTStatusCallback)cb {
    ARTMessage *message = [[ARTMessage alloc] init];
    message.name = name;
    message.payload = [ARTPayload payloadWithPayload:payload encoding:@""];

    NSArray *messages = [NSArray arrayWithObject:message];
    [self publishMessages:messages cb:cb];
}

- (void)publishMessages:(NSArray *)messages cb:(ARTStatusCallback)cb {
    if (self.payloadEncoder) {
        messages = [messages artMap:^id(ARTMessage *message) {
            ARTPayload *encodedPayload = nil;
            ARTStatus status = [self.payloadEncoder encode:message.payload output:&encodedPayload];
            if (status != ARTStatusOk) {
                // TODO log error message
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

- (void)publishPresenceEnter:(id)data cb:(ARTStatusCallback)cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceMessageEnter;
    msg.clientId = self.clientId;
    msg.payload = data;
    [self publishPresence:msg cb:cb];
}

- (void)publishPresenceUpdate:(id)data cb:(ARTStatusCallback)cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceMessageUpdate;
    msg.clientId = self.clientId;
    msg.payload = data;
    [self publishPresence:msg cb:cb];
}

- (void)publishPresenceLeave:(ARTStatusCallback)cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceMessageLeave;
    msg.clientId = self.clientId;
    [self publishPresence:msg cb:cb];
}

- (void)publishPresence:(ARTPresenceMessage *)msg cb:(ARTStatusCallback)cb {
    if (!msg.clientId) {
        msg.clientId = self.clientId;
    }

    NSAssert(msg.clientId, @"clientId has not been set on either the message or the channel");

    if (msg.payload && self.payloadEncoder) {
        ARTPayload *encodedPayload = nil;
        ARTStatus status = [self.payloadEncoder encode:msg.payload output:&encodedPayload];
        if (status != ARTStatusOk) {
            // TODO log
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
                cb(ARTStatusError);
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

- (id<ARTCancellable>)history:(ARTPaginatedResultCb)cb {
    return [self.restChannel history:cb];
}

- (id<ARTCancellable>)historyWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
    return [self.restChannel historyWithParams:queryParams cb:cb];
}

- (id<ARTCancellable>)presenceHistory:(ARTPaginatedResultCb)cb {
    return [self.restChannel presenceHistory:cb];
}

- (id<ARTCancellable>)presenceHistoryWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
    return [self.restChannel presenceWithParams:queryParams cb:cb];
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

- (id<ARTSubscription>)subscribeToPresence:(ARTRealtimeChannelPresenceCb)cb {
    ARTRealtimeChannelPresenceSubscription *subscription = [[ARTRealtimeChannelPresenceSubscription alloc] initWithChannel:self cb:cb];
    [self.presenceSubscriptions addObject:subscription];
    [self attach];
    return subscription;
}

- (void)unsubscribePresence:(ARTRealtimeChannelPresenceSubscription *)subscription {
    [self.presenceSubscriptions removeObject:subscription];
}

- (id<ARTSubscription>)subscribeToStateChanges:(ARTRealtimeChannelStateCb)cb {
    ARTRealtimeChannelStateSubscription *subscription = [[ARTRealtimeChannelStateSubscription alloc] initWithChannel:self cb:cb];
    [self.stateSubscriptions addObject:subscription];
    return subscription;
}

- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription {
    [self.stateSubscriptions removeObject:subscription];
}

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus)status {
    self.state = state;

    for (ARTRealtimeChannelStateSubscription *subscription in self.stateSubscriptions) {
        subscription.cb(state, status);
    }
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
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
        default:
            // TODO log?
            break;
    }
}

- (void)setAttached:(ARTProtocolMessage *)message {
    self.attachSerial = message.channelSerial;
    [self sendQueuedMessages];

    for (ARTPresenceMessage *pm in message.presence) {
        [self.presence setObject:pm forKey:pm.clientId];
    }

    [self transition:ARTRealtimeChannelAttached status:ARTStatusOk];
}

- (void)setDetached:(ARTProtocolMessage *)message {
    self.attachSerial = nil;

    ARTStatus reason = message.error ? message.error : ARTStatusNotAttached;
    [self failQueuedMessages:reason];
    [self transition:ARTRealtimeChannelDetached status:reason];
}

- (void)setSuspended:(ARTStatus)error {
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

        [self.presence setObject:pm forKey:pm.clientId];
        [self broadcastPresence:pm];

        ++i;
    }
}

- (void)broadcastPresence:(ARTPresenceMessage *)pm {
    for (ARTRealtimeChannelPresenceSubscription *subscription in self.presenceSubscriptions) {
        subscription.cb(pm);
    }
}

- (void)onError:(ARTProtocolMessage *)msg {
    [self failQueuedMessages:msg.error];
    [self transition:ARTRealtimeChannelFailed status:msg.error];
}

- (void)attach {
    switch (self.state) {
        case ARTRealtimeChannelAttaching:
        case ARTRealtimeChannelAttached:
            // Nothing to do
            return;
        default:
            break;
    }

    if (![self.realtime isActive]) {
        // TODO error?
        return;
    }

    ARTProtocolMessage *attachMessage = [[ARTProtocolMessage alloc] init];
    attachMessage.action = ARTProtocolMessageAttach;
    attachMessage.channel = self.name;

    // TODO should queueEvents be forced?
    [self.realtime send:attachMessage cb:nil];

    [self transition:ARTRealtimeChannelAttaching status:ARTStatusOk];
}

- (void)detach {
    switch (self.state) {
        case ARTRealtimeChannelInitialised:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelDetached:
            return;
        default:
            break;
    }

    if (![self.realtime isActive]) {
        return;
    }

    ARTProtocolMessage *detachMessage = [[ARTProtocolMessage alloc] init];
    detachMessage.action = ARTProtocolMessageDetach;
    detachMessage.channel = self.name;
    
    [self.realtime send:detachMessage cb:nil];
    [self transition:ARTRealtimeChannelDetaching status:ARTStatusOk];
}

- (void)sendQueuedMessages {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *qm in qms) {
        [self.realtime send:qm.msg cb:qm.cb];
    }
}

- (void)failQueuedMessages:(ARTStatus)status {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];

    for (ARTQueuedMessage *qm in qms) {
        qm.cb(status);
    }
}

@end

@implementation ARTRealtime

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[ARTOptions optionsWithKey:key]];
}

- (instancetype)initWithOptions:(ARTOptions *)options {
    self = [super init];
    if (self) {
        _rest = [[ARTRest alloc] initWithOptions:options];
        _channels = [NSMutableDictionary dictionary];
        _transport = nil;
        _state = ARTRealtimeInitialized;
        _connectTimeout = NULL;
        _suspendTimeout = NULL;
        _retryTimeout = NULL;
        _connectionId = nil;
        _msgSerial = 0;
        _queuedMessages = [NSMutableArray array];
        _pendingMessages = [NSMutableArray array];
        _pendingMessageStartSerial = 0;
        _clientId = options.clientId;
        _options = [options clone];
        _stateSubscriptions = [NSMutableArray array];
        [self connect];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"DEALOC OF ARCREALTIME");
    // Custom dealloc required to release CoreFoundation objects
    [self cancelConnectTimer];
    [self cancelSuspendTimer];
    [self cancelRetryTimer];

    self.transport.delegate = nil;
    // Do not call [super dealloc] explicitly
}

- (void)connect {
    [self transition:ARTRealtimeConnecting];
}

- (void)close {
    [self transition:ARTRealtimeClosed];
}

- (id<ARTCancellable>)time:(void(^)(ARTStatus status, NSDate *time))cb {
    return [self.rest time:cb];
}

- (id<ARTCancellable>)stats:(ARTPaginatedResultCb)cb {
    return [self.rest stats:cb];
}

- (id<ARTCancellable>)statsWithParams:(NSDictionary *)queryParams cb:(ARTPaginatedResultCb)cb {
    return [self.rest statsWithParams:queryParams cb:cb];
}

- (ARTRealtimeChannel *)channel:(NSString *)channelName {
    return [self channel:channelName cipherParams:nil];
}

- (ARTRealtimeChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams {
    ARTRealtimeChannel *channel = [self.channels objectForKey:channelName];
    if (!channel) {
        channel = [ARTRealtimeChannel channelWithRealtime:self name:channelName cipherParams:cipherParams];
        [self.channels setObject:channel forKey:channelName];
    }

    return channel;
}

- (id<ARTSubscription>)subscribeToStateChanges:(ARTRealtimeConnectionStateCb)cb {
    ARTRealtimeConnectionStateSubscription *subscription = [[ARTRealtimeConnectionStateSubscription alloc] initWithRealtime:self cb:cb];
    [self.stateSubscriptions addObject:subscription];
    return subscription;
}

- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription {
    [self.stateSubscriptions removeObject:subscription];
}

- (void)transition:(ARTRealtimeConnectionState)state {
    NSLog(@"Transition to %lu requested", state);
    // On exit logic
    switch (self.state) {
        case ARTRealtimeInitialized:
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
        case ARTRealtimeClosed:
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended:
        case ARTRealtimeFailed:
            // Currently no on-exit logic
            break;
    }

    // Cancel timers
    [self cancelConnectTimer];
    [self cancelRetryTimer];

    if (state == ARTRealtimeConnected) {
        [self cancelSuspendTimer];
    }

    ARTRealtimeConnectionState previousState = self.state;
    self.state = state;

    // On enter logic
    switch (self.state) {
        case ARTRealtimeConnecting:
            [self startSuspendTimer];
            [self startConnectTimer];

            // Create transport and initiate connection
            self.transport.delegate = nil;
            self.transport = [self createTransport];
            self.transport.delegate = self;
            [self.transport connect];
            break;
        case ARTRealtimeConnected:
            self.msgSerial = 0;
            [self startSuspendTimer];
            break;
        case ARTRealtimeClosed:
            [self.transport close:(previousState == ARTRealtimeConnected)];
            self.transport.delegate = nil;
            self.transport = nil;
            break;
        case ARTRealtimeFailed:
            // reasonFailed doesn't need to be a property on self
            [self.transport abort:ARTStatusConnectionFailed];
            self.transport.delegate = nil;
            self.transport = nil;
        case ARTRealtimeInitialized:
        case ARTRealtimeDisconnected:
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
        for (NSString *channelName in self.channels) {
            ARTRealtimeChannel *channel = [self.channels objectForKey:channelName];
            [channel setSuspended:[self defaultError]];
        }
    }

    for (ARTRealtimeConnectionStateSubscription *subscription in self.stateSubscriptions) {
        subscription.cb(state);
    }
}

- (void)startConnectTimer {
    if (!self.connectTimeout) {
        self.connectTimeout = [self startTimer:^{
            [self onConnectTimerFired];
        }interval:15.0]; // TODO set connect timer back to 15
    }
}

- (void)startSuspendTimer {
    if (!self.suspendTimeout) {
        self.suspendTimeout = [self startTimer:^{
            [self onSuspendTimerFired];
        }interval:60.0];
    }
}

- (void)startRetryTimer:(NSTimeInterval)timeout {
    if (!self.retryTimeout) {
        self.retryTimeout = [self startTimer:^{
            [self onRetryTimerFired];
        }interval:timeout];
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

- (void)onHeartbeat:(ARTProtocolMessage *)message {
    // Ignore
}

- (void)onConnected:(ARTProtocolMessage *)message {
    switch (self.state) {
        case ARTRealtimeConnecting:
            self.connectionId = message.connectionId;
            [self transition:ARTRealtimeConnected];
            break;
        default:
            // TODO - Invalid transition
            break;
    }
}

- (void)onDisconnected:(ARTProtocolMessage *)message {
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

    // TODO set connection serial
    if (message.connectionSerial) {
        self.connectionSerial = message.connectionSerial;
    }

    ARTRealtimeChannel *channel = [self.channels objectForKey:message.channel];
    [channel onChannelMessage:message];
}

- (void)onConnectTimerFired {
    switch (self.state) {
        case ARTRealtimeConnecting:
            [self transition:ARTRealtimeFailed];
            break;
        default:
            // TODO invalid connection state
            break;
    }
}

- (void)onSuspendTimerFired {
    switch (self.state) {
        case ARTRealtimeConnected:
            [self transition:ARTRealtimeSuspended];
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
            return 10.0;
        case ARTRealtimeSuspended:
            return 60.0;
        default:
            return 0.0;
    }
}

- (ARTStatus)defaultError {
    return ARTStatusError;
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
            cb(ARTStatusError);
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

- (void)failQueuedMessages:(ARTStatus)error {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *message in qms) {
        message.cb(error);
    }
}

- (void)ack:(int64_t)serial count:(int64_t)count {
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
        NSRange ackRange = NSMakeRange(0, count);
        ackMessages = [self.pendingMessages subarrayWithRange:ackRange];
        [self.pendingMessages removeObjectsInRange:ackRange];
        // TODO what happens if count > pendingMessages.count
        self.pendingMessageStartSerial += count;
    }

    for (ARTQueuedMessage *msg in nackMessages) {
        msg.cb(ARTStatusError);
    }

    for (ARTQueuedMessage *msg in ackMessages) {
        msg.cb(ARTStatusOk);
    }
}

- (void)nack:(int64_t)serial count:(int64_t)count {
    if (serial != self.pendingMessageStartSerial) {
        // This is an error condition and it shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
        serial = self.pendingMessageStartSerial;
    }

    NSRange nackRange = NSMakeRange(0, count);
    NSArray *nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
    [self.pendingMessages removeObjectsInRange:nackRange];
    self.pendingMessageStartSerial = serial;

    for (ARTQueuedMessage *msg in nackMessages) {
        msg.cb(ARTStatusError);
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

    NSAssert(transport == self.transport, @"Unexpected transport");
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
+(NSString *) ARTRealtimeStateToStr:(ARTRealtimeConnectionState) state
{
    /*

    ARTRealtimeInitialized,
    ARTRealtimeConnecting,
    ARTRealtimeConnected,
    ARTRealtimeDisconnected,
    ARTRealtimeSuspended,
    ARTRealtimeClosed,
    ARTRealtimeFailed
    
          */
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
        case ARTRealtimeClosed:
            return @"ARTRealtimeClosed";
        case ARTRealtimeFailed:
            return @"ARTRealtimeFailed";
        default:
            return @"unknown connectionstate";
        
    }
}

@end
