#import "ARTBackoffRetryDelayCalculator.h"
#import "ARTJitterCoefficientGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTBackoffRetryDelayCalculator ()

@property (nonatomic, readonly) NSTimeInterval initialRetryTimeout;
@property (nonatomic, readonly) id<ARTJitterCoefficientGenerator> jitterCoefficientGenerator;

@end

NS_ASSUME_NONNULL_END

@implementation ARTBackoffRetryDelayCalculator

- (instancetype)initWithInitialRetryTimeout:(NSTimeInterval)initialRetryTimeout
                 jitterCoefficientGenerator:(id<ARTJitterCoefficientGenerator>)jitterCoefficientGenerator {
    if (self = [super init]) {
        _initialRetryTimeout = initialRetryTimeout;
        _jitterCoefficientGenerator = jitterCoefficientGenerator;
    }

    return self;
}

- (NSTimeInterval)delayForRetryNumber:(NSInteger)retryNumber {
    const double backoffCoefficient = [ARTBackoffRetryDelayCalculator backoffCoefficientForRetryNumber:retryNumber];
    const double jitterCoefficient = [self.jitterCoefficientGenerator generateJitterCoefficient];

    return self.initialRetryTimeout * backoffCoefficient * jitterCoefficient;
}

+ (double)backoffCoefficientForRetryNumber:(NSInteger)retryNumber {
    return MIN((NSTimeInterval)(retryNumber + 2.0) / 3.0, 2.0);
}

@end
