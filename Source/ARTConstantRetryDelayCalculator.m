#import "ARTConstantRetryDelayCalculator.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTConstantRetryDelayCalculator ()

@property (nonatomic, readonly) NSTimeInterval constantDelay;

@end

NS_ASSUME_NONNULL_END

@implementation ARTConstantRetryDelayCalculator

- (instancetype)initWithConstantDelay:(NSTimeInterval)constantDelay {
    if (self = [super init]) {
        _constantDelay = constantDelay;
    }

    return self;
}

- (NSTimeInterval)delayForRetryNumber:(NSInteger)retryNumber {
    return self.constantDelay;
}

@end
