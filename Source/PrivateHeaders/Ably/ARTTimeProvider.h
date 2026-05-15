@import Foundation;
@import _AblyPluginSupportPrivate;

NS_ASSUME_NONNULL_BEGIN

/**
 The unified abstraction over all time-dependent primitives used by ably-cocoa's internal code.

 All time-dependent code in ably-cocoa MUST go through an injected `ARTTimeProvider` rather than calling clock or scheduler primitives directly. This indirection allows the Universal Test Suite to install a fake-time implementation that controls all clock-dependent behaviour across both ably-cocoa and any plugins.

 See ably-cocoa's `CONTRIBUTING.md` for details on what is and is not permitted in new code.
 */
@protocol ARTTimeProvider <NSObject>

/**
 Returns the current wall-clock time; equivalent to `[NSDate date]` when using the default `ARTSystemTimeProvider`.
 */
- (NSDate *)wallClockNow;

/**
 Returns the current instant on a continuous clock (a clock which keeps incrementing while the system is asleep).
 */
- (id<APContinuousClockInstant>)continuousClockNow;

/**
 Schedules `block` for execution on `queue` after `delay` seconds.

 Returns a handle that may be used to cancel the scheduled execution before it fires.
 */
- (id<APSchedulerHandle>)scheduleAfter:(NSTimeInterval)delay
                                 queue:(dispatch_queue_t)queue
                                 block:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
