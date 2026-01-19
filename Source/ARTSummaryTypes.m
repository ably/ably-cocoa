#import "ARTSummaryTypes.h"
#import "ARTDictionarySerializable.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTMessageAnnotations.h"

@interface ARTSummaryClientIdList () <ARTDictionarySerializable>
@end

@implementation ARTSummaryClientIdList

- (instancetype)initWithTotal:(NSInteger)total clientIds:(NSArray<NSString *> *)clientIds {
    return [self initWithTotal:total clientIds:clientIds clipped:NO];
}

- (instancetype)initWithTotal:(NSInteger)total
                    clientIds:(NSArray<NSString *> *)clientIds
                      clipped:(BOOL)clipped {
    self = [super init];
    if (self) {
        _total = total;
        _clientIds = [clientIds copy];
        _clipped = clipped;
    }
    return self;
}

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSInteger total = [dictionary artInteger:@"total"];
    NSArray *clientIdsArray = [dictionary artArray:@"clientIds"];
    BOOL clipped = [dictionary artBoolean:@"clipped"];

    if (!clientIdsArray) {
        return nil;
    }

    // Validate that all items in the array are strings
    NSMutableArray<NSString *> *validatedClientIds = [NSMutableArray array];
    for (id item in clientIdsArray) {
        if ([item isKindOfClass:[NSString class]]) {
            [validatedClientIds addObject:item];
        } else {
            return nil; // Invalid data type in array
        }
    }

    return [self initWithTotal:total
                     clientIds:[validatedClientIds copy]
                       clipped:clipped];
}

+ (nullable instancetype)createFromDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary {
    dictionary[@"total"] = @(self.total);
    dictionary[@"clientIds"] = self.clientIds;
    dictionary[@"clipped"] = @(self.clipped);
}

- (id)copyWithZone:(NSZone *)zone {
    return [[ARTSummaryClientIdList allocWithZone:zone] initWithTotal:self.total
                                                            clientIds:self.clientIds
                                                              clipped:self.clipped];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> { total: %ld, clientIds: %@, clipped: %@ }",
            self.class, self, (long)self.total, self.clientIds, @(self.clipped)];
}

@end

@interface ARTSummaryClientIdCounts () <ARTDictionarySerializable>
@end

@implementation ARTSummaryClientIdCounts

- (instancetype)initWithTotal:(NSInteger)total clientIds:(NSDictionary<NSString *, NSNumber *> *)clientIds {
    return [self initWithTotal:total clientIds:clientIds clipped:NO totalUnidentified:0 totalClientIds:clientIds.count];
}

- (instancetype)initWithTotal:(NSInteger)total
                    clientIds:(NSDictionary<NSString *, NSNumber *> *)clientIds
                      clipped:(BOOL)clipped
            totalUnidentified:(NSInteger)totalUnidentified
               totalClientIds:(NSInteger)totalClientIds {
    self = [super init];
    if (self) {
        _total = total;
        _clientIds = [clientIds copy];
        _clipped = clipped;
        _totalUnidentified = totalUnidentified;
        _totalClientIds = totalClientIds;
    }
    return self;
}

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSInteger total = [dictionary artInteger:@"total"];
    NSDictionary *clientIdsDict = [dictionary artDictionary:@"clientIds"];
    BOOL clipped = [dictionary artBoolean:@"clipped"];
    NSInteger totalUnidentified = [dictionary artInteger:@"totalUnidentified"];
    NSInteger totalClientIds = [dictionary artInteger:@"totalClientIds"];

    if (!clientIdsDict) {
        return nil;
    }

    // Validate that all values in the dictionary are numbers
    NSMutableDictionary<NSString *, NSNumber *> *validatedClientIds = [NSMutableDictionary dictionary];
    for (NSString *key in clientIdsDict) {
        if (![key isKindOfClass:[NSString class]]) {
            return nil; // Invalid key type
        }

        id value = clientIdsDict[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            validatedClientIds[key] = value;
        } else if ([value isKindOfClass:[NSString class]]) {
            // Try to convert string to number
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            NSNumber *numberValue = [formatter numberFromString:value];
            if (numberValue != nil) {
                validatedClientIds[key] = numberValue;
            } else {
                return nil; // Invalid string that can't be converted to number
            }
        } else {
            return nil; // Invalid value type
        }
    }

    return [self initWithTotal:total
                     clientIds:[validatedClientIds copy]
                       clipped:clipped
             totalUnidentified:totalUnidentified
                totalClientIds:totalClientIds];
}

