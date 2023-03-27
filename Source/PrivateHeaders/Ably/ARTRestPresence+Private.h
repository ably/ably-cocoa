#import <Ably/ARTRestPresence.h>
#import "ARTQueuedDealloc.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTRestChannelInternal;

@interface ARTRestPresenceInternal : ARTPresence <ARTRestPresenceProtocol>

- (instancetype)initWithChannel:(ARTRestChannelInternal *)channel;

@end

@interface ARTRestPresence ()

@property (nonatomic, readonly) ARTRestPresenceInternal *internal;

- (instancetype)initWithInternal:(ARTRestPresenceInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
