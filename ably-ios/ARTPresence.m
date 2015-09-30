//
//  ARTPresence.m
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTDataQuery+Private.h"
#import "ARTPresence.h"

@implementation ARTPresenceMessage

- (id)copyWithZone:(NSZone *)zone {
    ARTPresenceMessage *message = [super copyWithZone:zone];
    message->_action = self.action;
    return message;
}

@end

@implementation ARTPresence

- (void)get:(void (^)(ARTStatus *status, ARTPaginatedResult *__nullable result))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)history:(nullable ARTDataQuery *)query callback:(void (^)(ARTStatus *status, ARTPaginatedResult *__nullable result))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
