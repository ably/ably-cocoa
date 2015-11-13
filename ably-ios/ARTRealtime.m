
//
//  ARTRealtime.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRealtime+Private.h"

#import "ARTRealtimeChannel+Private.h"
#import "ARTStatus.h"
#import "ARTDefault.h"
#import "ARTRest.h"
#import "ARTAuth+Private.h"
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTChannelOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTWebSocketTransport.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTPresenceMap.h"
#import "ARTProtocolMessage.h"
#import "ARTRealtimeChannelSubscription.h"
#import "ARTEventEmitter.h"
#import "ARTQueuedMessage.h"

@interface ARTRealtime () <ARTRealtimeTransportDelegate> {
    Class _transportClass;
}

// Shared with private header
@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readwrite, strong, nonatomic) id<ARTRealtimeTransport> transport;
@property (readonly, strong, nonatomic) NSMutableArray *stateSubscriptions;

@property (readonly, strong, nonatomic) __GENERIC(NSMutableDictionary, NSString *, ARTRealtimeChannel *) *allChannels;
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

@property (nonatomic, copy) ARTRealtimePingCb pingCb;
@property (readonly, weak, nonatomic) ARTClientOptions *options;

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

// Message sending
- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)error;
- (void)ack:(int64_t)serial count:(int64_t)count;
- (void)nack:(int64_t)serial count:(int64_t)count;

// Util
- (id<ARTRealtimeTransport>)createTransport;
- (CFRunLoopTimerRef)startTimer:(void(^)())onTimeout interval:(NSTimeInterval)interval;
- (void)cancelTimer:(CFRunLoopTimerRef)timer;

@end


#pragma mark - ARTRealtime implementation

@implementation ARTRealtime

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    return [self initWithLogger:[[ARTLog alloc] init] andOptions:options];
}

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRealtime: No options provided");
        
        _rest = [[ARTRest alloc] initWithLogger:logger andOptions:options];
        _eventEmitter = [[ARTEventEmitter alloc] initWithRealtime:self];
        _allChannels = [NSMutableDictionary dictionary];
        _transport = nil;
        _transportClass = [ARTWebSocketTransport class];
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
        
        if (options.autoConnect) {
            [self connect];
        }
    }
    return self;
}

- (ARTLog *)getLogger {
    return _rest.logger;
}

- (int64_t)connectionSerial {
    return _connectionSerial;
}

- (NSString *)getRecoveryString {
    NSString *recStr = self.connectionKey;
    NSString *str = [recStr stringByAppendingString:[NSString stringWithFormat:@":%lld", self.connectionSerial]];
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

- (void)time:(void(^)(NSDate *time, NSError *error))cb {
    [self.rest time:cb];
}

- (void)ping:(ARTRealtimePingCb) cb {
    if(self.state == ARTRealtimeClosed || self.state == ARTRealtimeFailed) {
        [NSException raise:@"Can't ping a closed or failed connection" format:@"%@:", [ARTRealtime ARTRealtimeStateToStr:self.state]];
    }
    self.pingCb = cb;
    [self startPingTimer];
    [self.transport sendPing];
}

- (void)stats:(ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult *result, NSError *error))completion {
    [self.rest stats:query callback:completion];
}

- (ARTRealtimeChannel *)channel:(NSString *)channelName {
    return [self channel:channelName cipherParams:nil];
}

- (ARTRealtimeChannel *)channel:(NSString *)channelName cipherParams:(ARTCipherParams *)cipherParams {
    ARTRealtimeChannel *channel = [self.allChannels objectForKey:channelName];
    if (!channel) {
        channel = [ARTRealtimeChannel channelWithRealtime:self andName:channelName withOptions:[[ARTChannelOptions alloc] initEncrypted:cipherParams]];
        [self.allChannels setObject:channel forKey:channelName];
    }

    return channel;
}

- (void)removeChannel:(NSString *)name {
    [_allChannels removeObjectForKey:name];
}

- (void)unsubscribeState:(ARTRealtimeChannelStateSubscription *)subscription {
    [self.stateSubscriptions removeObject:subscription];
}


