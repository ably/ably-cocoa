@import Foundation;
#import "ARTRetryDelayCalculator.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An implementation of `ARTRetryDelayCalculator` that returns the same delay for all retries.
 */
NS_SWIFT_NAME(ConstantRetryDelayCalculator)
@interface ARTConstantRetryDelayCalculator: NSObject <ARTRetryDelayCalculator>

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates a calculator whose `delayForRetryNumber:` method always returns the same value.

 - Parameters:
    - constantDelay: The constant delay to use.
 */
- (instancetype)initWithConstantDelay:(NSTimeInterval)constantDelay;

@end

NS_ASSUME_NONNULL_END
