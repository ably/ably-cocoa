#import "ARTMessageFilter.h"

@implementation ARTMessageFilter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.name = nil;
        self.clientId = nil;
        self.isRef = nil;
        self.refType = nil;
        self.refTimeserial = nil;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ARTMessageFilter *filter = [[[self class] allocWithZone:zone] init];
    filter.name = self.name;
    filter.clientId = self.clientId;
    filter.isRef = self.isRef;
    filter.refTimeserial = self.refTimeserial;
    filter.refType = self.refType;

    return filter;
}

@end