- (BOOL)isFromResume {
    return self.options.resumeKey != nil;
}

- (void)transition:(ARTRealtimeConnectionState)state {
    [self transition:state withErrorInfo:nil];
}

- (void)transition:(ARTRealtimeConnectionState)state withErrorInfo:(ARTErrorInfo *)errorInfo {
    [self.logger verbose:@"Transition to %@ requested", [ARTRealtime ARTRealtimeStateToStr:state]];

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
            // TODO: ConnectionManager
            if (!self.transport) {
                if (previousState == ARTRealtimeFailed || previousState == ARTRealtimeDisconnected) {
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
            if ([self isFromResume]) {
                if(![self.options.resumeKey isEqualToString:self.connectionKey] || self.options.connectionSerial != self.connectionSerial) {
                    [self.logger warn:@"ARTRealtime: connection has reconnected, but resume failed. Detaching all channels"];
                    for (NSString *channelName in self.allChannels) {
                        ARTErrorInfo * info = [[ARTErrorInfo alloc] init];
                        [info setCode:80000 message:@"resume connection failed"];
                        
                        [self.logger warn:@"%@: resume connection failed", channelName];

                        ARTRealtimeChannel *channel = [self.allChannels objectForKey:channelName];
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
            if (channel.state == ARTRealtimeChannelInitialised || channel.state == ARTRealtimeChannelAttaching || channel.state == ARTRealtimeChannelAttached) {
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
        subscription.cb(state, errorInfo);
    }

    if (state == ARTRealtimeClosing) {
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
        }interval:self.options.suspendedRetryTimeout];
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
        }interval:10.0];
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
            [self.logger warn:@"ARTRealtime received a ping when in state %@", [ARTRealtime ARTRealtimeStateToStr:self.state]];
            self.pingCb([ARTStatus state:ARTStateError]);
        }
        else {
            self.pingCb([ARTStatus state:ARTStateOk]);
        }
        self.pingCb = nil;
    }
}

- (void)onConnected:(ARTProtocolMessage *)message withErrorInfo:(ARTErrorInfo *)errorInfo {
    self.connectionId = message.connectionId;
    switch (self.state) {
        case ARTRealtimeConnecting:
            self.connectionKey = message.connectionKey;
            if (![self isFromResume]) {
                self.connectionSerial = -1;
            }
            [self transition:ARTRealtimeConnected withErrorInfo:errorInfo];
            break;
        default:
            NSAssert(false, @"Invalid Realtime state: expected Connecting has current state");
            break;
    }
}

- (NSString *)connectionKey {
    return _connectionKey;
}

- (NSString *)connectionId {
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
            NSAssert(false, @"Invalid Realtime state: expected Connected has current state");
            break;
    }
}

- (void)onError:(ARTProtocolMessage *)message withErrorInfo:(ARTErrorInfo *)errorInfo {
    // TODO work out which states this can be received in
    if (message.channel) {
        [self onChannelMessage:message withErrorInfo:errorInfo];
    } else {
        self.connectionId = nil;
        [self transition:ARTRealtimeFailed withErrorInfo:errorInfo];
    }
}

- (void)onAck:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    [self ack:message.msgSerial count:message.count];
}

- (void)onNack:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    [self nack:message.msgSerial count:message.count];
}

- (void)onChannelMessage:(ARTProtocolMessage *)message withErrorInfo:(ARTErrorInfo *)errorInfo {
    // TODO work out which states this can be received in / error info?
    ARTRealtimeChannel *channel = [self.allChannels objectForKey:message.channel];
    [channel onChannelMessage:message];
}

