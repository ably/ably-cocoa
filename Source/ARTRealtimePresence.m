#import "ARTRealtimePresence+Private.h"
#import "ARTRealtime+Private.h"
#import "ARTChannel+Private.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTPresenceMessage.h"
#import "ARTPresenceMessage+Private.h"
#import "ARTStatus.h"
#import "ARTPresence+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTConnection+Private.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTInternalLog.h"
#import "ARTEventEmitter+Private.h"
#import "ARTDataEncoder.h"
#import "ARTBaseMessage+Private.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTEventEmitter+Private.h"

#pragma mark - ARTRealtimePresenceQuery

@implementation ARTRealtimePresenceQuery

- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    self = [super initWithLimit:limit clientId:clientId connectionId:connectionId];
    if (self) {
        _waitForSync = true;
    }
    return self;
}

@end

@implementation ARTRealtimePresence {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRealtimePresenceInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (BOOL)syncComplete {
    return _internal.syncComplete;
}

- (void)get:(ARTPresenceMessagesCallback)callback {
    [_internal get:callback];
}

- (void)get:(ARTRealtimePresenceQuery *)query callback:(ARTPresenceMessagesCallback)callback {
    [_internal get:query callback:callback];
}

- (void)enter:(id _Nullable)data {
    [_internal enter:data];
}

- (void)enter:(id _Nullable)data callback:(nullable ARTCallback)cb {
    [_internal enter:data callback:cb];
}

- (void)update:(id _Nullable)data {
    [_internal update:data];
}

- (void)update:(id _Nullable)data callback:(nullable ARTCallback)cb {
    [_internal update:data callback:cb];
}

- (void)leave:(id _Nullable)data {
    [_internal leave:data];
}

- (void)leave:(id _Nullable)data callback:(nullable ARTCallback)cb {
    [_internal leave:data callback:cb];
}

- (void)enterClient:(NSString *)clientId data:(id _Nullable)data {
    [_internal enterClient:clientId data:data];
}

- (void)enterClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb {
    [_internal enterClient:clientId data:data callback:cb];
}

- (void)updateClient:(NSString *)clientId data:(id _Nullable)data {
    [_internal updateClient:clientId data:data];
}

- (void)updateClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb {
    [_internal updateClient:clientId data:data callback:cb];
}

- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data {
    [_internal leaveClient:clientId data:data];
}

- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable ARTCallback)cb {
    [_internal leaveClient:clientId data:data callback:cb];
}

- (ARTEventListener *_Nullable)subscribe:(ARTPresenceMessageCallback)callback {
    return [_internal subscribe:callback];
}

- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb {
    return [_internal subscribeWithAttachCallback:onAttach callback:cb];
}

- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action callback:(ARTPresenceMessageCallback)cb {
    return [_internal subscribe:action callback:cb];
}

- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action onAttach:(nullable ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb {
    return [_internal subscribe:action onAttach:onAttach callback:cb];
}

- (void)unsubscribe {
    [_internal unsubscribe];
}

- (void)unsubscribe:(ARTEventListener *)listener {
    [_internal unsubscribe:listener];
}

- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener *)listener {
    [_internal unsubscribe:action listener:listener];
}

- (void)history:(ARTPaginatedPresenceCallback)callback {
    [_internal history:callback];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal history:query callback:callback error:errorPtr];
}

@end

#pragma mark - ARTRealtimePresenceInternal

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceInternal ()

@property (nonatomic, readonly) ARTInternalLog *logger;

@end

NS_ASSUME_NONNULL_END

typedef NS_ENUM(NSUInteger, ARTPresenceSyncState) {
    ARTPresenceSyncInitialized,
    ARTPresenceSyncStarted, //ItemType: nil
    ARTPresenceSyncEnded, //ItemType: NSArray<ARTPresenceMessage *>*
    ARTPresenceSyncFailed //ItemType: ARTErrorInfo*
};

@interface ARTEvent (PresenceSyncState)

