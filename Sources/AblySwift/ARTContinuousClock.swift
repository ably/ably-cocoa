import Foundation

// swift-migration: original location ARTContinuousClock.h, line 12 and ARTContinuousClock.m, line 16
/**
 A clock that increments monotonically, including while the system is asleep.

 - Note: We don't give this one an `NS_SWIFT_NAME`, to avoid confusion with the Swift standard library type also named `ContinuousClock`.
 */
internal class ARTContinuousClock: NSObject {
    
    // swift-migration: original location ARTContinuousClock.h, line 17 and ARTContinuousClock.m, line 18
    /**
     Returns the current instant in time.
     */
    internal func now() -> ARTContinuousClockInstant {
        let time = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        return ARTContinuousClockInstant(time: time)
    }
    
    // swift-migration: original location ARTContinuousClock.h, line 22 and ARTContinuousClock.m, line 23
    /**
     Returns the instant in time that occurs after a given duration has elapsed in relation to a given instant in time.
     */
    internal func addingDuration(_ duration: TimeInterval, toInstant instant: ARTContinuousClockInstant) -> ARTContinuousClockInstant {
        let time = instant.timeInNanosecondsSinceClockReferenceInstant + UInt64(duration * Double(NSEC_PER_SEC))
        return ARTContinuousClockInstant(time: time)
    }
}

// swift-migration: original location ARTContinuousClock.h, line 29 and ARTContinuousClock.m, line 30
/**
 Represents an instant in time, as described by an instance of `ARTContinuousClock`.
 */
internal class ARTContinuousClockInstant: NSObject {
    
    // swift-migration: original location ARTContinuousClock.m, line 12
    /**
     The value returned by `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)` at this instant.

     We choose `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)` as it gives us a clock that increments whilst the system is asleep. Its use is recommended by the documentation for `mach_continuous_time`.
     */
    internal let timeInNanosecondsSinceClockReferenceInstant: UInt64
    
    // swift-migration: original location ARTContinuousClock.m, line 5 and ARTContinuousClock.m, line 36
    internal init(time: UInt64) {
        self.timeInNanosecondsSinceClockReferenceInstant = time
        super.init()
    }
    
    // swift-migration: original location ARTContinuousClock.m, line 32
    internal override var description: String {
        return "<\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): time: \(timeInNanosecondsSinceClockReferenceInstant)>"
    }
    
    // swift-migration: original location ARTContinuousClock.h, line 36 and ARTContinuousClock.m, line 44
    /**
     Returns `YES` if and only if the instant in time represented by `other` occurs after that represented by the receiver.
     */
    internal func isAfter(_ other: ARTContinuousClockInstant) -> Bool {
        return timeInNanosecondsSinceClockReferenceInstant > other.timeInNanosecondsSinceClockReferenceInstant
    }
}