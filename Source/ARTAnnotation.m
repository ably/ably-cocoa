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
    // spec is not clear here, issue - https://github.com/ably/specification/issues/336
    return [super messageSize];
}

@end

@implementation ARTAnnotation (Decoding)

+ (instancetype)fromEncoded:(NSDictionary *)jsonObject channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    // TODO: implement
    return nil;
}

+ (NSArray<ARTMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray channelOptions:(ARTChannelOptions *)options error:(NSError **)error {
    // TODO: implement
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
