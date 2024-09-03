#import "ARTPush.h"
#import "ARTDevicePushDetails.h"
#import "ARTDevicePushDetails+Private.h"

@implementation ARTDevicePushDetails

- (instancetype)init {
    if (self = [super init]) {
        _recipient = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTDevicePushDetails *push = [[[self class] allocWithZone:zone] init];

    push.recipient = [self.recipient copy];
    push.state = self.state;
    push.errorReason = [self.errorReason copy];

    return push;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t recipient: %@; \n\t state: %@; \n\t errorReason: %@;", [super description], self.recipient, self.state, self.errorReason];
}

@end
