
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
#import "ARTTokenDetails.h"
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
#import "ARTEventEmitter+Private.h"
#import "ARTQueuedMessage.h"
#import "ARTConnection+Private.h"
#import "ARTConnectionDetails.h"
#import "ARTStats.h"
#import "ARTRealtimeTransport.h"
#import "ARTFallback.h"
#import "ARTAuthDetails.h"
#import "ARTGCD.h"

@interface ARTConnectionStateChange ()

- (void)setRetryIn:(NSTimeInterval)retryIn;

@end

#pragma mark - ARTRealtime implementation

@implementation ARTRealtime {
    BOOL _resuming;
    BOOL _renewingToken;
    __GENERIC(ARTEventEmitter, NSNull *, ARTErrorInfo *) *_pingEventEmitter;
    NSDate *_startedReconnection;
    Class _transportClass;
    Class _reachabilityClass;
    id<ARTRealtimeTransport> _transport;
    ARTFallback *_fallbacks;
    _Nonnull dispatch_queue_t _eventQueue;
}

@synthesize authorizationEmitter = _authorizationEmitter;

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
        _eventQueue = dispatch_queue_create("io.ably.realtime.events", DISPATCH_QUEUE_SERIAL);
        _internalEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
        _connectedEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
        _pingEventEmitter = [[ARTEventEmitter alloc] initWithQueue:_eventQueue];
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
        _authorizationEmitter = [[ARTEventEmitter alloc] init];
        self.auth.delegate = self;

        [self.connection setState:ARTRealtimeInitialized];

        [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p initialized with RS:%p", self, _rest];

        self.rest.prioritizedHost = nil;

        if (options.autoConnect) {
            [self connect];
        }
    }
    return self;
}

