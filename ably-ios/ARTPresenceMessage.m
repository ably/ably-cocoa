//
//  ARTPresenceMessage.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTPresenceMessage.h"
#import "ARTLog.h"
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

- (ARTPresenceMessage *)messageWithPayload:(ARTPayload *)payload {
    ARTPresenceMessage *m = [[ARTPresenceMessage alloc] init];
    m.id = self.id;
    m.clientId = self.clientId;
    m.payload = payload;
    m.timestamp = self.timestamp;
    m.action = self.action;
    m.connectionId = self.connectionId;
    m.encoding = self.encoding;
    return m;
}

- (ARTPresenceMessage *)decode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus *status = [encoder decode:payload output:&payload];
    if (status.status != ARTStatusOk) {
        [ARTLog warn:[NSString stringWithFormat:@"ARTPresenceMessage could not decode payload, ARTStatus: %tu", status]];
    }
    return [self messageWithPayload:payload];
}

- (ARTPresenceMessage *)encode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus *status = [encoder encode:payload output:&payload];
    if (status.status != ARTStatusOk) {
        [ARTLog warn:[NSString stringWithFormat:@"ARTPresenceMessage could not encode payload, ARTStatus: %tu", status]];
    }
    return [self messageWithPayload:payload];
}

- (id) content {
    return self.payload.payload;
}

@end
