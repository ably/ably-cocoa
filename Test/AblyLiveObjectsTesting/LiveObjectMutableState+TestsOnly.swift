// Test-only initializer for `LiveObjectMutableState`, moved out of the shipped sources so that
// production code carries no test plumbing. Consumed by AblyLiveObjectsTests via
// `@testable import AblyLiveObjectsTesting`. See README.md for the dumb-accessor review rule.

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
