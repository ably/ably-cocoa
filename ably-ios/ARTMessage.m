//
//  ARTMessage.m
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTMessage.h"

@implementation ARTMessage

- (instancetype)initWithData:(id)data name:(NSString *)name {
    if (self = [self init]) {
        _name = [name copy];
        if (data) {
            // FIXME:
            //_payload = nil; //[ARTPayload payloadWithPayload:data encoding:@""];
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessage *message = [super init];
    message->_name = self.name;
    return message;
}

@end