- (instancetype)initWithPresenceSyncState:(ARTPresenceSyncState)value;
+ (instancetype)newWithPresenceSyncState:(ARTPresenceSyncState)value;

@end

@implementation ARTRealtimePresenceInternal {
    __weak ARTRealtimeChannelInternal *_channel; // weak because channel owns self
    __weak ARTRealtimeInternal *_realtime;
    dispatch_queue_t _userQueue;
    NSMutableArray<ARTQueuedMessage *> *_pendingPresence;
    ARTEventEmitter<ARTEvent *, ARTPresenceMessage *> *_eventEmitter;
    ARTDataEncoder *_dataEncoder;
    
    ARTPresenceSyncState _syncState;
    ARTEventEmitter<ARTEvent * /*ARTSyncState*/, id> *_syncEventEmitter;
    
    NSMutableDictionary<NSString *, ARTPresenceMessage *> *_members;
    NSMutableDictionary<NSString *, ARTPresenceMessage *> *_internalMembers; // RTP17h
    
    NSMutableDictionary<NSString *, ARTPresenceMessage *> *_beforeSyncMembers; // RTP19
}

- (instancetype)initWithChannel:(ARTRealtimeChannelInternal *)channel logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _channel = channel;
        _realtime = channel.realtime;
        _userQueue = _realtime.rest.userQueue;
        _queue = _realtime.rest.queue;
        _pendingPresence = [NSMutableArray array];
        _lastPresenceAction = ARTPresenceAbsent;
        _logger = logger;
        _eventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_queue];
        _dataEncoder = _channel.dataEncoder;
        _members = [NSMutableDictionary new];
        _internalMembers = [NSMutableDictionary new];
        _syncState = ARTPresenceSyncInitialized;
        _syncEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_queue];
    }
    return self;
}

- (void)get:(ARTPresenceMessagesCallback)callback {
    [self get:[[ARTRealtimePresenceQuery alloc] init] callback:callback];
}

- (void)get:(ARTRealtimePresenceQuery *)query callback:(ARTPresenceMessagesCallback)callback {
    if (callback) {
        ARTPresenceMessagesCallback userCallback = callback;
        callback = ^(NSArray<ARTPresenceMessage *> *m, ARTErrorInfo *e) {
            dispatch_async(self->_userQueue, ^{
                userCallback(m, e);
            });
        };
    }

dispatch_async(_queue, ^{
    switch (self->_channel.state_nosync) {
        case ARTRealtimeChannelDetached:
        case ARTRealtimeChannelFailed:
            if (callback) callback(nil, [ARTErrorInfo createWithCode:ARTErrorChannelOperationFailedInvalidState message:[NSString stringWithFormat:@"unable to return the list of current members (incompatible channel state: %@)", ARTRealtimeChannelStateToStr(self->_channel.state_nosync)]]);
            return;
        case ARTRealtimeChannelSuspended:
            if (query && !query.waitForSync) {
                if (callback) callback(self->_members.allValues, nil);
                return;
            }
            if (callback) callback(nil, [ARTErrorInfo createWithCode:ARTErrorPresenceStateIsOutOfSync message:@"presence state is out of sync due to the channel being SUSPENDED"]);
            return;
        default:
            break;
    }

    BOOL (^filterMemberBlock)(ARTPresenceMessage *message) = ^BOOL(ARTPresenceMessage *message) {
        return (query.clientId == nil || [message.clientId isEqualToString:query.clientId]) &&
            (query.connectionId == nil || [message.connectionId isEqualToString:query.connectionId]);
    };

    [self->_channel _attach:^(ARTErrorInfo *error) {
        if (error) {
            callback(nil, error);
            return;
        }
        const BOOL syncInProgress = self.syncInProgress;
        if (syncInProgress && query.waitForSync) {
            ARTLogDebug(self.logger, @"R:%p C:%p (%@) sync is in progress, waiting until the presence members is synchronized", self->_realtime, self->_channel, self->_channel.name);
            [self onceSyncEnds:^(NSArray<ARTPresenceMessage *> *members) {
                NSArray<ARTPresenceMessage *> *filteredMembers = [members artFilter:filterMemberBlock];
                callback(filteredMembers, nil);
            }];
            [self onceSyncFails:^(ARTErrorInfo *error) {
                callback(nil, error);
            }];
        } else {
            ARTLogDebug(self.logger, @"R:%p C:%p (%@) returning presence members (syncInProgress=%d)", self->_realtime, self->_channel, self->_channel.name, syncInProgress);
            NSArray<ARTPresenceMessage *> *members = self->_members.allValues;
            NSArray<ARTPresenceMessage *> *filteredMembers = [members artFilter:filterMemberBlock];
            callback(filteredMembers, nil);
        }
    }];
});
}

