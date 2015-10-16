//
//  ARTBaseMessage.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTBaseMessage.h"
#import "ARTLog.h"

@implementation ARTBaseMessage

- (void)setClientId:(NSString *)clientId {
    if(clientId) {
        const char* c = [clientId UTF8String];
        _clientId = [NSString stringWithUTF8String:c];
    }
    else {
        _clientId = nil;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    ARTBaseMessage *message = [[self.class allocWithZone:zone] init];
    message->_id = self.id;
    message->_clientId = self.clientId;
    message->_timestamp = self.timestamp;
    message->_payload = self.payload;
    message->_connectionId = self.connectionId;
    message->_encoding = self.encoding;
    return message;
}

- (instancetype)messageWithPayload:(ARTPayload *)payload {
    ARTBaseMessage *message = [self copy];
    message.payload = payload;
    return message;
}

- (instancetype)decode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    // FIXME:
    [encoder decode:payload output:&payload];
    return [self messageWithPayload:payload];
}

- (instancetype)encode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    // FIXME:
    [encoder encode:payload output:&payload];
    return [self messageWithPayload:payload];
}

- (id)content {
    // FIXME: payload.payload
    return self.payload.payload;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"%@: id=%@ clientId=%@ connectionId=%@ payload=%@",
            NSStringFromClass([self class]), self.id, self.clientId, self.connectionId, self.payload];
}

+ (NSArray *)messagesWithPayloads:(NSArray *)payloads {
    if([payloads count] > [ARTPayload payloadArraySizeLimit]) {
        [NSException raise:@"Too many items in payload array" format:@"%lu > %lu", (unsigned long)[payloads count], [ARTPayload payloadArraySizeLimit]];
    }
    NSMutableArray * messages =[[NSMutableArray alloc] init];
    for (int i=0; i < [payloads count]; i++) {
        // FIXME
        //[messages addObject:[ARTMessage messageWithPayload:[payloads objectAtIndex:i] name:nil]];
    }
    return messages;
}

@end
