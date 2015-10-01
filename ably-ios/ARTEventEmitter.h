//
//  ARTEventEmitter.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ably.h"

@protocol ARTSubscription;

@class ARTRealtime;

@interface ARTEventEmitter : NSObject

- (instancetype)initWithRealtime:(ARTRealtime *)realtime;
- (id<ARTSubscription>)on:(ARTRealtimeConnectionStateCb)cb;

@end
