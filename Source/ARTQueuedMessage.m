#import "ARTQueuedMessage.h"

#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"

@implementation ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg sentCallback:(ARTCallback)sentCallback ackCallback:(ARTMessageSendCallback)ackCallback {
    self = [super init];
    if (self) {
        _msg = msg;
        _sentCallbacks = [NSMutableArray array];
        if (sentCallback) {
            [_sentCallbacks addObject:sentCallback];
        }
        _ackCallbacks = [NSMutableArray array];
        if (ackCallback) {
            [_ackCallbacks addObject:ackCallback];
        }
    }
    return self;
}

- (NSString *)description {
    return [self.msg description];
}

- (ARTCallback)sentCallback {
    return ^(ARTErrorInfo *error) {
        for (ARTCallback cb in self.sentCallbacks) {
            cb(error);
        }
    };
}

- (ARTMessageSendCallback)ackCallback {
    return ^(ARTMessageSendStatus *status) {
        for (ARTMessageSendCallback cb in self.ackCallbacks) {
            cb(status);
        }
    };
}

@end
