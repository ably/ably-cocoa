#import "ARTConnectionStateChangeMetadata.h"

@implementation ARTConnectionStateChangeMetadata

- (instancetype)init {
    return [self initWithErrorInfo:nil];
}

- (instancetype)initWithErrorInfo:(ARTErrorInfo *)errorInfo {
    if (self = [super init]) {
        _errorInfo = errorInfo;
    }

    return self;
}

@end
