#import "ARTFallback+Private.h"

#import "ARTDefault+Private.h"
#import "ARTStatus.h"
#import "ARTHttp.h"

void (^const ARTFallback_shuffleArray)(NSMutableArray *) = ^void(NSMutableArray *a) {
    for (NSUInteger i = a.count; i > 1; i--) {
        [a exchangeObjectAtIndex:i - 1 withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
    }
};

@interface ARTFallback ()

@end

@implementation ARTFallback

- (instancetype)initWithFallbackHosts:(nullable NSArray<NSString *> *)fallbackHosts shuffleArray:(void (^)(NSMutableArray *))shuffleArray {
    self = [super init];
    if (self) {
        if (fallbackHosts == nil || fallbackHosts.count == 0) {
            return nil;
        }
        self.hosts = [[NSMutableArray alloc] initWithArray:fallbackHosts];
        shuffleArray(self.hosts);
    }
    return self;
}

- (NSString *)popFallbackHost {
    if ([self.hosts count] == 0) {
        return nil;
    }
    NSString *host = [self.hosts lastObject];
    [self.hosts removeLastObject];
    return host;
}

@end
