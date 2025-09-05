#import "ARTConnectionStateChangeParams.h"

@implementation ARTConnectionStateChangeParams

- (instancetype)init {
    return [self initWithErrorInfo:nil];
}

- (instancetype)initWithErrorInfo:(ARTErrorInfo *)errorInfo {
    return [self initWithErrorInfo:errorInfo retryAttempt:nil];
}

- (instancetype)initWithErrorInfo:(ARTErrorInfo *)errorInfo retryAttempt:(ARTRetryAttempt *)retryAttempt {
    if (self = [super init]) {
        _errorInfo = errorInfo;
        _retryAttempt = retryAttempt;
    }

    return self;
}

@end
