//
//  ARTRealtime.m
//
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
#import "ARTClientOptions+TestConfiguration.h"
#import "ARTTestClientOptions.h"
#import "ARTChannelOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTWebSocketTransport+Private.h"
#import "ARTOSReachability.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTPresenceMap.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTQueuedMessage.h"
#import "ARTPendingMessage.h"
#import "ARTConnection+Private.h"
#import "ARTConnectionDetails.h"
#import "ARTStats.h"
#import "ARTRealtimeTransport.h"
#import "ARTFallback.h"
#import "ARTFallbackHosts.h"
#import "ARTAuthDetails.h"
#import "ARTGCD.h"
#import "ARTEncoder.h"
#import "ARTRealtimeChannels+Private.h"
#import "ARTPush+Private.h"
#import "ARTQueuedDealloc.h"
#import "ARTTypes.h"
#import "ARTChannels.h"
#import "ARTConstants.h"
#import "ARTCrypto.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTErrorChecker.h"
#import "ARTConnectionStateChangeMetadata.h"
#import "ARTChannelStateChangeMetadata.h"
#import "ARTAttachRequestMetadata.h"
#import "ARTRetrySequence.h"
#import "ARTConstantRetryDelayCalculator.h"
#import "ARTTypes+Private.h"
#import "ARTResumeRequestResponse.h"
#import "ARTInternalLog.h"

@interface ARTConnectionStateChange ()

- (void)setRetryIn:(NSTimeInterval)retryIn;

@end

#pragma mark - ARTRealtime implementation

@implementation ARTRealtime {
    ARTQueuedDealloc *_dealloc;
}

- (void)internalAsync:(void (^)(ARTRealtimeInternal * _Nonnull))use {
    dispatch_async(_internal.queue, ^{
        use(self->_internal);
    });
}

- (void)internalSync:(void (^)(ARTRealtimeInternal * _Nonnull))use {
    dispatch_sync(_internal.queue, ^{
        use(self->_internal);
    });
}

- (ARTConnection *)connection {
    return [[ARTConnection alloc] initWithInternal:_internal.connection queuedDealloc:_dealloc];
}

- (ARTRealtimeChannels *)channels {
    return [[ARTRealtimeChannels alloc] initWithInternal:_internal.channels queuedDealloc:_dealloc];
}

- (ARTAuth *)auth {
    return [[ARTAuth alloc] initWithInternal:_internal.auth queuedDealloc:_dealloc];
}

- (ARTPush *)push {
    return [[ARTPush alloc] initWithInternal:_internal.push queuedDealloc:_dealloc];
}

#if TARGET_OS_IOS
- (ARTLocalDevice *)device {
    return _internal.device;
}
#endif

- (NSString *)clientId {
    return _internal.clientId;
}

- (void)initCommon {
    _dealloc = [[ARTQueuedDealloc alloc] init:_internal queue:_internal.queue];
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        _internal = [[ARTRealtimeInternal alloc] initWithOptions:options];
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        _internal = [[ARTRealtimeInternal alloc] initWithKey:key];
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)token {
    self = [super init];
    if (self) {
        _internal = [[ARTRealtimeInternal alloc] initWithToken:token];
        [self initCommon];
    }
    return self;
}

+ (instancetype)createWithOptions:(ARTClientOptions *)options {
    return [[ARTRealtime alloc] initWithOptions:options];
}

+ (instancetype)createWithKey:(NSString *)key {
    return [[ARTRealtime alloc] initWithKey:key];
}

+ (instancetype)createWithToken:(NSString *)tokenId {
    return [[ARTRealtime alloc] initWithToken:tokenId];
}

- (void)time:(ARTDateTimeCallback)cb {
    [_internal time:cb];
}

- (void)ping:(ARTCallback)cb {
    [_internal ping:cb];
}

- (BOOL)stats:(ARTPaginatedStatsCallback)callback {
    return [_internal stats:callback];
}

- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(ARTPaginatedStatsCallback)callback error:(NSError **)errorPtr {
    return [_internal stats:query callback:callback error:errorPtr];
}

- (void)connect {
    [_internal connect];
}

- (void)close {
    [_internal close];
}

@end

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeInternal ()

@property (nonatomic, readonly) id<ARTRetryDelayCalculator> connectRetryDelayCalculator;
@property (nonatomic, nullable) ARTRetrySequence *connectRetrySequence;

@end

NS_ASSUME_NONNULL_END


@implementation ARTRealtimeInternal {
    BOOL _renewingToken;
    BOOL _shouldImmediatelyReconnect;
    ARTEventEmitter<ARTEvent *, ARTErrorInfo *> *_pingEventEmitter;
    NSDate *_connectionLostAt;
    NSDate *_lastActivity;
    Class _transportClass;
    Class _reachabilityClass;
    id<ARTRealtimeTransport> _transport;
    ARTFallback *_fallbacks;
    __weak ARTEventListener *_connectionRetryFromSuspendedListener;
    __weak ARTEventListener *_connectionRetryFromDisconnectedListener;
    __weak ARTEventListener *_connectingTimeoutListener;
    ARTScheduledBlockHandle *_authenitcatingTimeoutWork;
    NSObject<ARTCancellable> *_authTask;
    ARTScheduledBlockHandle *_idleTimer;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRealtime: No options provided");
        
        _rest = [[ARTRestInternal alloc] initWithOptions:options realtime:self];
        _userQueue = _rest.userQueue;
        _queue = _rest.queue;
        _internalEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _connectedEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _pingEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _channels = [[ARTRealtimeChannelsInternal alloc] initWithRealtime:self];
        _transport = nil;
        _transportClass = [ARTWebSocketTransport class];
        _reachabilityClass = [ARTOSReachability class];
        _queuedMessages = [NSMutableArray array];
        _pendingMessages = [NSMutableArray array];
        _pendingMessageStartSerial = 0;
        _pendingAuthorizations = [NSMutableArray array];
        _connection = [[ARTConnectionInternal alloc] initWithRealtime:self];
        _connectionStateTtl = [ARTDefault connectionStateTtl];
        _shouldImmediatelyReconnect = true;
        _connectRetryDelayCalculator = [[ARTConstantRetryDelayCalculator alloc] initWithConstantDelay:options.disconnectedRetryTimeout];
        self.auth.delegate = self;
        
        [self.connection setState:ARTRealtimeInitialized];
        
        ARTLogVerbose(self.logger, @"R:%p initialized with RS:%p", self, _rest);
        
        self.rest.prioritizedHost = nil;
        
        if (options.autoConnect) {
            [self connect];
        }

        if (options.recover) { //RTN16f
            ARTConnectionRecoveryKey *const recoveryKey = [ARTConnectionRecoveryKey fromJsonString:options.recover];
            self.msgSerial = recoveryKey.msgSerial;
            self.connection.latestMessageSerial = self.msgSerial;
            [self recoverChannelsWithRecoveryKey: recoveryKey]; //RTN16j
        } else {
            self.msgSerial = 0;
            self.connection.latestMessageSerial = 0;
        }
    }
    return self;
}

