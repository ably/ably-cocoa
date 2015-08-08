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
    self = [super init];
    if (self) {
        _id = nil;
        _name = nil;
        _clientId = nil;
        _payload = nil;
        _timestamp = nil;
        _connectionId = nil;
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

- (ARTMessage *)messageWithPayload:(ARTPayload *)payload status:(ARTStatus * ) status {
    ARTMessage *m = [[ARTMessage alloc] init];
    m.id = self.id;
    m.name = self.name;
    m.clientId = self.clientId;
    m.timestamp = self.timestamp;
    m.payload = payload;
    m.connectionId = self.connectionId;
    m.status = status;
    return m;
}
- (ARTMessage *)messageWithPayload:(ARTPayload *)payload {
   return [self messageWithPayload:payload status: nil];
}

- (ARTMessage *)decode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus *status = [encoder decode:payload output:&payload];
    return [self messageWithPayload:payload status: status];
}

- (ARTMessage *)encode:(id<ARTPayloadEncoder>)encoder {
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
