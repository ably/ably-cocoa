
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
#import "ARTRest+Private.h"
#import "ARTAuth+Private.h"
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTChannelOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTWebSocketTransport.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTPresenceMap.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTEventEmitter.h"
#import "ARTQueuedMessage.h"
#import "ARTConnection+Private.h"
#import "ARTConnectionDetails.h"
#import "ARTStats.h"

@interface ARTRealtime () <ARTRealtimeTransportDelegate> {
    Class _transportClass;
    id<ARTRealtimeTransport> _transport;
}

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

// Util
- (CFRunLoopTimerRef)startTimer:(void(^)())onTimeout interval:(NSTimeInterval)interval;
- (void)cancelTimer:(CFRunLoopTimerRef)timer;

@end


#pragma mark - ARTRealtime implementation

@implementation ARTRealtime {
    BOOL _resuming;
}

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (instancetype)initWithToken:(NSString *)token {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithToken:token]];
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRealtime: No options provided");
        
        _rest = [[ARTRest alloc] initWithOptions:options];
        _eventEmitter = [[ARTEventEmitter alloc] init];
        _channels = [[ARTRealtimeChannels alloc] initWithRealtime:self];
        _transport = nil;
        _transportClass = [ARTWebSocketTransport class];
        _connectTimeout = NULL;
        _suspendTimeout = NULL;
        _retryTimeout = NULL;
        _msgSerial = 0;
        _queuedMessages = [NSMutableArray array];
        _pendingMessages = [NSMutableArray array];
        _pendingMessageStartSerial = 0;
        _connection = [[ARTConnection alloc] initWithRealtime:self];
        [self.connection setState:ARTRealtimeInitialized];

        [self.logger debug:__FILE__ line:__LINE__ message:@"initialised %p", self];
        
        if (options.autoConnect) {
            [self connect];
        }
    }
    return self;
}

- (id<ARTRealtimeTransport>)getTransport {
    return _transport;
}

- (ARTLog *)getLogger {
    return _rest.logger;
}

- (ARTClientOptions *)getClientOptions {
    return _rest.options;
}

- (NSString *)getClientId {
    return _rest.options.clientId;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Realtime: %@", self.clientId];
}

- (ARTAuth *)getAuth {
    return self.rest.auth;
}

- (void)dealloc {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p dealloc", self];

    [self cancelConnectTimer];
    [self cancelSuspendTimer];
    [self cancelRetryTimer];

    if (_transport) {
        _transport.delegate = nil;
        [_transport close];
    }
    _transport = nil;
}

- (void)connect {
    if(self.connection.state == ARTRealtimeClosing) {
        return;
    }
    [self transition:ARTRealtimeConnecting];
}

- (void)close {
    [self transition:ARTRealtimeClosing];
}

- (void)time:(void(^)(NSDate *time, NSError *error))cb {
    [self.rest time:cb];
}

- (void)ping:(ARTRealtimePingCb) cb {
    if(self.connection.state == ARTRealtimeClosed || self.connection.state == ARTRealtimeFailed) {
        [NSException raise:@"Can't ping a closed or failed connection" format:@"%@:", [ARTRealtime ARTRealtimeStateToStr:self.connection.state]];
    }
    self.pingCb = cb;
    [self startPingTimer];
    [self.transport sendPing];
}


- (NSError *)stats:(ARTStatsCallback)callback {
    NSError *error = nil;
    [self statsWithError:&error callback:callback];
    return error;
}

- (NSError *)stats:(ARTStatsQuery *)query callback:(ARTStatsCallback)callback {
    NSError *error = nil;
    [self stats:query error:&error callback:callback];
    return error;
}

- (BOOL)statsWithError:(NSError *__autoreleasing  _Nullable *)errorPtr callback:(ARTStatsCallback)callback {
    return [self stats:[[ARTStatsQuery alloc] init] error:errorPtr callback:callback];
}

- (BOOL)stats:(ARTStatsQuery *)query error:(NSError **)errorPtr callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *, NSError *))callback {
    return [self.rest stats:query error:errorPtr callback:callback];
}

- (void)resetEventEmitter {
    _eventEmitter = [[ARTEventEmitter alloc] init];
}

- (void)transition:(ARTRealtimeConnectionState)state {
    [self transition:state withErrorInfo:nil];
}

