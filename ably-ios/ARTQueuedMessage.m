//
//  ARTQueuedMessage.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTQueuedMessage.h"

#import "ARTProtocolMessage.h"

@implementation ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb {
    self = [super init];
    if (self) {
        _msg = msg;
        _cbs = [NSMutableArray array];
        if (cb) {
            [_cbs addObject:cb];
        }
    }
    return self;
}

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg cb:(ARTStatusCallback)cb {
    if ([self.msg mergeFrom:msg]) {
        if (cb) {
            [self.cbs addObject:cb];
        }
        return YES;
    }
    return NO;
}

- (ARTStatusCallback)cb {
    return ^(ARTStatus * status) {
        for (ARTStatusCallback cb in self.cbs) {
            cb(status);
        }
    };
}

@end
