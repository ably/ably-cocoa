//
//  ARTPaginatedResult.m
//  ably
//
//  Created by Yavor Georgiev on 10.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPaginatedResult.h"

@implementation ARTPaginatedResult

- (void)first:(ARTPaginatedResultCallback)callback {
    NSAssert(false, @"-[ARTPaginatedResult first] should always be overriden.");
}

- (void)current:(ARTPaginatedResultCallback)callback {
    NSAssert(false, @"-[ARTPaginatedResult current] should always be overriden.");
}

- (void)next:(ARTPaginatedResultCallback)callback {
    NSAssert(false, @"-[ARTPaginatedResult next] should always be overriden.");
}

- (BOOL)isLast {
    return !self.hasNext;
}

@end
