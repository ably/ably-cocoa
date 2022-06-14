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