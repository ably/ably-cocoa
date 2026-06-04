#import <Foundation/Foundation.h>
#import "ARTSchedulerHandle.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A handle to a block scheduled via `-[ARTTimeProvider scheduleAfter:queue:block:]` (when backed by `ARTSystemTimeProvider`).

 Conforms to `ARTSchedulerHandle` so that handles may be returned across the `ARTTimeProvider` boundary.
 */
@interface ARTScheduledBlockHandle : NSObject <ARTSchedulerHandle>
- (instancetype)initWithDelay:(NSTimeInterval)delay queue:(dispatch_queue_t)queue block:(dispatch_block_t)block;
- (void)cancel;
@end

/// Like `dispatch_sync`, but throws an `NSException` if the queue is `nil` at runtime.
///
/// This is to aid in debugging client crash reports (if you pass a `nil` queue to `dispatch_sync` you get a rather opaque `EXC_BAD_ACCESS`).
void art_dispatch_sync(dispatch_queue_t queue, DISPATCH_NOESCAPE dispatch_block_t block);

/// Like `dispatch_async`, but throws an `NSException` if the queue is `nil` at runtime.
///
/// This is to aid in debugging client crash reports (if you pass a `nil` block to `dispatch_async` you get a rather opaque `EXC_BAD_ACCESS`).
void art_dispatch_async(dispatch_queue_t queue, dispatch_block_t block);

NS_ASSUME_NONNULL_END
