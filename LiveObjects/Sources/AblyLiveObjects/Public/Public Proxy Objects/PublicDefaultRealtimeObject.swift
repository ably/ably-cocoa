import Ably

/// The default implementation of the public ``RealtimeObject`` entry point, backing
/// ``ARTRealtimeChannel/object``.
///
/// This is largely a wrapper around ``InternalDefaultRealtimeObjects``. The `Public` prefix
/// expresses the contrast with that internal type, per the documented memory-management policy (the
/// public proxy holds a strong reference to the internal object, not vice versa); hence it lives
/// alongside the other proxy objects in `Public/Public Proxy Objects`.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal final class PublicDefaultRealtimeObject: RealtimeObject {
    private let proxied: InternalDefaultRealtimeObjects

    // MARK: - Dependencies that hold a strong reference to `proxied`

    private let coreSDK: CoreSDK
    private let logger: Logger

    internal init(proxied: InternalDefaultRealtimeObjects, coreSDK: CoreSDK, logger: Logger) {
        self.proxied = proxied
        self.coreSDK = coreSDK
        self.logger = logger
    }

    internal var testsOnly_proxied: InternalDefaultRealtimeObjects {
        proxied
    }

    internal var testsOnly_coreSDK: CoreSDK {
        coreSDK
    }

    // MARK: - `RealtimeObject` protocol

    internal func get() async throws(ARTErrorInfo) -> any LiveMapPathObject {
        notImplemented()
    }

    @discardableResult
    internal func on(event _: ObjectsEvent, callback _: @escaping @Sendable () -> Void) -> any StatusSubscription {
        notImplemented()
    }
}