- (void)auth:(ARTAuth *)auth didAuthorize:(ARTTokenDetails *)tokenDetails {
    switch (self.connection.state) {
        case ARTRealtimeConnected: {
                // Update (send AUTH message)
                [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p AUTH message using %@", _rest, tokenDetails];
                ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
                msg.action = ARTProtocolMessageAuth;
                msg.auth = [[ARTAuthDetails alloc] initWithToken:tokenDetails.token];
                [self send:msg callback:nil];
            }
            break;
        case ARTRealtimeConnecting: {
                switch (_transport.state) {
                    case ARTRealtimeTransportStateOpening:
                    case ARTRealtimeTransportStateOpened: {
                            // Halt the current connection and reconnect with the most recent token
                            [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p halt current connection and reconnect with %@", _rest, tokenDetails];
                            [_transport abort:[ARTStatus state:ARTStateOk]];
                            [_transport connectWithToken:tokenDetails.token];
                        }
                        break;
                    case ARTRealtimeTransportStateClosed:
                    case ARTRealtimeTransportStateClosing:
                        // Ignore
                        [_authorizationEmitter off];
                        break;
                }
            }
            break;
        default:
            // Client state is NOT Connecting or Connected, so it should start a new connection
            [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p start a connection using %@", _rest, tokenDetails];
            [self transition:ARTRealtimeConnecting];
            break;
    }
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
    NSString *info;
    if (self.options.token) {
        info = [NSString stringWithFormat:@"token: %@", self.options.token];
    }
    else if (self.options.authUrl) {
        info = [NSString stringWithFormat:@"authUrl: %@", self.options.authUrl];
    }
    else if (self.options.authCallback) {
        info = [NSString stringWithFormat:@"authCallback: %@", self.options.authCallback];
    }
    else {
        info = [NSString stringWithFormat:@"key: %@", self.options.key];
    }
    return [NSString stringWithFormat:@"%@ - \n\t %@;", [super description], info];
}

- (ARTAuth *)getAuth {
    return self.rest.auth;
}

- (void)dealloc {
    [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p dealloc", self];

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
        cb([ARTErrorInfo createWithCode:0 status:ARTStateConnectionFailed message:[NSString stringWithFormat:@"Can't ping a %@ connection", ARTRealtimeConnectionStateToStr(self.connection.state)]]);
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
            cb([ARTErrorInfo createWithCode:ARTCodeErrorConnectionTimedOut status:ARTStateConnectionFailed message:@"timed out"]);
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
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p realtime state transitions to %tu - %@", self, state, ARTRealtimeConnectionStateToStr(state)];

    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:state previous:self.connection.state event:(ARTRealtimeConnectionEvent)state reason:errorInfo retryIn:0];
    [self.connection setState:state];

    if (errorInfo != nil) {
        [self.connection setErrorReason:errorInfo];
    }

    dispatch_semaphore_t waitingForCurrentEventSemaphore = [self transitionSideEffects:stateChange];

    [_internalEventEmitter emit:[NSNumber numberWithInteger:state] with:stateChange];

    if (waitingForCurrentEventSemaphore) {
        // Current event is handled. Start running timeouts.
        dispatch_semaphore_signal(waitingForCurrentEventSemaphore);
    }
}

- (void)updateWithErrorInfo:(art_nullable ARTErrorInfo *)errorInfo {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p update requested", self];

    if (self.connection.state != ARTRealtimeConnected) {
        [self.logger warn:@"R:%p update ignored because connection is not connected", self];
        return;
    }

    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:self.connection.state previous:self.connection.state event:ARTRealtimeConnectionEventUpdate reason:errorInfo retryIn:0];

    dispatch_semaphore_t semaphore = [self transitionSideEffects:stateChange];

    if (semaphore) {
        dispatch_semaphore_signal(semaphore);
    }
}

- (_Nullable dispatch_semaphore_t)transitionSideEffects:(ARTConnectionStateChange *)stateChange {
    ARTStatus *status = nil;
    dispatch_semaphore_t waitingForCurrentEventSemaphore = nil;
    // Do not increase the reference count (avoid retain cycles):
    // i.e. the `unlessStateChangesBefore` is setting a timer and if the `ARTRealtime` instance is released before that timer, then it could create a leak.
    __weak __typeof(self) weakSelf = self;

    switch (stateChange.current) {
        case ARTRealtimeConnecting: {
            waitingForCurrentEventSemaphore = [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
                [weakSelf onConnectionTimeOut];
            }];

            if (!_reachability) {
                _reachability = [[_reachabilityClass alloc] initWithLogger:self.logger];
            }

            if (!_transport) {
                NSString *resumeKey = nil;
                NSNumber *connectionSerial = nil;
                if (stateChange.previous == ARTRealtimeFailed || stateChange.previous == ARTRealtimeDisconnected || stateChange.previous == ARTRealtimeSuspended) {
                    resumeKey = self.connection.key;
                    connectionSerial = [NSNumber numberWithLongLong:self.connection.serial];
                    _resuming = true;
                }
                _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:resumeKey connectionSerial:connectionSerial];
                _transport.delegate = self;
                [self transportConnectForcingNewToken:_renewingToken];
            }

            if (self.connection.state != ARTRealtimeFailed && self.connection.state != ARTRealtimeClosed && self.connection.state != ARTRealtimeDisconnected) {
                [_reachability listenForHost:[_transport host] callback:^(BOOL reachable) {
                    if (reachable) {
                        switch ([[weakSelf connection] state]) {
                            case ARTRealtimeDisconnected:
                            case ARTRealtimeSuspended:
                                [weakSelf transition:ARTRealtimeConnecting];
                            default:
                                break;
                        }
                    } else {
                        switch ([[weakSelf connection] state]) {
                            case ARTRealtimeConnecting:
                            case ARTRealtimeConnected: {
                                ARTErrorInfo *unreachable = [ARTErrorInfo createWithCode:-1003 message:@"unreachable host"];
                                [weakSelf transition:ARTRealtimeDisconnected withErrorInfo:unreachable];
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
            waitingForCurrentEventSemaphore = [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
                [weakSelf transition:ARTRealtimeClosed];
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
            [_authorizationEmitter emit:[NSNumber numberWithInt:ARTAuthorizationFailed] with:[ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been closed"]];
            break;
        case ARTRealtimeFailed:
            status = [ARTStatus state:ARTStateConnectionFailed info:stateChange.reason];
            [self.transport abort:status];
            self.transport.delegate = nil;
            _transport = nil;
            self.rest.prioritizedHost = nil;
            [_authorizationEmitter emit:[NSNumber numberWithInt:ARTAuthorizationFailed] with:stateChange.reason];
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
                return nil;
            }

            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            [stateChange setRetryIn:self.options.disconnectedRetryTimeout];
            waitingForCurrentEventSemaphore = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                [weakSelf transition:ARTRealtimeConnecting];
            }];
            break;
        }
        case ARTRealtimeSuspended: {
            [self.transport close];
            self.transport.delegate = nil;
            _transport = nil;
            [stateChange setRetryIn:self.options.suspendedRetryTimeout];
            waitingForCurrentEventSemaphore = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                [weakSelf transition:ARTRealtimeConnecting];
            }];
            [_authorizationEmitter emit:[NSNumber numberWithInt:ARTAuthorizationFailed] with:[ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been suspended"]];
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
            [_authorizationEmitter emit:[NSNumber numberWithInt:ARTAuthorizationSucceeded] with:nil];
            break;
        }
        case ARTRealtimeInitialized:
            break;
    }

    if ([self shouldSendEvents]) {
        [self sendQueuedMessages];
        // For every Channel
        for (ARTRealtimeChannel* channel in self.channels) {
            if (channel.state == ARTRealtimeChannelSuspended) {
                [channel attach];
            }
        }
    } else if (![self shouldQueueEvents]) {
        [self failQueuedMessages:status];
        ARTStatus *channelStatus = status;
        if (!channelStatus) {
            channelStatus = [self defaultError];
        }
        // For every Channel
        for (ARTRealtimeChannel* channel in self.channels) {
            switch (channel.state) {
                case ARTRealtimeChannelInitialized:
                case ARTRealtimeChannelAttaching:
                case ARTRealtimeChannelAttached:
                case ARTRealtimeChannelFailed:
                    if (stateChange.current == ARTRealtimeClosing) {
                        //do nothing. Closed state is coming.
                    }
                    else if (stateChange.current == ARTRealtimeClosed) {
                        [channel detachChannel:[ARTStatus state:ARTStateOk]];
                    }
                    else if (stateChange.current == ARTRealtimeSuspended) {
                        [channel setSuspended:channelStatus];
                    }
                    else {
                        [channel setFailed:channelStatus];
                    }
                    break;
                default:
                    [channel setSuspended:channelStatus];
                    break;
            }
        }
    }

    [self.connection emit:stateChange.event with:stateChange];
    return waitingForCurrentEventSemaphore;
}

- (_Nonnull dispatch_semaphore_t)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)())callback __attribute__((warn_unused_result)) {
    // Defer until next event loop execution so that any event emitted in the current one doesn't cancel the timeout.
    ARTRealtimeConnectionState state = self.connection.state;
    // Timeout should be dispatched after current event.
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), _eventQueue, ^{
        // Wait until the current event is done.
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (state != self.connection.state) {
            // Already changed; Ignore the timer.
            return;
        }
        [_internalEventEmitter timed:[_internalEventEmitter once:^(ARTConnectionStateChange *change) {
            // Any state change cancels the timeout.
        }] deadline:deadline onTimeout:callback];
    });
    return semaphore;
}

- (void)onHeartbeat {
    [self.logger verbose:@"R:%p ARTRealtime heartbeat received", self];
    if(self.connection.state != ARTRealtimeConnected) {
        NSString *msg = [NSString stringWithFormat:@"ARTRealtime received a ping when in state %@", ARTRealtimeConnectionStateToStr(self.connection.state)];
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
            _resuming = false;
        }
        else if (message.error) {
            [self.logger warn:@"R:%p ARTRealtime: connection has resumed with non-fatal error %@", self, message.error.message];
            // The error will be emitted on `transition`
        }

        [self.logger debug:@"RT:%p connection \"%@\" has reconnected and resumed successfully", self, self.connection.id];

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
                [self.logger debug:@"RT:%p msgSerial of connection \"%@\" has been reset", self, self.connection.id];
                self.msgSerial = 0;
                self.pendingMessageStartSerial = 0;
            }
            if (message.connectionDetails && message.connectionDetails.connectionStateTtl) {
                _connectionStateTtl = message.connectionDetails.connectionStateTtl;
            }
            [self transition:ARTRealtimeConnected withErrorInfo:message.error];
            break;
        case ARTRealtimeConnected: {
            // Renewing token.
            [self updateWithErrorInfo:message.error];
        }
        default:
            break;
    }

    _resuming = false;
}

