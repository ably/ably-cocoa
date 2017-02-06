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
        // Default
        _action = ARTPresenceEnter;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTPresenceMessage *message = [super copyWithZone:zone];
    message->_action = self.action;
    return message;
}

- (NSString *)description {
    NSMutableString *description = [[super description] mutableCopy];
    [description deleteCharactersInRange:NSMakeRange(description.length - (description.length>2 ? 2:0), 2)];
    [description appendFormat:@",\n"];
    [description appendFormat:@" action: %lu\n", (unsigned long)self.action];
    [description appendFormat:@"}"];
    return description;
}

- (NSString *)memberKey {
    return [NSString stringWithFormat:@"%@:%@", self.connectionId, self.clientId];
}

- (BOOL)isEqualToPresenceMessage:(ARTPresenceMessage *)presence {
    if (!presence) {
        return NO;
    }

    BOOL haveEqualConnectionId = (!self.connectionId && !presence.connectionId) || [self.connectionId isEqualToString:presence.connectionId];
    BOOL haveEqualCliendId = (!self.clientId && !presence.clientId) || [self.clientId isEqualToString:presence.clientId];

    return haveEqualConnectionId && haveEqualCliendId;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ARTPresenceMessage class]]) {
        return NO;
    }

    return [self isEqualToPresenceMessage:(ARTPresenceMessage *)object];
}

- (NSUInteger)hash {
    return [self.connectionId hash] ^ [self.clientId hash];
}

@end

NSString *ARTPresenceActionToStr(ARTPresenceAction action) {
    switch (action) {
        case ARTPresenceAbsent:
            return @"Absent"; //0
        case ARTPresencePresent:
            return @"Present"; //1
        case ARTPresenceEnter:
            return @"Enter"; //2
        case ARTPresenceLeave:
            return @"Leave"; //3
        case ARTPresenceUpdate:
            return @"Update"; //4
    }
}
