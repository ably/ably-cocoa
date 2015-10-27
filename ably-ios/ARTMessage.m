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
            self.payload = [ARTPayload payloadWithPayload:data encoding:@""];
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessage *message = [super init];
    message->_name = self.name;
    return message;
}

+ (ARTMessage *)messageWithPayload:(id)payload name:(NSString *)name {
    ARTMessage *message = [[ARTMessage alloc] init];
    message.name = name;
    message.payload = [ARTPayload payloadWithPayload:payload encoding:@""];
    return message;
}

+ (NSArray *)messagesWithPayloads:(NSArray *)payloads {
    if([payloads count] > [ARTPayload payloadArraySizeLimit]) {
        [NSException raise:@"Too many items in payload array" format:@"%lu > %lu", (unsigned long)[payloads count], [ARTPayload payloadArraySizeLimit]];
    }
    NSMutableArray * messages =[[NSMutableArray alloc] init];
    for (int i=0; i < [payloads count]; i++) {
        [messages addObject:[ARTMessage messageWithPayload:[payloads objectAtIndex:i] name:nil]];
    }
    return messages;
}

@end
