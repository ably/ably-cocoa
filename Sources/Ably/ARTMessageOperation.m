#import <Foundation/Foundation.h>
#import "ARTMessageOperation.h"

@implementation ARTMessageOperation

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

+ (instancetype)createFromDictionary:(NSDictionary<NSString *, id> *)jsonObject {
    ARTMessageOperation *operation = [[ARTMessageOperation alloc] init];
    if (jsonObject[@"clientId"]) {
        operation.clientId = jsonObject[@"clientId"];
    }
    if (jsonObject[@"description"]) {
        operation.descriptionText = jsonObject[@"description"];
    }
    
    id metadata = jsonObject[@"metadata"];
    if (metadata && [metadata isKindOfClass:[NSDictionary class]]) {
        operation.metadata = metadata;
    }
    
    return operation;
}

@end
