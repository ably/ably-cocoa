//
//  ARTBaseMessage.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTBaseMessage.h"
#import "ARTLog.h"
#import "ARTStatus.h"

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
    message->_data = self.data;
    message->_connectionId = self.connectionId;
    message->_encoding = self.encoding;
    return message;
}

- (instancetype)messageWithData:(id)data encoding:(NSString *)encoding {
    ARTBaseMessage *message = [self copy];
    message.data = data;
    message.encoding = encoding;
    return message;
}

- (ARTStatus *)decodeWithEncoder:(ARTDataEncoder*)encoder output:(id *)output {
    id decoded = nil;
    NSString *decodedEncoding = nil;
    ARTStatus *status = [encoder decode:self.data encoding:self.encoding outputData:&decoded outputEncoding:&decodedEncoding];
    *output = [self copy];
    ((ARTBaseMessage *)*output).data = decoded;
    ((ARTBaseMessage *)*output).encoding = decodedEncoding;
    return status;
}

- (ARTStatus *)encodeWithEncoder:(ARTDataEncoder*)encoder output:(id *)output {
    id encoded = nil;
    NSString *encoding = nil;
    ARTStatus *status = [encoder encode:self.data outputData:&encoded outputEncoding:&encoding];
    *output = [self copy];
    ((ARTBaseMessage *)*output).data = encoded;
    ((ARTBaseMessage *)*output).encoding = [self.encoding artAddEncoding:encoding];
    return status;
}

- (id)content {
    return self.data;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" id: %@,\n", self.id];
    [description appendFormat:@" clientId: %@,\n", self.clientId];
    [description appendFormat:@" connectionId: %@,\n", self.connectionId];
    [description appendFormat:@" timestamp: %@,\n", self.timestamp];
    [description appendFormat:@" encoding: %@,\n", self.encoding];
    [description appendFormat:@" data: %@\n", self.data];
    [description appendFormat:@"}"];
    return description;
}

@end
