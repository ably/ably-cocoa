#import "ARTConnectRetryState.h"
#import "ARTRetryDelayCalculator.h"
#import "ARTRetrySequence.h"
#import "ARTInternalLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTConnectRetryState ()

@property (nonatomic, readonly) ARTInternalLog *logger;
@property (nonatomic, readonly) NSString *logMessagePrefix;
@property (nonatomic, readonly) id<ARTRetryDelayCalculator> retryDelayCalculator;
@property (nonatomic, nullable) ARTRetrySequence *retrySequence;

@end

NS_ASSUME_NONNULL_END

@implementation ARTConnectRetryState

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
        ARTLogDebug(self.logger, @"%@Created connect retry sequence %@", self.logMessagePrefix, self.retrySequence);
    }

    ARTRetryAttempt *const retryAttempt = [self.retrySequence addRetryAttempt];
    ARTLogDebug(self.logger, @"%@Adding connect retry attempt to %@ gave %@", self.logMessagePrefix, self.retrySequence.id, retryAttempt);

    return retryAttempt;
}

- (void)connectionWillTransitionToState:(ARTRealtimeConnectionState)state {
    // The client library specification doesn’t specify when to reset the retry count (see https://github.com/ably/specification/issues/127); have copied the analogous logic in ARTAttachRetryState.
    if (state != ARTRealtimeConnecting && state != ARTRealtimeDisconnected) {
        self.retrySequence = nil;
    }
}

@end
