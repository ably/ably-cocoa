#import "ARTTestClientOptions.h"
#import "ARTDefault.h"
#import "ARTFallback+Private.h"
#import "ARTRealtimeTransportFactory.h"
#import "ARTJitterCoefficientGenerator.h"

@implementation ARTTestClientOptions

- (instancetype)init {
    if (self = [super init]) {
        _realtimeRequestTimeout = [ARTDefault realtimeRequestTimeout];
        _shuffleArray = ARTFallback_shuffleArray;
        _transportFactory = [[ARTDefaultRealtimeTransportFactory alloc] init];
        _jitterCoefficientGenerator = [[ARTDefaultJitterCoefficientGenerator alloc] init];
    }

    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ARTTestClientOptions *const copied = [[ARTTestClientOptions alloc] init];
    copied.channelNamePrefix = self.channelNamePrefix;
    copied.realtimeRequestTimeout = self.realtimeRequestTimeout;
    copied.shuffleArray = self.shuffleArray;
    copied.transportFactory = self.transportFactory;
    copied.reconnectionRealtimeHost = self.reconnectionRealtimeHost;
    copied.jitterCoefficientGenerator = self.jitterCoefficientGenerator;

    return copied;
}

@end
