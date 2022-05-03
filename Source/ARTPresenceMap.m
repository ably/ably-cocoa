#import "ARTPresenceMap.h"
#import "ARTPresenceMessage.h"
#import "ARTPresenceMessage+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTLog.h"

typedef NS_ENUM(NSUInteger, ARTPresenceSyncState) {
    ARTPresenceSyncInitialized,
    ARTPresenceSyncStarted, //ItemType: nil
    ARTPresenceSyncEnded, //ItemType: NSArray<ARTPresenceMessage *>*
    ARTPresenceSyncFailed //ItemType: ARTErrorInfo*
};

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

static NSString *_logMessage(ARTPresenceMessage *message) {
    return [message description];
}

#pragma mark - ARTEvent

@interface ARTEvent (PresenceSyncState)

- (instancetype)initWithPresenceSyncState:(ARTPresenceSyncState)value;
+ (instancetype)newWithPresenceSyncState:(ARTPresenceSyncState)value;

@end

#pragma mark - ARTPresenceMap

@interface ARTPresenceMap () {
    ARTPresenceSyncState _syncState;
    ARTEventEmitter<ARTEvent * /*ARTSyncState*/, id> *_syncEventEmitter;
    NSMutableDictionary<NSString *, ARTPresenceMessage *> *_members;
    NSMutableSet<ARTPresenceMessage *> *_localMembers;
}

@end

@implementation ARTPresenceMap {
    ARTLog *_logger;
}

- (instancetype)initWithQueue:(_Nonnull dispatch_queue_t)queue logger:(ARTLog *)logger { 
    self = [super init];
    if(self) {
        _logger = logger;
        [self reset:@"ARTPresenceMap init"];
        _syncSessionId = 0;
        _syncState = ARTPresenceSyncInitialized;
        _syncEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:queue];
    }
    return self;
}

- (NSDictionary<NSString *, ARTPresenceMessage *> *)members {
    return _members;
}

- (NSMutableSet<ARTPresenceMessage *> *)localMembers {
    return _localMembers;
}

- (BOOL)add:(ARTPresenceMessage *)message reason:(NSString *)reason {
    ARTPresenceMessage *latest = [_members objectForKey:message.memberKey];
    [_logger debug:__FILE__ line:__LINE__ message:@"1279-logging (reason %@): add: %@. Comparing to latest %@", reason, _logMessage(message), _logMessage(latest)];
    if ([message isNewerThan:latest]) {
        ARTPresenceMessage *messageCopy = [message copy];
        switch (message.action) {
            case ARTPresenceEnter:
            case ARTPresenceUpdate:
                messageCopy.action = ARTPresencePresent;
                // intentional fallthrough
            case ARTPresencePresent:
                [self internalAdd:messageCopy reason:reason];
                break;
            case ARTPresenceLeave:
                [self internalRemove:messageCopy reason:reason];
                break;
            default:
                break;
        }
        return YES;
    }
    [_logger debug:__FILE__ line:__LINE__ message:@"Presence member \"%@\" with action %@ has been ignored", message.memberKey, ARTPresenceActionToStr(message.action)];
    latest.syncSessionId = _syncSessionId;
    return NO;
}

- (void)internalAdd:(ARTPresenceMessage *)message reason:(NSString *)reason {
    [self internalAdd:message withSessionId:_syncSessionId reason:reason];
}

- (void)internalAdd:(ARTPresenceMessage *)message withSessionId:(NSUInteger)sessionId reason:(NSString *)reason {
    message.syncSessionId = sessionId;
    [_logger debug:__FILE__ line:__LINE__ message:@"1279-logging (reason %@): internalAdd: %@", reason, _logMessage(message)];
    [_members setObject:message forKey:message.memberKey];
    // Local member
    if ([message.connectionId isEqualToString:self.delegate.connectionId]) {
        [_localMembers addObject:message];
        [_logger debug:__FILE__ line:__LINE__ message:@"local member %@ with action %@ has been added", message.memberKey, ARTPresenceActionToStr(message.action).uppercaseString];
    }
}

- (void)internalRemove:(ARTPresenceMessage *)message reason:(NSString *)reason {
    [self internalRemove:message force:false reason:reason];
}

