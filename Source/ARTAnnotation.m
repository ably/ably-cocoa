#import "ARTAnnotation.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTBaseMessage+Private.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTInternalLog.h"

@implementation ARTAnnotation

- (instancetype)initWithType:(NSString *)type data:(id)data {
    if (self = [self init]) {
        self.type = [type copy];
        if (data) {
            self.data = data;
            self.encoding = @"";
        }
    }
    return self;
}

- (instancetype)initWithType:(NSString *)type data:(id)data clientId:(NSString *)clientId {
    if (self = [self initWithType:type data:data]) {
        self.clientId = clientId;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[super description] mutableCopy];
    [description deleteCharactersInRange:NSMakeRange(description.length - (description.length>2 ? 2:0), 2)];
    [description appendFormat:@",\n"];
    [description appendFormat:@" action: %@\n", ARTAnnotationActionToStr(self.action)];
    [description appendFormat:@" serial: %@\n", self.serial];
    [description appendFormat:@" messageSerial: %@\n", self.messageSerial];
    [description appendFormat:@" type: %@\n", self.type];
    [description appendFormat:@" name: %@\n", self.name];
    [description appendFormat:@" count: %@\n", self.count];
    [description appendFormat:@"}"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTAnnotation *annotation = [super copyWithZone:zone];
    annotation.action = self.action;
    annotation.serial = self.serial;
    annotation.messageSerial = self.messageSerial;
    annotation.type = self.type;
    annotation.name = self.name;
    annotation.count = self.count;
    return annotation;
}

- (NSInteger)messageSize {
    // TO3l8*
    return [super messageSize] + [self.type lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation ARTAnnotation (Decoding)

+ (instancetype)fromEncoded:(NSDictionary *)jsonObject channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
//    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
//    NSError *encoderError = nil;
//    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher logger:ARTInternalLog.sharedClassMethodLogger_readDocumentationBeforeUsing error:&encoderError];
//    if (encoderError != nil) {
//        if (error != nil) {
//            ARTErrorInfo *errorInfo =
//            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:encoderError.localizedFailureReason]
//                       prepend:[NSString stringWithFormat:@"Decoder can't be created with cipher: %@", options.cipher]];
//            *error = errorInfo;
//        }
//        return nil;
//    }
//    
//    ARTMessage *message = [jsonEncoder messageFromDictionary:jsonObject protocolMessage:nil];
//    
//    NSError *decodeError = nil;
//    message = [message decodeWithEncoder:decoder error:&decodeError];
//    if (decodeError != nil) {
//        if (error != nil) {
//            ARTErrorInfo *errorInfo =
//            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason]
//                       prepend:[NSString stringWithFormat:@"Failed to decode data for message: %@. Decoding array aborted.", message.name]];
//            *error = errorInfo;
//        }
//        return nil;
//    }
//    return message;
    return nil;
}

+ (NSArray<ARTMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
//    ARTJsonLikeEncoder *jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithDelegate:[[ARTJsonEncoder alloc] init]];
//    NSError *encoderError = nil;
//    ARTDataEncoder *decoder = [[ARTDataEncoder alloc] initWithCipherParams:options.cipher logger:ARTInternalLog.sharedClassMethodLogger_readDocumentationBeforeUsing error:&encoderError];
//    if (encoderError != nil) {
//        if (error != nil) {
//            ARTErrorInfo *errorInfo =
//            [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:encoderError.localizedFailureReason]
//                       prepend:[NSString stringWithFormat:@"Decoder can't be created with cipher: %@", options.cipher]];
//            *error = errorInfo;
//        }
//        return nil;
//    }
//    
//    NSArray<ARTMessage *> *messages = [jsonEncoder messagesFromArray:jsonArray protocolMessage:nil];
//    
//    NSMutableArray<ARTMessage *> *decodedMessages = [NSMutableArray array];
//    for (ARTMessage *message in messages) {
//        NSError *decodeError = nil;
//        ARTMessage *decodedMessage = [message decodeWithEncoder:decoder error:&decodeError];
//        if (decodeError != nil) {
//            if (error != nil) {
//                ARTErrorInfo *errorInfo =
//                [ARTErrorInfo wrap:[ARTErrorInfo createWithCode:ARTErrorUnableToDecodeMessage message:decodeError.localizedFailureReason]
//                           prepend:[NSString stringWithFormat:@"Failed to decode data for message: %@. Decoding array aborted.", message.name]];
//                *error = errorInfo;
//            }
//            break;
//        }
//        else {
//            [decodedMessages addObject:decodedMessage];
//        }
//    }
//    return decodedMessages;
    return nil;
}

@end

NSString *ARTAnnotationActionToStr(ARTAnnotationAction action) {
    switch (action) {
        case ARTAnnotationCreate:
            return @"Create"; //0
        case ARTAnnotationDelete:
            return @"Delete"; //1
    }
    return @"Unknown";
}

#pragma mark - ARTEvent

@implementation ARTEvent (AnnotationAction)

- (instancetype)initWithAnnotationAction:(ARTAnnotationAction)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTAnnotation%@", ARTAnnotationActionToStr(value)]];
}

+ (instancetype)newWithAnnotationAction:(ARTAnnotationAction)value {
    return [[self alloc] initWithAnnotationAction:value];
}

- (instancetype)initWithAnnotationType:(NSString *)type {
    return [self initWithString:[NSString stringWithFormat:@"ARTAnnotation:%@", type]];
}

+ (instancetype)newWithAnnotationType:(NSString *)type {
    return [[self alloc] initWithAnnotationType:type];
}

@end
