#import <Ably/ARTPushChannel.h>
#import <Ably/ARTQueuedDealloc.h>

@class ARTRestInternal;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannelInternal : NSObject <ARTPushChannelProtocol>

- (instancetype)init:(ARTRestInternal *)rest withChannel:(ARTChannel *)channel logger:(ARTInternalLog *)logger;

@end

@interface ARTPushChannel ()

@property (nonatomic, readonly) ARTPushChannelInternal *internal;

- (instancetype)initWithInternal:(ARTPushChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
