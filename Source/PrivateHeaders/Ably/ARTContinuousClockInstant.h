@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 An instant on a continuous clock; that is, a clock which keeps incrementing while the system is asleep.

 An instant is an opaque value type: code compares instants and derives new instants from them by
 adding durations, but does not depend on the underlying representation. The default implementation,
 `ARTSystemContinuousClockInstant`, is private to `ARTSystemTimeProvider`.
 */
NS_SWIFT_NAME(ContinuousClockInstant)
NS_SWIFT_SENDABLE
@protocol ARTContinuousClockInstant <NSObject>

/// Returns `YES` if the receiver represents a later moment than `other`.
- (BOOL)isAfter:(id<ARTContinuousClockInstant>)other NS_SWIFT_NAME(isAfter(_:));

/// Returns a new instant representing the receiver advanced by `duration` seconds.
- (id<ARTContinuousClockInstant>)addingDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
