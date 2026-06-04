#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Like `dispatch_sync`, but throws an `NSException` if the queue is `nil` at runtime.
///
/// This is to aid in debugging client crash reports (if you pass a `nil` queue to `dispatch_sync` you get a rather opaque `EXC_BAD_ACCESS`).
void art_dispatch_sync(dispatch_queue_t queue, DISPATCH_NOESCAPE dispatch_block_t block);

/// Like `dispatch_async`, but throws an `NSException` if the queue is `nil` at runtime.
///
/// This is to aid in debugging client crash reports (if you pass a `nil` block to `dispatch_async` you get a rather opaque `EXC_BAD_ACCESS`).
void art_dispatch_async(dispatch_queue_t queue, dispatch_block_t block);

NS_ASSUME_NONNULL_END
