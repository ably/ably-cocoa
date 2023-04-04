#import "ARTTestClientOptions.h"

@implementation ARTTestClientOptions

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ARTTestClientOptions *const copied = [[ARTTestClientOptions alloc] init];
    copied.channelNamePrefix = self.channelNamePrefix;

    return copied;
}

@end