+ (nullable instancetype)createFromDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary {
    dictionary[@"total"] = @(self.total);
    dictionary[@"clientIds"] = self.clientIds;
    dictionary[@"clipped"] = @(self.clipped);
    dictionary[@"totalUnidentified"] = @(self.totalUnidentified);
    dictionary[@"totalClientIds"] = @(self.totalClientIds);
}

- (id)copyWithZone:(NSZone *)zone {
    return [[ARTSummaryClientIdCounts allocWithZone:zone] initWithTotal:self.total
                                                              clientIds:self.clientIds
                                                                clipped:self.clipped
                                                      totalUnidentified:self.totalUnidentified
                                                         totalClientIds:self.totalClientIds];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> { total: %ld, clientIds: %@, clipped: %@, totalUnidentified: %ld, totalClientIds: %ld }",
            self.class, self, (long)self.total, self.clientIds, @(self.clipped), (long)self.totalUnidentified, (long)self.totalClientIds];
}

@end

@interface ARTSummaryTotal () <ARTDictionarySerializable>
@end

@implementation ARTSummaryTotal

- (instancetype)initWithTotal:(NSInteger)total {
    self = [super init];
    if (self) {
        _total = total;
    }
    return self;
}

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSInteger total = [dictionary artInteger:@"total"];
    return [self initWithTotal:total];
}

+ (nullable instancetype)createFromDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary {
    dictionary[@"total"] = @(self.total);
}

- (id)copyWithZone:(NSZone *)zone {
    return [[ARTSummaryTotal allocWithZone:zone] initWithTotal:self.total];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> { total: %ld }", self.class, self, (long)self.total];
}

@end

#pragma mark - Global Summary Functions

NSDictionary<NSString *, ARTSummaryClientIdList *> * _Nullable ARTSummaryUniqueV1(NSDictionary * _Nullable dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [dictionary artMap:^id(id key, id value) {
        if (![key isKindOfClass:[NSString class]] || ![value isKindOfClass:[NSDictionary class]]) {
            return nil; // Skip invalid key-value pairs
        }
        return [ARTSummaryClientIdList createFromDictionary:(NSDictionary *)value];
    }];
}

NSDictionary<NSString *, ARTSummaryClientIdList *> * _Nullable ARTSummaryDistinctV1(NSDictionary * _Nullable dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [dictionary artMap:^id(id key, id value) {
        if (![key isKindOfClass:[NSString class]] || ![value isKindOfClass:[NSDictionary class]]) {
            return nil; // Skip invalid key-value pairs
        }
        return [ARTSummaryClientIdList createFromDictionary:(NSDictionary *)value];
    }];
}

NSDictionary<NSString *, ARTSummaryClientIdCounts *> * _Nullable ARTSummaryMultipleV1(NSDictionary * _Nullable dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [dictionary artMap:^id(id key, id value) {
        if (![key isKindOfClass:[NSString class]] || ![value isKindOfClass:[NSDictionary class]]) {
            return nil; // Skip invalid key-value pairs
        }
        return [ARTSummaryClientIdCounts createFromDictionary:(NSDictionary *)value];
    }];
}

ARTSummaryClientIdList * _Nullable ARTSummaryFlagV1(NSDictionary * _Nullable dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [ARTSummaryClientIdList createFromDictionary:dictionary];
}

ARTSummaryTotal * _Nullable ARTSummaryTotalV1(NSDictionary * _Nullable dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [ARTSummaryTotal createFromDictionary:dictionary];
}
