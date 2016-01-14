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
    [encoder decode:payload output:&payload];
    return [self messageWithPayload:payload];
}

- (instancetype)encode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    [encoder encode:payload output:&payload];
    return [self messageWithPayload:payload];
}

- (id)content {
    // FIXME: payload.payload
    return self.payload.payload;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" id: %@,\n", self.id];
    [description appendFormat:@" clientId: %@,\n", self.clientId];
    [description appendFormat:@" connectionId: %@,\n", self.connectionId];
    [description appendFormat:@" timestamp: %@,\n", self.timestamp];
    [description appendFormat:@" encoding: %@,\n", self.encoding];
    [description appendFormat:@" payload: %@\n", self.payload];
    [description appendFormat:@"}"];
    return description;}

@end
