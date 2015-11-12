//
//  ARTPresence.m
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPresence.h"

#import "ARTChannel.h"

@interface ARTPresence () {
    ARTChannel *_channel;
}

@end

@implementation ARTPresence

- (instancetype) initWithChannel:(ARTChannel *) channel {
    if (self = [super init]) {
        _channel = channel;
    }
    return self;
}

- (ARTChannel *)getChannel {
    return _channel;
}

- (void)get:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *result, NSError *error))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)history:(ARTDataQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTPresenceMessage *> */ *result, NSError *error))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
