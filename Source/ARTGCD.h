//
//  ARTGCD.h
//  Ably
//
//  Created by Ricardo Pereira on 17/11/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTGCD_h
#define ARTGCD_h

#import <Foundation/Foundation.h>

void artDispatchSpecifyMainQueue();
void artDispatchMainQueue(dispatch_block_t block);
void artDispatchGlobalQueue(dispatch_block_t block);
dispatch_block_t artDispatchScheduledOnMainQueue(NSTimeInterval seconds, dispatch_block_t block);
dispatch_block_t artDispatchScheduledOnGlobalQueue(NSTimeInterval seconds, dispatch_block_t block);
dispatch_block_t artDispatchScheduled(NSTimeInterval seconds, dispatch_queue_t queue, dispatch_block_t block);
void artDispatchCancel(dispatch_block_t block);
void artDispatchSync(dispatch_queue_t queue, dispatch_block_t block);

#endif /* ARTGCD_h */
