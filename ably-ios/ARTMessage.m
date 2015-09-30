//
//  ARTMessage.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTMessage.h"
#import "ARTLog.h"

@implementation ARTMessage

- (instancetype)init {
    return self = [self init];
}

- (instancetype)initWithData:(id)data name:(NSString *)name {
    if (self = [self init]) {
        _name = [name copy];
        if (data) {
            _payload = [ARTPayload payloadWithPayload:data encoding:@""];
        }
    }
    
    return self;
}

-(void) setClientId:(NSString *)clientId {
    if(clientId) {
        const char* c = [clientId UTF8String];
        _clientId = [NSString stringWithUTF8String:c];
    }
    else {
        _clientId = nil;
    }
    
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessage *message = [[self.class allocWithZone:zone] init];
    message->_id = self.id;
    message->_name = self.name;
    message->_clientId = self.clientId;
    message->_timestamp = self.timestamp;
    message->_payload = self.payload;
    message->_connectionId = self.connectionId;
    message->_status = self.status;
    return message;
}

- (instancetype)messageWithPayload:(ARTPayload *)payload status:(ARTStatus * ) status {
    ARTMessage *message = [self copy];
    message.payload = payload;
    message.status = status;
    return message;
}
- (instancetype)messageWithPayload:(ARTPayload *)payload {
    return [self messageWithPayload:payload status: nil];
}

- (instancetype)decode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus *status = [encoder decode:payload output:&payload];
    return [self messageWithPayload:payload status: status];
}

- (instancetype)encode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus *status = [encoder encode:payload output:&payload];
    return [self messageWithPayload:payload status:status];
}

- (id) content {
    return self.payload.payload;
}

+ (ARTMessage *) messageWithPayload:(id) payload name:(NSString *) name {
    ARTMessage *message = [[ARTMessage alloc] init];
    message.name = name;
    message.payload = [ARTPayload payloadWithPayload:payload encoding:@""];
    return message;
}

+ (NSArray *) messagesWithPayloads:(NSArray *) payloads {
    
    if([payloads count] > [ARTPayload payloadArraySizeLimit]) {
        [NSException raise:@"Too many items in payload array" format:@"%lu > %lu", (unsigned long)[payloads count], [ARTPayload payloadArraySizeLimit]];
    }
    NSMutableArray * messages =[[NSMutableArray alloc] init];
    for(int i=0; i < [payloads count]; i++) {
        [messages addObject:[ARTMessage messageWithPayload:[payloads objectAtIndex:i] name:nil]];
    }
    return messages;
}

@end
