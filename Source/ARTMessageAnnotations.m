#import "ARTDefault.h"
#import "ARTMessageAnnotations.h"

@implementation ARTMessageAnnotations

- (instancetype)init {
    self = [super init];
    if (self) {
        _summary = nil;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTMessageAnnotations *annotations = [[[self class] allocWithZone:zone] init];
    annotations.summary = self.summary;
    return annotations;
}

- (void)writeToDictionary:(NSMutableDictionary<NSString *, id> *)dictionary {
    if (self.summary) {
        dictionary[@"summary"] = self.summary;
    }
}

+ (instancetype)createFromDictionary:(NSDictionary<NSString *, id> *)jsonObject {
    ARTMessageAnnotations *annotations = [[ARTMessageAnnotations alloc] init];
    annotations.summary = [jsonObject objectForKey:@"summary"];
    return annotations;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" summary: %@\n", self.summary];
    [description appendFormat:@"}"];
    return description;
}

@end
