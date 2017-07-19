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

dispatch_block_t artDispatchScheduled(NSTimeInterval seconds, dispatch_queue_t queue, dispatch_block_t block);
void artDispatchCancel(dispatch_block_t block);

#endif /* ARTGCD_h */
