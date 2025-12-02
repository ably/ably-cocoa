#import "ARTMessageOperation.h"
#import "ARTMessageOperation+Private.h"

@implementation ARTMessageOperation

- (instancetype)initWithClientId:(NSString *)clientId descriptionText:(NSString *)descriptionText metadata:(NSDictionary<NSString *, NSString *> *)metadata {
    self = [super init];
    if (self) {
        _clientId = clientId;
        _descriptionText = descriptionText;
        _metadata = metadata;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessageOperation *operation = [[[self class] allocWithZone:zone] init];
    operation->_clientId = self.clientId;
    operation->_descriptionText = self.descriptionText;
    operation->_metadata = self.metadata;
    return operation;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" clientId: %@,\n", self.clientId];
    [description appendFormat:@" descriptionText: %@,\n", self.descriptionText];
    [description appendFormat:@" metadata: %@\n", self.metadata];
    [description appendFormat:@"}"];
    return description;
}

- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary {
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

+ (nullable instancetype)createFromDictionary:(nonnull NSDictionary *)dictionary {
    NSAssert(false, @"Not implemented");
    return nil;
}

- (nullable instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary {
    NSAssert(false, @"Not implemented");
    return nil;
}

@end
