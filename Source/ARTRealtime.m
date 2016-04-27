
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

// State properties
- (BOOL)shouldSendEvents;
- (BOOL)shouldQueueEvents;
- (ARTStatus *)defaultError;

// Message sending
- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)error;

@end


#pragma mark - ARTRealtime implementation

@implementation ARTRealtime {
    BOOL _resuming;
    BOOL _renewingToken;
    __GENERIC(ARTEventEmitter, NSNull *, ARTErrorInfo *) *_pingEventEmitter;
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
        _reconnectedEventEmitter = [[ARTEventEmitter alloc] init];
        _pingEventEmitter = [[ARTEventEmitter alloc] init];
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

        [self.logger debug:__FILE__ line:__LINE__ message:@"initialized %p", self];
        
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

    if (_connection) {
        [_connection off];
    }

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
    switch (self.connection.state) {
    case ARTRealtimeInitialized:
    case ARTRealtimeClosing:
    case ARTRealtimeClosed:
    case ARTRealtimeFailed:
        return;
    case ARTRealtimeConnecting: {
        [_connection once:^(ARTConnectionStateChange *change) {
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
        [NSException raise:@"Can't ping a closed or failed connection" format:@"%@:", [ARTRealtime ARTRealtimeStateToStr:self.connection.state]];
        return;
    case ARTRealtimeConnecting:
    case ARTRealtimeDisconnected: {
        [_connection once:^(ARTConnectionStateChange *change) {
            [self ping:cb];
        }];
        return;
    }
    case ARTRealtimeConnected:
        [_pingEventEmitter timed:[_pingEventEmitter once:cb] deadline:[ARTDefault realtimeRequestTimeout] onTimeout:^{
            cb([ARTErrorInfo createWithCode:0 status:ARTStateConnectionFailed message:@"connection failed"]);
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

- (void)resetEventEmitter {
    _eventEmitter = [[ARTEventEmitter alloc] init];
}

- (void)transition:(ARTRealtimeConnectionState)state {
    [self transition:state withErrorInfo:nil];
}

- (void)transition:(ARTRealtimeConnectionState)state withErrorInfo:(ARTErrorInfo *)errorInfo {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p transition to %@ requested", self, [ARTRealtime ARTRealtimeStateToStr:state]];

    ARTRealtimeConnectionState previousState = self.connection.state;
    [self.connection setState:state];

    ARTStatus *status = nil;

    switch (self.connection.state) {
        case ARTRealtimeConnecting: {
            [self unlessStateChangesBefore:[ARTDefault connectTimeout] do:^{
                [self transition:ARTRealtimeFailed];
            }];

            if (!_transport) {
                NSString *resumeKey = nil;
                NSNumber *connectionSerial = nil;
                if (previousState == ARTRealtimeFailed || previousState == ARTRealtimeDisconnected) {
                    resumeKey = self.connection.key;
                    connectionSerial = [NSNumber numberWithLongLong:self.connection.serial];
                    _resuming = true;
                }
                _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:resumeKey connectionSerial:connectionSerial];
                _transport.delegate = self;
                [_transport connect];
            }

            if (previousState == ARTRealtimeDisconnected) {
                __GENERIC(NSArray, ARTQueuedMessage *) *pending = self.pendingMessages;
                _pendingMessages = [[NSMutableArray alloc] init];
                for (ARTQueuedMessage *queued in pending) {
                    [self send:queued.msg callback:^(ARTStatus *__art_nonnull status) {
                        for (id cb in queued.cbs) {
                            ((void(^)(ARTStatus *__art_nonnull))cb)(status);
                        }
                    }];
                }

                [_reconnectedEventEmitter emit:[NSNull null] with:nil];
            }

            break;
        }
        case ARTRealtimeClosing: {
            [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
                [self transition:ARTRealtimeClosed];
            }];
            [self.transport sendClose];
            break;
        }
        case ARTRealtimeClosed:
            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            break;
        case ARTRealtimeFailed:
            status = [ARTStatus state:ARTStateConnectionFailed info:errorInfo];
            [self.transport abort:status];
            self.transport.delegate = nil;
            _transport = nil;
            break;
        case ARTRealtimeDisconnected: {
            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;

            [self unlessStateChangesBefore:self.options.disconnectedRetryTimeout do:^{
                [self transition:ARTRealtimeConnecting];
            }];

            break;
        }
        case ARTRealtimeSuspended: {
            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            [self unlessStateChangesBefore:self.options.suspendedRetryTimeout do:^{
                [self transition:ARTRealtimeConnecting];
            }];
            break;
        }
        case ARTRealtimeConnected:
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
                if(state == ARTRealtimeClosing) {
                    //do nothing. Closed state is coming.
                }
                else if(state == ARTRealtimeClosed) {
                    [channel detachChannel:[ARTStatus state:ARTStateOk]];
                }
                else if(state == ARTRealtimeSuspended) {
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
    
    [self.connection emit:state with:[[ARTConnectionStateChange alloc] initWithCurrent:state previous:previousState reason:errorInfo]];
}

- (void)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)())callback {
    // Defer until next event loop execution so that any event emitted in the current
    // one doesn't cancel the timeout.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
        [_connection timed:[_connection once:^(ARTConnectionStateChange *change) {
            // Any state change cancels the timeout.
        }] deadline:deadline onTimeout:callback];
    });
}

- (void)onHeartbeat {
    [self.logger verbose:@"ARTRealtime heartbeat received"];
    if(self.connection.state != ARTRealtimeConnected) {
        NSString *msg = [NSString stringWithFormat:@"ARTRealtime received a ping when in state %@", [ARTRealtime ARTRealtimeStateToStr:self.connection.state]];
        [self.logger warn:@"%@", msg];
    }
    [_pingEventEmitter emit:[NSNull null] with:nil];
}

- (void)onConnected:(ARTProtocolMessage *)message {
    _renewingToken = false;

    // Resuming
    if (_resuming) {
        if (message.error && ![message.connectionId isEqualToString:self.connection.id]) {
            [self.logger warn:@"ARTRealtime: connection has reconnected, but resume failed. Detaching all channels"];
            // Fatal error, detach all channels
            for (ARTRealtimeChannel *channel in self.channels) {
                [channel detachChannel:[ARTStatus state:ARTStateConnectionDisconnected info:message.error]];
            }
        }
        else if (message.error) {
            [self.logger warn:@"ARTRealtime: connection has resumed with non-fatal error %@", message.error.message];
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
            [self transition:ARTRealtimeDisconnected];
            break;
        default:
            NSAssert(false, @"Invalid Realtime state transitioning to Disconnected: expected Connected");
            break;
    }
}

- (void)onClosed {
    [self.logger info:@"ARTRealtime closed"];
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
    [self.transport close];
    [self.transport connectForcingNewToken:true];
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
        if ([self.queuedMessages count]) {
            ARTQueuedMessage *lastQueued = [self.queuedMessages objectAtIndex:(self.queuedMessages.count) - 1];
            merged = [lastQueued mergeFrom:msg callback:cb];
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
    [self transition:ARTRealtimeDisconnected];
}

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport {
    // Close succeeded. Nothing more to do.
    [self transition:ARTRealtimeClosed];
}

- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport {
    if (self.connection.state == ARTRealtimeClosing) {
        [self transition:ARTRealtimeClosed];
    } else {
        [self transition:ARTRealtimeDisconnected];
    }
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

+ (NSString *)ARTRealtimeStateToStr:(ARTRealtimeConnectionState) state {
    switch(state)
    {
        case ARTRealtimeInitialized:
            return @"Initialized"; //0
        case ARTRealtimeConnecting:
            return @"Connecting"; //1
        case ARTRealtimeConnected:
            return @"Connected"; //2
        case ARTRealtimeDisconnected:
            return @"Disconnected"; //3
        case ARTRealtimeSuspended:
            return @"Suspended"; //4
        case ARTRealtimeClosing:
            return @"Closing"; //5
        case ARTRealtimeClosed:
            return @"Closed"; //6
        case ARTRealtimeFailed:
            return @"Failed"; //7
        default:
            return [NSString stringWithFormat: @"unknown connection state %d", (int)state];
    }
}

@end
