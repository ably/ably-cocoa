@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 Consider an operation which can fail. If we attempt to perform the operation and it fails, we may wish to start performing a sequence of retries, until success or some other termination condition is achieved. An `ARTRetryDelayCalculator` describes the amount of time that we wish to wait before performing each retry in this sequence.
 */
NS_SWIFT_NAME(RetryDelayCalculator)
@protocol ARTRetryDelayCalculator

/**
 Returns the duration that should be waited before performing a retry of the operation.

 - Parameters:
   - retryNumber: The ordinal of the retry in the retry sequence, greater than or equal to 1. After the first attempt at the operation fails, the subsequent attempt is considered retry number 1.

     What constitutes the "first attempt" is for the caller to decide.
 */
- (NSTimeInterval)delayForRetryNumber:(NSInteger)retryNumber;

@end

NS_ASSUME_NONNULL_END
