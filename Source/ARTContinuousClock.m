#import "ARTContinuousClock.h"

@interface ARTContinuousClockInstant ()

- (instancetype)initWithTime:(uint64_t)time NS_DESIGNATED_INITIALIZER;

/**
 The value returned by `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)` at this instant.

 We choose `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)` as it gives us a clock that increments whilst the system is asleep. Its use is recommended by the documentation for `mach_continuous_time`.
 */
@property (nonatomic, readonly) uint64_t timeInNanosecondsSinceClockReferenceInstant;

@end

@implementation ARTContinuousClock

- (ARTContinuousClockInstant *)now {
    const uint64_t time = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW);
    return [[ARTContinuousClockInstant alloc] initWithTime:time];
}

- (ARTContinuousClockInstant *)addingDuration:(NSTimeInterval)duration toInstant:(ARTContinuousClockInstant *)instant {
    const uint64_t time = instant.timeInNanosecondsSinceClockReferenceInstant + duration * NSEC_PER_SEC;
    return [[ARTContinuousClockInstant alloc] initWithTime:time];
}

@end

@implementation ARTContinuousClockInstant

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p: time: %"PRIu64">", [self class], self, self.timeInNanosecondsSinceClockReferenceInstant];
}

- (instancetype)initWithTime:(uint64_t)time {
    if (self = [super init]) {
        _timeInNanosecondsSinceClockReferenceInstant = time;
    }

    return self;
}

- (BOOL)isAfter:(ARTContinuousClockInstant *)other {
    return self.timeInNanosecondsSinceClockReferenceInstant > other.timeInNanosecondsSinceClockReferenceInstant;
}

@end
