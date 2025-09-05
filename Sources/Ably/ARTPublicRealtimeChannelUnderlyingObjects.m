#import "ARTPublicRealtimeChannelUnderlyingObjects.h"

@implementation APDefaultPublicRealtimeChannelUnderlyingObjects

@synthesize client = _client;
@synthesize channel = _channel;

- (instancetype)initWithClient:(id<APRealtimeClient>)client channel:(id<APRealtimeChannel>)channel {
    if (self = [super init]) {
        _client = client;
        _channel = channel;
    }

    return self;
}

@end
