#ifdef ABLY_SUPPORTS_PLUGINS

#import "ARTPluginDecodingContext.h"

@implementation ARTPluginDecodingContext

@synthesize parentID = _parentID;
@synthesize parentConnectionID = _parentConnectionID;
@synthesize parentTimestamp = _parentTimestamp;
@synthesize indexInParent = _indexInParent;

- (instancetype)initWithParentID:(NSString *)parentID
              parentConnectionID:(NSString *)parentConnectionID
                 parentTimestamp:(NSDate *)parentTimestamp
                   indexInParent:(NSInteger)indexInParent {
    self = [super init];
    if (self) {
        _parentID = [parentID copy];
        _parentConnectionID = [parentConnectionID copy];
        _parentTimestamp = [parentTimestamp copy];
        _indexInParent = indexInParent;
    }
    return self;
}

@end

#endif
