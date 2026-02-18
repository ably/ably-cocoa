#import <Ably/ARTPresence.h>
#import "ARTChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTPresenceQuery ()

- (NSMutableArray<NSURLQueryItem *> *)asQueryItems;

@end

@interface ARTPresence ()

@property (readonly, getter=getChannel) ARTChannel *channel;

- (instancetype)initWithChannel:(ARTChannel *)channel;

@end

NS_ASSUME_NONNULL_END