- (void)history:(ARTPaginatedPresenceCallback)callback {
    [self history:[[ARTRealtimeHistoryQuery alloc] init] callback:callback error:nil];
}

- (BOOL)history:(ARTRealtimeHistoryQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError **)errorPtr {
    query.realtimeChannel = _channel;
    return [_channel.restChannel.presence history:query callback:callback error:errorPtr];
}

- (void)enter:(id)data {
    [self enter:data callback:nil];
}

- (void)enter:(id)data callback:(ARTCallback)cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    [self enterOrUpdateAfterChecks:ARTPresenceEnter messageId:nil clientId:nil data:data callback:cb];
});
}

- (void)enterClient:(NSString *)clientId data:(id)data {
    [self enterClient:clientId data:data callback:nil];
}

- (void)enterClient:(NSString *)clientId data:(id)data callback:(ARTCallback)cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    [self enterOrUpdateAfterChecks:ARTPresenceEnter messageId:nil clientId:clientId data:data callback:cb];
});
}

- (void)enterWithPresenceMessageId:(NSString *)messageId clientId:(NSString *)clientId data:(id)data callback:(ARTCallback)cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }
    dispatch_async(_queue, ^{
        [self enterOrUpdateAfterChecks:ARTPresenceEnter messageId:messageId clientId:clientId data:data callback:cb];
    });
}

- (void)update:(id)data {
    [self update:data callback:nil];
}

- (void)update:(id)data callback:(ARTCallback)cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    [self enterOrUpdateAfterChecks:ARTPresenceUpdate messageId:nil clientId:nil data:data callback:cb];
});
}

- (void)updateClient:(NSString *)clientId data:(id)data {
    [self updateClient:clientId data:data callback:nil];
}

- (void)updateClient:(NSString *)clientId data:(id)data callback:(ARTCallback)cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
    [self enterOrUpdateAfterChecks:ARTPresenceUpdate messageId:nil clientId:clientId data:data callback:cb];
});
}

- (void)enterOrUpdateAfterChecks:(ARTPresenceAction)action messageId:(NSString *_Nullable)messageId clientId:(NSString *_Nullable)clientId data:(id)data callback:(ARTCallback)cb {
    switch (_channel.state_nosync) {
        case ARTRealtimeChannelDetached:
        case ARTRealtimeChannelFailed: {
            if (cb) {
                ARTErrorInfo *channelError = [ARTErrorInfo createWithCode:ARTErrorChannelOperationFailedInvalidState message:[NSString stringWithFormat:@"unable to enter presence channel (incompatible channel state: %@)", ARTRealtimeChannelStateToStr(_channel.state_nosync)]];
                cb(channelError);
            }
            return;
        }
        default:
            break;
    }

    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = action;
    msg.id = messageId;
    msg.clientId = clientId;
    msg.data = data;
    msg.connectionId = _realtime.connection.id_nosync;

    [self publishPresence:msg callback:cb];
}

- (void)leave:(id)data {
    [self leave:data callback:nil];
}

- (void)leave:(id)data callback:(ARTCallback)cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

    __block ARTException *exception = nil;
dispatch_sync(_queue, ^{
@try {
    [self leaveAfterChecks:nil data:data callback:cb];
} @catch (ARTException *e) {
    exception = e;
}
});
    if (exception) {
        @throw exception;
    }
}

