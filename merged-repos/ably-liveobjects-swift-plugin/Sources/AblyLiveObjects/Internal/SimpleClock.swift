import Foundation

/// A simple clock interface for getting the current time.
///
/// This protocol allows for dependency injection of time-related functionality,
/// making it easier to test time-dependent code.
@available(macOS 10.15, iOS 13, tvOS 13, *)
internal protocol SimpleClock: Sendable {
    /// Returns the current time as a Date.
    var now: Date { get }
}

/// The default implementation of SimpleClock that uses the system clock.
@available(macOS 10.15, iOS 13, tvOS 13, *)
internal final class DefaultSimpleClock: SimpleClock {
    internal init() {}

    internal var now: Date {
        Date()
    }
}