- (void)onDisconnected {
    [self onDisconnected:nil];
}

- (void)onDisconnected:(ARTProtocolMessage *)message {
    [self.logger info:@"R:%p ARTRealtime disconnected", self];
    ARTErrorInfo *error = message.error;
    if ([self shouldRenewToken:&error]) {
        [self transition:ARTRealtimeDisconnected withErrorInfo:error];
        [self.connection setErrorReason:nil];
        _renewingToken = true;
        [self transition:ARTRealtimeConnecting withErrorInfo:nil];
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

- (void)onAuth {
    [self.logger info:@"R:%p server has requested an authorise", self];
    switch (self.connection.state) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
            _resuming = true;
            [self transportReconnectWithRenewedToken];
            break;
        default:
            [self.logger error:@"Invalid Realtime state: expected Connecting or Connected"];
            break;
    }
}

- (void)onError:(ARTProtocolMessage *)message {
    if (message.channel) {
        [self onChannelMessage:message];
    } else {
        ARTErrorInfo *error = message.error;
        if ([self shouldRenewToken:&error]) {
            [self.transport close];
            [self transportReconnectWithRenewedToken];
            return;
        }
        [self.connection setId:nil];
        [self transition:ARTRealtimeFailed withErrorInfo:error];
    }
}

- (void)onConnectionTimeOut {
    ARTErrorInfo *error;
    if (self.auth.authorizing && (self.options.authUrl || self.options.authCallback)) {
        error = [ARTErrorInfo createWithCode:ARTCodeErrorAuthConfiguredProviderFailure status:ARTStateConnectionFailed message:@"timed out"];
    }
    else {
        error = [ARTErrorInfo createWithCode:ARTCodeErrorConnectionTimedOut status:ARTStateConnectionFailed message:@"timed out"];
    }
    switch (self.connection.state) {
        case ARTRealtimeConnected:
            [self transition:ARTRealtimeConnected withErrorInfo:error];
            break;
        default:
            [self transition:ARTRealtimeDisconnected withErrorInfo:error];
            break;
    }
}

- (BOOL)shouldRenewToken:(ARTErrorInfo **)errorPtr {
    if (!_renewingToken && errorPtr && *errorPtr &&
        (*errorPtr).statusCode == 401 && (*errorPtr).code >= 40140 && (*errorPtr).code < 40150) {
        if ([self.auth tokenIsRenewable]) {
            return YES;
        }
        *errorPtr = [ARTErrorInfo createWithCode:ARTStateRequestTokenFailed message:ARTAblyMessageNoMeansToRenewToken];
    }
    return NO;
}

- (void)transportReconnectWithHost:(NSString *)host {
    [self.transport setHost:host];
    [self transportConnectForcingNewToken:false];
}

- (void)transportReconnectWithRenewedToken {
    _renewingToken = true;
    [self transportConnectForcingNewToken:true];
}

- (void)transportConnectForcingNewToken:(BOOL)forceNewToken {
    ARTClientOptions *options = [self.options copy];
    if ([options isBasicAuth]) {
        // Basic
        [self.transport connectWithKey:options.key];
    }
    else {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p connecting with token auth; authorising", self];

        if (!forceNewToken && [self.auth tokenRemainsValid]) {
            // Reuse token
            [self.transport connectWithToken:self.auth.tokenDetails.token];
        }
        else {
            // New Token
            // Transport instance couldn't exist anymore when `authorize` completes or reaches time out.
            __weak __typeof(self) weakSelf = self;

            dispatch_block_t work = artDispatchScheduled([ARTDefault realtimeRequestTimeout], ^{
                [weakSelf onConnectionTimeOut];
            });

            // Deactivate use of `ARTAuthDelegate`: `authorize` should complete without waiting for a CONNECTED state.
            id<ARTAuthDelegate> delegate = self.auth.delegate;
            self.auth.delegate = nil;
            @try {
                [self.auth authorize:nil options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
                    // Cancel scheduled work
                    artDispatchCancel(work);
                    // It's still valid?
                    switch ([[weakSelf connection] state]) {
                        case ARTRealtimeClosing:
                        case ARTRealtimeClosed:
                            return;
                        default:
                            break;
                    }

                    [[weakSelf getLogger] debug:__FILE__ line:__LINE__ message:@"R:%p authorised: %@ error: %@", weakSelf, tokenDetails, error];
                    if (error) {
                        [weakSelf handleTokenAuthError:error];
                        return;
                    }

                    if (forceNewToken) {
                        [_transport close];
                        _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:_transport.resumeKey connectionSerial:_transport.connectionSerial];
                        _transport.delegate = self;
                    }
                    [[weakSelf getTransport] connectWithToken:tokenDetails.token];
                }];
            }
            @finally {
                self.auth.delegate = delegate;
            }
        }
    }
}

