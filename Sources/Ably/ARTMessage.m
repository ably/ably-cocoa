#import "ARTMessage.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTBaseMessage+Private.h"
#import "NSArray+ARTFunctional.h"
#import "ARTInternalLog.h"

@implementation ARTMessage

- (instancetype)initWithName:(NSString *)name data:(id)data {
    if (self = [self init]) {
        self.name = [name copy];
        if (data) {
            self.data = data;
            self.encoding = @"";
        }
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name data:(id)data clientId:(NSString *)clientId {
    if (self = [self initWithName:name data:data]) {
        self.clientId = clientId;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[super description] mutableCopy];
    [description deleteCharactersInRange:NSMakeRange(description.length - (description.length>2 ? 2:0), 2)];
    [description appendFormat:@",\n"];
    [description appendFormat:@" name: %@\n", self.name];
    [description appendFormat:@" action: %@\n", ARTMessageActionToStr(self.action)];
    [description appendFormat:@" serial: %@\n", self.serial];
    [description appendFormat:@" updateSerial: %@\n", self.updateSerial];
    [description appendFormat:@" version: %@\n", self.version];
    [description appendFormat:@" createdAt: %@\n", self.createdAt];
    [description appendFormat:@" updatedAt: %@\n", self.updatedAt];
    [description appendFormat:@" refType: %@\n", self.refType];
    [description appendFormat:@" refSerial: %@\n", self.refSerial];
    [description appendFormat:@" operation: %@\n", self.operation];
    [description appendFormat:@" summary: %@\n", self.summary];
    [description appendFormat:@"}"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessage *message = [super copyWithZone:zone];
    message.name = self.name;
    message.action = self.action;
    message.serial = self.serial;
    message.updateSerial = self.updateSerial;
    message.version = self.version;
    message.createdAt = self.createdAt;
    message.updatedAt = self.updatedAt;
    message.operation = self.operation;
    message.refType = self.refType;
    message.refSerial = self.refSerial;
    message.summary = self.summary;
    return message;
}

- (NSInteger)messageSize {
    // TO3l8*
    return [super messageSize] + [self.name lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

@end

NSString *ARTMessageActionToStr(ARTMessageAction action) {
    switch (action) {
        case ARTMessageActionCreate:
            return @"Create";
        case ARTMessageActionUpdate:
            return @"Update";
        case ARTMessageActionDelete:
            return @"Delete";
        case ARTMessageActionMeta:
            return @"Meta";
        case ARTMessageActionMessageSummary:
            return @"Summary";
    }
    return @"Unknown";
}

@implementation ARTMessage (Decoding)

+ (instancetype)fromEncoded:(NSDictionary *)jsonObject channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
    NSError *encoderError = nil;
    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher logger:ARTInternalLog.sharedClassMethodLogger_readDocumentationBeforeUsing error:&encoderError];
    if (encoderError != nil) {
        if (error != nil) {
            ARTErrorInfo *errorInfo =
            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:encoderError.localizedFailureReason]
                       prepend:[NSString stringWithFormat:@"Decoder can't be created with cipher: %@", options.cipher]];
            *error = errorInfo;
        }
        return nil;
    }
    
    ARTMessage *message = [jsonEncoder messageFromDictionary:jsonObject protocolMessage:nil];
    
    NSError *decodeError = nil;
    message = [message decodeWithEncoder:decoder error:&decodeError];
    if (decodeError != nil) {
        if (error != nil) {
            ARTErrorInfo *errorInfo =
            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason]
                       prepend:[NSString stringWithFormat:@"Failed to decode data for message: %@. Decoding array aborted.", message.name]];
            *error = errorInfo;
        }
        return nil;
    }
    return message;
}

+ (NSArray<ARTMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
    NSError *encoderError = nil;
    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher logger:ARTInternalLog.sharedClassMethodLogger_readDocumentationBeforeUsing error:&encoderError];
    if (encoderError != nil) {
        if (error != nil) {
            ARTErrorInfo *errorInfo =
            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:encoderError.localizedFailureReason]
                       prepend:[NSString stringWithFormat:@"Decoder can't be created with cipher: %@", options.cipher]];
            *error = errorInfo;
        }
        return nil;
    }
    
    NSArray<ARTMessage *> *messages = [jsonEncoder messagesFromArray:jsonArray protocolMessage:nil];
    
    NSMutableArray<ARTMessage *> *decodedMessages = [NSMutableArray array];
    for (ARTMessage *message in messages) {
        NSError *decodeError = nil;
        ARTMessage *decodedMessage = [message decodeWithEncoder:decoder error:&decodeError];
        if (decodeError != nil) {
            if (error != nil) {
                ARTErrorInfo *errorInfo =
                [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason]
                           prepend:[NSString stringWithFormat:@"Failed to decode data for message: %@. Decoding array aborted.", message.name]];
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