- (void)transition:(ARTRealtimeConnectionState)state withErrorInfo:(ARTErrorInfo *)errorInfo {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p transition to %@ requested", self, [ARTRealtime ARTRealtimeStateToStr:state]];

    // Cancel timers
    [self cancelConnectTimer];
    [self cancelRetryTimer];

    ARTRealtimeConnectionState previousState = self.connection.state;
    [self.connection setState:state];

    // On enter logic
    switch (self.connection.state) {
        case ARTRealtimeConnecting:
            [self startSuspendTimer];
            [self startConnectTimer];

            // Create transport and initiate connection
            // TODO: ConnectionManager
            if (!_transport) {
                NSString *resumeKey = nil;
                NSNumber *connectionSerial = nil;
                if (previousState == ARTRealtimeFailed || previousState == ARTRealtimeDisconnected) {
                    resumeKey = self.connection.key;
                    connectionSerial = [NSNumber numberWithInteger:self.connection.serial];
                    _resuming = true;
                }
                _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:resumeKey connectionSerial:connectionSerial];
                _transport.delegate = self;
                [_transport connect];
            }
            break;
        case ARTRealtimeConnected:
            [self cancelSuspendTimer];
            break;
        case ARTRealtimeClosing:
            [self startCloseTimer];
            [self.transport sendClose];
            break;
        case ARTRealtimeClosed:
            [self cancelCloseTimer];
            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            break;
        case ARTRealtimeFailed:
            [self.transport abort:[ARTStatus state:ARTStateConnectionFailed info:errorInfo]];
            self.transport.delegate = nil;
            _transport = nil;
            break;
        case ARTRealtimeDisconnected:
            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            break;
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
        // For every Channel
        for (ARTRealtimeChannel* channel in self.channels) {
            if (channel.state == ARTRealtimeChannelInitialised || channel.state == ARTRealtimeChannelAttaching || channel.state == ARTRealtimeChannelAttached) {
                if(state == ARTRealtimeClosing) {
                    //do nothing. Closed state is coming.
                }
                else if(state == ARTRealtimeClosed) {
                    [channel detachChannel:[ARTStatus state:ARTStateOk]];
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
    
    [self.connection emit:[NSNumber numberWithInt:state] with:[[ARTConnectionStateChange alloc] initWithCurrent:state previous:previousState reason:errorInfo]];
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

- (void)onHeartbeat {
    [self.logger verbose:@"ARTRealtime heartbeat received"];
    if(self.pingCb) {
        [self cancelPingTimer];
        if(self.connection.state != ARTRealtimeConnected) {
            [self.logger warn:@"ARTRealtime received a ping when in state %@", [ARTRealtime ARTRealtimeStateToStr:self.connection.state]];
            self.pingCb([ARTStatus state:ARTStateError]);
        }
        else {
            self.pingCb([ARTStatus state:ARTStateOk]);
        }
        self.pingCb = nil;
    }
}

- (void)onConnected:(ARTProtocolMessage *)message {
    // Resuming
    if (_resuming) {
        if (message.error && ![message.connectionId isEqualToString:self.connection.id]) {
            [self.logger warn:@"ARTRealtime: connection has reconnected, but resume failed. Detaching all channels"];
            // Fatal error, detach all channels
            for (ARTRealtimeChannel *channel in self.channels) {
                [channel detachChannel:[ARTStatus state:ARTStateConnectionDisconnected info:message.error]];
            }

            _resuming = false;

            for (ARTRealtimeChannel *channel in self.channels) {
                if([channel.presenceMap stillSyncing]) {
                    [channel requestContinueSync];
                }
            }
        }
        else if (message.error) {
            [self.logger warn:@"ARTRealtime: connection has resumed with non-fatal error %@", message.error.message];
            // The error will be emitted on `transition`
        }
    }

    switch (self.connection.state) {
        case ARTRealtimeConnecting:
            [self.connection setId:message.connectionId];
            [self.connection setKey:message.connectionKey];
            if (!_resuming) {
                [self.connection setSerial:-1];
                self.msgSerial = 0;
                self.pendingMessageStartSerial = 0;
            }
            [self transition:ARTRealtimeConnected withErrorInfo:message.error];
            break;
        default:
            break;
    }
}

- (void)onDisconnected {
    [self.logger info:@"ARTRealtime disconnected"];
    switch (self.connection.state) {
        case ARTRealtimeConnected:
            [self.connection setId:nil];
            [self transition:ARTRealtimeDisconnected];
            break;
        default:
            NSAssert(false, @"Invalid Realtime state: expected Connected has current state");
            break;
    }
}

- (void)onError:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    if (message.channel) {
        [self onChannelMessage:message];
    } else {
        [self.connection setId:nil];
        [self transition:ARTRealtimeFailed withErrorInfo:message.error];
    }
}

- (void)onAck:(ARTProtocolMessage *)message {
    [self ack:message];
}

- (void)onNack:(ARTProtocolMessage *)message {
    [self nack:message];
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in / error info?
    ARTRealtimeChannel *channel = [self.channels get:message.channel];
    [channel onChannelMessage:message];
}

- (void)onConnectTimerFired {
    switch (self.connection.state) {
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
    switch (self.connection.state) {
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
    switch (self.connection.state) {
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
    switch (self.connection.state) {
        case ARTRealtimeInitialized:
        case ARTRealtimeConnecting:
        case ARTRealtimeDisconnected:
            return true;
        default:
            return false;
    }
}

- (NSTimeInterval)retryInterval {
    switch (self.connection.state) {
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

    // Callback is called with ACK/NACK action
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

- (void)ack:(ARTProtocolMessage *)message {
    int64_t serial = message.msgSerial;
    int count = message.count;
    NSArray *nackMessages = nil;
    NSArray *ackMessages = nil;
    [self.logger verbose:@"ARTRealtime ACK: msgSerial=%lld, count=%d", serial, count];
    [self.logger verbose:@"ARTRealtime ACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];

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
        NSRange ackRange;
        if (count > self.pendingMessages.count) {
            [self.logger error:@"ARTRealtime ACK: count response is greater than the total of pending messages"];
            // Process all the available pending messages
            ackRange = NSMakeRange(0, self.pendingMessages.count);
        }
        else {
            ackRange = NSMakeRange(0, count);
        }
        ackMessages = [self.pendingMessages subarrayWithRange:ackRange];
        [self.pendingMessages removeObjectsInRange:ackRange];
        self.pendingMessageStartSerial += count;
    }

    for (ARTQueuedMessage *msg in nackMessages) {
        if (msg.cb) msg.cb([ARTStatus state:ARTStateError info:message.error]);
    }

    for (ARTQueuedMessage *msg in ackMessages) {
        if (msg.cb) msg.cb([ARTStatus state:ARTStateOk]);
    }

    [self.logger verbose:@"ARTRealtime ACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];
}

- (void)nack:(ARTProtocolMessage *)message {
    int64_t serial = message.msgSerial;
    int count = message.count;
    [self.logger verbose:@"ARTRealtime NACK: msgSerial=%lld, count=%d", serial, count];
    [self.logger verbose:@"ARTRealtime NACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];

    if (serial != self.pendingMessageStartSerial) {
        // This is an error condition and it shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
        serial = self.pendingMessageStartSerial;
    }

    NSRange nackRange;
    if (count > self.pendingMessages.count) {
        [self.logger error:@"ARTRealtime NACK: count response is greater than the total of pending messages"];
        // Process all the available pending messages
        nackRange = NSMakeRange(0, self.pendingMessages.count);
    }
    else {
        nackRange = NSMakeRange(0, count);
    }

    NSArray *nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
    [self.pendingMessages removeObjectsInRange:nackRange];
    self.pendingMessageStartSerial += count;

    for (ARTQueuedMessage *msg in nackMessages) {
        if (msg.cb) msg.cb([ARTStatus state:ARTStateError info:message.error]);
    }

    [self.logger verbose:@"ARTRealtime NACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];
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
        [self.connection setSerial:message.connectionSerial];
    }

    switch (message.action) {
        case ARTProtocolMessageHeartbeat:
            [self onHeartbeat];
            break;
        case ARTProtocolMessageError:
            [self onError:message];
            break;
        case ARTProtocolMessageConnected:
            // Set Auth#clientId
            if (message.connectionDetails) {
                [self.auth setProtocolClientId:message.connectionDetails.clientId];
            }
            // Event
            [self onConnected:message];
            break;
        case ARTProtocolMessageDisconnected:
            [self onDisconnected];
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
    // Close succeeded. Nothing more to do.
    [self transition:ARTRealtimeClosed];
}

- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport {
    [self transition:ARTRealtimeDisconnected];
}

- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withErrorInfo:(ARTErrorInfo *)errorInfo {
    [self transition:ARTRealtimeFailed withErrorInfo:errorInfo];
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
