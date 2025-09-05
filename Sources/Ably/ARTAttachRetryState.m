#import "ARTAttachRetryState.h"
#import "ARTRetryDelayCalculator.h"
#import "ARTRetrySequence.h"
#import "ARTInternalLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTAttachRetryState ()

@property (nonatomic, readonly) ARTInternalLog *logger;
@property (nonatomic, readonly) NSString *logMessagePrefix;
@property (nonatomic, readonly) id<ARTRetryDelayCalculator> retryDelayCalculator;
@property (nonatomic, nullable) ARTRetrySequence *retrySequence;

@end

NS_ASSUME_NONNULL_END

@implementation ARTAttachRetryState

- (instancetype)initWithRetryDelayCalculator:(id<ARTRetryDelayCalculator>)retryDelayCalculator
                                      logger:(ARTInternalLog *)logger
                            logMessagePrefix:(NSString *)logMessagePrefix {
    if (self = [super init]) {
        _retryDelayCalculator = retryDelayCalculator;
        _logger = logger;
        _logMessagePrefix = logMessagePrefix;
    }

    return self;
}

- (ARTRetryAttempt *)addRetryAttempt {
    if (!self.retrySequence) {
        self.retrySequence = [[ARTRetrySequence alloc] initWithDelayCalculator:self.retryDelayCalculator];
        ARTLogDebug(self.logger, @"%@Created attach retry sequence %@", self.logMessagePrefix, self.retrySequence);
    }

    ARTRetryAttempt *const retryAttempt = [self.retrySequence addRetryAttempt];
    ARTLogDebug(self.logger, @"%@Adding attach retry attempt to %@ gave %@", self.logMessagePrefix, self.retrySequence.id, retryAttempt);

    return retryAttempt;
}

- (void)channelWillTransitionToState:(ARTRealtimeChannelState)state {
    // The client library specification doesn’t specify when to reset the retry count (see https://github.com/ably/specification/issues/127); have taken the logic from ably-js: https://github.com/ably/ably-js/blob/404c4128316cc5f735e3bf95a25e654e3fedd166/src/common/lib/client/realtimechannel.ts#L804-L806 (see discussion https://github.com/ably/ably-js/pull/1008/files#r925898316)
    if (state != ARTRealtimeChannelAttaching && state != ARTRealtimeChannelSuspended) {
        self.retrySequence = nil;
    }
}

@end
