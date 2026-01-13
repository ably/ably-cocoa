#import "ARTUpdateDeleteResult.h"

@implementation ARTUpdateDeleteResult

- (instancetype)initWithVersionSerial:(nullable NSString *)versionSerial {
    if (self = [super init]) {
        _versionSerial = versionSerial;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> { versionSerial: %@ }", self.class, self, self.versionSerial ?: @"nil"];
}

@end
