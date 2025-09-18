#import "ARTDefault.h"
#import "ARTMessageVersion.h"
#import "ARTNSDate+ARTUtil.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"

@implementation ARTMessageVersion

- (instancetype)init {
    self = [super init];
    if (self) {
        _serial = nil;
        _timestamp = nil;
        _clientId = nil;
        _descriptionText = nil;
        _metadata = nil;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessageVersion *version = [[[self class] allocWithZone:zone] init];
    version.serial = self.serial;
    version.timestamp = self.timestamp;
    version.clientId = self.clientId;
    version.descriptionText = self.descriptionText;
    version.metadata = self.metadata;
    return version;
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
    ARTMessageVersion *version = [[ARTMessageVersion alloc] init];
    version.serial = [jsonObject artString:@"serial"];
    version.timestamp = [jsonObject artTimestamp:@"timestamp"];
    version.clientId = [jsonObject artString:@"clientId"];
    version.descriptionText = [jsonObject artString:@"description"];

    id metadata = jsonObject[@"metadata"];
    if (metadata && [metadata isKindOfClass:[NSDictionary class]]) {
        version.metadata = metadata;
    }

    return version;
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
