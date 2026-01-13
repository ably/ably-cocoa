#import "ARTPublishResult.h"
#import "ARTPublishResultSerial.h"

@implementation ARTPublishResult

- (instancetype)initWithSerials:(NSArray<ARTPublishResultSerial *> *)serials {
    if (self = [super init]) {
        _serials = serials;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> { serials: %@ }", self.class, self, self.serials];
}

@end
