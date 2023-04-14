#import "ARTTestClientOptions.h"
#import "ARTDefault.h"
#import "ARTFallback+Private.h"
#import "ARTRealtimeTransportFactory.h"
#import "ARTLocalDeviceFetcher.h"

@implementation ARTTestClientOptions

- (instancetype)init {
    if (self = [super init]) {
        _realtimeRequestTimeout = [ARTDefault realtimeRequestTimeout];
        _shuffleArray = ARTFallback_shuffleArray;
        _transportFactory = [[ARTDefaultRealtimeTransportFactory alloc] init];
        _localDeviceFetcher = ARTDefaultLocalDeviceFetcher.sharedInstance;
    }

    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ARTTestClientOptions *const copied = [[ARTTestClientOptions alloc] init];
    copied.channelNamePrefix = self.channelNamePrefix;
    copied.realtimeRequestTimeout = self.realtimeRequestTimeout;
    copied.shuffleArray = self.shuffleArray;
    copied.transportFactory = self.transportFactory;
    copied.localDeviceFetcher = self.localDeviceFetcher;

    return copied;
}

@end
