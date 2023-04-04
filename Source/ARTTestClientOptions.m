#import "ARTTestClientOptions.h"
#import "ARTDefault.h"

@implementation ARTTestClientOptions

- (instancetype)init {
    if (self = [super init]) {
        _realtimeRequestTimeout = [ARTDefault realtimeRequestTimeout];
    }

    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ARTTestClientOptions *const copied = [[ARTTestClientOptions alloc] init];
    copied.channelNamePrefix = self.channelNamePrefix;
    copied.realtimeRequestTimeout = self.realtimeRequestTimeout;

    return copied;
}

@end
