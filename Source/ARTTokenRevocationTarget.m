#import "ARTTokenRevocationTarget.h"

@implementation ARTTokenRevocationTarget
- (instancetype)initWith:(NSString *)type value:(NSString *)value {
    if (self = [super init]) {
        self.type = type;
        self.value = value;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isMemberOfClass:[ARTTokenRevocationTarget class]]) {
        ARTTokenRevocationTarget *otherTarget = object;
        return [otherTarget.type isEqualToString:self.type] && [otherTarget.value isEqualToString:self.value];
    }
    return NO;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;

    result = prime * result + [self.type hash];
    result = prime * result + [self.value hash];

    return result;
}

@end