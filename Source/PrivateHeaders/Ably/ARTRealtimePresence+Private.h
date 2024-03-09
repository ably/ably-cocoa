#import <Ably/ARTRealtimePresence.h>
#import <Ably/ARTRealtimeChannel+Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceInternal : NSObject <ARTRealtimePresenceProtocol>

@property (nonatomic, readonly) NSString *connectionId;
@property (readonly, nonatomic) ARTEventEmitter<ARTEvent *, ARTPresenceMessage *> *eventEmitter;

- (instancetype)initWithChannel:(ARTRealtimeChannelInternal *)channel logger:(ARTInternalLog *)logger;
- (void)_unsubscribe;
- (BOOL)syncComplete_nosync;

- (void)failPendingPresence:(ARTStatus *)status;
- (void)broadcast:(ARTPresenceMessage *)pm;

- (void)sync;
- (void)sync:(nullable ARTCallback)callback;

- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onSync:(ARTProtocolMessage *)message;
- (void)onAttached:(ARTProtocolMessage *)message;

@property (nonatomic) dispatch_queue_t queue;
@property (readwrite, nonatomic) ARTPresenceAction lastPresenceAction;
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
@property (readonly, atomic) NSMutableDictionary<NSString *, ARTPresenceMessage *> *localMembers;

@property (readonly, nonatomic) NSUInteger syncSessionId;
@property (readonly, nonatomic) BOOL syncComplete;
@property (readonly, nonatomic) BOOL syncInProgress;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithQueue:(_Nonnull dispatch_queue_t)queue logger:(ARTInternalLog *)logger;

- (BOOL)add:(ARTPresenceMessage *)message;
- (void)reset;

- (void)startSync;
- (void)endSync;
- (void)failsSync:(ARTErrorInfo *)error;

- (void)onceSyncEnds:(void (^)(NSArray<ARTPresenceMessage *> *))callback;
- (void)onceSyncFails:(ARTCallback)callback;

- (void)internalAdd:(ARTPresenceMessage *)message;
- (void)internalAdd:(ARTPresenceMessage *)message withSessionId:(NSUInteger)sessionId;

- (void)cleanUpAbsentMembers;

@end

NS_ASSUME_NONNULL_END
