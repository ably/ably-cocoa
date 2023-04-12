#import <Ably/ARTRest.h>
#import <Ably/ARTHttp.h>
#import "ARTRestChannels+Private.h"
#import "ARTPush+Private.h"

@protocol ARTEncoder;
@protocol ARTHTTPExecutor;
@protocol ARTDeviceStorage;
@class ARTInternalLog;
@class ARTRealtimeInternal;
@class ARTAuthInternal;

NS_ASSUME_NONNULL_BEGIN

/// ARTRest private methods that are used internally and for internal testing
@interface ARTRestInternal : NSObject <ARTRestProtocol, ARTHTTPAuthenticatedExecutor>

@property (nonatomic, readonly) ARTRestChannelsInternal *channels;
@property (nonatomic, readonly) ARTAuthInternal *auth;
@property (nonatomic, readonly) ARTPushInternal *push;
#if TARGET_OS_IOS
@property (nonnull, nonatomic, readonly, getter=device) ARTLocalDevice *device;
@property (nonnull, nonatomic, readonly, getter=device_nosync) ARTLocalDevice *device_nosync;
@property (nonatomic) id<ARTDeviceStorage> storage;
#endif

@property (nonatomic, readonly) ARTClientOptions *options;
@property (nonatomic, weak, nullable) ARTRealtimeInternal *realtime; // weak because realtime owns self
@property (readonly, nonatomic) id<ARTEncoder> defaultEncoder;
@property (readonly, nonatomic) NSString *defaultEncoding; //Content-Type
@property (readonly, nonatomic) NSDictionary<NSString *, id<ARTEncoder>> *encoders;

// Must be atomic!
@property (readwrite, atomic, nullable) NSString *prioritizedHost;

@property (nonatomic) id<ARTHTTPExecutor> httpExecutor;
@property (nonatomic, readonly, getter=getBaseUrl) NSURL *baseUrl;
@property (nullable, nonatomic, copy) NSString *currentFallbackHost;
@property (readonly, nonatomic) CFAbsoluteTime fallbackRetryExpiration;

@property (nonatomic, readonly) ARTInternalLog *logger;

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) dispatch_queue_t userQueue;

// MARK: Not accessible by tests
@property (readonly, nonatomic) ARTHttp *http;
@property (readwrite, assign, nonatomic) int fallbackCount;

- (instancetype)initWithOptions:(ARTClientOptions *)options realtime:(ARTRealtimeInternal *_Nullable)realtime;

- (nullable NSObject<ARTCancellable> *)_time:(ARTDateTimeCallback)callback;

// MARK: ARTHTTPExecutor

- (nullable NSObject<ARTCancellable> *)executeRequest:(NSURLRequest *)request completion:(nullable ARTURLRequestCallback)callback;

// MARK: Internal

- (nullable NSObject<ARTCancellable> *)executeRequest:(NSMutableURLRequest *)request
                                       withAuthOption:(ARTAuthentication)authOption
                                           completion:(ARTURLRequestCallback)callback;

- (nullable NSObject<ARTCancellable> *)internetIsUp:(void (^)(BOOL isUp))cb;

#if TARGET_OS_IOS
// This is only intended to be called from test code.
- (void)resetDeviceSingleton;
#endif

@end

@interface ARTRest ()

@property (nonatomic, readonly) ARTRestInternal *internal;

- (void)internalAsync:(void (^)(ARTRestInternal *))use;

@end

NS_ASSUME_NONNULL_END
