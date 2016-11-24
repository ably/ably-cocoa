
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
#import "ARTOSReachability.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTPresenceMap.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTEventEmitter.h"
#import "ARTQueuedMessage.h"
#import "ARTConnection+Private.h"
#import "ARTConnectionDetails.h"
#import "ARTStats.h"
#import "ARTRealtimeTransport.h"
#import "ARTFallback.h"

@interface ARTConnectionStateChange ()

- (void)setRetryIn:(NSTimeInterval)retryIn;

@end

#pragma mark - ARTRealtime implementation

@implementation ARTRealtime {
    BOOL _resuming;
    BOOL _renewingToken;
    __GENERIC(ARTEventEmitter, NSNull *, ARTErrorInfo *) *_pingEventEmitter;
    NSDate *_startedReconnection;
    NSTimeInterval _connectionStateTtl;
    Class _transportClass;
    Class _reachabilityClass;
    id<ARTRealtimeTransport> _transport;
    ARTFallback *_fallbacks;
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
        _internalEventEmitter = [[ARTEventEmitter alloc] init];
        _connectedEventEmitter = [[ARTEventEmitter alloc] init];
        _pingEventEmitter = [[ARTEventEmitter alloc] init];
        _channels = [[ARTRealtimeChannels alloc] initWithRealtime:self];
        _transport = nil;
        _transportClass = [ARTWebSocketTransport class];
        _reachabilityClass = [ARTOSReachability class];
        _msgSerial = 0;
        _queuedMessages = [NSMutableArray array];
        _pendingMessages = [NSMutableArray array];
        _pendingMessageStartSerial = 0;
        _connection = [[ARTConnection alloc] initWithRealtime:self];
        _connectionStateTtl = [ARTDefault connectionStateTtl];
        [self.connection setState:ARTRealtimeInitialized];

        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p initialized with RS:%p", self, _rest];

        self.rest.prioritizedHost = nil;
        
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
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p dealloc", self];

    if (_connection) {
        [_connection off];
    }

    if (_internalEventEmitter) {
        [_internalEventEmitter off];
    }

    if (_transport) {
        _transport.delegate = nil;
        [_transport close];
    }
    _transport = nil;
    self.rest.prioritizedHost = nil;
}

- (void)connect {
    if(self.connection.state == ARTRealtimeClosing) {
        // New connection
        _transport = nil;
    }
    [self transition:ARTRealtimeConnecting];
}

- (void)close {
    switch (self.connection.state) {
    case ARTRealtimeInitialized:
    case ARTRealtimeClosing:
    case ARTRealtimeClosed:
    case ARTRealtimeFailed:
        return;
    case ARTRealtimeConnecting: {
        [_internalEventEmitter once:^(ARTConnectionStateChange *change) {
            [self close];
        }];
        return;
    }
    case ARTRealtimeDisconnected:
    case ARTRealtimeSuspended:
        [self transition:ARTRealtimeClosed];
        break;
    case ARTRealtimeConnected:
        [self transition:ARTRealtimeClosing];
        break;
    }
}

- (void)time:(void(^)(NSDate *time, NSError *error))cb {
    [self.rest time:cb];
}

- (void)ping:(void (^)(ARTErrorInfo *)) cb {
    switch (self.connection.state) {
    case ARTRealtimeInitialized:
    case ARTRealtimeSuspended:
    case ARTRealtimeClosing:
    case ARTRealtimeClosed:
    case ARTRealtimeFailed:
        cb([ARTErrorInfo createWithCode:0 status:ARTStateConnectionFailed message:[NSString stringWithFormat:@"Can't ping a %@ connection", ARTRealtimeStateToStr(self.connection.state)]]);
        return;
    case ARTRealtimeConnecting:
    case ARTRealtimeDisconnected:
    case ARTRealtimeConnected:
        if (![self shouldSendEvents]) {
            [_connectedEventEmitter once:^(NSNull *n) {
                [self ping:cb];
            }];
            return;
        }
        [_pingEventEmitter timed:[_pingEventEmitter once:cb] deadline:[ARTDefault realtimeRequestTimeout] onTimeout:^{
            cb([ARTErrorInfo createWithCode:0 status:ARTStateConnectionFailed message:@"timed out"]);
        }];
        [self.transport sendPing];
    }
}

- (BOOL)stats:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *, ARTErrorInfo *))callback {
    return [self stats:[[ARTStatsQuery alloc] init] callback:callback error:nil];
}

