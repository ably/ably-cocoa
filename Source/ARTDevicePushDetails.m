#import "ARTDevicePushDetails.h"
#import "ARTDevicePushDetails+Private.h"
#import "ARTPush.h"

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

- (NSString *)stateString {
    switch (_state) {
        case ARTPushStateActive:
            return @"Active";
        case ARTPushStateFailing:
            return @"Failing";
        case ARTPushStateFailed:
            return @"Failed";
        default:
            return @"Unknown";
    }
}

+ (ARTPushState)stateFromString:(NSString *)string {
    string = string.lowercaseString;
    if ([string isEqualToString:@"active"]) {
        return ARTPushStateActive;
    }
    else if ([string isEqualToString:@"failing"]) {
        return ARTPushStateFailing;
    }
    else if ([string isEqualToString:@"failed"]) {
        return ARTPushStateFailed;
    }
    return ARTPushStateUnknown;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t recipient: %@; \n\t state: %@; \n\t errorReason: %@;", [super description], self.recipient, self.stateString, self.errorReason];
}

@end
