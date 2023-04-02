#import "ARTAttachRequestMetadata.h"

@implementation ARTAttachRequestMetadata

- (instancetype)initWithReason:(ARTErrorInfo *)reason {
    return [self initWithReason:reason channelSerial:nil];
}

- (instancetype)initWithReason:(ARTErrorInfo *)reason channelSerial:(NSString *)channelSerial {
    if (self = [super init]) {
        _reason = reason;
        _channelSerial = channelSerial;
    }

    return self;
}

@end