- (BOOL)stats:(ARTStatsQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
    return [self.rest stats:query callback:callback error:errorPtr];
}

- (void)transition:(ARTRealtimeConnectionState)state {
    [self transition:state withErrorInfo:nil];
}

- (void)transition:(ARTRealtimeConnectionState)state withErrorInfo:(ARTErrorInfo *)errorInfo {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p transition to %@ requested", self, ARTRealtimeStateToStr(state)];

    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:state previous:self.connection.state reason:errorInfo retryIn:0];
    [self.connection setState:state];

    [self transitionSideEffects:stateChange];

    if (errorInfo != nil) {
        [self.connection setErrorReason:errorInfo];
    }
    [self.connection emit:state with:stateChange];
    [_internalEventEmitter emit:[NSNumber numberWithInteger:state] with:stateChange];
}

- (void)transitionSideEffects:(ARTConnectionStateChange *)stateChange {
    ARTStatus *status = nil;

    switch (stateChange.current) {
        case ARTRealtimeConnecting: {
            [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
                [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createWithCode:0 status:ARTStateConnectionFailed message:@"timed out"]];
            }];

            if (!_reachability) {
                _reachability = [[_reachabilityClass alloc] initWithLogger:self.logger];
            }

            if (!_transport) {
                NSString *resumeKey = nil;
                NSNumber *connectionSerial = nil;
                if (stateChange.previous == ARTRealtimeFailed || stateChange.previous == ARTRealtimeDisconnected) {
                    resumeKey = self.connection.key;
                    connectionSerial = [NSNumber numberWithLongLong:self.connection.serial];
                    _resuming = true;
                }
                _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:resumeKey connectionSerial:connectionSerial];
                _transport.delegate = self;
                [_transport connect];
            }

            if (self.connection.state != ARTRealtimeFailed && self.connection.state != ARTRealtimeClosed) {
                [_reachability listenForHost:[_transport host] callback:^(BOOL reachable) {
                    if (reachable) {
                        switch (_connection.state) {
                            case ARTRealtimeDisconnected:
                            case ARTRealtimeSuspended:
                                [self transition:ARTRealtimeConnecting];
                            default:
                                break;
                        }
                    } else {
                        switch (_connection.state) {
                            case ARTRealtimeConnecting:
                            case ARTRealtimeConnected: {
                                ARTErrorInfo *unreachable = [ARTErrorInfo createWithCode:-1003 message:@"unreachable host"];
                                [self transition:ARTRealtimeDisconnected withErrorInfo:unreachable];
                                break;
                            }
                            default:
                                break;
                        }
                    }
                }];
            }

            break;
        }
        case ARTRealtimeClosing: {
            [_reachability off];
            [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
                [self transition:ARTRealtimeClosed];
            }];
            [self.transport sendClose];
            break;
        }
        case ARTRealtimeClosed:
            [_reachability off];
            [self.transport close];
            self.transport.delegate = nil;
            _connection.key = nil;
            _connection.id = nil;
            _transport = nil;
            self.rest.prioritizedHost = nil;
            break;
        case ARTRealtimeFailed:
            status = [ARTStatus state:ARTStateConnectionFailed info:stateChange.reason];
            [self.transport abort:status];
            self.transport.delegate = nil;
            _transport = nil;
            self.rest.prioritizedHost = nil;
            break;
        case ARTRealtimeDisconnected: {
            if (!_startedReconnection) {
                _startedReconnection = [NSDate date];
                [_internalEventEmitter on:^(ARTConnectionStateChange *change) {
                    if (change.current != ARTRealtimeDisconnected && change.current != ARTRealtimeConnecting) {
                        _startedReconnection = nil;
                    }
                }];
            }
            if ([[NSDate date] timeIntervalSinceDate:_startedReconnection] >= _connectionStateTtl) {
                [self transition:ARTRealtimeSuspended withErrorInfo:stateChange.reason];
                return;
            }

            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            [stateChange setRetryIn:self.options.disconnectedRetryTimeout];

            [self unlessStateChangesBefore:stateChange.retryIn do:^{
                [self transition:ARTRealtimeConnecting];
            }];

            break;
        }
        case ARTRealtimeSuspended: {
            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            [stateChange setRetryIn:self.options.suspendedRetryTimeout];
            [self unlessStateChangesBefore:stateChange.retryIn do:^{
                [self transition:ARTRealtimeConnecting];
            }];
            break;
        }
        case ARTRealtimeConnected: {
            _fallbacks = nil;
            __GENERIC(NSArray, ARTQueuedMessage *) *pending = self.pendingMessages;
            _pendingMessages = [[NSMutableArray alloc] init];
            for (ARTQueuedMessage *queued in pending) {
                [self send:queued.msg callback:^(ARTStatus *__art_nonnull status) {
                    for (id cb in queued.cbs) {
                        ((void(^)(ARTStatus *__art_nonnull))cb)(status);
                    }
                }];
            }
            [_connectedEventEmitter emit:[NSNull null] with:nil];
            break;
        }
        case ARTRealtimeInitialized:
            break;
    }

    if ([self shouldSendEvents]) {
        [self sendQueuedMessages];
    } else if (![self shouldQueueEvents]) {
        [self failQueuedMessages:status];
        ARTStatus *channelStatus = status;
        if (!channelStatus) {
            channelStatus = [self defaultError];
        }
        // For every Channel
        for (ARTRealtimeChannel* channel in self.channels) {
            if (channel.state == ARTRealtimeChannelInitialized || channel.state == ARTRealtimeChannelAttaching || channel.state == ARTRealtimeChannelAttached || channel.state == ARTRealtimeChannelFailed) {
                if(stateChange.current == ARTRealtimeClosing) {
                    //do nothing. Closed state is coming.
                }
                else if(stateChange.current == ARTRealtimeClosed) {
                    [channel detachChannel:[ARTStatus state:ARTStateOk]];
                }
                else if(stateChange.current == ARTRealtimeSuspended) {
                    [channel detachChannel:channelStatus];
                }
                else {
                    [channel setFailed:channelStatus];
                }
            }
            else {
                [channel setSuspended:channelStatus];
            }
        }
    }
}

