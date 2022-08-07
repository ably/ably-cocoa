#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTBaseMessage+Private.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTPresenceMessage+Private.h"

NSString *const ARTPresenceMessageException = @"ARTPresenceMessageException";
NSString *const ARTAblyMessageInvalidPresenceId = @"Received presence message id is invalid %@";

@implementation ARTPresenceMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default
        _action = ARTPresenceEnter;
        _syncSessionId = 0;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTPresenceMessage *message = [super copyWithZone:zone];
    message->_action = self.action;
    message->_syncSessionId = self.syncSessionId;
    return message;
}

- (NSString *)description {
    NSMutableString *description = [[super description] mutableCopy];
    [description deleteCharactersInRange:NSMakeRange(description.length - (description.length>2 ? 2:0), 2)];
    [description appendFormat:@",\n"];
    [description appendFormat:@" action: %lu,\n", (unsigned long)self.action];
    [description appendFormat:@" syncSessionId: %lu\n", (unsigned long)self.syncSessionId];
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

- (BOOL)isNewerThan:(ARTPresenceMessage *)latest {
    if (latest == nil) {
        return YES;
    }

    if ([self isSynthesized] || [latest isSynthesized]) {
        return !self.timestamp || [latest.timestamp timeIntervalSince1970] <= [self.timestamp timeIntervalSince1970];
    }

    NSInteger currentMsgSerial = [self msgSerialFromId];
    NSInteger currentIndex = [self indexFromId];
    NSInteger latestMsgSerial = [latest msgSerialFromId];
    NSInteger latestIndex = [latest indexFromId];

    if (currentMsgSerial == latestMsgSerial) {
        return currentIndex > latestIndex;
    }
    else {
        return currentMsgSerial > latestMsgSerial;
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
            return @"Absent";
        case ARTPresencePresent:
            return @"Present";
        case ARTPresenceEnter:
            return @"Enter";
        case ARTPresenceLeave:
            return @"Leave";
        case ARTPresenceUpdate:
            return @"Update";
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

@implementation ARTPresenceMessage (Decoding)

+ (instancetype)fromEncoded:(NSDictionary *)jsonObject channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
    NSError *encoderError = nil;
    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher error:&encoderError];
    if (encoderError != nil) {
        if (error != nil) {
            ARTErrorInfo *errorInfo =
            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:encoderError.localizedFailureReason]
                       prepend:[NSString stringWithFormat:@"Decoder can't be created with cipher: %@", options.cipher]];
            *error = errorInfo;
        }
        return nil;
    }
    
    ARTPresenceMessage *message = [jsonEncoder presenceMessageFromDictionary:jsonObject];
    
    NSError *decodeError = nil;
    message = [message decodeWithEncoder:decoder error:&decodeError];
    if (decodeError != nil) {
        if (error != nil) {
            ARTErrorInfo *errorInfo =
            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason]
                       prepend:[NSString stringWithFormat:@"Failed to decode data for presence message: %@. Decoding array aborted.", ARTPresenceActionToStr(message.action)]];
            *error = errorInfo;
        }
        return nil;
    }
    return message;
}

+ (NSArray<ARTPresenceMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
    NSError *encoderError = nil;
    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher error:&encoderError];
    if (encoderError != nil) {
        if (error != nil) {
            ARTErrorInfo *errorInfo =
            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:encoderError.localizedFailureReason]
                       prepend:[NSString stringWithFormat:@"Decoder can't be created with cipher: %@", options.cipher]];
            *error = errorInfo;
        }
        return nil;
    }
    
    NSArray<ARTPresenceMessage *> *messages = [jsonEncoder presenceMessagesFromArray:jsonArray];
    
    NSMutableArray<ARTPresenceMessage *> *decodedMessages = [NSMutableArray array];
    for (ARTPresenceMessage *message in messages) {
        NSError *decodeError = nil;
        ARTPresenceMessage *decodedMessage = [message decodeWithEncoder:decoder error:&decodeError];
        if (decodeError != nil) {
            if (error != nil) {
                ARTErrorInfo *errorInfo =
                [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason]
                           prepend:[NSString stringWithFormat:@"Failed to decode data for message: %@. Decoding array aborted.", ARTPresenceActionToStr(message.action)]];
                *error = errorInfo;
            }
            break;
        }
        else {
            [decodedMessages addObject:decodedMessage];
        }
    }
    return decodedMessages;
}

@end
