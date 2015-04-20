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
    }
    return self;
}

- (ARTMessage *)messageWithPayload:(ARTPayload *)payload {
    ARTMessage *m = [[ARTMessage alloc] init];
    m.id = self.id;
    m.name = self.name;
    m.clientId = self.clientId;
    m.timestamp = self.timestamp;
    m.payload = payload;
    return m;
}

- (ARTMessage *)decode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus status = [encoder decode:payload output:&payload];
    if (status != ARTStatusOk) {
        [ARTLog warn:[NSString stringWithFormat:@"ARTMessage could not decode payload, ARTStatus: %tu", status]];
    }
    return [self messageWithPayload:payload];
}

- (ARTMessage *)encode:(id<ARTPayloadEncoder>)encoder {
    ARTPayload *payload = self.payload;
    ARTStatus status = [encoder encode:payload output:&payload];
    if (status != ARTStatusOk) {
        [ARTLog warn:[NSString stringWithFormat:@"ARTMessage could not encode payload, ARTStatus: %tu", status]];
    }
    return [self messageWithPayload:payload];
}

- (id) content {
    return self.payload.payload;
}

@end