- (void)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)())callback {
    // Defer until next event loop execution so that any event emitted in the current
    // one doesn't cancel the timeout.
    ARTRealtimeConnectionState state = self.connection.state;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
        if (state != self.connection.state) {
            // Already changed; do nothing.
            return;
        }
        [_internalEventEmitter timed:[_internalEventEmitter once:^(ARTConnectionStateChange *change) {
            // Any state change cancels the timeout.
        }] deadline:deadline onTimeout:callback];
    });
}

- (void)onHeartbeat {
    [self.logger verbose:@"R:%p ARTRealtime heartbeat received", self];
    if(self.connection.state != ARTRealtimeConnected) {
        NSString *msg = [NSString stringWithFormat:@"ARTRealtime received a ping when in state %@", ARTRealtimeStateToStr(self.connection.state)];
        [self.logger warn:@"R:%p %@", self, msg];
    }
    [_pingEventEmitter emit:[NSNull null] with:nil];
}

- (void)onConnected:(ARTProtocolMessage *)message {
    _renewingToken = false;

    // Resuming
    if (_resuming) {
        if (![message.connectionId isEqualToString:self.connection.id]) {
            [self.logger warn:@"R:%p ARTRealtime: connection has reconnected, but resume failed. Detaching all channels", self];
            // Fatal error, detach all channels
            for (ARTRealtimeChannel *channel in self.channels) {
                [channel detachChannel:[ARTStatus state:ARTStateConnectionDisconnected info:message.error]];
            }
        }
        else if (message.error) {
            [self.logger warn:@"R:%p ARTRealtime: connection has resumed with non-fatal error %@", self, message.error.message];
            // The error will be emitted on `transition`
        }
        _resuming = false;

        for (ARTRealtimeChannel *channel in self.channels) {
            if (channel.presenceMap.syncInProgress) {
                [channel requestContinueSync];
            }
        }
    }

    switch (self.connection.state) {
        case ARTRealtimeConnecting:
            [self.connection setId:message.connectionId];
            [self.connection setKey:message.connectionKey];
            if (!_resuming) {
                [self.connection setSerial:message.connectionSerial];
                self.msgSerial = 0;
                self.pendingMessageStartSerial = 0;
            }
            if (message.connectionDetails && message.connectionDetails.connectionStateTtl) {
                _connectionStateTtl = message.connectionDetails.connectionStateTtl;
            }
            [self transition:ARTRealtimeConnected withErrorInfo:message.error];
            break;
        case ARTRealtimeConnected:
            // Renewing token.
            [self transitionSideEffects:[[ARTConnectionStateChange alloc] initWithCurrent:ARTRealtimeConnected previous:ARTRealtimeConnected reason:nil]];
            [self transition:ARTRealtimeConnected withErrorInfo:message.error];
        default:
            break;
    }
}

