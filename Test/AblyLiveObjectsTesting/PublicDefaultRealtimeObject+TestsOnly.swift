// Test-only accessors for `PublicDefaultRealtimeObject`, moved out of the shipped sources so that
// production code carries no test plumbing. Consumed by AblyLiveObjectsTests via
// `@testable import AblyLiveObjectsTesting`. See README.md for the dumb-accessor review rule.

@testable import AblyLiveObjects

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension PublicDefaultRealtimeObject {
    var testsOnly_proxied: InternalDefaultRealtimeObjects {
        proxied
    }

    var testsOnly_coreSDK: CoreSDK {
        coreSDK
    }
}
