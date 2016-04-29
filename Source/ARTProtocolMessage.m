//
//  ARTProtocolMessage.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTStatus.h"
#import "ARTConnectionDetails.h"

@implementation ARTProtocolMessage

- (id)init {
    self = [super init];
    if (self) {
        _count = 0;
        _id = nil;
        _channel = nil;
        _channelSerial = nil;
        _connectionId = nil;
        _connectionKey = nil;
        _connectionSerial = 0;
        _hasConnectionSerial = false;
        _msgSerial = 0;
        _timestamp = nil;
        _messages = nil;
        _presence = nil;
        _flags = 0;
        _error = nil;
        _connectionDetails = nil;
    }
    return self;
}

- (NSString *)getConnectionKey {
    if (_connectionDetails && _connectionDetails.connectionKey) {
        return _connectionDetails.connectionKey;
    }
    return _connectionKey;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" count: %d,\n", self.count];
    [description appendFormat:@" id: %@,\n", self.id];
    [description appendFormat:@" action: %lu,\n", (unsigned long)self.action];
    [description appendFormat:@" channel: %@,\n", self.channel];
    [description appendFormat:@" channelSerial: %@,\n", self.channelSerial];
    [description appendFormat:@" connectionId: %@,\n", self.connectionId];
    [description appendFormat:@" connectionKey: %@,\n", self.connectionKey];
    [description appendFormat:@" connectionSerial: %lld,\n", self.connectionSerial];
    [description appendFormat:@" msgSerial: %lld,\n", self.msgSerial];
    [description appendFormat:@" timestamp: %@,\n", self.timestamp];
    [description appendFormat:@" flags: %lld,\n", self.flags];
    [description appendFormat:@" messages: %@\n", self.messages];
    [description appendFormat:@"}"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTProtocolMessage *pm = [[[self class] allocWithZone:zone] init];
    pm.action = self.action;
    pm.count = self.count;
    pm.id = self.id;
    pm.channel = self.channel;
    pm.channelSerial = self.channelSerial;
    pm.connectionId = self.connectionId;
    pm.connectionKey = self.connectionKey;
    pm.connectionSerial = self.connectionSerial;
    pm.hasConnectionSerial = self.hasConnectionSerial;
    pm.msgSerial = self.msgSerial;
    pm.timestamp = self.timestamp;
    pm.messages = self.messages;
    pm.presence = self.presence;
    pm.flags = self.flags;
    pm.error = self.error;
    pm.connectionDetails = self.connectionDetails;
    return pm;
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

- (void)setConnectionSerial:(int64_t)connectionSerial {
    _connectionSerial =connectionSerial;
    _hasConnectionSerial = true;
}

- (BOOL)ackRequired {
    return self.action == ARTProtocolMessageMessage || self.action == ARTProtocolMessagePresence;
}

- (BOOL)isSyncEnabled {
    return self.flags & 0x1;
}

- (ARTConnectionDetails *)getConnectionDetails {
    return _connectionDetails;
}

@end
