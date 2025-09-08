#import "ARTAttachRequestParams.h"

@implementation ARTAttachRequestParams

- (instancetype)initWithReason:(ARTErrorInfo *)reason {
    return [self initWithReason:reason channelSerial:nil];
}

- (instancetype)initWithReason:(ARTErrorInfo *)reason channelSerial:(NSString *)channelSerial {
    return [self initWithReason:reason channelSerial:channelSerial retryAttempt:nil];
}

- (instancetype)initWithReason:(ARTErrorInfo *)reason channelSerial:(NSString *)channelSerial retryAttempt:(ARTRetryAttempt *)retryAttempt {
    if (self = [super init]) {
        _reason = reason;
        _channelSerial = channelSerial;
        _retryAttempt = retryAttempt;
    }

    return self;
}

@end
