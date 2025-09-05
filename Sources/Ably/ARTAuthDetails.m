#import "ARTAuthDetails.h"

@implementation ARTAuthDetails

- (instancetype)initWithToken:(NSString *)token {
    if (self = [super init]) {
        _accessToken = token;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t accessToken: %@; \n", [super description], self.accessToken];
}

- (id)copyWithZone:(NSZone *)zone {
    ARTAuthDetails *authDetails = [[[self class] allocWithZone:zone] init];
    authDetails.accessToken = self.accessToken;
    return authDetails;
}

@end
