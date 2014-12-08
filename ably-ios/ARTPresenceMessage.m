//
//  ARTPresenceMessage.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTPresenceMessage.h"

@implementation ARTPresenceMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        _id = nil;
        _clientId = nil;
        _payload = nil;
        _timestamp = nil;
        _action = ARTPresenceMessageEnter;
        _memberId = nil;
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
    m.memberId = self.memberId;
    return m;
}

- (ARTPresenceMessage *)decode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus status = [encoder decode:payload output:&payload];
    if (status != ARTStatusOk) {
        // TODO log
    }
    return [self messageWithPayload:payload];
}

- (ARTPresenceMessage *)encode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus status = [encoder encode:payload output:&payload];
    if (status != ARTStatusOk) {
        // TODO log
    }
    return [self messageWithPayload:payload];
}

@end
