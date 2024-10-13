//
//  ARTRealtimeChannel+Private.h
//
//

#import <Ably/ARTRestChannel+Private.h>
#import <Ably/ARTRealtimeChannel.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtime+Private.h>
#import <Ably/ARTQueuedDealloc.h>
#import <Ably/ARTPushChannel+Private.h>

@class ARTProtocolMessage;
@class ARTRealtimePresenceInternal;
@class ARTChannelStateChangeParams;
@class ARTAttachRequestParams;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannelInternal : ARTChannel <ARTRealtimeChannelProtocol>

@property (readonly) ARTRealtimePresenceInternal *presence;
#if TARGET_OS_IPHONE
@property (readonly) ARTPushChannelInternal *push;
#endif

@property (readwrite, nonatomic) ARTRealtimeChannelState state;
@property (readonly, nonatomic, nullable) ARTErrorInfo *errorReason;
@property (readonly, nullable, getter=getOptions_nosync) ARTRealtimeChannelOptions *options_nosync;
@property (nonatomic, readonly) NSString *connectionId;

- (ARTRealtimeChannelState)state_nosync;
- (ARTErrorInfo *)errorReason_nosync;
- (NSString * _Nullable)clientId_nosync;
- (BOOL)canBeReattached;
- (BOOL)shouldAttach;
- (ARTChannelProperties *)properties_nosync;

@property (readonly, weak, nonatomic) ARTRealtimeInternal *realtime; // weak because realtime owns self
@property (readonly, nonatomic) ARTRestChannelInternal *restChannel;
@property (readwrite, nonatomic, nullable) NSString *attachSerial;
@property (readwrite, nonatomic, nullable) NSString *channelSerial; // CP2b
@property (readonly, nullable, getter=getClientId) NSString *clientId;
@property (readonly, nonatomic) ARTEventEmitter<ARTEvent *, ARTChannelStateChange *> *internalEventEmitter;
@property (readonly, nonatomic) ARTEventEmitter<ARTEvent *, ARTChannelStateChange *> *statesEventEmitter;
@property (readonly, nonatomic) ARTEventEmitter<id<ARTEventIdentification>, ARTMessage *> *messagesEventEmitter;

@property (readwrite, nonatomic) BOOL attachResume;

- (instancetype)initWithRealtime:(ARTRealtimeInternal *)realtime andName:(NSString *)name withOptions:(ARTRealtimeChannelOptions *)options logger:(ARTInternalLog *)logger;

- (void)proceedAttachDetachWithParams:(ARTAttachRequestParams *)params;

- (void)_attach:(nullable ARTCallback)callback;
- (void)_detach:(nullable ARTCallback)callback;

- (void)_unsubscribe;
- (void)off_nosync;

@property (nonatomic) dispatch_queue_t queue;

@end

@interface ARTRealtimeChannelInternal (Private)

- (void)performTransitionToState:(ARTRealtimeChannelState)state withParams:(ARTChannelStateChangeParams *)params;

- (void)onChannelMessage:(ARTProtocolMessage *)message;
- (void)publishProtocolMessage:(ARTProtocolMessage *)pm callback:(ARTStatusCallback)cb;

- (void)setAttached:(ARTProtocolMessage *)message;
- (void)setDetached:(ARTProtocolMessage *)message;

- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onPresence:(ARTProtocolMessage *)message;
- (void)onSync:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)error;

- (void)setSuspended:(ARTChannelStateChangeParams *)params;
- (void)setFailed:(ARTChannelStateChangeParams *)params;

- (void)detachChannel:(ARTChannelStateChangeParams *)params;

- (void)emit:(ARTChannelEvent)event with:(ARTChannelStateChange *)data;

@end

@interface ARTRealtimeChannel ()

@property (nonatomic, readonly) ARTRealtimeChannelInternal *internal;

- (void)internalAsync:(void (^)(ARTRealtimeChannelInternal *))use;
- (void)internalSync:(void (^)(ARTRealtimeChannelInternal *))use;

- (instancetype)initWithInternal:(ARTRealtimeChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
