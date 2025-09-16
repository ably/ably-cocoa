import Foundation

// swift-migration: Utility functions for handling Objective-C to Swift migration edge cases

/// Helper function to handle cases where Objective-C declarations have conflicting nullability declarations. For example, where the Objective-C code passes a value that's declared as nullable to a parameter that's not declared as nullable, which the Objective-C compiler does not usually catch.
///
/// - Parameter optionalValue: The optional value from Swift code  
/// - Returns: The value cast to non-optional type, preserving nil-passing behavior
func unwrapValueWithAmbiguousObjectiveCNullability<T>(_ optionalValue: T?) -> T {
    // swift-migration: Using unsafeBitCast to preserve original Objective-C nil-passing behavior
    // The receiving Objective-C method was designed to handle nil despite missing _Nullable annotation
    // This is safer than force unwrapping and preserves exact original behavior
    guard let value = optionalValue else {
        preconditionFailure("unwrapValueWithAmbiguousObjectiveCNullability unexpectedly got nil")
    }
    return value
}
