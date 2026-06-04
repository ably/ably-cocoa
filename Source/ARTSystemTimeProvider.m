#import "ARTSystemTimeProvider.h"
#import "ARTContinuousClock.h"
#import "ARTGCD.h"

@implementation ARTSystemTimeProvider

- (NSDate *)wallClockNow {
    return [NSDate date];
}

- (id<ARTContinuousClockInstantProtocol>)continuousClockNow {
    const uint64_t time = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW);
    return [[ARTContinuousClockInstant alloc] initWithTime:time];
}

- (id<ARTSchedulerHandle>)scheduleAfter:(NSTimeInterval)delay
                                 queue:(dispatch_queue_t)queue
                                 block:(dispatch_block_t)block {
    return [[ARTScheduledBlockHandle alloc] initWithDelay:delay queue:queue block:block];
}

@end
