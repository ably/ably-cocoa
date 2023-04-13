#import <Ably/ARTPushChannel.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;
@class ARTInternalLog;

@interface ARTPushChannelInternal : NSObject <ARTPushChannelProtocol>

- (instancetype)init:(ARTRestInternal *)rest withChannel:(ARTChannel *)channel logger:(ARTInternalLog *)logger;

@end

@interface ARTPushChannel ()

@property (nonatomic, readonly) ARTPushChannelInternal *internal;

- (instancetype)initWithInternal:(ARTPushChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end
