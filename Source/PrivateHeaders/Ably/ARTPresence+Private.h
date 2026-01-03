#import <Ably/ARTPresence.h>
#import "ARTChannel.h"

@interface ARTPresence ()

@property (readonly, getter=getChannel) ARTChannel *channel;

- (instancetype)initWithChannel:(ARTChannel *)channel;

@end
