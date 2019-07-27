//
//  ARTFlushable.m
//  Ably
//
//  Created by Toni Cárdenas on 27/07/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

#import "ARTFlusher.h"

@implementation ARTFlusher {
    NSMutableSet<id<ARTFlushable>> *_flushables;
}

- (instancetype)init {
    if (self = [super init]) {
        _flushables = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)add:(id<ARTFlushable>)flushable {
    [self->_flushables addObject:flushable];
}

- (void)remove:(id<ARTFlushable>)flushable {
    [self->_flushables removeObject:flushable];
}

- (void)flush {
    for (id<ARTFlushable> flushable in _flushables) {
        [flushable flush];
    }
}

@end