- (void)leaveClient:(NSString *)clientId data:(id)data {
    [self leaveClient:clientId data:data callback:nil];
}

- (void)leaveClient:(NSString *)clientId data:(id)data callback:(ARTCallback)cb {
    if (cb) {
        ARTCallback userCallback = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_sync(_queue, ^{
    [self leaveAfterChecks:clientId data:data callback:cb];
});
}

- (void)leaveAfterChecks:(NSString *_Nullable)clientId data:(id)data callback:(ARTCallback)cb {
    ARTPresenceMessage *msg = [[ARTPresenceMessage alloc] init];
    msg.action = ARTPresenceLeave;
    msg.data = data;
    msg.clientId = clientId;
    msg.connectionId = _realtime.connection.id_nosync;
    [self publishPresence:msg callback:cb];
}

- (BOOL)syncComplete {
    __block BOOL ret;
dispatch_sync(_queue, ^{
    ret = [self syncComplete_nosync];
});
    return ret;
}

- (BOOL)syncComplete_nosync {
    return _syncState == ARTPresenceSyncEnded || _syncState == ARTPresenceSyncFailed;
}

- (ARTEventListener *)subscribe:(ARTPresenceMessageCallback)callback {
    return [self subscribeWithAttachCallback:nil callback:callback];
}

- (ARTEventListener *)subscribeWithAttachCallback:(ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb {
    if (cb) {
        ARTPresenceMessageCallback userCallback = cb;
        cb = ^(ARTPresenceMessage *_Nullable m) {
            dispatch_async(self->_userQueue, ^{
                userCallback(m);
            });
        };
    }
    if (onAttach) {
        ARTCallback userOnAttach = onAttach;
        onAttach = ^(ARTErrorInfo *_Nullable m) {
            dispatch_async(self->_userQueue, ^{
                userOnAttach(m);
            });
        };
    }

    __block ARTEventListener *listener = nil;
dispatch_sync(_queue, ^{
    if (self->_channel.state_nosync == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:ARTErrorChannelOperationFailedInvalidState message:@"attempted to subscribe while channel is in Failed state."]);
        return;
    }
    [self->_channel _attach:onAttach];
    listener = [_eventEmitter on:cb];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) presence subscribe to all actions", self->_realtime, self->_channel, self->_channel.name);
});
    return listener;
}

- (ARTEventListener *)subscribe:(ARTPresenceAction)action callback:(ARTPresenceMessageCallback)cb {
    return [self subscribe:action onAttach:nil callback:cb];
}

- (ARTEventListener *)subscribe:(ARTPresenceAction)action onAttach:(ARTCallback)onAttach callback:(ARTPresenceMessageCallback)cb {
    if (cb) {
        ARTPresenceMessageCallback userCallback = cb;
        cb = ^(ARTPresenceMessage *_Nullable m) {
            dispatch_async(self->_userQueue, ^{
                userCallback(m);
            });
        };
    }
    if (onAttach) {
        ARTCallback userOnAttach = onAttach;
        onAttach = ^(ARTErrorInfo *_Nullable m) {
            dispatch_async(self->_userQueue, ^{
                userOnAttach(m);
            });
        };
    }

    __block ARTEventListener *listener = nil;
dispatch_sync(_queue, ^{
    if (self->_channel.state_nosync == ARTRealtimeChannelFailed) {
        if (onAttach) onAttach([ARTErrorInfo createWithCode:ARTErrorChannelOperationFailedInvalidState message:@"attempted to subscribe while channel is in Failed state."]);
        return;
    }
    [self->_channel _attach:onAttach];
    listener = [_eventEmitter on:[ARTEvent newWithPresenceAction:action] callback:cb];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) presence subscribe to action %@", self->_realtime, self->_channel, self->_channel.name, ARTPresenceActionToStr(action));
});
    return listener;
}

