#import "ARTBaseQuery.h"

@implementation ARTBaseQuery

- (void)throwIfFrozen {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change query after you've passed it to the receiver.", self.class]
                                     userInfo:nil];
    }
}

@end
