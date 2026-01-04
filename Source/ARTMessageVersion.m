#import "ARTDefault.h"
#import "ARTMessageVersion.h"
#import "ARTNSDate+ARTUtil.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"

@implementation ARTMessageVersion

- (instancetype)init {
    return [self initWithSerial:nil timestamp:nil clientId:nil descriptionText:nil metadata:nil];
}

- (instancetype)initWithSerial:(nullable NSString *)serial
                     timestamp:(nullable NSDate *)timestamp
                      clientId:(nullable NSString *)clientId
               descriptionText:(nullable NSString *)descriptionText
                      metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    self = [super init];
    if (self) {
        _serial = serial;
        _timestamp = timestamp;
        _clientId = clientId;
        _descriptionText = descriptionText;
        _metadata = metadata;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithSerial:self.serial
                                                 timestamp:self.timestamp
                                                  clientId:self.clientId
                                           descriptionText:self.descriptionText
                                                  metadata:self.metadata];
}

- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary {
    if (self.serial) {
        dictionary[@"serial"] = self.serial;
    }
    if (self.timestamp) {
        dictionary[@"timestamp"] = [self.timestamp artToNumberMs];
    }
    if (self.clientId) {
        dictionary[@"clientId"] = self.clientId;
    }
    if (self.descriptionText) {
        dictionary[@"description"] = self.descriptionText;
    }
    if (self.metadata) {
        dictionary[@"metadata"] = self.metadata;
    }
}

+ (instancetype)createFromDictionary:(NSDictionary<NSString *, id> *)jsonObject {
    id metadata = jsonObject[@"metadata"];
    NSDictionary<NSString *, NSString *> *metadataDict = nil;
    if (metadata && [metadata isKindOfClass:[NSDictionary class]]) {
        metadataDict = metadata;
    }
    
    return [[ARTMessageVersion alloc] initWithSerial:[jsonObject artString:@"serial"]
                                           timestamp:[jsonObject artTimestamp:@"timestamp"]
                                            clientId:[jsonObject artString:@"clientId"]
                                     descriptionText:[jsonObject artString:@"description"]
                                            metadata:metadataDict];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" serial: %@,\n", self.serial];
    [description appendFormat:@" timestamp: %@,\n", self.timestamp];
    [description appendFormat:@" clientId: %@,\n", self.clientId];
    [description appendFormat:@" descriptionText: %@,\n", self.descriptionText];
    [description appendFormat:@" metadata: %@\n", self.metadata];
    [description appendFormat:@"}"];
    return description;
}

@end
