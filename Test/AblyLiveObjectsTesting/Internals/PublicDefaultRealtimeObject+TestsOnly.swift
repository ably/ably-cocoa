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
