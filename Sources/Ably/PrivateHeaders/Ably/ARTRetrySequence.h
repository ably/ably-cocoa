@import Foundation;

@protocol ARTRetryDelayCalculator;
@class ARTRetryAttempt;

NS_ASSUME_NONNULL_BEGIN

/**
 Consider an operation which can fail. If we attempt to perform the operation and it fails, we may wish to start performing a sequence of retries, until success or some other termination condition is achieved. An `ARTRetrySequence` keeps track of the number of retries that have been attempted. Each time its `addRetryAttempt` method is called, it increments its retry count, and returns an `ARTRetryAttempt` which describes the duration that we should wait before performing the retry of the operation.
 */
NS_SWIFT_NAME(RetrySequence)
@interface ARTRetrySequence: NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates a new retry sequence representing an operation which has not yet been retried.

 Parameters:
    - delayCalculator: The retry delay calculator used to calculate the duration after which each retry attempt should be performed.
 */
- (instancetype)initWithDelayCalculator:(id<ARTRetryDelayCalculator>)delayCalculator NS_DESIGNATED_INITIALIZER;

/**
 A unique identifier for this retry sequence, for logging purposes.
 */
@property (nonatomic, readonly) NSUUID *id;

/**
 Informs the receiver that we intend to schedule another retry of the operation. Increments the sequence’s retry count and returns an `ARTRetryAttempt` object which describes how long we should wait before performing this retry.
 */
- (ARTRetryAttempt *)addRetryAttempt;

@end

/**
 Describes an intention to retry an operation.
 */
NS_SWIFT_NAME(RetryAttempt)
@interface ARTRetryAttempt: NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 A unique identifier for this retry attempt, for logging purposes.
 */
@property (nonatomic, readonly) NSUUID *id;

/**
 The duration that should we should wait before performing this retry of the operation.
 */
@property (nonatomic, readonly) NSTimeInterval delay;

@end

NS_ASSUME_NONNULL_END
