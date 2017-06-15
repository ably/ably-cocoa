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
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

// artDispatchSync is like dispatch_sync, but if the a thread attempts to
// dispatch_sync to a queue to which it already is dispatch_syncinc, it calls
// the block right away.
void artDispatchSync(dispatch_queue_t queue, dispatch_block_t block) {
    NSString *queueName = [NSString stringWithUTF8String:dispatch_queue_get_label(queue)];
    
    static NSMutableDictionary<NSString *, NSMutableSet<NSThread *> *> *threadsUsingQueues;
    // threadsUsingQueuesOps is the serial queue we use to operate on threadsUsingQueues,
    // to avoid concurrent operations on it.
    static dispatch_queue_t threadsUsingQueuesOps;

    // Initialize locks set and its queue.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        threadsUsingQueues = [[NSMutableDictionary alloc] init];
        threadsUsingQueuesOps = dispatch_queue_create("io.ably.artDispatchSync.threadsUsingQueuesOps", DISPATCH_QUEUE_SERIAL);
    });

    bool __block queueIsUsedByThisThread = false;

    dispatch_sync(threadsUsingQueuesOps, ^{
        NSMutableSet<NSThread *> *threads = threadsUsingQueues[queueName];
        if (!threads) {
            threads = [[NSMutableSet alloc] init];
            threadsUsingQueues[queueName] = threads;
        } else if ([threads containsObject:[NSThread currentThread]]) {
            queueIsUsedByThisThread = true;
            return;
        }
        [threads addObject:[NSThread currentThread]];
    });

    if (queueIsUsedByThisThread) {
        block();
    } else {
        dispatch_sync(queue, ^{
            @try {
                block();
            } @finally {
                dispatch_sync(threadsUsingQueuesOps, ^{
                    NSMutableSet<NSThread *> *threads = threadsUsingQueues[queueName];
                    [threads removeObject:[NSThread currentThread]];
                    if ([threads count] == 0) {
                        [threadsUsingQueues removeObjectForKey:queueName];
                    }
                });
            }
        });
    }
}
