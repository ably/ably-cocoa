#import <Ably/ARTRealtime.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTQueuedMessage.h>
#import <Ably/ARTPendingMessage.h>
#import <Ably/ARTProtocolMessage.h>
#import <Ably/ARTReachability.h>

#import <Ably/ARTRealtimeTransport.h>
#import <Ably/ARTAuth+Private.h>
#import <Ably/ARTRest+Private.h>

@class ARTRestInternal;
@class ARTErrorInfo;
@class ARTProtocolMessage;
@class ARTConnectionInternal;
@class ARTRealtimeChannelsInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtime ()

@property (nonatomic, readonly) ARTRealtimeInternal *internal;

- (void)internalAsync:(void (^)(ARTRealtimeInternal *))use;
- (void)internalSync:(void (^)(ARTRealtimeInternal *))use;

@end

@interface ARTRealtimeInternal : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)token;

@property (nonatomic, readonly) ARTConnectionInternal *connection;
@property (nonatomic, readonly) ARTRealtimeChannelsInternal *channels;
@property (readonly) ARTAuthInternal *auth;
@property (readonly) ARTPushInternal *push;
#if TARGET_OS_IOS
@property (nonnull, nonatomic, readonly, getter=device) ARTLocalDevice *device;
#endif
@property (readonly, nullable, getter=clientId) NSString *clientId;

@property (readonly, nonatomic) dispatch_queue_t queue;

- (void)timeWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                      completion:(ARTDateTimeCallback)callback;

- (BOOL)request:(NSString *)method
           path:(NSString *)path
         params:(nullable NSStringDictionary *)params
           body:(nullable id)body
        headers:(nullable NSStringDictionary *)headers
wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
       callback:(ARTHTTPPaginatedCallback)callback
          error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)ping:(ARTCallback)cb;

- (BOOL)statsWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                         callback:(ARTPaginatedStatsCallback)callback;

- (BOOL)stats:(nullable ARTStatsQuery *)query wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTPaginatedStatsCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)connect;

- (void)close;

@end

@interface ARTRealtimeInternal () <ARTRealtimeTransportDelegate, ARTAuthDelegate>

@property (readonly, nonatomic) ARTEventEmitter<ARTEvent *, ARTConnectionStateChange *> *internalEventEmitter;
@property (readonly, nonatomic) ARTEventEmitter<ARTEvent *, NSNull *> *connectedEventEmitter;

@property (readonly, nonatomic) NSMutableArray<void (^)(ARTRealtimeConnectionState, ARTErrorInfo *_Nullable)> *pendingAuthorizations;

// State properties
- (BOOL)shouldSendEvents;

// Message sending
- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)error;

@end

/// ARTRealtimeInternal private methods that are used for internal testing.
@interface ARTRealtimeInternal ()

@property (readwrite, nonatomic) ARTRestInternal *rest;
@property (readonly, nullable) id<ARTRealtimeTransport> transport;
@property (readonly, nonatomic, nonnull) id<ARTReachability> reachability;
@property (nonatomic) NSTimeInterval connectionStateTtl;
@property (nonatomic) NSTimeInterval maxIdleInterval;

/// Current protocol `msgSerial`. Starts at zero.
@property (readwrite, nonatomic) int64_t msgSerial;

/// List of queued messages on a connection in the disconnected or connecting states.
@property (readwrite, nonatomic) NSMutableArray<ARTQueuedMessage *> *queuedMessages;

/// List of pending messages waiting for ACK/NACK action to confirm the success receipt and acceptance.
@property (readwrite, nonatomic) NSMutableArray<ARTPendingMessage *> *pendingMessages;

/// First `msgSerial` pending message.
@property (readwrite, nonatomic) int64_t pendingMessageStartSerial;

/// Client is trying to resume the last connection
@property (readwrite, nonatomic) BOOL resuming;

@property (readonly, getter=getClientOptions) ARTClientOptions *options;

/// Suspend the behavior defined in RTN15a, that is trying to immediately reconnect after a disconnection
@property (readwrite, nonatomic) BOOL shouldImmediatelyReconnect;

@end

@interface ARTRealtimeInternal (Private)

- (BOOL)isActive;

// Transport Events
- (void)onHeartbeat;
- (void)onConnected:(ARTProtocolMessage *)message;
- (void)onDisconnected;
- (void)onClosed;
- (void)onSuspended;
- (void)onError:(ARTProtocolMessage *)message;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message;

- (void)setReachabilityClass:(Class _Nullable)reachabilityClass;
- (void)transportReconnectWithExistingParameters;

// Message sending
- (void)send:(ARTProtocolMessage *)msg sentCallback:(nullable ARTCallback)sentCallback ackCallback:(nullable ARTStatusCallback)ackCallback;

- (void)send:(ARTProtocolMessage *)msg reuseMsgSerial:(BOOL)reuseMsgSerial sentCallback:(nullable ARTCallback)sentCallback ackCallback:(nullable ARTStatusCallback)ackCallback;

@end

NS_ASSUME_NONNULL_END
