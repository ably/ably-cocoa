// Test-only accessors for the `ARTRealtimeChannel` LiveObjects seam, moved out of the shipped sources so that
// production code carries no test plumbing. Consumed by AblyLiveObjectsTests via
// `@testable import AblyLiveObjectsTesting`. See README.md for the dumb-accessor review rule.

import Ably
@testable import AblyLiveObjects

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension ARTRealtimeChannel {
    /// For tests to access the non-public API of `PublicDefaultRealtimeObject`.
    var testsOnly_nonTypeErasedObject: PublicDefaultRealtimeObject {
        nonTypeErasedObject
    }
}
