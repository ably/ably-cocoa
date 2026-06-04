@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 A handle to a block scheduled via `-[ARTTimeProvider scheduleAfter:queue:block:]`.

 Calling `cancel` prevents the block from running if it has not already fired. It is safe to call
 `cancel` after the block has fired.
 */
NS_SWIFT_NAME(SchedulerHandle)
NS_SWIFT_SENDABLE
@protocol ARTSchedulerHandle <NSObject>

/// Prevents the scheduled block from running, if it has not already fired.
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
