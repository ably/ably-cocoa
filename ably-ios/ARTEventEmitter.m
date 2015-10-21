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

@property (readonly, weak, nonatomic) ARTRealtime * realtime;

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
    ARTRealtimeConnectionStateSubscription *subscription = [[ARTRealtimeConnectionStateSubscription alloc] initWithRealtime:self.realtime cb:cb];
    [self.realtime.stateSubscriptions addObject:subscription];
    cb(self.realtime.state);
    return subscription;
}

- (id<ARTSubscription>)on {
    return nil;
}

- (void)test {
    
}

@end
