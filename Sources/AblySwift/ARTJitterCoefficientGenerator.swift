import Foundation

// swift-migration: original location ARTJitterCoefficientGenerator.h, line 9
/// An object which generates the random "jitter coefficient" used to determine when the library will next retry an operation.
public protocol ARTJitterCoefficientGenerator {
    /// Generates a random number (approximately uniformly distributed) in the range [0.8, 1], as required by RTB1b.
    ///
    /// Test implementations of `ARTJitterCoefficientGenerator` may return a non-random number.
    // swift-migration: original location ARTJitterCoefficientGenerator.h, line 16
    func generateJitterCoefficient() -> Double
}

// swift-migration: original location ARTJitterCoefficientGenerator.h, line 24 and ARTJitterCoefficientGenerator.m, line 4
/// The implementation of `ARTJitterCoefficientGenerator` that should be used in non-test code.
public class ARTDefaultJitterCoefficientGenerator: NSObject, ARTJitterCoefficientGenerator {
    
    // swift-migration: original location ARTJitterCoefficientGenerator.m, line 6
    public func generateJitterCoefficient() -> Double {
        return 0.8 + 0.2 * (Double(arc4random()) / Double(UInt32.max))
    }
}