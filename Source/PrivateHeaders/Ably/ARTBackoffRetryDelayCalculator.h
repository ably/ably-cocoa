@import Foundation;
#import <Ably/ARTRetryDelayCalculator.h>

@protocol ARTJitterCoefficientGenerator;

NS_ASSUME_NONNULL_BEGIN

/**
 An implementation of `ARTRetryDelayCalculator` which uses the incremental backoff and jitter rules of RTB1.
 */
NS_SWIFT_NAME(BackoffRetryDelayCalculator)
@interface ARTBackoffRetryDelayCalculator: NSObject <ARTRetryDelayCalculator>

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates an instance of `ARTRetryDelayCalculator`.

 - Parameters:
   - initialRetryTimeout: The initial retry timeout, as defined by RTB1.
   - jitterCoefficientGenerator: An object to use for generating the jitter coefficients.
 */
- (instancetype)initWithInitialRetryTimeout:(NSTimeInterval)initialRetryTimeout
                 jitterCoefficientGenerator:(id<ARTJitterCoefficientGenerator>)jitterCoefficientGenerator;

@end

NS_ASSUME_NONNULL_END