- (void)unsubscribe {
dispatch_sync(_queue, ^{
    [self _unsubscribe];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) presence unsubscribe to all actions", self->_realtime, self->_channel, self->_channel.name);
});
}

- (void)_unsubscribe {
    [_eventEmitter off];
}

- (void)unsubscribe:(ARTEventListener *)listener {
dispatch_sync(_queue, ^{
    [_eventEmitter off:listener];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) presence unsubscribe to all actions", self->_realtime, self->_channel, self->_channel.name);
});
}

- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener *)listener {
dispatch_sync(_queue, ^{
    [_eventEmitter off:[ARTEvent newWithPresenceAction:action] listener:listener];
    ARTLogVerbose(self.logger, @"R:%p C:%p (%@) presence unsubscribe to action %@", self->_realtime, self->_channel, self->_channel.name, ARTPresenceActionToStr(action));
});
}

- (void)addPendingPresence:(ARTProtocolMessage *)msg callback:(ARTStatusCallback)cb {
    ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:msg sentCallback:nil ackCallback:cb];
    [_pendingPresence addObject:qm];
}

- (void)publishPresence:(ARTPresenceMessage *)msg callback:(ARTCallback)callback {
    if (msg.clientId == nil) {
        NSString *authClientId = _realtime.auth.clientId_nosync;
        BOOL connected = _realtime.connection.state_nosync == ARTRealtimeConnected;
        if (connected && (authClientId == nil || [authClientId isEqualToString:@"*"])) {
            if (callback) {
                callback([ARTErrorInfo createWithCode:ARTStateNoClientId message:@"Invalid attempt to publish presence message without clientId."]);
            }
            return;
        }
    }

    if (!_realtime.connection.isActive_nosync) {
        if (callback) callback([_realtime.connection error_nosync]);
        return;
    }

    if ([_channel exceedMaxSize:@[msg]]) {
        if (callback) {
            ARTErrorInfo *sizeError = [ARTErrorInfo createWithCode:ARTErrorMaxMessageLengthExceeded
                                                           message:@"Maximum message length exceeded."];
            callback(sizeError);
        }
        return;
    }

    _lastPresenceAction = msg.action;

    if (msg.data && _channel.dataEncoder) {
        ARTDataEncoderOutput *encoded = [_channel.dataEncoder encode:msg.data];
        if (encoded.errorInfo) {
            ARTLogWarn(self.logger, @"RT:%p C:%p (%@) error encoding presence message: %@", _realtime, self, _channel.name, encoded.errorInfo);
        }
        msg.data = encoded.data;
        msg.encoding = encoded.encoding;
    }

    ARTProtocolMessage *pm = [[ARTProtocolMessage alloc] init];
    pm.action = ARTProtocolMessagePresence;
    pm.channel = _channel.name;
    pm.presence = @[msg];

    ARTRealtimeChannelState channelState = _channel.state_nosync;
    switch (channelState) {
        case ARTRealtimeChannelInitialized:
        case ARTRealtimeChannelDetached:
            [_channel _attach:nil];
        case ARTRealtimeChannelAttaching: {
            [self addPendingPresence:pm callback:^(ARTStatus *status) {
                if (callback) {
                    callback(status.errorInfo);
                }
            }];
            break;
        }
        case ARTRealtimeChannelAttached: {
            [_realtime send:pm sentCallback:nil ackCallback:^(ARTStatus *status) {
                if (callback) callback(status.errorInfo);
            }];
            break;
        }
        case ARTRealtimeChannelSuspended:
        case ARTRealtimeChannelDetaching:
        case ARTRealtimeChannelFailed: {
            if (callback) {
                ARTErrorInfo *invalidChannelError = [ARTErrorInfo createWithCode:ARTErrorChannelOperationFailedInvalidState message:[NSString stringWithFormat:@"channel operation failed (invalid channel state: %@)", ARTRealtimeChannelStateToStr(channelState)]];
                callback(invalidChannelError);
            }
            break;
        }
    }
}

