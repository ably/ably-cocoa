import Foundation

/**
 Consider an operation which can fail. If we attempt to perform the operation and it fails, we may wish to start performing a sequence of retries, until success or some other termination condition is achieved. An `ARTRetryDelayCalculator` describes the amount of time that we wish to wait before performing each retry in this sequence.
 */
// swift-migration: original location ARTRetryDelayCalculator.h, line 9
public protocol ARTRetryDelayCalculator {
    /**
     Returns the duration that should be waited before performing a retry of the operation.

     - Parameters:
       - retryNumber: The ordinal of the retry in the retry sequence, greater than or equal to 1. After the first attempt at the operation fails, the subsequent attempt is considered retry number 1.

         What constitutes the "first attempt" is for the caller to decide.
     */
    func delayForRetryNumber(_ retryNumber: Int) -> TimeInterval
}

/**
 Describes an intention to retry an operation.
 */
// swift-migration: original location ARTRetrySequence.h, line 40 and ARTRetrySequence.m, line 46
public class ARTRetryAttempt: NSObject {
    
    /**
     A unique identifier for this retry attempt, for logging purposes.
     */
    // swift-migration: original location ARTRetrySequence.h, line 47 and ARTRetrySequence.m, line 50
    public let id: UUID
    
    /**
     The duration that should we should wait before performing this retry of the operation.
     */
    // swift-migration: original location ARTRetrySequence.h, line 52 and ARTRetrySequence.m, line 51
    public let delay: TimeInterval
    
    // swift-migration: original location ARTRetrySequence.m, line 48
    public init(delay: TimeInterval) {
        self.id = UUID()
        self.delay = delay
        super.init()
    }
    
    // swift-migration: original location ARTRetrySequence.m, line 57
    public override var description: String {
        return "<\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): id: \(id), delay: \(String(format: "%.2f", delay))>"
    }
}

/**
 Consider an operation which can fail. If we attempt to perform the operation and it fails, we may wish to start performing a sequence of retries, until success or some other termination condition is achieved. An `ARTRetrySequence` keeps track of the number of retries that have been attempted. Each time its `addRetryAttempt` method is called, it increments its retry count, and returns an `ARTRetryAttempt` which describes the duration that we should wait before performing the retry of the operation.
 */
// swift-migration: original location ARTRetrySequence.h, line 12 and ARTRetrySequence.m, line 22
public class ARTRetrySequence: NSObject {
    
    /**
     A unique identifier for this retry sequence, for logging purposes.
     */
    // swift-migration: original location ARTRetrySequence.h, line 27 and ARTRetrySequence.m, line 26
    public let id: UUID
    
    // swift-migration: original location ARTRetrySequence.m, line 14
    private let delayCalculator: ARTRetryDelayCalculator
    
    // swift-migration: original location ARTRetrySequence.m, line 16
    // Starts off as zero, incremented each time -addRetryAttempt is called
    private var retryCount: Int = 0
    
    /**
     Creates a new retry sequence representing an operation which has not yet been retried.

     Parameters:
        - delayCalculator: The retry delay calculator used to calculate the duration after which each retry attempt should be performed.
     */
    // swift-migration: original location ARTRetrySequence.h, line 22 and ARTRetrySequence.m, line 24
    public init(delayCalculator: ARTRetryDelayCalculator) {
        self.id = UUID()
        self.delayCalculator = delayCalculator
        super.init()
    }
    
    // swift-migration: original location ARTRetrySequence.m, line 33
    public override var description: String {
        return "<\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): id: \(id), retryCount: \(retryCount)>"
    }
    
    /**
     Informs the receiver that we intend to schedule another retry of the operation. Increments the sequence's retry count and returns an `ARTRetryAttempt` object which describes how long we should wait before performing this retry.
     */
    // swift-migration: original location ARTRetrySequence.h, line 32 and ARTRetrySequence.m, line 37
    public func addRetryAttempt() -> ARTRetryAttempt {
        retryCount += 1
        let delay = delayCalculator.delayForRetryNumber(retryCount)
        return ARTRetryAttempt(delay: delay)
    }
}