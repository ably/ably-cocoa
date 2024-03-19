#import "ARTPresenceMessage+Private.h"

NSString *const ARTPresenceMessageException = @"ARTPresenceMessageException";
NSString *const ARTAblyMessageInvalidPresenceId = @"Received presence message id is invalid %@";

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
    [description appendFormat:@" action: %lu,\n", (unsigned long)self.action];
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

- (NSArray<NSString *> *)parseId {
    if (self.id == nil) {
        return nil;
    }
    NSArray<NSString *> *idParts = [self.id componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    if (idParts.count != 3) {
        [ARTException raise:ARTPresenceMessageException format:ARTAblyMessageInvalidPresenceId, self.id];
    }
    return idParts;
}

- (BOOL)isSynthesized {
    NSString *connectionId = [[self parseId] objectAtIndex:0];
    return ![connectionId isEqualToString:self.connectionId];
}

- (NSInteger)msgSerialFromId {
    NSInteger msgSerial = [[[self parseId] objectAtIndex:1] integerValue];
    return msgSerial;
}

- (NSInteger)indexFromId {
    NSInteger index = [[[self parseId] objectAtIndex:2] integerValue];
    return index;
}

- (BOOL)isNewerThan:(ARTPresenceMessage *)other {
    if ([self isSynthesized] || [other isSynthesized]) {
        return !self.timestamp || [other.timestamp timeIntervalSince1970] <= [self.timestamp timeIntervalSince1970];
    }

    NSInteger msgSerial = [self msgSerialFromId];
    NSInteger index = [self indexFromId];
    NSInteger otherMsgSerial = [other msgSerialFromId];
    NSInteger otherIndex = [other indexFromId];

    if (msgSerial == otherMsgSerial) {
        return index > otherIndex;
    }
    else {
        return msgSerial > otherMsgSerial;
    }
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

#pragma mark - ARTEvent

@implementation ARTEvent (PresenceAction)

- (instancetype)initWithPresenceAction:(ARTPresenceAction)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTPresenceAction%@", ARTPresenceActionToStr(value)]];
}

+ (instancetype)newWithPresenceAction:(ARTPresenceAction)value {
    return [[self alloc] initWithPresenceAction:value];
}

@end
