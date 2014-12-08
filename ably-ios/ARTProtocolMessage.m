//
//  ARTProtocolMessage.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTProtocolMessage.h"

@implementation ARTProtocolMessage

- (id)init {
    self = [super init];
    if (self) {
        _count = 0;
        _error = ARTStatusOk;
        _id = nil;
        _channel = nil;
        _channelSerial = nil;
        _connectionId = nil;
        _connectionSerial = 0;
        _msgSerial = 0;
        _timestamp = nil;
        _messages = nil;
        _presence = nil;
    }
    return self;
}

 - (BOOL)mergeFrom:(ARTProtocolMessage *)other {
     if (![other.channel isEqualToString:self.channel] || other.action != self.action) {
         return NO;
     }

     switch (self.action) {
         case ARTProtocolMessageMessage:
             self.messages = [self.messages arrayByAddingObjectsFromArray:other.messages];
             return YES;
         case ARTProtocolMessagePresence:
             self.presence = [self.presence arrayByAddingObjectsFromArray:other.presence];
             return YES;
         default:
             return NO;
     }
 }

- (BOOL)ackRequired {
    return self.action == ARTProtocolMessageMessage || self.action == ARTProtocolMessagePresence;
}

@end
