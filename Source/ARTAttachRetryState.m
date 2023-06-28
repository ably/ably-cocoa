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
    // Note: we currently reset the retry sequence every time we wish to perform a retry (defeating the point of using it in the first place, but it's OK since the delays are all constant). As part of implementing #1431 we will reuse any existing retry sequence, resetting it only in response to certain state changes.
    self.retrySequence = [[ARTRetrySequence alloc] initWithDelayCalculator:self.retryDelayCalculator];
    ARTLogDebug(self.logger, @"%@Created attach retry sequence %@", self.logMessagePrefix, self.retrySequence);

    ARTRetryAttempt *const retryAttempt = [self.retrySequence addRetryAttempt];
    ARTLogDebug(self.logger, @"%@Adding attach retry attempt to %@ gave %@", self.logMessagePrefix, self.retrySequence.id, retryAttempt);

    return retryAttempt;
}

@end
