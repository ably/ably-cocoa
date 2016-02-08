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
            self.data = data;
            self.encoding = @"";
        }
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[super description] mutableCopy];
    [description deleteCharactersInRange:NSMakeRange(description.length - (description.length>2 ? 2:0), 2)];
    [description appendFormat:@",\n"];
    [description appendFormat:@" name: %@\n", self.name];
    [description appendFormat:@"}"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessage *message = [super copyWithZone:zone];
    message->_name = self.name;
    return message;
}

+ (ARTMessage *)messageWithData:(id)data name:(NSString *)name {
    ARTMessage *message = [[ARTMessage alloc] init];
    message.name = name;
    message.data = data;
    message.encoding = @"";
    return message;
}

+ (NSArray *)messagesWithData:(NSArray *)data {
    NSMutableArray * messages =[[NSMutableArray alloc] initWithCapacity:[data count]];
    for (int i=0; i < [data count]; i++) {
        [messages addObject:[ARTMessage messageWithData:[data objectAtIndex:i] name:nil]];
    }
    return messages;
}

@end