- (NSMutableArray<ARTQueuedMessage *> *)pendingPresence {
    __block NSMutableArray<ARTQueuedMessage *> *ret;
dispatch_sync(_queue, ^{
    ret = _pendingPresence;
});
    return ret;
}

- (void)sendPendingPresence {
    NSArray *pendingPresence = _pendingPresence;
    ARTRealtimeChannelState channelState = _channel.state_nosync;
    _pendingPresence = [NSMutableArray array];
    for (ARTQueuedMessage *qm in pendingPresence) {
        if (qm.msg.action == ARTProtocolMessagePresence &&
            channelState != ARTRealtimeChannelAttached) {
            // Presence messages should only be sent when the channel is attached.
            [_pendingPresence addObject:qm];
            continue;
        }
        [_realtime send:qm.msg sentCallback:nil ackCallback:qm.ackCallback];
    }
}

- (void)failPendingPresence:(ARTStatus *)status {
    NSArray *pendingPresence = _pendingPresence;
    _pendingPresence = [NSMutableArray array];
    for (ARTQueuedMessage *qm in pendingPresence) {
        qm.ackCallback(status);
    }
}

- (void)broadcast:(ARTPresenceMessage *)pm {
    [_eventEmitter emit:[ARTEvent newWithPresenceAction:pm.action] with:pm];
}

/*
 * Checks that a channelSerial is the final serial in a sequence of sync messages,
 * by checking that there is nothing after the colon - RTP18b, RTP18c
 */
- (bool)isLastChannelSerial:(NSString *)channelSerial {
    if ([channelSerial isEqualToString:@""]) {
        return true;
    }
    NSArray *a = [channelSerial componentsSeparatedByString:@":"];
    if (a.count > 1 && ![[a objectAtIndex:1] isEqualToString:@""]) {
        return false;
    }
    return true;
}

- (void)onAttached:(ARTProtocolMessage *)message {
    [self startSync];
    if (!message.hasPresence) {
        // RTP1 - when an ATTACHED message is received without a HAS_PRESENCE flag, reset PresenceMap
        [self endSync];
        ARTLogDebug(self.logger, @"R:%p C:%p (%@) PresenceMap has been reset", _realtime, self, _channel.name);
    }
    [self sendPendingPresence];
    [self reenterInternalMembers]; // RTP17i
}

- (void)onMessage:(ARTProtocolMessage *)message {
    int i = 0;
    for (ARTPresenceMessage *p in message.presence) {
        ARTPresenceMessage *member = p;
        if (member.data && _dataEncoder) {
            NSError *decodeError = nil;
            member = [p decodeWithEncoder:_dataEncoder error:&decodeError];
            if (decodeError != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason] prepend:@"Failed to decode data: "];
                ARTLogError(self.logger, @"RT:%p C:%p (%@) %@", _realtime, _channel, _channel.name, errorInfo.message);
            }
        }

        if (!member.timestamp) {
            member.timestamp = message.timestamp;
        }

        if (!member.id) {
            member.id = [NSString stringWithFormat:@"%@:%d", message.id, i];
        }

        if (!member.connectionId) {
            member.connectionId = message.connectionId;
        }
        
        [self processMember:member];

        ++i;
    }
}

- (void)onSync:(ARTProtocolMessage *)message {
    if (!self.syncInProgress) {
        [self startSync];
    }
    else {
        ARTLogDebug(self.logger, @"RT:%p C:%p (%@) PresenceMap sync is in progress", _realtime, _channel, _channel.name);
    }

    [self onMessage:message];

    if ([self isLastChannelSerial:message.channelSerial]) {
        [self endSync];
        ARTLogDebug(self.logger, @"RT:%p C:%p (%@) PresenceMap sync ended", _realtime, _channel, _channel.name);
    }
}

- (NSString *)connectionId {
    return _realtime.connection.id_nosync;
}

- (void)didRemovedMemberNoLongerPresent:(ARTPresenceMessage *)pm {
    pm.action = ARTPresenceLeave;
    pm.id = nil;
    pm.timestamp = [NSDate date];
    [self broadcast:pm];
    ARTLogDebug(self.logger, @"RT:%p C:%p (%@) member \"%@\" no longer present", _realtime, _channel, _channel.name, pm.memberKey);
}

