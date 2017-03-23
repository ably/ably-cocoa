//
//  ARTGCD.m
//  Ably
//
//  Created by Ricardo Pereira on 17/11/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "ARTGCD.h"

// Use `dispatch_queue_set_specific` and `dispatch_get_specific` to check if our code is running on the main queue over using NSThread.isMainThread()
static NSString *const ARTGCDMainQueueKey = @"io.ably.cocoa.mainQueue";
static int ARTGCDMainQueueValue = 99;

void artDispatchSpecifyMainQueue() {
    dispatch_queue_set_specific(dispatch_get_main_queue(), (__bridge const void *)ARTGCDMainQueueKey, &ARTGCDMainQueueValue, nil);
}

void artDispatchMainQueue(dispatch_block_t block) {
    int *result = (int*)dispatch_get_specific((__bridge const void *)(ARTGCDMainQueueKey));
    if (result && *result == ARTGCDMainQueueValue) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void artDispatchGlobalQueue(dispatch_block_t block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

dispatch_block_t artDispatchScheduledOnMainQueue(NSTimeInterval seconds, dispatch_block_t block) {
    return artDispatchScheduled(seconds, dispatch_get_main_queue(), block);
}

dispatch_block_t artDispatchScheduledOnGlobalQueue(NSTimeInterval seconds, dispatch_block_t block) {
    return artDispatchScheduled(seconds, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

dispatch_block_t artDispatchScheduled(NSTimeInterval seconds, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_block_t work = dispatch_block_create(0, block);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * seconds)), queue, work);
    return work;
}

void artDispatchCancel(dispatch_block_t block) {
    if (block) dispatch_block_cancel(block);
}
