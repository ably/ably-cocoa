#import "ARTRetrySequence.h"
#import "ARTRetryDelayCalculator.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTRetryAttempt ()

- (instancetype)initWithDelay:(NSTimeInterval)delay NS_DESIGNATED_INITIALIZER;

@end

@interface ARTRetrySequence ()

@property (nonatomic, readonly) id<ARTRetryDelayCalculator> delayCalculator;
// Starts off as zero, incremented each time -addRetryAttempt is called
@property (nonatomic) NSInteger retryCount;

@end

NS_ASSUME_NONNULL_END

@implementation ARTRetrySequence

- (instancetype)initWithDelayCalculator:(id<ARTRetryDelayCalculator>)delayCalculator {
    if (self = [super init]) {
        _id = [NSUUID UUID];
        _delayCalculator = delayCalculator;
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p: id: %@, retryCount: %ld>", [self class], self, self.id, (long)self.retryCount];
}

- (ARTRetryAttempt *)addRetryAttempt {
    self.retryCount += 1;
    const NSTimeInterval delay = [self.delayCalculator delayForRetryNumber:self.retryCount];

    return [[ARTRetryAttempt alloc] initWithDelay:delay];
}

@end

@implementation ARTRetryAttempt

- (instancetype)initWithDelay:(NSTimeInterval)delay {
    if (self = [super init]) {
        _id = [NSUUID UUID];
        _delay = delay;
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p: id: %@, delay: %.2f>", [self class], self, self.id, self.delay];
}

@end
