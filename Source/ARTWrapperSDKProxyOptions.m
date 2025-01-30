#import "ARTWrapperSDKProxyOptions.h"

@implementation ARTWrapperSDKProxyOptions

- (instancetype)initWithAgents:(nullable NSDictionary<NSString *,NSString *> *)agents {
    if (self = [super init]) {
        _agents = [agents copy];
    }

    return self;
}

@end
