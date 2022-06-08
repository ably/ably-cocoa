//
// Created by Ikbal Kaya on 07/06/2022.
//

#import "ARTTokenRevocationTarget.h"

@implementation ARTTokenRevocationTarget
- (instancetype)initWith:(NSString *)type value:(NSString *)value {
    if (self = [super init]) {
        self.type = type;
        self.value = value;
    }
    return self;
}

@end