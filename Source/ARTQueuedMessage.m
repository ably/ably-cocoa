//
//  ARTQueuedMessage.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTQueuedMessage.h"

#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"

@implementation ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb {
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

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg callback:(void (^)(ARTStatus *))cb {
    if ([self.msg mergeFrom:msg]) {
        if (cb) {
            [self.cbs addObject:cb];
        }
        return YES;
    }
    return NO;
}

- (void (^)(ARTStatus *))cb {
    return ^(ARTStatus * status) {
        for (void (^cb)(ARTStatus *) in self.cbs) {
            cb(status);
        }
    };
}

@end
