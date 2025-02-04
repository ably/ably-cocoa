#import <Ably/ARTPushChannelSubscriptions.h>
#import <Ably/ARTQueuedDealloc.h>

@class ARTRestInternal;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannelSubscriptionsInternal : NSObject

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

- (void)save:(ARTPushChannelSubscription *)channelSubscription callback:(ARTCallback)callback;

- (void)listChannels:(ARTPaginatedTextCallback)callback;

- (void)list:(NSStringDictionary *)params callback:(ARTPaginatedPushChannelCallback)callback;

- (void)remove:(ARTPushChannelSubscription *)subscription callback:(ARTCallback)callback;

- (void)removeWhere:(NSStringDictionary *)params callback:(ARTCallback)callback;

@end

@interface ARTPushChannelSubscriptions ()

@property (nonatomic, readonly) ARTPushChannelSubscriptionsInternal *internal;

- (instancetype)initWithInternal:(ARTPushChannelSubscriptionsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
