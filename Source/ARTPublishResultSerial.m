#import "ARTPublishResultSerial.h"
#import "ARTPublishResultSerial+Private.h"

@implementation ARTPublishResultSerial

- (instancetype)initWithValue:(nullable NSString *)value {
    if (self = [super init]) {
        _value = [value copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> { value: %@ }", self.class, self, self.value];
}

@end
