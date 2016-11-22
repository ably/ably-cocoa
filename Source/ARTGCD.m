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
