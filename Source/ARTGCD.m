#import "ARTGCD.h"

void art_dispatch_sync(dispatch_queue_t queue, DISPATCH_NOESCAPE dispatch_block_t block) {
    if (!queue) {
        [NSException raise:NSInvalidArgumentException format: @"nil queue passed to art_dispatch_sync"];
    }

    dispatch_sync(queue, block);
}

void art_dispatch_async(dispatch_queue_t queue, dispatch_block_t block) {
    if (!queue) {
        [NSException raise:NSInvalidArgumentException format: @"nil queue passed to art_dispatch_async"];
    }

    dispatch_async(queue, block);
}
