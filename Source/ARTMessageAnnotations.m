#import "ARTDefault.h"
#import "ARTMessageAnnotations.h"

@implementation ARTMessageAnnotations

- (instancetype)init {
    return [self initWithSummary:nil];
}

- (instancetype)initWithSummary:(nullable ARTJsonObject *)summary {
    self = [super init];
    if (self) {
        _summary = summary;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessageAnnotations *annotations = [[[self class] allocWithZone:zone] initWithSummary:self.summary];
    return annotations;
}

- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary {
    if (self.summary) {
        dictionary[@"summary"] = self.summary;
    }
}

+ (instancetype)createFromDictionary:(NSDictionary<NSString *, id> *)jsonObject {
    return [[ARTMessageAnnotations alloc] initWithSummary:[jsonObject objectForKey:@"summary"]];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" summary: %@\n", self.summary];
    [description appendFormat:@"}"];
    return description;
}

@end