- (void)reenterInternalMembers {
    ARTLogDebug(self.logger, @"%p reentering local members", self);
    for (ARTPresenceMessage *member in [self.internalMembers allValues]) {
        [self enterWithPresenceMessageId:member.id clientId:member.clientId data:member.data callback:^(ARTErrorInfo *error) {
            if (error != nil) {
                NSString *message = [NSString stringWithFormat:@"Re-entering member \"%@\" is failed with code %ld (%@)", member.memberKey, (long)error.code, error.message];
                ARTErrorInfo *reenterError = [ARTErrorInfo createWithCode:ARTErrorUnableToAutomaticallyReEnterPresenceChannel message:message];
                ARTChannelStateChange *stateChange = [[ARTChannelStateChange alloc] initWithCurrent:self->_channel.state_nosync previous:self->_channel.state_nosync event:ARTChannelEventUpdate reason:reenterError resumed:true]; // RTP17e
                
                [self->_channel emit:stateChange.event with:stateChange];
                
                ARTLogWarn(self.logger, @"RT:%p C:%p (%@) Re-entering member \"%@\" is failed with code %ld (%@)", self->_realtime, self->_channel, self->_channel.name, member.memberKey, (long)error.code, error.message);
            }
            else {
                ARTLogDebug(self.logger, @"RT:%p C:%p (%@) re-entered local member \"%@\"", self->_realtime, self->_channel, self->_channel.name, member.memberKey);
            }
        }];
        ARTLogDebug(self.logger, @"RT:%p C:%p (%@) re-entering local member \"%@\"", _realtime, _channel, _channel.name, member.memberKey);
    }
}

#pragma mark - Presence Map

- (NSDictionary<NSString *, ARTPresenceMessage *> *)members {
    return _members;
}

- (NSDictionary<NSString *, ARTPresenceMessage *> *)internalMembers {
    return _internalMembers;
}

- (void)processMember:(ARTPresenceMessage *)message {
    ARTPresenceMessage *messageCopy = [message copy];
    // Internal member
    if ([message.connectionId isEqualToString:self.connectionId]) {
        switch (message.action) {
            case ARTPresenceEnter:
            case ARTPresenceUpdate:
            case ARTPresencePresent:
                messageCopy.action = ARTPresencePresent;
                [self addInternalMember:messageCopy];
                break;
            case ARTPresenceLeave:
                if (!message.isSynthesized) {
                    [self removeInternalMember:messageCopy];
                }
                break;
            default:
                break;
        }
    }
    
    BOOL memberUpdated = false;
    switch (message.action) {
        case ARTPresenceEnter:
        case ARTPresenceUpdate:
        case ARTPresencePresent:
            messageCopy.action = ARTPresencePresent;
            memberUpdated = [self addMember:messageCopy];
            break;
        case ARTPresenceLeave:
            messageCopy.action = ARTPresenceAbsent; // RTP2f
            memberUpdated = [self removeMember:messageCopy];
            break;
        default:
            break;
    }

    if (memberUpdated) {
        [_beforeSyncMembers removeObjectForKey:message.memberKey]; // RTP19
        [self broadcast:message];
    }
    else {
        ARTLogDebug(_logger, @"Presence member \"%@\" with action %@ has been ignored", message.memberKey, ARTPresenceActionToStr(message.action));
    }
}

- (BOOL)addMember:(ARTPresenceMessage *)message {
    ARTPresenceMessage *existing = [_members objectForKey:message.memberKey];
    if (existing && [existing isNewerThan:message]) {
        return false;
    }
    _members[message.memberKey] = message;
    return true;
}

- (BOOL)addInternalMember:(ARTPresenceMessage *)message {
    ARTPresenceMessage *existing = [_internalMembers objectForKey:message.clientId];
    if (existing && [existing isNewerThan:message]) {
        return false;
    }
    _internalMembers[message.clientId] = message;
    ARTLogDebug(_logger, @"local member %@ with action %@ has been added", message.clientId, ARTPresenceActionToStr(message.action).uppercaseString);
    return true;
}