- (void)onDisconnected {
    [self onDisconnected:nil];
}

- (void)onDisconnected:(ARTProtocolMessage *)message {
    [self.logger info:@"R:%p ARTRealtime disconnected", self];
    ARTErrorInfo *error;
    if (message) {
        error = message.error;
    }
    if (!_renewingToken && error && error.statusCode == 401 && error.code >= 40140 && error.code < 40150 && [self isTokenRenewable]) {
        [self connectWithRenewedToken];
        [self transition:ARTRealtimeDisconnected withErrorInfo:error];
        [self.connection setErrorReason:nil];
        return;
    }
    [self transition:ARTRealtimeDisconnected withErrorInfo:error];
}

- (void)onClosed {
    [self.logger info:@"R:%p ARTRealtime closed", self];
    switch (self.connection.state) {
        case ARTRealtimeClosed:
            break;
        case ARTRealtimeClosing:
            [self.connection setId:nil];
            [self transition:ARTRealtimeClosed];
            break;
        default:
            NSAssert(false, @"Invalid Realtime state transitioning to Closed: expected Closing or Closed");
            break;
    }
}

- (void)onError:(ARTProtocolMessage *)message {
    // TODO work out which states this can be received in
    if (message.channel) {
        [self onChannelMessage:message];
    } else {
        ARTErrorInfo *error = message.error;
        if (!_renewingToken && error && error.statusCode == 401 && error.code >= 40140 && error.code < 40150 && [self isTokenRenewable]) {
            [self connectWithRenewedToken];
            return;
        }
        [self.connection setId:nil];
        [self transition:ARTRealtimeFailed withErrorInfo:message.error];
    }
}

- (BOOL)isTokenRenewable {
    return self.options.authCallback || self.options.authUrl || self.options.key;
}

- (void)connectWithRenewedToken {
    _renewingToken = true;
    [_transport close];
    _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:_transport.resumeKey connectionSerial:_transport.connectionSerial];
    _transport.delegate = self;
    [_transport connectForcingNewToken:true];
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

- (void)onSuspended {
    [self transition:ARTRealtimeSuspended];
}

- (BOOL)shouldSendEvents {
    switch (self.connection.state) {
        case ARTRealtimeConnected:
            return !_renewingToken;
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
        case ARTRealtimeConnected:
            return _renewingToken;
        default:
            return false;
    }
}

- (ARTStatus *)defaultError {
    return [ARTStatus state:ARTStateError];
}

- (BOOL)isActive {
    return [self shouldQueueEvents] || [self shouldSendEvents];
}

- (void)sendImpl:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb {
    if (msg.ackRequired) {
        msg.msgSerial = self.msgSerial++;
        ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:msg callback:cb];
        [self.pendingMessages addObject:qm];
    }

    // Callback is called with ACK/NACK action
    [self.transport send:msg];
}

