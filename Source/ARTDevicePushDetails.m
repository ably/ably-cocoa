#import "ARTDevicePushDetails.h"
#import "ARTPush.h"

@implementation ARTDevicePushStatus

- (instancetype)init {
    if (self = [super init]) {
        //
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTDevicePushStatus *push = [[[self class] allocWithZone:zone] init];
    push.state = self.state;
    push.errorReason = [self.errorReason copy];
    return push;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t state: %@; \n\t errorReason: %@;", [super description], self.state, self.errorReason];
}

@end

@implementation ARTDeviceDetailsResponse

- (instancetype)init {
    if (self = [super init]) {
        //
    }
    return self;
}

@end
