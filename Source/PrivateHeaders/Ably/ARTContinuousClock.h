@import Foundation;
@import _AblyPluginSupportPrivate;

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

 Conforms to `APContinuousClockInstant` so that instances may cross the plugin boundary as instants of the unified clock abstraction.
 */
@interface ARTContinuousClockInstant: NSObject <APContinuousClockInstant>

- (instancetype)init NS_UNAVAILABLE;

/**
 Designated initialiser; `time` is a value in the same units as `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)`.
 */
- (instancetype)initWithTime:(uint64_t)time NS_DESIGNATED_INITIALIZER;

/**
 Returns `YES` if and only if the instant in time represented by the receiver occurs after that represented by `other`.
 */
- (BOOL)isAfter:(id<APContinuousClockInstant>)other;

/**
 Returns a new instant representing the receiver advanced by `duration` seconds.
 */
- (id<APContinuousClockInstant>)addingDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
