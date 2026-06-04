@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 An instant on a continuous clock; that is, a clock which keeps incrementing while the system is asleep.

 An instant is an opaque value type: code compares instants and derives new instants from them by
 adding durations, but does not depend on the underlying representation.

 - Note: This protocol is named with a `Protocol` suffix to distinguish it from the concrete
   `ARTContinuousClockInstant` class (the `ARTSystemTimeProvider`'s instant type) that conforms to it.
 */
NS_SWIFT_NAME(ContinuousClockInstant)
NS_SWIFT_SENDABLE
@protocol ARTContinuousClockInstantProtocol <NSObject>

/// Returns `YES` if the receiver represents a later moment than `other`.
- (BOOL)isAfter:(id<ARTContinuousClockInstantProtocol>)other;

/// Returns a new instant representing the receiver advanced by `duration` seconds.
- (id<ARTContinuousClockInstantProtocol>)addingDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
