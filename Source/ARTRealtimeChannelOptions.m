#import "ARTRealtimeChannelOptions.h"
#import "ARTChannelOptions+Private.h"

@implementation ARTRealtimeChannelOptions {
    NSStringDictionary *_params;
    ARTChannelMode _modes;
}

- (NSStringDictionary *)params {
    return _params;
}

- (void)setParams:(NSStringDictionary *)params {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change options after you've passed it to receiver.", self.class]
                                     userInfo:nil];
    }
    _params = params;
}

- (ARTChannelMode)modes {
    return _modes;
}

- (void)setModes:(ARTChannelMode)modes {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change options after you've passed it to receiver.", self.class]
                                     userInfo:nil];
    }
    _modes = modes;
}

@end
