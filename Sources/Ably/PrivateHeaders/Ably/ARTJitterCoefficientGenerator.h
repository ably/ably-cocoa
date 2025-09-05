@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 An object which generates the random "jitter coefficient" used to determine when the library will next retry an operation.
 */
NS_SWIFT_NAME(JitterCoefficientGenerator)
@protocol ARTJitterCoefficientGenerator

/**
 Generates a random number (approximately uniformly distributed) in the range [0.8, 1], as required by RTB1b.

 Test implementations of `ARTJitterCoefficientGenerator` may return a non-random number.
 */
- (double)generateJitterCoefficient;

@end

/**
 The implementation of `ARTJitterCoefficientGenerator` that should be used in non-test code.
 */
NS_SWIFT_NAME(DefaultJitterCoefficientGenerator)
@interface ARTDefaultJitterCoefficientGenerator: NSObject<ARTJitterCoefficientGenerator>
@end

NS_ASSUME_NONNULL_END
