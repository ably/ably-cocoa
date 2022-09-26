#import <Ably/ARTConnection.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTTypes.h>
#import "ARTQueuedDealloc.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTRealtimeInternal;

@interface ARTConnectionRecoveryKey : NSObject
@property (readwrite, strong, nonatomic) NSString *connectionKey;
@property (readwrite, assign, nonatomic) int64_t msgSerial;
@property (readwrite, strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *serials;
 
- (nullable NSString *)asJson;
+ (nullable ARTConnectionRecoveryKey *)fromJson:(NSString *)json;
@end

@interface ARTConnectionInternal : NSObject<ARTConnectionProtocol>

@property (nullable, readonly, strong, nonatomic) NSString *id;
@property (nullable, readonly, strong, nonatomic) NSString *key;
@property (readonly, assign, nonatomic) int64_t serial;
@property (readonly, assign, nonatomic) NSInteger maxMessageSize;
@property (readonly, assign, nonatomic) ARTRealtimeConnectionState state;
@property (nullable, readonly, strong, nonatomic) ARTErrorInfo *errorReason;

- (instancetype)initWithRealtime:(ARTRealtimeInternal *)realtime;

- (nullable NSString *)id_nosync;
- (nullable NSString *)key_nosync;
- (BOOL)isActive_nosync;
- (ARTRealtimeConnectionState)state_nosync;
- (nullable ARTErrorInfo *)errorReason_nosync;
- (nullable ARTErrorInfo *)error_nosync;

@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTConnectionStateChange *> *eventEmitter;
@property(weak, nonatomic) ARTRealtimeInternal* realtime; // weak because realtime owns self

- (void)setId:(NSString *_Nullable)newId;
- (void)setKey:(NSString *_Nullable)key;
- (void)setMaxMessageSize:(NSInteger)maxMessageSize;
- (void)setState:(ARTRealtimeConnectionState)state;
- (void)setErrorReason:(ARTErrorInfo *_Nullable)errorReason;

- (void)emit:(ARTRealtimeConnectionEvent)event with:(ARTConnectionStateChange *)data;

@property (readonly, nonatomic) dispatch_queue_t queue;

@end

@interface ARTConnection ()

@property (nonatomic, readonly) ARTConnectionInternal *internal;

- (instancetype)initWithInternal:(ARTConnectionInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@property (readonly) ARTConnectionInternal *internal_nosync;

@end

NS_ASSUME_NONNULL_END
