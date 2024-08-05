#import <Ably/ARTRealtimePresence.h>
#import <Ably/ARTRealtimeChannel+Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceInternal : NSObject <ARTRealtimePresenceProtocol>

@property (nonatomic, readonly) NSString *connectionId;
@property (readonly, nonatomic) ARTEventEmitter<ARTEvent *, ARTPresenceMessage *> *eventEmitter;

- (instancetype)initWithChannel:(ARTRealtimeChannelInternal *)channel logger:(ARTInternalLog *)logger;
- (void)_unsubscribe;
- (BOOL)syncComplete_nosync;
- (BOOL)syncInProgress_nosync;

- (void)failPendingPresence:(ARTStatus *)status;
- (void)broadcast:(ARTPresenceMessage *)pm;

- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onSync:(ARTProtocolMessage *)message;
- (void)onAttached:(ARTProtocolMessage *)message;

@property (nonatomic) dispatch_queue_t queue;
@property (readonly, nonatomic) NSMutableArray<ARTQueuedMessage *> *pendingPresence;

@end

@interface ARTRealtimePresence ()

@property (nonatomic, readonly) ARTRealtimePresenceInternal *internal;

- (instancetype)initWithInternal:(ARTRealtimePresenceInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

@interface ARTRealtimePresenceInternal (PresenceMap)

/// List of members.
/// The key is the memberKey and the value is the latest relevant ARTPresenceMessage for that clientId.
@property (readonly, atomic) NSDictionary<NSString *, ARTPresenceMessage *> *members;

/// List of internal members.
/// The key is the clientId and the value is the latest relevant ARTPresenceMessage for that clientId.
@property (readonly, atomic) NSMutableDictionary<NSString *, ARTPresenceMessage *> *internalMembers;

@property (readonly, nonatomic) BOOL syncComplete;
@property (readonly, nonatomic) BOOL syncInProgress;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithQueue:(_Nonnull dispatch_queue_t)queue logger:(ARTInternalLog *)logger;

- (void)processMember:(ARTPresenceMessage *)message;
- (void)reset;

- (void)startSync;
- (void)endSync;
- (void)failsSync:(ARTErrorInfo *)error;

- (void)onceSyncEnds:(void (^)(NSArray<ARTPresenceMessage *> *))callback;
- (void)onceSyncFails:(ARTCallback)callback;

- (BOOL)addMember:(ARTPresenceMessage *)message;
- (void)addInternalMember:(ARTPresenceMessage *)message;

- (BOOL)removeMember:(ARTPresenceMessage *)message;
- (void)removeInternalMember:(ARTPresenceMessage *)message;

- (void)cleanUpAbsentMembers;

- (BOOL)member:(ARTPresenceMessage *)msg1 isNewerThan:(ARTPresenceMessage *)msg2 __attribute__((warn_unused_result));

@end

NS_ASSUME_NONNULL_END