- (void)send:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb {
    if ([self shouldSendEvents]) {
        [self sendImpl:msg callback:cb];
    } else if ([self shouldQueueEvents]) {
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
        [self sendImpl:message.msg callback:message.cb];
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
    [self.logger verbose:@"R:%p ARTRealtime ACK: msgSerial=%lld, count=%d", self, serial, count];
    [self.logger verbose:@"R:%p ARTRealtime ACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];

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
            [self.logger error:@"R:%p ARTRealtime ACK: count response is greater than the total of pending messages", self];
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

    [self.logger verbose:@"R:%p ARTRealtime ACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];
}

- (void)nack:(ARTProtocolMessage *)message {
    int64_t serial = message.msgSerial;
    int count = message.count;
    [self.logger verbose:@"R:%p ARTRealtime NACK: msgSerial=%lld, count=%d", self, serial, count];
    [self.logger verbose:@"R:%p ARTRealtime NACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];

    if (serial != self.pendingMessageStartSerial) {
        // This is an error condition and it shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
        serial = self.pendingMessageStartSerial;
    }

    NSRange nackRange;
    if (count > self.pendingMessages.count) {
        [self.logger error:@"R:%p ARTRealtime NACK: count response is greater than the total of pending messages", self];
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

    [self.logger verbose:@"R:%p ARTRealtime NACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];
}

- (BOOL)reconnectWithFallback {
    NSString *host = [_fallbacks popFallbackHost];
    if (host != nil) {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p host is down; retrying realtime connection at %@", self, host];
        self.rest.prioritizedHost = host;
        [self.transport setHost:host];
        [self.transport connect];
        return true;
    } else {
        _fallbacks = nil;
        return false;
    }
}

- (BOOL)shouldRetryWithFallback:(ARTRealtimeTransportError *)error {
    if (
        (error.type == ARTRealtimeTransportErrorTypeBadResponse && error.badResponseCode >= 500 && error.badResponseCode <= 504) ||
        error.type == ARTRealtimeTransportErrorTypeHostUnreachable ||
        error.type == ARTRealtimeTransportErrorTypeTimeout
    ) {
        return YES;
    }
    return NO;
}

- (void)setTransportClass:(Class)transportClass {
    _transportClass = transportClass;
}

- (void)setReachabilityClass:(Class)reachabilityClass {
    _reachabilityClass = reachabilityClass;
}

+ (NSString *)protocolStr:(ARTProtocolMessageAction) action {
    switch(action) {
        case ARTProtocolMessageHeartbeat:
            return @"Heartbeat"; //0
        case ARTProtocolMessageAck:
            return @"Ack"; //1
        case ARTProtocolMessageNack:
            return @"Nack"; //2
        case ARTProtocolMessageConnect:
            return @"Connect"; //3
        case ARTProtocolMessageConnected:
            return @"Connected"; //4
        case ARTProtocolMessageDisconnect:
            return @"Disconnect"; //5
        case ARTProtocolMessageDisconnected:
            return @"Disconnected"; //6
        case ARTProtocolMessageClose:
            return @"Close"; //7
        case ARTProtocolMessageClosed:
            return @"Closed"; //8
        case ARTProtocolMessageError:
            return @"Error"; //9
        case ARTProtocolMessageAttach:
            return @"Attach"; //10
        case ARTProtocolMessageAttached:
            return @"Attached"; //11
        case ARTProtocolMessageDetach:
            return @"Detach"; //12
        case ARTProtocolMessageDetached:
            return @"Detached"; //13
        case ARTProtocolMessagePresence:
            return @"Presence"; //14
        case ARTProtocolMessageMessage:
            return @"Message"; //15
        case ARTProtocolMessageSync:
            return @"Sync"; //16
        default:
            return [NSString stringWithFormat: @"unknown protocol state %d", (int)action];
    }
}

#pragma mark - ARTRealtimeTransportDelegate implementation

- (void)realtimeTransport:(id)transport didReceiveMessage:(ARTProtocolMessage *)message {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self.logger verbose:@"R:%p ARTRealtime didReceive Protocol Message %@ ", self, [ARTRealtime protocolStr:message.action]];

    if (message.error) {
        [self.logger verbose:@"R:%p ARTRealtime Protocol Message with error %@ ", self, message.error];
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
        case ARTProtocolMessageDisconnect:
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
            [self onClosed];
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
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self transition:ARTRealtimeDisconnected];
}

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    // Close succeeded. Nothing more to do.
    [self transition:ARTRealtimeClosed];
}

- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    if (self.connection.state == ARTRealtimeClosing) {
        [self transition:ARTRealtimeClosed];
    } else {
        [self transition:ARTRealtimeDisconnected];
    }
}

- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p realtime transport failed: %@", self, error];

    if ([self shouldRetryWithFallback:error]) {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p host is down; can retry with fallback host", self];
        if (!_fallbacks && [error.url.host isEqualToString:[ARTDefault realtimeHost]]) {
            [self.rest internetIsUp:^void(BOOL isUp) {
                _fallbacks = [[ARTFallback alloc] initWithFallbackHosts:[self getClientOptions].fallbackHosts];
                (_fallbacks != nil) ? [self reconnectWithFallback] : [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createWithNSError:error.error]];
            }];
            return;
        } else if (_fallbacks && [self reconnectWithFallback]) {
            return;
        }
    }

    if (error.type == ARTRealtimeTransportErrorTypeNoInternet) {
        [self transition:ARTRealtimeDisconnected];
    } else {
        [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createWithNSError:error.error]];
    }
}

- (void)realtimeTransportNeverConnected:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self transition:ARTRealtimeFailed];
}

- (void)realtimeTransportRefused:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self transition:ARTRealtimeFailed];
}

- (void)realtimeTransportTooBig:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self transition:ARTRealtimeFailed];
}

@end