- (void)onConnectTimerFired {
    switch (self.state) {
        case ARTRealtimeConnecting:
            [self.logger warn:@"ARTRealtime: connecting timer fired."];
            [self transition:ARTRealtimeFailed];
            break;
        default:
            NSAssert(false, @"Invalid connection state");
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
            return self.options.disconnectedRetryTimeout;
        case ARTRealtimeSuspended:
            return self.options.suspendedRetryTimeout;
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
    [self.logger verbose:@"ARTRealtime ack: %lld , count %lld",  serial,  count];
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
    [self.logger verbose:@"ARTRealtime Nack: %lld , count %lld",  serial,  count];
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
    ARTWebSocketTransport *websocketTransport = [[_transportClass alloc] initWithRest:self.rest options:self.options];
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

    [self.logger verbose:@"ARTRealtime didReceive Protocol Message %@ ", [ARTRealtime protocolStr:message.action]];

    if (message.error) {
        [self.logger verbose:@"ARTRealtime Protocol Message with error %@ ", message.error];
    }

    NSAssert(transport == self.transport, @"Unexpected transport");
    if (message.hasConnectionSerial) {
        self.connectionSerial = message.connectionSerial;
    }

    switch (message.action) {
        case ARTProtocolMessageHeartbeat:
            [self onHeartbeat:message];
            break;
        case ARTProtocolMessageError:
            [self onError:message withErrorInfo:message.error];
            break;
        case ARTProtocolMessageConnected:
            // Set Auth#clientId
            [[self auth] setProtocolClientId:message.clientId];
            // Event
            [self onConnected:message withErrorInfo:message.error];
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
            [self onChannelMessage:message withErrorInfo:message.error];
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

- (void)setTransportClass:(Class)transportClass {
    _transportClass = transportClass;
}

+ (NSString *)protocolStr:(ARTProtocolMessageAction) action {
    switch(action) {
        case ARTProtocolMessageHeartbeat:
            return @"ARTProtocolMessageHeartbeat"; //0
        case ARTProtocolMessageAck:
            return @"ARTProtocolMessageAck"; //1
        case ARTProtocolMessageNack:
            return @"ARTProtocolMessageNack"; //2
        case ARTProtocolMessageConnect:
            return @"ARTProtocolMessageConnect"; //3
        case ARTProtocolMessageConnected:
            return @"ARTProtocolMessageConnected"; //4
        case ARTProtocolMessageDisconnect:
            return @"ARTProtocolMessageDisconnect"; //5
        case ARTProtocolMessageDisconnected:
            return @"ARTProtocolMessageDisconnected"; //6
        case ARTProtocolMessageClose:
            return @"ARTProtocolMessageClose"; //7
        case ARTProtocolMessageClosed:
            return @"ARTProtocolMessageClosed"; //8
        case ARTProtocolMessageError:
            return @"ARTProtocolMessageError"; //9
        case ARTProtocolMessageAttach:
            return @"ARTProtocolMessageAttach"; //10
        case ARTProtocolMessageAttached:
            return @"ARTProtocolMessageAttached"; //11
        case ARTProtocolMessageDetach:
            return @"ARTProtocolMessageDetach"; //12
        case ARTProtocolMessageDetached:
            return @"ARTProtocolMessageDetached"; //13
        case ARTProtocolMessagePresence:
            return @"ARTProtocolMessagePresence"; //14
        case ARTProtocolMessageMessage:
            return @"ARTProtocolMessageMessage"; //15
        case ARTProtocolMessageSync:
            return @"ARTProtocolMessageSync"; //16
        default:
            return [NSString stringWithFormat: @"unknown protocol state %d", (int)action];
    }
}

+ (NSString *)ARTRealtimeStateToStr:(ARTRealtimeConnectionState) state {
    switch(state)
    {
        case ARTRealtimeInitialized:
            return @"ARTRealtimeInitialized"; //0
        case ARTRealtimeConnecting:
            return @"ARTRealtimeConnecting"; //1
        case ARTRealtimeConnected:
            return @"ARTRealtimeConnected"; //2
        case ARTRealtimeDisconnected:
            return @"ARTRealtimeDisconnected"; //3
        case ARTRealtimeSuspended:
            return @"ARTRealtimeSuspended"; //4
        case ARTRealtimeClosing:
            return @"ARTRealtimeClosing"; //5
        case ARTRealtimeClosed:
            return @"ARTRealtimeClosed"; //6
        case ARTRealtimeFailed:
            return @"ARTRealtimeFailed"; //7
        default:
            return @"unknown connectionstate";
    }
}

@end
