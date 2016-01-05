//
//  ARTEventEmitter.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@protocol ARTSubscription;

@class ARTRealtime;

@interface ARTEventEmitter : NSObject

- (instancetype)initWithRealtime:(ARTRealtime *)realtime;
- (id<ARTSubscription>)on:(ARTRealtimeConnectionStateCb)cb;
- (void)removeEvents;

@end