- (void)recoverChannelsWithRecoveryKey:(ARTConnectionRecoveryKey *const)recoveryKey {
    for (NSString *const channelName in recoveryKey.channelSerials) {
        ARTRealtimeChannelInternal *const channel = [_channels get:channelName];
        channel.serial = recoveryKey.channelSerials[channelName];
    }
}

#pragma mark - ARTAuthDelegate

- (void)auth:(ARTAuthInternal *)auth didAuthorize:(ARTTokenDetails *)tokenDetails completion:(void (^)(ARTAuthorizationState, ARTErrorInfo *_Nullable))completion {
    void (^waitForResponse)(void) = ^{
        [self.pendingAuthorizations art_enqueue:^(ARTRealtimeConnectionState state, ARTErrorInfo *_Nullable error){
            switch (state) {
                case ARTRealtimeConnected:
                    completion(ARTAuthorizationSucceeded, nil);
                    break;
                case ARTRealtimeFailed:
                    completion(ARTAuthorizationFailed, error);
                    break;
                case ARTRealtimeSuspended:
                    completion(ARTAuthorizationFailed, [ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been suspended"]);
                    break;
                case ARTRealtimeClosed:
                    completion(ARTAuthorizationFailed, [ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been closed"]);
                    break;
                case ARTRealtimeDisconnected:
                    completion(ARTAuthorizationCancelled, nil);
                    break;
                case ARTRealtimeInitialized:
                case ARTRealtimeConnecting:
                case ARTRealtimeClosing:
                    ARTLogDebug(self.logger, @"RS:%p authorize completion has been ignored because the connection state is unexpected (%@)", self.rest, ARTRealtimeConnectionStateToStr(state));
                    break;
            }
        }];
    };
    
    void (^haltCurrentConnectionAndReconnect)(void) = ^{
        // Halt the current connection and reconnect with the most recent token
        ARTLogDebug(self.logger, @"RS:%p halt current connection and reconnect with %@", self.rest, tokenDetails);
        [self abortAndReleaseTransport:[ARTStatus state:ARTStateOk]];
        [self setTransportWithResumeKey:self->_transport.resumeKey];
        [self->_transport connectWithToken:tokenDetails.token];
        [self cancelAllPendingAuthorizations];
        waitForResponse();
    };
    
    switch (self.connection.state_nosync) {
        case ARTRealtimeConnected: {
            // Update (send AUTH message)
            ARTLogDebug(self.logger, @"RS:%p AUTH message using %@", self.rest, tokenDetails);
            ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
            msg.action = ARTProtocolMessageAuth;
            msg.auth = [[ARTAuthDetails alloc] initWithToken:tokenDetails.token];
            [self send:msg sentCallback:nil ackCallback:nil];
            waitForResponse();
            break;
        }
        case ARTRealtimeConnecting: {
            [_transport.stateEmitter once:[ARTEvent newWithTransportState:ARTRealtimeTransportStateOpened] callback:^(id sender) {
                haltCurrentConnectionAndReconnect();
            }];
            break;
        }
        case ARTRealtimeClosing: {
            // Should ignore because the connection is being closed
            ARTLogDebug(self.logger, @"RS:%p authorize has been cancelled because the connection is closing", self.rest);
            [self cancelAllPendingAuthorizations];
            break;
        }
        default: {
            // Client state is NOT Connecting or Connected, so it should start a new connection
            ARTLogDebug(self.logger, @"RS:%p new connection from successfull authorize %@", self.rest, tokenDetails);
            [self transition:ARTRealtimeConnecting withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
            waitForResponse();
            break;
        }
    }
}

- (void)performPendingAuthorizationWithState:(ARTRealtimeConnectionState)state error:(nullable ARTErrorInfo *)error {
    void (^pendingAuthorization)(ARTRealtimeConnectionState, ARTErrorInfo *_Nullable) = [self.pendingAuthorizations art_dequeue];
    if (!pendingAuthorization) {
        return;
    }
    switch (state) {
        case ARTRealtimeConnected:
            pendingAuthorization(state, nil);
            break;
        case ARTRealtimeFailed:
            pendingAuthorization(state, error);
            break;
        default:
            [self discardPendingAuthorizations];
            pendingAuthorization(state, error);
            break;
    }
}

- (void)cancelAllPendingAuthorizations {
    [self.pendingAuthorizations enumerateObjectsUsingBlock:^(void (^pendingAuthorization)(ARTRealtimeConnectionState, ARTErrorInfo * _Nullable), NSUInteger idx, BOOL * _Nonnull stop) {
        pendingAuthorization(ARTRealtimeDisconnected, nil);
    }];
    [self.pendingAuthorizations removeAllObjects];
}

- (void)discardPendingAuthorizations {
    [self.pendingAuthorizations removeAllObjects];
}

#pragma mark - Realtime

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (instancetype)initWithToken:(NSString *)token {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithToken:token]];
}

- (id<ARTRealtimeTransport>)transport {
    return _transport;
}

- (ARTInternalLog *)getLogger {
    return _rest.logger;
}

- (ARTClientOptions *)getClientOptions {
    return _rest.options;
}

- (NSString *)clientId {
    // Doesn't need synchronization since it's immutable.
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

- (ARTAuthInternal *)auth {
    return self.rest.auth;
}

- (ARTPushInternal *)push {
    return self.rest.push;
}

- (void)dealloc {
    ARTLogVerbose(self.logger, @"R:%p dealloc", self);
    
    self.rest.prioritizedHost = nil;
}

- (void)connect {
    dispatch_sync(_queue, ^{
        [self _connect];
    });
}

- (void)_connect {
    if(self.connection.state_nosync == ARTRealtimeClosing) {
        // New connection
        _transport = nil;
    }
    [self transition:ARTRealtimeConnecting withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
}

- (void)close {
    dispatch_sync(_queue, ^{
        [self _close];
    });
}

- (void)_close {
    [_reachability off];
    [self cancelTimers];
    
    switch (self.connection.state_nosync) {
        case ARTRealtimeInitialized:
        case ARTRealtimeClosing:
        case ARTRealtimeClosed:
        case ARTRealtimeFailed:
            return;
        case ARTRealtimeConnecting: {
            [_internalEventEmitter once:^(ARTConnectionStateChange *change) {
                [self _close];
            }];
            return;
        }
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended:
            [self transition:ARTRealtimeClosed withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
            break;
        case ARTRealtimeConnected:
            [self transition:ARTRealtimeClosing withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
            break;
    }
}

- (void)time:(ARTDateTimeCallback)cb {
    [self.rest time:cb];
}

- (void)ping:(ARTCallback) cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    
    dispatch_async(_queue, ^{
        switch (self.connection.state_nosync) {
            case ARTRealtimeInitialized:
            case ARTRealtimeSuspended:
            case ARTRealtimeClosing:
            case ARTRealtimeClosed:
            case ARTRealtimeFailed:
                cb([ARTErrorInfo createWithCode:0 status:ARTStateConnectionFailed message:[NSString stringWithFormat:@"Can't ping a %@ connection", ARTRealtimeConnectionStateToStr(self.connection.state_nosync)]]);
                return;
            case ARTRealtimeConnecting:
            case ARTRealtimeDisconnected:
            case ARTRealtimeConnected:
                if (![self shouldSendEvents]) {
                    [self->_connectedEventEmitter once:^(NSNull *n) {
                        [self ping:cb];
                    }];
                    return;
                }
                [[[self->_pingEventEmitter once:cb] setTimer:self.options.testOptions.realtimeRequestTimeout onTimeout:^{
                    ARTLogVerbose(self.logger, @"R:%p ping timed out", self);
                    cb([ARTErrorInfo createWithCode:ARTErrorConnectionTimedOut status:ARTStateConnectionFailed message:@"timed out"]);
                }] startTimer];
                [self.transport sendPing];
        }
    });
}

- (BOOL)stats:(ARTPaginatedStatsCallback)callback {
    return [self stats:[[ARTStatsQuery alloc] init] callback:callback error:nil];
}

- (BOOL)stats:(ARTStatsQuery *)query callback:(ARTPaginatedStatsCallback)callback error:(NSError **)errorPtr {
    return [self.rest stats:query callback:callback error:errorPtr];
}

- (void)transition:(ARTRealtimeConnectionState)state withMetadata:(ARTConnectionStateChangeMetadata *)metadata {
    ARTLogVerbose(self.logger, @"R:%p realtime state transitions to %tu - %@%@", self, state, ARTRealtimeConnectionStateToStr(state), metadata.retryAttempt ? [NSString stringWithFormat: @" (result of %@)", metadata.retryAttempt.id] : @"");
    
    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:state previous:self.connection.state_nosync event:(ARTRealtimeConnectionEvent)state reason:metadata.errorInfo retryIn:0 retryAttempt:metadata.retryAttempt];

    [self.connection setState:state];
    [self.connection setErrorReason:metadata.errorInfo];
    
    ARTEventListener *stateChangeEventListener = [self transitionSideEffects:stateChange];
    
    [_internalEventEmitter emit:[ARTEvent newWithConnectionEvent:(ARTRealtimeConnectionEvent)state] with:stateChange];
    
    // stateChangeEventListener may be nil if we're in a failed state
    if (stateChangeEventListener != nil) {
        [stateChangeEventListener startTimer];
    }
}

- (void)transitionToDisconnectedOrSuspendedWithMetadata:(ARTConnectionStateChangeMetadata *)metadata {
    if ([self isSuspendMode]) {
        [self transition:ARTRealtimeSuspended withMetadata:metadata];
    }
    else {
        [self transition:ARTRealtimeDisconnected withMetadata:metadata];
    }
}

- (void)updateWithErrorInfo:(nullable ARTErrorInfo *)errorInfo {
    ARTLogDebug(self.logger, @"R:%p update requested", self);
    
    if (self.connection.state_nosync != ARTRealtimeConnected) {
        ARTLogWarn(self.logger, @"R:%p update ignored because connection is not connected", self);
        return;
    }
    
    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:self.connection.state_nosync previous:self.connection.state_nosync event:ARTRealtimeConnectionEventUpdate reason:errorInfo retryIn:0];
    
    ARTEventListener *stateChangeEventListener = [self transitionSideEffects:stateChange];
    
    // stateChangeEventListener may be nil if we're in a failed state
    if (stateChangeEventListener != nil) {
        [stateChangeEventListener startTimer];
    }
}

- (ARTEventListener *)transitionSideEffects:(ARTConnectionStateChange *)stateChange {
    ARTChannelStateChangeMetadata *channelStateChangeMetadata = nil;
    ARTEventListener *stateChangeEventListener = nil;
    
    ARTLogDebug(self.logger, @"RT:%p realtime is transitioning from %tu - %@ to %tu - %@", self, stateChange.previous, ARTRealtimeConnectionStateToStr(stateChange.previous), stateChange.current, ARTRealtimeConnectionStateToStr(stateChange.current));
    
    switch (stateChange.current) {
        case ARTRealtimeConnecting: {
            
            // RTN15g We want to enforce a new connection also when there hasn't been activity for longer than (idle interval + TTL)
            if (stateChange.previous == ARTRealtimeDisconnected || stateChange.previous == ARTRealtimeSuspended) {
                NSTimeInterval intervalSinceLast = [[NSDate date] timeIntervalSinceDate:_lastActivity];
                if (intervalSinceLast > (_maxIdleInterval + _connectionStateTtl)) {
                    [self.connection setId:nil];
                    [self.connection setKey:nil];
                }
            }
            
            stateChangeEventListener = [self unlessStateChangesBefore:self.options.testOptions.realtimeRequestTimeout do:^{
                [self onConnectionTimeOut];
            }];
            _connectingTimeoutListener = stateChangeEventListener;
            
            if (!_reachability) {
                _reachability = [[_reachabilityClass alloc] initWithLogger:self.logger queue:_queue];
            }
            
            if (!_transport) {
                NSString *resumeKey = nil;
                if (stateChange.previous == ARTRealtimeFailed ||
                    stateChange.previous == ARTRealtimeDisconnected ||
                    stateChange.previous == ARTRealtimeSuspended) {
                    resumeKey = self.connection.key_nosync;
                }
                [self setTransportWithResumeKey:resumeKey];
                [self transportConnectForcingNewToken:_renewingToken newConnection:true];
            }
            
            if (self.connection.state_nosync != ARTRealtimeFailed &&
                self.connection.state_nosync != ARTRealtimeClosed &&
                self.connection.state_nosync != ARTRealtimeDisconnected) {
                [_reachability listenForHost:[_transport host] callback:^(BOOL reachable) {
                    // The ref cycle creating by taking self here is resolved on close
                    // when [_reachability off] is called.
                    if (reachable) {
                        switch (self.connection.state_nosync) {
                            case ARTRealtimeDisconnected:
                            case ARTRealtimeSuspended:
                                [self transition:ARTRealtimeConnecting withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
                            default:
                                break;
                        }
                    } else {
                        switch (self.connection.state_nosync) {
                            case ARTRealtimeConnecting:
                            case ARTRealtimeConnected: {
                                ARTErrorInfo *unreachable = [ARTErrorInfo createWithCode:-1003 message:@"unreachable host"];
                                ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:unreachable];
                                [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
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
            [self stopIdleTimer];
            [_reachability off];
            stateChangeEventListener = [self unlessStateChangesBefore:self.options.testOptions.realtimeRequestTimeout do:^{
                [self transition:ARTRealtimeClosed withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
            }];
            [self.transport sendClose];
            break;
        }
        case ARTRealtimeClosed:
            [self stopIdleTimer];
            [_reachability off];
            [self closeAndReleaseTransport];
            _connection.key = nil;
            _connection.id = nil;
            _transport = nil;
            self.rest.prioritizedHost = nil;
            [self.auth cancelAuthorization:nil];
            [self failPendingMessages:[ARTStatus state:ARTStateError info:[ARTErrorInfo createWithCode:ARTErrorConnectionClosed message:@"connection broken before receiving publishing acknowledgment"]]];
            break;
        case ARTRealtimeFailed: {
            ARTStatus *const status = [ARTStatus state:ARTStateConnectionFailed info:stateChange.reason];
            channelStateChangeMetadata = [[ARTChannelStateChangeMetadata alloc] initWithState:status.state
                                                                                    errorInfo:status.errorInfo];
            [self abortAndReleaseTransport:status];
            self.rest.prioritizedHost = nil;
            [self.auth cancelAuthorization:stateChange.reason];
            [self failPendingMessages:[ARTStatus state:ARTStateError info:[ARTErrorInfo createWithCode:ARTErrorConnectionFailed message:@"connection broken before receiving publishing acknowledgment"]]];
            break;
        }
        case ARTRealtimeDisconnected: {
            [self closeAndReleaseTransport];
            if (!_connectionLostAt) {
                _connectionLostAt = [NSDate date];
                ARTLogVerbose(self.logger, @"RT:%p set connection lost time; expected suspension at %@ (ttl=%f)", self, [self suspensionTime], self.connectionStateTtl);
            }

            NSTimeInterval retryDelay;
            ARTRetryAttempt *retryAttempt;

            // RTN15a - retry immediately if client was connected
            if (stateChange.previous == ARTRealtimeConnected && _shouldImmediatelyReconnect) {
                retryDelay = 0.1;
            } else {
                // Note: we currently reset the retry sequence every time we wish to perform a retry (defeating the point of using it in the first place, but it's OK since the delays are all constant). As part of implementing #1431 we will reuse any existing retry sequence, resetting it only in response to certain state changes.
                self.connectRetrySequence = [[ARTRetrySequence alloc] initWithDelayCalculator:self.connectRetryDelayCalculator];
                ARTLogVerbose(self.logger, @"RT:%p Created connect retry sequence %@", self, self.connectRetrySequence);

                retryAttempt = [self.connectRetrySequence addRetryAttempt];
                ARTLogVerbose(self.logger, @"RT:%p Adding connect retry attempt to %@ gave %@", self, self.connectRetrySequence.id, retryAttempt);

                retryDelay = retryAttempt.delay;
            }
            [stateChange setRetryIn:retryDelay];
            stateChangeEventListener = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                self->_connectionRetryFromDisconnectedListener = nil;
                ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:nil
                                                                                                                  retryAttempt:retryAttempt];
                [self transition:ARTRealtimeConnecting withMetadata:metadata];
            }];
            _connectionRetryFromDisconnectedListener = stateChangeEventListener;
            break;
        }
        case ARTRealtimeSuspended: {
            [_connectionRetryFromDisconnectedListener stopTimer];
            _connectionRetryFromDisconnectedListener = nil;
            [self.auth cancelAuthorization:nil];
            [self closeAndReleaseTransport];
            [stateChange setRetryIn:self.options.suspendedRetryTimeout];
            stateChangeEventListener = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                self->_connectionRetryFromSuspendedListener = nil;
                [self transition:ARTRealtimeConnecting withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
            }];
            _connectionRetryFromSuspendedListener = stateChangeEventListener;
            break;
        }
        case ARTRealtimeConnected: {
            _fallbacks = nil;
            _connectionLostAt = nil;
            // resend regardless of resumption result
            [self resendPendingMessages];

            [_connectedEventEmitter emit:nil with:nil];
            break;
        }
        case ARTRealtimeInitialized:
            break;
    }
    
    // If there's a channels.release() going on waiting on this channel
    // to detach, doing those operations on it here would fire its event listener and
    // immediately remove the channel from the channels dictionary, thus
    // invalidating the iterator and causing a crashing.
    //
    // So copy the channels and operate on them later, when we're done using the iterator.
    NSMutableArray<ARTRealtimeChannelInternal *> * const channels = [[NSMutableArray alloc] init];
    for (ARTRealtimeChannelInternal *channel in self.channels.nosyncIterable) {
        [channels addObject:channel];
    }
    
    if ([self shouldSendEvents]) {
        [self sendQueuedMessages];
        
        // Channels
        for (ARTRealtimeChannelInternal *channel in channels) {
            if (stateChange.previous == ARTRealtimeInitialized ||
                stateChange.previous == ARTRealtimeConnecting ||
                stateChange.previous == ARTRealtimeDisconnected) {
                // RTL4i
                [channel _attach:nil];
            }
        }
    } else if (![self shouldQueueEvents]) {
        if (!channelStateChangeMetadata) {
            if (stateChange.reason) {
                channelStateChangeMetadata = [[ARTChannelStateChangeMetadata alloc] initWithState:ARTStateError
                                                                                        errorInfo:stateChange.reason];
            } else {
                channelStateChangeMetadata = [[ARTChannelStateChangeMetadata alloc] initWithState:ARTStateError];
            }
        }

        ARTStatus *const channelStatus = [ARTStatus state:channelStateChangeMetadata.state info:channelStateChangeMetadata.errorInfo];
        [self failQueuedMessages:channelStatus];
        
        // Channels
        for (ARTRealtimeChannelInternal *channel in channels) {
            switch (stateChange.current) {
                case ARTRealtimeClosing:
                    //do nothing. Closed state is coming.
                    break;
                case ARTRealtimeClosed: {
                    ARTChannelStateChangeMetadata *const metadata = [[ARTChannelStateChangeMetadata alloc] initWithState:ARTStateOk];
                    [channel detachChannel:metadata];
                    break;
                }
                case ARTRealtimeSuspended: {
                    [channel setSuspended:channelStateChangeMetadata];
                    break;
                }
                case ARTRealtimeFailed: {
                    [channel setFailed:channelStateChangeMetadata];
                    break;
                }
                default:
                    break;
            }
        }
    }
    
    [self.connection emit:stateChange.event with:stateChange];
    
    [self performPendingAuthorizationWithState:stateChange.current error:stateChange.reason];
    
    return stateChangeEventListener;
}

- (void)abortAndReleaseTransport:(ARTStatus *)status {
    [_transport abort:status];
    _transport = nil;
}

- (void)closeAndReleaseTransport {
    if (_transport) {
        [_transport close];
        _transport = nil;
    }
}

- (void)resetTransportWithResumeKey:(NSString *const)resumeKey {
    [self closeAndReleaseTransport];
    [self setTransportWithResumeKey:resumeKey];
}

- (void)setTransportWithResumeKey:(NSString *const)resumeKey {
    _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:resumeKey];
    _transport.delegate = self;
}

- (ARTEventListener *)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)(void))callback __attribute__((warn_unused_result)) {
    return [[_internalEventEmitter once:^(ARTConnectionStateChange *change) {
        // Any state change cancels the timeout.
    }] setTimer:deadline onTimeout:^{
        if (callback) {
            callback();
        }
    }];
}

- (void)onHeartbeat {
    ARTLogVerbose(self.logger, @"R:%p heartbeat received", self);
    if(self.connection.state_nosync != ARTRealtimeConnected) {
        NSString *msg = [NSString stringWithFormat:@"received a ping when in state %@", ARTRealtimeConnectionStateToStr(self.connection.state_nosync)];
        ARTLogWarn(self.logger, @"R:%p %@", self, msg);
    }
    [_pingEventEmitter emit:nil with:nil];
}

- (void)resetSerials {
    self.msgSerial = 0;
    self.connection.latestMessageSerial = 0;
    self.pendingMessageStartSerial = 0;
}

- (void)onConnected:(ARTProtocolMessage *)message {
    _renewingToken = false;

    switch (self.connection.state_nosync) {
        case ARTRealtimeConnecting: {
            const BOOL isResuming = self.connection.id_nosync != nil || message.error != nil || _connectionLostAt != nil;
            if (isResuming) {
                ARTResumeRequestResponse *response = [[ARTResumeRequestResponse alloc] initWithCurrentConnectionID:_connection.id_nosync protocolMessage:message errorChecker:[[ARTDefaultErrorChecker alloc] init]];
                switch (response.type) {
                    case ARTResumeRequestResponseTypeValid:
                        ARTLogDebug(self.logger, @"RT:%p connection \"%@\" has reconnected and resumed successfully", self, message.connectionId);
                        break;
                    case ARTResumeRequestResponseTypeInvalid:
                        ARTLogWarn(self.logger, @"RT:%p connection \"%@\" has resumed with non-fatal error \"%@\"", self, message.connectionId, message.error.message);
                        [self resetSerials];
                        break;
                    case ARTResumeRequestResponseTypeFatalError:
                    case ARTResumeRequestResponseTypeTokenError:
                    case ARTResumeRequestResponseTypeUnknown:
                        [self resetSerials];
                }
                [self reattachChannelsWithReason:message.error];
            }
            [self.connection setId:message.connectionId];
            [self.connection setKey:message.connectionKey];
            [self.connection setMaxMessageSize:message.connectionDetails.maxMessageSize];
            
            if (message.connectionDetails && message.connectionDetails.connectionStateTtl) {
                _connectionStateTtl = message.connectionDetails.connectionStateTtl;
            }
            if (message.connectionDetails && message.connectionDetails.maxIdleInterval) {
                _maxIdleInterval = message.connectionDetails.maxIdleInterval;
                _lastActivity = [NSDate date];
                [self setIdleTimer];
            }
            ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:message.error];
            [self transition:ARTRealtimeConnected withMetadata:metadata];
            break;
        }
        case ARTRealtimeConnected: {
            // Renewing token.
            [self updateWithErrorInfo:message.error];
        }
        default:
            break;
    }
}

- (void)reattachChannelsWithReason:(ARTErrorInfo *)reason {
    for (ARTRealtimeChannelInternal *const channel in self.channels.nosyncIterable) {
        ARTAttachRequestMetadata *const metadata = [[ARTAttachRequestMetadata alloc] initWithReason:reason];
        [channel reattachWithMetadata:metadata];
    }
}

- (void)onDisconnected {
    [self onDisconnected:nil];
}

- (void)onDisconnected:(ARTProtocolMessage *)message {
    ARTLogInfo(self.logger, @"R:%p Realtime disconnected", self);
    ARTErrorInfo * const error = message.error;
    
    if (
        [self isTokenError:error]
        && !_renewingToken // If already reconnecting, give up.
        ) {
        if (![self.auth tokenIsRenewable]) {
            ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:error];
            [self transition:ARTRealtimeFailed withMetadata:metadata];
            return;
        }

        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:error];
        [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
        [self.connection setErrorReason:nil];
        _renewingToken = true;
        [self transition:ARTRealtimeConnecting withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
        return;
    }

    ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:error];
    [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
}

- (void)onClosed {
    ARTLogInfo(self.logger, @"R:%p Realtime closed", self);
    switch (self.connection.state_nosync) {
        case ARTRealtimeClosed:
            break;
        case ARTRealtimeClosing:
            [self.connection setId:nil];
            [self transition:ARTRealtimeClosed withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
            break;
        default:
            NSAssert(false, @"Invalid Realtime state transitioning to Closed: expected Closing or Closed, has %@", ARTRealtimeConnectionStateToStr(self.connection.state_nosync));
            break;
    }
}

- (void)onAuth {
    ARTLogInfo(self.logger, @"R:%p server has requested an authorize", self);
    switch (self.connection.state_nosync) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
            [self transportConnectForcingNewToken:true newConnection:false];
            break;
        default:
            ARTLogError(self.logger, @"Invalid Realtime state: expected Connecting or Connected, has %@", ARTRealtimeConnectionStateToStr(self.connection.state_nosync));
            break;
    }
}

- (void)onError:(ARTProtocolMessage *)message {
    if (message.channel) {
        [self onChannelMessage:message];
    } else {
        ARTErrorInfo *error = message.error;
        
        if ([self isTokenError:error] && [self.auth tokenIsRenewable]) {
            if (_renewingToken) {
                // Already retrying; give up.
                [self.connection setErrorReason:error];
                ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:error];
                [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
                return;
            }
            [self transportReconnectWithRenewedToken];
            return;
        }
        
        [self.connection setId:nil];
        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:message.error];
        [self transition:ARTRealtimeFailed withMetadata:metadata];
    }
}

- (void)cancelTimers {
    ARTLogVerbose(self.logger, @"R:%p cancel timers", self);
    [_connectionRetryFromSuspendedListener stopTimer];
    _connectionRetryFromSuspendedListener = nil;
    [_connectionRetryFromDisconnectedListener stopTimer];
    _connectionRetryFromDisconnectedListener = nil;
    // Cancel connecting scheduled work
    [_connectingTimeoutListener stopTimer];
    _connectingTimeoutListener = nil;
    // Cancel auth scheduled work
    artDispatchCancel(_authenitcatingTimeoutWork);
    _authenitcatingTimeoutWork = nil;
    [_authTask cancel];
    _authTask = nil;
    // Idle timer
    [self stopIdleTimer];
    // Ping timer
    [_pingEventEmitter off];
}

- (void)onConnectionTimeOut {
    ARTLogVerbose(self.logger, @"R:%p connection timed out", self);
    // Cancel connecting scheduled work
    [_connectingTimeoutListener stopTimer];
    _connectingTimeoutListener = nil;
    // Cancel auth scheduled work
    artDispatchCancel(_authenitcatingTimeoutWork);
    _authenitcatingTimeoutWork = nil;
    [_authTask cancel];
    _authTask = nil;
    
    ARTErrorInfo *error;
    if (self.auth.authorizing_nosync && (self.options.authUrl || self.options.authCallback)) {
        error = [ARTErrorInfo createWithCode:ARTErrorAuthConfiguredProviderFailure status:ARTStateConnectionFailed message:@"timed out"];
    }
    else {
        error = [ARTErrorInfo createWithCode:ARTErrorConnectionTimedOut status:ARTStateConnectionFailed message:@"timed out"];
    }
    switch (self.connection.state_nosync) {
        case ARTRealtimeConnected: {
            ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:error];
            [self transition:ARTRealtimeConnected withMetadata:metadata];
            break;
        }
        default: {
            ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:error];
            [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
            break;
        }
    }
}

- (BOOL)isTokenError:(nullable ARTErrorInfo *)error {
    return error != nil && [[[ARTDefaultErrorChecker alloc] init] isTokenError:error];
}

- (void)transportReconnectWithHost:(NSString *)host {
    [self resetTransportWithResumeKey:_transport.resumeKey];
    [self.transport setHost:host];
    [self transportConnectForcingNewToken:false newConnection:true];
}

- (void)transportReconnectWithRenewedToken {
    _renewingToken = true;
    [self resetTransportWithResumeKey:_transport.resumeKey];
    [_connectingTimeoutListener restartTimer];
    [self transportConnectForcingNewToken:true newConnection:true];
}

- (void)transportConnectForcingNewToken:(BOOL)forceNewToken newConnection:(BOOL)newConnection {
    ARTClientOptions *options = [self.options copy];
    if ([options isBasicAuth]) {
        // Basic
        [self.transport connectWithKey:options.key];
    }
    else {
        // Token
        ARTLogDebug(self.logger, @"R:%p connecting with token auth; authorising (timeout of %f)", self, self.options.testOptions.realtimeRequestTimeout);
        
        if (!forceNewToken && [self.auth tokenRemainsValid]) {
            // Reuse token
            ARTLogDebug(self.logger, @"R:%p reusing token for auth", self);
            [self.transport connectWithToken:self.auth.tokenDetails.token];
        }
        else {
            // New Token
            [self.auth setTokenDetails:nil];
            
            // Schedule timeout handler
            _authenitcatingTimeoutWork = artDispatchScheduled(self.options.testOptions.realtimeRequestTimeout, _rest.queue, ^{
                [self onConnectionTimeOut];
            });
            
            id<ARTAuthDelegate> delegate = self.auth.delegate;
            if (newConnection) {
                // Deactivate use of `ARTAuthDelegate`: `authorize` should complete without waiting for a CONNECTED state.
                self.auth.delegate = nil;
            }
            @try {
                _authTask = [self.auth _authorize:nil options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
                    // Cancel scheduled work
                    artDispatchCancel(self->_authenitcatingTimeoutWork);
                    self->_authenitcatingTimeoutWork = nil;
                    self->_authTask = nil;
                    
                    // It's still valid?
                    switch (self.connection.state_nosync) {
                        case ARTRealtimeClosing:
                        case ARTRealtimeClosed:
                            return;
                        default:
                            break;
                    }
                    
                    ARTLogDebug(self.logger, @"R:%p authorized: %@ error: %@", self, tokenDetails, error);
                    if (error) {
                        [self handleTokenAuthError:error];
                        return;
                    }
                    
                    if (forceNewToken && newConnection) {
                        [self resetTransportWithResumeKey:self->_transport.resumeKey];
                    }
                    if (newConnection) {
                        [self.transport connectWithToken:tokenDetails.token];
                    }
                }];
            }
            @finally {
                self.auth.delegate = delegate;
            }
        }
    }
}

- (void)handleTokenAuthError:(NSError *)error {
    ARTLogError(self.logger, @"R:%p token auth failed with %@", self, error.description);
    if (error.code == ARTErrorIncompatibleCredentials) {
        // RSA15c
        ARTErrorInfo *const errorInfo = [ARTErrorInfo createFromNSError:error];
        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
        [self transition:ARTRealtimeFailed withMetadata:metadata];
    }
    else if (self.options.authUrl || self.options.authCallback) {
        if (error.code == ARTErrorForbidden /* RSA4d */) {
            ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTErrorAuthConfiguredProviderFailure
                                                            status:error.artStatusCode
                                                           message:error.description];
            ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
            [self transition:ARTRealtimeFailed withMetadata:metadata];
        } else {
            ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTErrorAuthConfiguredProviderFailure status:ARTStateConnectionFailed message:error.description];
            switch (self.connection.state_nosync) {
                case ARTRealtimeConnected:
                    // RSA4c3
                    [self.connection setErrorReason:errorInfo];
                    break;
                default: {
                    // RSA4c
                    ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
                    [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
                    break;
                }
            }
        }
    }
    else {
        // RSA4b
        ARTErrorInfo *const errorInfo = [ARTErrorInfo createFromNSError:error];
        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
        [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
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
    ARTRealtimeChannelInternal *channel = [self.channels _getChannel:message.channel options:nil addPrefix:false];
    [channel onChannelMessage:message];
}

- (void)onSuspended {
    [self transition:ARTRealtimeSuspended withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
}

- (NSDate *)suspensionTime {
    return [_connectionLostAt dateByAddingTimeInterval:self.connectionStateTtl];
}

- (BOOL)isSuspendMode {
    NSDate *currentTime = [NSDate date];
    return [currentTime timeIntervalSinceDate:[self suspensionTime]] > 0;
}

- (BOOL)shouldSendEvents {
    switch (self.connection.state_nosync) {
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
    switch (self.connection.state_nosync) {
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

- (BOOL)isActive {
    return [self shouldQueueEvents] || [self shouldSendEvents];
}

- (void)sendImpl:(ARTProtocolMessage *)pm sentCallback:(ARTCallback)sentCallback ackCallback:(ARTStatusCallback)ackCallback {
    if (pm.ackRequired) {
        pm.msgSerial = [NSNumber numberWithLongLong:self.msgSerial];
    }
    
    for (ARTMessage *msg in pm.messages) {
        msg.connectionId = self.connection.id_nosync;
    }
    
    NSError *error = nil;
    NSData *data = [self.rest.defaultEncoder encodeProtocolMessage:pm error:&error];
    
    if (error) {
        ARTErrorInfo *e = [ARTErrorInfo createFromNSError:error];
        if (sentCallback) sentCallback(e);
        if (ackCallback) ackCallback([ARTStatus state:ARTStateError info:e]);
        return;
    }
    else if (!data) {
        ARTErrorInfo *e = [ARTErrorInfo createWithCode:ARTClientCodeErrorInvalidType message:@"Encoder as failed without error."];
        if (sentCallback) sentCallback(e);
        if (ackCallback) ackCallback([ARTStatus state:ARTStateError info:e]);
        return;
    }
    
    if (pm.ackRequired) {
        self.msgSerial++;
        self.connection.latestMessageSerial = self.msgSerial;
        ARTPendingMessage *pendingMessage = [[ARTPendingMessage alloc] initWithProtocolMessage:pm ackCallback:ackCallback];
        [self.pendingMessages addObject:pendingMessage];
    }
    
    ARTLogDebug(self.logger, @"RT:%p sending action %tu - %@", self, pm.action, ARTProtocolMessageActionToStr(pm.action));
    if ([self.transport send:data withSource:pm]) {
        if (sentCallback) sentCallback(nil);
        // `ackCallback()` is called with ACK/NACK action
    }
}

- (void)send:(ARTProtocolMessage *)msg sentCallback:(ARTCallback)sentCallback ackCallback:(ARTStatusCallback)ackCallback {
    if ([self shouldSendEvents]) {
        [self sendImpl:msg sentCallback:sentCallback ackCallback:ackCallback];
    }
    else if ([self shouldQueueEvents]) {
        ARTQueuedMessage *lastQueuedMessage = self.queuedMessages.lastObject; //RTL6d5
        BOOL merged = [lastQueuedMessage mergeFrom:msg sentCallback:nil ackCallback:ackCallback];
        if (!merged) {
            ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:msg sentCallback:nil ackCallback:ackCallback];
            [self.queuedMessages addObject:qm];
            ARTLogDebug(self.logger, @"RT:%p (channel: %@) protocol message with action '%lu - %@' has been queued (%@)", self, msg.channel, (unsigned long)msg.action, ARTProtocolMessageActionToStr(msg.action), msg.messages);
        }
        else {
            ARTLogVerbose(self.logger, @"RT:%p (channel: %@) message %@ has been bundled to %@", self, msg.channel, msg, lastQueuedMessage.msg);
        }
    }
    else if (ackCallback) {
        ARTErrorInfo *error = self.connection.errorReason_nosync;
        if (!error) error = [ARTErrorInfo createWithCode:ARTErrorChannelOperationFailed status:400 message:[NSString stringWithFormat:@"not possile to send message (state is %@)", ARTRealtimeConnectionStateToStr(self.connection.state_nosync)]];
        ackCallback([ARTStatus state:ARTStateError info:error]);
    }
}

- (void)resendPendingMessages {
    NSArray<ARTPendingMessage *> *pms = self.pendingMessages;
    if (pms.count > 0) {
        ARTLogDebug(self.logger, @"RT:%p resending messages waiting for acknowledgment", self);
    }
    self.pendingMessages = [NSMutableArray array];
    for (ARTPendingMessage *pendingMessage in pms) {
        [self send:pendingMessage.msg sentCallback:nil ackCallback:^(ARTStatus *status) {
            pendingMessage.ackCallback(status);
        }];
    }
}

- (void)failPendingMessages:(ARTStatus *)status {
    NSArray<ARTPendingMessage *> *pms = self.pendingMessages;
    self.pendingMessages = [NSMutableArray array];
    for (ARTPendingMessage *pendingMessage in pms) {
        pendingMessage.ackCallback(status);
    }
}

- (void)sendQueuedMessages {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    
    for (ARTQueuedMessage *message in qms) {
        [self sendImpl:message.msg sentCallback:message.sentCallback ackCallback:message.ackCallback];
    }
}

- (void)failQueuedMessages:(ARTStatus *)status {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *message in qms) {
        message.sentCallback(status.errorInfo);
        message.ackCallback(status);
    }
}

- (void)ack:(ARTProtocolMessage *)message {
    int64_t serial = [message.msgSerial longLongValue];
    int count = message.count;
    NSArray *nackMessages = nil;
    NSArray *ackMessages = nil;
    ARTLogVerbose(self.logger, @"R:%p ACK: msgSerial=%lld, count=%d", self, serial, count);
    ARTLogVerbose(self.logger, @"R:%p ACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count);
    
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
        NSRange nackRange;
        if (nCount > self.pendingMessages.count) {
            NSString *message = [NSString stringWithFormat:@"R:%p ACK: receiving a serial greater than expected", self];
            ARTLogError(self.logger, @"%@", message);
            // Process all the available pending messages as nack
            nackRange = NSMakeRange(0, self.pendingMessages.count);
        }
        else {
            nackRange = NSMakeRange(0, nCount);
        }
        nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
        [self.pendingMessages removeObjectsInRange:nackRange];
        self.pendingMessageStartSerial = serial;
    }
    
    if (serial == self.pendingMessageStartSerial) {
        NSRange ackRange;
        if (count > self.pendingMessages.count) {
            ARTLogError(self.logger, @"R:%p ACK: count response is greater than the total of pending messages", self);
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
    
    for (ARTPendingMessage *msg in nackMessages) {
        msg.ackCallback([ARTStatus state:ARTStateError info:message.error]);
    }
    
    for (ARTPendingMessage *msg in ackMessages) {
        msg.ackCallback([ARTStatus state:ARTStateOk]);
    }
    
    ARTLogVerbose(self.logger, @"R:%p ACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count);
}

- (void)nack:(ARTProtocolMessage *)message {
    int64_t serial = [message.msgSerial longLongValue];
    int count = message.count;
    ARTLogVerbose(self.logger, @"R:%p NACK: msgSerial=%lld, count=%d", self, serial, count);
    ARTLogVerbose(self.logger, @"R:%p NACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count);
    
    if (serial != self.pendingMessageStartSerial) {
        // This is an error condition and it shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
    }
    
    NSRange nackRange;
    if (count > self.pendingMessages.count) {
        ARTLogError(self.logger, @"R:%p NACK: count response is greater than the total of pending messages", self);
        // Process all the available pending messages
        nackRange = NSMakeRange(0, self.pendingMessages.count);
    }
    else {
        nackRange = NSMakeRange(0, count);
    }
    
    NSArray *nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
    [self.pendingMessages removeObjectsInRange:nackRange];
    self.pendingMessageStartSerial += count;
    
    for (ARTPendingMessage *msg in nackMessages) {
        msg.ackCallback([ARTStatus state:ARTStateError info:message.error]);
    }
    
    ARTLogVerbose(self.logger, @"R:%p NACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count);
}

- (BOOL)reconnectWithFallback {
    NSString *host = [_fallbacks popFallbackHost];
    if (host != nil) {
        [self.rest internetIsUp:^void(BOOL isUp) {
            if (!isUp) {
                ARTErrorInfo *const errorInfo = [ARTErrorInfo createWithCode:0 message:@"no Internet connection"];
                ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
                [self transition:ARTRealtimeDisconnected withMetadata:metadata];
                return;
            }
            
            ARTLogDebug(self.logger, @"R:%p host is down; retrying realtime connection at %@", self, host);
            self.rest.prioritizedHost = host;
            [self transportReconnectWithHost:host];
        }];
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

- (void)onActivity {
    ARTLogVerbose(self.logger, @"R:%p activity", self);
    _lastActivity = [NSDate date];
    [self setIdleTimer];
}

- (void)setIdleTimer {
    if (self.maxIdleInterval <= 0) {
        ARTLogVerbose(self.logger, @"R:%p set idle timer had been ignored", self);
        return;
    }
    artDispatchCancel(_idleTimer);
    
    _idleTimer = artDispatchScheduled(self.options.testOptions.realtimeRequestTimeout + self.maxIdleInterval, _rest.queue, ^{
        ARTLogError(self.logger, @"R:%p No activity seen from realtime in %f seconds; assuming connection has dropped", self, [[NSDate date] timeIntervalSinceDate:self->_lastActivity]);
        
        ARTErrorInfo *idleTimerExpired = [ARTErrorInfo createWithCode:ARTErrorDisconnected status:408 message:@"Idle timer expired"];
        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:idleTimerExpired];
        [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
    });
}

- (void)stopIdleTimer {
    artDispatchCancel(_idleTimer);
    _idleTimer = nil;
}

- (void)setTransportClass:(Class)transportClass {
    _transportClass = transportClass;
}

- (void)setReachabilityClass:(Class)reachabilityClass {
    _reachabilityClass = reachabilityClass;
}

#pragma mark - ARTRealtimeTransportDelegate implementation

- (void)realtimeTransport:(id)transport didReceiveMessage:(ARTProtocolMessage *)message {
    [self onActivity];
    
    if (!message) {
        // Invalid data
        return;
    }
    
    if (transport != self.transport) {
        // Old connection
        return;
    }
    
    if (self.connection.state_nosync == ARTRealtimeDisconnected) {
        // Already disconnected
        return;
    }
    
    ARTLogVerbose(self.logger, @"R:%p did receive Protocol Message %@ (connection state is %@)", self, ARTProtocolMessageActionToStr(message.action), ARTRealtimeConnectionStateToStr(self.connection.state_nosync));
    
    if (message.error) {
        ARTLogVerbose(self.logger, @"R:%p Protocol Message with error %@", self, message.error);
    }
    
    NSAssert(transport == self.transport, @"Unexpected transport");

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

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }
    
    if (self.connection.state_nosync == ARTRealtimeClosing) {
        // Close succeeded. Nothing more to do.
        [self transition:ARTRealtimeClosed withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
    } else if (self.connection.state_nosync != ARTRealtimeClosed && self.connection.state_nosync != ARTRealtimeFailed) {
        // Unexpected closure; recover.
        [self transitionToDisconnectedOrSuspendedWithMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
    }
}

- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error {
    if (transport != self.transport) {
        // Old connection
        return;
    }
    
    if (self.connection.state_nosync == ARTRealtimeClosing) {
        [self transition:ARTRealtimeClosed withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
    } else {
        ARTErrorInfo *const errorInfo = [ARTErrorInfo createFromNSError:error.error];
        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
        [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
    }
}

- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)transportError {
    if (transport != self.transport) {
        // Old connection
        return;
    }
    
    ARTLogDebug(self.logger, @"R:%p realtime transport failed: %@", self, transportError);
    
    if ([self shouldRetryWithFallback:transportError]) {
        ARTLogDebug(self.logger, @"R:%p host is down; can retry with fallback host", self);
        if (!_fallbacks && [transportError.url.host isEqualToString:[ARTDefault realtimeHost]]) {
            NSArray *hosts = [ARTFallbackHosts hostsFromOptions:[self getClientOptions]];
            self->_fallbacks = [[ARTFallback alloc] initWithFallbackHosts:hosts];
            if (self->_fallbacks != nil) {
                [self reconnectWithFallback];
            } else {
                ARTErrorInfo *const errorInfo = [ARTErrorInfo createFromNSError:transportError.error];
                ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
                [self transition:ARTRealtimeFailed withMetadata:metadata];
            }
            return;
        } else if (_fallbacks && [self reconnectWithFallback]) {
            return;
        }
    }
    
    switch (transportError.type) {
        case ARTRealtimeTransportErrorTypeBadResponse:
        case ARTRealtimeTransportErrorTypeOther: {
            ARTErrorInfo *const errorInfo = [ARTErrorInfo createFromNSError:transportError.error];
            ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
            [self transition:ARTRealtimeFailed withMetadata:metadata];
            break;
        }
        default: {
            ARTErrorInfo *error = [ARTErrorInfo createFromNSError:transportError.error];
            ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:error];
            [self transitionToDisconnectedOrSuspendedWithMetadata:metadata];
        }
    }
}

- (void)realtimeTransportNeverConnected:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }
    
    ARTErrorInfo *const errorInfo = [ARTErrorInfo createWithCode:ARTClientCodeErrorTransport message:@"Transport never connected"];
    ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
    [self transition:ARTRealtimeFailed withMetadata:metadata];
}

- (void)realtimeTransportRefused:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error {
    if (transport != self.transport) {
        // Old connection
        return;
    }
    
    if (error && error.type == ARTRealtimeTransportErrorTypeRefused) {
        ARTErrorInfo *const errorInfo = [ARTErrorInfo createWithCode:ARTClientCodeErrorTransport message:[NSString stringWithFormat:@"Connection refused using %@", error.url]];
        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
        [self transition:ARTRealtimeFailed withMetadata:metadata];
    }
    else if (error) {
        ARTErrorInfo *const errorInfo = [ARTErrorInfo createFromNSError:error.error];
        ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
        [self transition:ARTRealtimeFailed withMetadata:metadata];
    }
    else {
        [self transition:ARTRealtimeFailed withMetadata:[[ARTConnectionStateChangeMetadata alloc] init]];
    }
}

- (void)realtimeTransportTooBig:(id<ARTRealtimeTransport>)transport {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    ARTErrorInfo *const errorInfo = [ARTErrorInfo createWithCode:ARTClientCodeErrorTransport message:@"Transport too big"];
    ARTConnectionStateChangeMetadata *const metadata = [[ARTConnectionStateChangeMetadata alloc] initWithErrorInfo:errorInfo];
    [self transition:ARTRealtimeFailed withMetadata:metadata];
}

- (void)realtimeTransportSetMsgSerial:(id<ARTRealtimeTransport>)transport msgSerial:(int64_t)msgSerial {
    if (transport != self.transport) {
        // Old connection
        return;
    }
    
    self.msgSerial = msgSerial;
    self.connection.latestMessageSerial = msgSerial;
}

#if TARGET_OS_IOS
- (ARTLocalDevice *)device {
    return _rest.device;
}
#endif

@end
