import Foundation

// swift-migration: original location ARTBackoffRetryDelayCalculator.h, line 12 and ARTBackoffRetryDelayCalculator.m, line 15
internal class BackoffRetryDelayCalculator: NSObject, RetryDelayCalculator {
    
    // swift-migration: original location ARTBackoffRetryDelayCalculator.m, line 8
    private let initialRetryTimeout: TimeInterval
    
    // swift-migration: original location ARTBackoffRetryDelayCalculator.m, line 9
    private let jitterCoefficientGenerator: JitterCoefficientGenerator
    
    // swift-migration: original location ARTBackoffRetryDelayCalculator.h, line 23 and ARTBackoffRetryDelayCalculator.m, line 17
    internal init(initialRetryTimeout: TimeInterval, jitterCoefficientGenerator: JitterCoefficientGenerator) {
        self.initialRetryTimeout = initialRetryTimeout
        self.jitterCoefficientGenerator = jitterCoefficientGenerator
        super.init()
    }
    
    // swift-migration: original location ARTRetryDelayCalculator.h, line 19 and ARTBackoffRetryDelayCalculator.m, line 27
    internal func delayForRetryNumber(_ retryNumber: Int) -> TimeInterval {
        let backoffCoefficient = BackoffRetryDelayCalculator.backoffCoefficient(forRetryNumber: retryNumber)
        let jitterCoefficient = jitterCoefficientGenerator.generateJitterCoefficient()
        
        return initialRetryTimeout * backoffCoefficient * jitterCoefficient
    }
    
    // swift-migration: original location ARTBackoffRetryDelayCalculator.m, line 34
    internal static func backoffCoefficient(forRetryNumber retryNumber: Int) -> Double {
        return min(Double(retryNumber + 2) / 3.0, 2.0)
    }
}
