//
// Created by Ikbal Kaya on 08/06/2022.
//

#import "ARTRevokedTarget.h"
#import "ARTTokenRevocationTarget.h"


@implementation ARTRevokedTarget {
}
- (instancetype)initWith:(ARTTokenRevocationTarget *)target issuedBefore:(NSDate *)issuedBefore appliesAt:(NSDate *)appliesAt {
    if (self = [super init]) {
        self.target = target;
        self.issuedBefore = issuedBefore;
        self.appliesAt = appliesAt;
    }
    return self;
}

@end