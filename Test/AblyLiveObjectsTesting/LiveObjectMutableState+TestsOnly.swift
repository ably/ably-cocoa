@testable import AblyLiveObjects
import Foundation

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension LiveObjectMutableState {
    // MARK: - Test-only initializers

    init(
        objectID: String,
        testsOnly_siteTimeserials siteTimeserials: [String: String] = [:],
        testsOnly_tombstonedAt tombstonedAt: Date? = nil,
    ) {
        self.init(objectID: objectID)
        self.siteTimeserials = siteTimeserials
        self.tombstonedAt = tombstonedAt
    }
}