- (void)internalRemove:(ARTPresenceMessage *)message force:(BOOL)force reason:(NSString *)reason {
    if ([message.connectionId isEqualToString:self.delegate.connectionId] && !message.isSynthesized) {
        [_localMembers removeObject:message];
    }

    const BOOL syncInProgress = self.syncInProgress;
    if (!force && syncInProgress) {
        [_logger debug:__FILE__ line:__LINE__ message:@"%p \"%@\" should be removed after sync ends (syncInProgress=%d)", self, message.clientId, syncInProgress];
        message.action = ARTPresenceAbsent;
        // Should be removed after Sync ends
        [self internalAdd:message withSessionId:message.syncSessionId reason:[NSString stringWithFormat:@"internalRemove (reason %@)", reason]];
    }
    else {
        [_logger debug:__FILE__ line:__LINE__ message:@"1279-logging (reason %@): internalRemove: %@ force: %@", reason, _logMessage(message), force ? @"YES" : @"NO"];
        [_members removeObjectForKey:message.memberKey];
    }
}

- (void)cleanUpAbsentMembers:(NSString *)reason {
    [_logger debug:__FILE__ line:__LINE__ message:@"%p cleaning up absent members (syncSessionId=%lu)", self, (unsigned long)_syncSessionId];
    NSSet<NSString *> *filteredMembers = [_members keysOfEntriesPassingTest:^BOOL(NSString *key, ARTPresenceMessage *message, BOOL *stop) {
        return message.action == ARTPresenceAbsent;
    }];
    for (NSString *key in filteredMembers) {
        [self internalRemove:[_members objectForKey:key] force:true reason:reason];
    }
}

- (void)leaveMembersNotPresentInSync:(NSString *)reason {
    [_logger debug:__FILE__ line:__LINE__ message:@"%p leaving members not present in sync (syncSessionId=%lu)", self, (unsigned long)_syncSessionId];
    for (ARTPresenceMessage *member in [_members allValues]) {
        if (member.syncSessionId != _syncSessionId) {
            // Handle members that have not been added or updated in the PresenceMap during the sync process
            ARTPresenceMessage *leave = [member copy];
            [self internalRemove:member reason:reason];
            [self.delegate map:self didRemovedMemberNoLongerPresent:leave];
        }
    }
}

- (void)reenterLocalMembersMissingFromSync:(NSString *)reason {
    [_logger debug:__FILE__ line:__LINE__ message:@"%p reentering local members missed from sync (syncSessionId=%lu)", self, (unsigned long)_syncSessionId];
    NSSet *filteredLocalMembers = [_localMembers filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"syncSessionId != %lu", (unsigned long)_syncSessionId]];
    for (ARTPresenceMessage *localMember in filteredLocalMembers) {
        ARTPresenceMessage *reenter = [localMember copy];
        [self internalRemove:localMember reason:reason];
        [self.delegate map:self shouldReenterLocalMember:reenter];
    }
    [self cleanUpAbsentMembers:reason];
}

- (void)reset:(NSString *)reason {
    [_logger debug:__FILE__ line:__LINE__ message:@"1279-logging (reason %@): reset", reason];
    _members = [NSMutableDictionary dictionary];
    _localMembers = [NSMutableSet set];
}

- (void)startSync {
    [_logger debug:__FILE__ line:__LINE__ message:@"%p PresenceMap sync started", self];
    _syncSessionId++;
    _syncState = ARTPresenceSyncStarted;
    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:_syncState] with:nil];
}

- (void)endSync:(NSString *)reason {
    [_logger verbose:__FILE__ line:__LINE__ message:@"%p PresenceMap sync ending", self];
    [self cleanUpAbsentMembers:reason];
    [self leaveMembersNotPresentInSync:reason];
    _syncState = ARTPresenceSyncEnded;
    [self reenterLocalMembersMissingFromSync:reason];
    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncEnded] with:[_members allValues]];
    [_syncEventEmitter off];
    [_logger debug:__FILE__ line:__LINE__ message:@"%p PresenceMap sync ended", self];
}

- (void)failsSync:(ARTErrorInfo *)error {
    [self reset:@"failsSync"];
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

- (BOOL)syncComplete {
    return !(_syncState == ARTPresenceSyncInitialized || _syncState == ARTPresenceSyncStarted);
}

- (BOOL)syncInProgress {
    return _syncState == ARTPresenceSyncStarted;
}

#pragma mark private

- (NSString *)memberKey:(ARTPresenceMessage *) message {
    return [NSString stringWithFormat:@"%@:%@", message.connectionId, message.clientId];
}

@end

#pragma mark - ARTEvent

@implementation ARTEvent (PresenceSyncState)

- (instancetype)initWithPresenceSyncState:(ARTPresenceSyncState)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTPresenceSyncState%@", ARTPresenceSyncStateToStr(value)]];
}

+ (instancetype)newWithPresenceSyncState:(ARTPresenceSyncState)value {
    return [[self alloc] initWithPresenceSyncState:value];
}

@end
