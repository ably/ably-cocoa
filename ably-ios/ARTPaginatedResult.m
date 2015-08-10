//
//  ARTPaginatedResult.m
//  ably
//
//  Created by Yavor Georgiev on 10.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPaginatedResult.h"

@implementation ARTPaginatedResult

- (void)getFirst:(ARTPaginatedResultCallback)callback {
    NSAssert(false, @"-[ARTPaginatedResult getFirst] should always be overriden.");
}

- (void)getCurrent:(ARTPaginatedResultCallback)callback {
    NSAssert(false, @"-[ARTPaginatedResult getCurrent] should always be overriden.");
}

- (void)getNext:(ARTPaginatedResultCallback)callback {
    NSAssert(false, @"-[ARTPaginatedResult getNext] should always be overriden.");
}

@end
