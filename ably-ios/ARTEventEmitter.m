//
//  ARTEventEmitter.m
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTEventEmitter.h"

#import "ARTRealtime.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimeChannelSubscription.h"

@interface ARTEventEmitter ()

@property (readonly, weak, nonatomic) ARTRealtime *realtime;

@end

@implementation ARTEventEmitter

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
    self = [super init];
    if(self) {
        _realtime = realtime;
    }
    return self;
}

- (id<ARTSubscription>)on:(ARTRealtimeConnectionStateCb)cb {
    // TODO: more protection, callback can be nil!
    ARTRealtimeConnectionStateSubscription *subscription = [[ARTRealtimeConnectionStateSubscription alloc] initWithRealtime:self.realtime cb:cb];
    [self.realtime.stateSubscriptions addObject:subscription];
    cb(self.realtime.state, nil);
    return subscription;
}

- (void)removeEvents {
    [self.realtime.stateSubscriptions removeAllObjects];
}

@end
