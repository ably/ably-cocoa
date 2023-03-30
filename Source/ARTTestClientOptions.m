#import "ARTTestClientOptions.h"
#import "ARTDefault.h"
#import "ARTJitterCoefficientGenerator.h"

@implementation ARTTestClientOptions

- (instancetype)init {
    if (self = [super init]) {
        _realtimeRequestTimeout = [ARTDefault realtimeRequestTimeout];
        _jitterCoefficientGenerator = [[ARTDefaultJitterCoefficientGenerator alloc] init];
    }

    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ARTTestClientOptions *const copied = [[ARTTestClientOptions alloc] init];
    copied.channelNamePrefix = self.channelNamePrefix;
    copied.realtimeRequestTimeout = self.realtimeRequestTimeout;
    copied.jitterCoefficientGenerator = self.jitterCoefficientGenerator;

    return copied;
}

@end
