#import "ARTSystemTimeProvider.h"

/**
 The concrete `ARTContinuousClockInstant` produced by `ARTSystemTimeProvider`.

 Backed by `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)`, a clock that keeps incrementing while the
 system is asleep (its use is recommended by the documentation for `mach_continuous_time`).
 */
@interface ARTSystemContinuousClockInstant : NSObject <ARTContinuousClockInstant>
- (instancetype)initWithTime:(uint64_t)time;
@end

@implementation ARTSystemContinuousClockInstant {
    // The value returned by `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)` at this instant.
    uint64_t _timeInNanosecondsSinceClockReferenceInstant;
}

- (instancetype)initWithTime:(uint64_t)time {
    if (self = [super init]) {
        _timeInNanosecondsSinceClockReferenceInstant = time;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p: time: %"PRIu64">", [self class], self, _timeInNanosecondsSinceClockReferenceInstant];
}

- (BOOL)isAfter:(id<ARTContinuousClockInstant>)other {
    // `other` should in practice only ever be an instant produced by the same `ARTTimeProvider`
    // (a single client has a single time provider, and instants aren't mixed across providers).
    if (![other isKindOfClass:[ARTSystemContinuousClockInstant class]]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot compare an ARTSystemContinuousClockInstant with a %@", [other class]];
    }
    ARTSystemContinuousClockInstant *const concreteOther = (ARTSystemContinuousClockInstant *)other;
    return _timeInNanosecondsSinceClockReferenceInstant > concreteOther->_timeInNanosecondsSinceClockReferenceInstant;
}

- (id<ARTContinuousClockInstant>)addingDuration:(NSTimeInterval)duration {
    const uint64_t time = _timeInNanosecondsSinceClockReferenceInstant + duration * NSEC_PER_SEC;
    return [[ARTSystemContinuousClockInstant alloc] initWithTime:time];
}

@end

/**
 The `ARTSchedulerHandle` returned by `ARTSystemTimeProvider`, backed by `dispatch_after`.
 */
@interface ARTScheduledBlockHandle : NSObject <ARTSchedulerHandle>
- (instancetype)initWithDelay:(NSTimeInterval)delay queue:(dispatch_queue_t)queue block:(dispatch_block_t)block;
// Marked `atomic` to synchronize access to it from `_scheduledBlock` and `cancel`.
@property (atomic, copy, nullable) dispatch_block_t block;
@end

@implementation ARTScheduledBlockHandle {
    dispatch_block_t _scheduledBlock;
}

- (instancetype)initWithDelay:(NSTimeInterval)delay queue:(dispatch_queue_t)queue block:(dispatch_block_t)block {
    self = [super init];
    if (self == nil)
        return nil;

    // We don't pass the block directly; instead, we put it in a property, and
    // read it back from the property once the timer fires. This gives us the
    // chance to set the property to nil when cancelling the timer, thus
    // releasing our retain on the block early. dispatch_block_cancel doesn't do
    // this, it retains the block even if you cancel the dispatch until the
    // dispatch time passes. (How this is a good idea escapes me.)
    //
    // From Apple's documentation [1]:
    //
    // > Release of any resources associated with the block object is delayed
    // > until execution of the block object is next attempted (or any execution
    // > already in progress completes).
    //
    // [1] https://developer.apple.com/documentation/dispatch/1431058-dispatch_block_cancel

    __weak ARTScheduledBlockHandle *weakSelf = self;
    _scheduledBlock = dispatch_block_create(0, ^{
        dispatch_block_t copiedBlock = nil;
        ARTScheduledBlockHandle *strongSelf = weakSelf;
        if (strongSelf != nil) {
            copiedBlock = strongSelf.block; // copied below
        }

        // If our block is non-nil, our scheduled block was still valid by the time this was invoked
        if (copiedBlock != nil) {
            copiedBlock();
        }
    });

    self.block = block; // copied block

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * delay)), queue, _scheduledBlock);

    return self;
}

- (void)cancel {
    self.block = nil;
    dispatch_block_cancel(_scheduledBlock);
}

- (void)dealloc {
    // Explicitly cancel when we deallocate. This happens implicitly since our scheduled block keeps a weak
    // reference to self, but we want to make sure that the weak reference can be safely accessed, even if
    // we're in the midst of deallocating.
    [self cancel];
}

@end

@implementation ARTSystemTimeProvider

- (NSDate *)wallClockNow {
    return [NSDate date];
}

- (id<ARTContinuousClockInstant>)continuousClockNow {
    const uint64_t time = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW);
    return [[ARTSystemContinuousClockInstant alloc] initWithTime:time];
}

- (id<ARTSchedulerHandle>)scheduleAfter:(NSTimeInterval)delay
                                 queue:(dispatch_queue_t)queue
                                 block:(dispatch_block_t)block {
    return [[ARTScheduledBlockHandle alloc] initWithDelay:delay queue:queue block:block];
}

@end