- (BOOL)removeMember:(ARTPresenceMessage *)message {
    ARTPresenceMessage *existing = [_members objectForKey:message.memberKey];
    if (existing && [existing isNewerThan:message]) {
        return false;
    }
    [_members removeObjectForKey:message.memberKey];
    return true;
}

- (BOOL)removeInternalMember:(ARTPresenceMessage *)message {
    ARTPresenceMessage *existing = [_internalMembers objectForKey:message.clientId];
    if (existing && [existing isNewerThan:message]) {
        return false;
    }
    [_internalMembers removeObjectForKey:message.clientId];
    return true;
}

- (void)cleanUpAbsentMembers {
    ARTLogDebug(_logger, @"%p cleaning up absent members...", self);
    NSSet<NSString *> *absentMembers = [_members keysOfEntriesPassingTest:^BOOL(NSString *key, ARTPresenceMessage *message, BOOL *stop) {
        return message.action == ARTPresenceAbsent;
    }];
    for (NSString *key in absentMembers) {
        [self removeMember:[_members objectForKey:key]];
    }
}

- (void)leaveMembersNotPresentInSync {
    ARTLogDebug(_logger, @"%p leaving members not present in sync...", self);
    for (ARTPresenceMessage *member in [_beforeSyncMembers allValues]) {
        // Handle members that have not been added or updated in the PresenceMap during the sync process
        ARTPresenceMessage *leave = [member copy];
        [self removeMember:member];
        [self didRemovedMemberNoLongerPresent:leave];
    }
}

- (void)reset {
    _members = [NSMutableDictionary new];
    _internalMembers = [NSMutableDictionary new];
}

- (void)startSync {
    ARTLogDebug(_logger, @"%p PresenceMap sync started", self);
    _beforeSyncMembers = [_members mutableCopy];
    _syncState = ARTPresenceSyncStarted;
    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:_syncState] with:nil];
}

- (void)endSync {
    ARTLogVerbose(_logger, @"%p PresenceMap sync ending", self);
    [self cleanUpAbsentMembers];
    [self leaveMembersNotPresentInSync];
    _syncState = ARTPresenceSyncEnded;

    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncEnded] with:[_members allValues]];
    [_syncEventEmitter off];
    ARTLogDebug(_logger, @"%p PresenceMap sync ended", self);
}

- (void)failsSync:(ARTErrorInfo *)error {
    [self reset];
    _syncState = ARTPresenceSyncFailed;
    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncFailed] with:error];
    [_syncEventEmitter off];
}

- (void)onceSyncEnds:(void (^)(NSArray<ARTPresenceMessage *> *))callback {
    [_syncEventEmitter once:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncEnded] callback:callback];
}

- (void)onceSyncFails:(ARTCallback)callback {
    [_syncEventEmitter once:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncFailed] callback:callback];
}

- (BOOL)syncInProgress {
    return _syncState == ARTPresenceSyncStarted;
}

@end

#pragma mark - ARTEvent

NSString *ARTPresenceSyncStateToStr(ARTPresenceSyncState state) {
    switch (state) {
        case ARTPresenceSyncInitialized:
            return @"Initialized"; //0
        case ARTPresenceSyncStarted:
            return @"Started"; //1
        case ARTPresenceSyncEnded:
            return @"Ended"; //2
        case ARTPresenceSyncFailed:
            return @"Failed"; //3
    }
}

@implementation ARTEvent (PresenceSyncState)

- (instancetype)initWithPresenceSyncState:(ARTPresenceSyncState)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTPresenceSyncState%@", ARTPresenceSyncStateToStr(value)]];
}

+ (instancetype)newWithPresenceSyncState:(ARTPresenceSyncState)value {
    return [[self alloc] initWithPresenceSyncState:value];
}

@end