- (void)handleTokenAuthError:(NSError *)error {
    [self.logger error:@"R:%p token auth failed with %@", self, error.description];
    if (error.code == 40102 /*incompatible credentials*/) {
        // RSA15c
        [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:error]];
    }
    else if (self.options.authUrl || self.options.authCallback) {
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTCodeErrorAuthConfiguredProviderFailure status:ARTStateConnectionFailed message:error.description];
        switch (self.connection.state) {
            case ARTRealtimeConnected:
                // RSA4c3
                [self.connection setErrorReason:errorInfo];
                break;
            default:
                // RSA4c
                [self transition:ARTRealtimeDisconnected withErrorInfo:errorInfo];
                break;
        }
    }
    else {
        // RSA4b
        [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createFromNSError:error]];
    }
}

- (void)onAck:(ARTProtocolMessage *)message {
    [self ack:message];
}

- (void)onNack:(ARTProtocolMessage *)message {
    [self nack:message];
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
    if (message.channel == nil) {
        return;
    }
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
        msg.msgSerial = [NSNumber numberWithLongLong:self.msgSerial++];
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
    int64_t serial = [message.msgSerial longLongValue];
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
    int64_t serial = [message.msgSerial longLongValue];
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
        [self transportReconnectWithHost:host];
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

#pragma mark - ARTRealtimeTransportDelegate implementation

- (void)realtimeTransport:(id)transport didReceiveMessage:(ARTProtocolMessage *)message {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self.logger verbose:@"R:%p ARTRealtime didReceive Protocol Message %@ ", self, ARTProtocolMessageActionToStr(message.action)];

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
        case ARTProtocolMessageAuth:
            [self onAuth];
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

- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    if (self.connection.state == ARTRealtimeClosing) {
        [self transition:ARTRealtimeClosed];
    } else {
        [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
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
                _fallbacks = [[ARTFallback alloc] initWithOptions:[self getClientOptions]];
                (_fallbacks != nil) ? [self reconnectWithFallback] : [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
            }];
            return;
        } else if (_fallbacks && [self reconnectWithFallback]) {
            return;
        }
    }

    if (error.type == ARTRealtimeTransportErrorTypeNoInternet) {
        [self transition:ARTRealtimeDisconnected];
    } else {
        [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
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
