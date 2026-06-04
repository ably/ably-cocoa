@import Foundation;
#import "ARTContinuousClockInstantProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The concrete implementation of `ARTContinuousClockInstantProtocol` used by `ARTSystemTimeProvider`.

 Represents an instant on a continuous clock — a clock that keeps incrementing while the system is asleep.

 - Note: We don't give this an `NS_SWIFT_NAME`, to avoid confusion with the Swift standard library type also named `ContinuousClock`.
 */
@interface ARTContinuousClockInstant: NSObject <ARTContinuousClockInstantProtocol>

- (instancetype)init NS_UNAVAILABLE;

/**
 Designated initialiser; `time` is a value in the same units as `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)`.
 */
- (instancetype)initWithTime:(uint64_t)time NS_DESIGNATED_INITIALIZER;

/**
 Returns `YES` if and only if the instant in time represented by the receiver occurs after that represented by `other`.
 */
- (BOOL)isAfter:(id<ARTContinuousClockInstantProtocol>)other;

/**
 Returns a new instant representing the receiver advanced by `duration` seconds.
 */
- (id<ARTContinuousClockInstantProtocol>)addingDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
