//
//  ARTPresenceMessage.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTPresenceMessage.h"
#import "ARTStatus.h"
@implementation ARTPresenceMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        _id = nil;
        _clientId = nil;
        _payload = nil;
        _timestamp = nil;
        _action = ARTPresenceMessageEnter;
        _connectionId = nil;
        _encoding = nil;
    }
    return self;
}

- (ARTPresenceMessage *)messageWithPayload:(ARTPayload *)payload status:(ARTStatus *) status{
    ARTPresenceMessage *m = [[ARTPresenceMessage alloc] init];
    m.status = status;
    m.id = self.id;
    m.clientId = self.clientId;
    m.payload = payload;
    m.timestamp = self.timestamp;
    m.action = self.action;
    m.connectionId = self.connectionId;
    m.encoding = self.encoding;
    return m;
}
- (ARTPresenceMessage *)messageWithPayload:(ARTPayload *)payload {
    return [self messageWithPayload:payload status:nil];
}

- (ARTPresenceMessage *)decode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus *status = [encoder decode:payload output:&payload];
    return [self messageWithPayload:payload];
}

- (ARTPresenceMessage *)encode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus *status = [encoder encode:payload output:&payload];
    return [self messageWithPayload:payload status:status];
}

- (id) content {
    return self.payload.payload;
}

@end
