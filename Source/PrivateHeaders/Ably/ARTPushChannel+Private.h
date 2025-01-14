#import <Ably/ARTPushChannel.h>
#import <Ably/ARTQueuedDealloc.h>

@class ARTRestInternal;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannelInternal : NSObject

- (instancetype)init:(ARTRestInternal *)rest withChannel:(ARTChannel *)channel logger:(ARTInternalLog *)logger;

- (void)subscribeDevice;

- (void)subscribeDevice:(nullable ARTCallback)callback;

- (void)subscribeClient;

- (void)subscribeClient:(nullable ARTCallback)callback;

- (void)unsubscribeDevice;

- (void)unsubscribeDevice:(nullable ARTCallback)callback;

- (void)unsubscribeClient;

- (void)unsubscribeClient:(nullable ARTCallback)callback;

- (BOOL)listSubscriptions:(NSStringDictionary *)params
                 callback:(ARTPaginatedPushChannelCallback)callback
                    error:(NSError *_Nullable *_Nullable)errorPtr;

@end

@interface ARTPushChannel ()

@property (nonatomic, readonly) ARTPushChannelInternal *internal;

- (instancetype)initWithInternal:(ARTPushChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
