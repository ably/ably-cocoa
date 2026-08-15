import Ably
@testable import AblyLiveObjects

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension ARTRealtimeChannel {
    /// For tests to access the non-public API of `PublicDefaultRealtimeObject`.
    var testsOnly_nonTypeErasedObject: PublicDefaultRealtimeObject {
        nonTypeErasedObject
    }
}
