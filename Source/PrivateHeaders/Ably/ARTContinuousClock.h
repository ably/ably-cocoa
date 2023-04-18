@import Foundation;

@class ARTContinuousClockInstant;

NS_ASSUME_NONNULL_BEGIN

/**
 A clock that increments monotonically, including while the system is asleep.

 - Note: We don't give this one an `NS_SWIFT_NAME`, to avoid confusion with the Swift standard library type also named `ContinuousClock`.
 */
@interface ARTContinuousClock: NSObject

/**
 Returns the current instant in time.
 */
- (ARTContinuousClockInstant *)now;

/**
 Returns the instant in time that occurs after a given duration has elapsed in relation to a given instant in time.
 */
- (ARTContinuousClockInstant *)addingDuration:(NSTimeInterval)duration toInstant:(ARTContinuousClockInstant *)instant;

@end

/**
 Represents an instant in time, as described by an instance of `ARTContinuousClock`.
 */
@interface ARTContinuousClockInstant: NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns `YES` if and only if the instant in time represented by `other` occurs after that represented by the receiver.
 */
- (BOOL)isAfter:(ARTContinuousClockInstant *)other NS_SWIFT_NAME(isAfter(_:));

@end

NS_ASSUME_NONNULL_END
