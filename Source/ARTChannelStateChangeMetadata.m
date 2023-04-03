#import "ARTChannelStateChangeMetadata.h"

@implementation ARTChannelStateChangeMetadata

- (instancetype)initWithState:(ARTState)state {
    return [self initWithState:state errorInfo:nil storeErrorInfo:NO];
}

- (instancetype)initWithState:(ARTState)state errorInfo:(ARTErrorInfo *)errorInfo {
    return [self initWithState:state errorInfo:errorInfo storeErrorInfo:YES];
}

- (instancetype)initWithState:(ARTState)state errorInfo:(ARTErrorInfo *)errorInfo storeErrorInfo:(BOOL)storeErrorInfo {
    if (self = [super init]) {
        _state = state;
        _errorInfo = errorInfo;
        _storeErrorInfo = storeErrorInfo;
    }

    return self;
}

@end
