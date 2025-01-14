#import <Ably/ARTPushChannelSubscriptions.h>
#import <Ably/ARTQueuedDealloc.h>

@class ARTRestInternal;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannelSubscriptionsInternal : NSObject <ARTPushChannelSubscriptionsProtocol>

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

@end

@interface ARTPushChannelSubscriptions ()

@property (nonatomic, readonly) ARTPushChannelSubscriptionsInternal *internal;

- (instancetype)initWithInternal:(ARTPushChannelSubscriptionsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
