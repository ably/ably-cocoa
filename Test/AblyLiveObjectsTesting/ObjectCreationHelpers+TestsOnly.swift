// Test-only accessors for `ObjectCreationHelpers`, moved out of the shipped sources so that
// production code carries no test plumbing. Consumed by AblyLiveObjectsTests via
// `@testable import AblyLiveObjectsTesting`. See README.md for the dumb-accessor review rule.

@testable import AblyLiveObjects
import Foundation

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension ObjectCreationHelpers {
    /// Creates an Object ID for a new LiveObject instance, per RTO14.
    static func testsOnly_createObjectID(
        type: String,
        initialValue: String,
        nonce: String,
        timestamp: Date,
    ) -> String {
        createObjectID(
            type: type,
            initialValue: initialValue,
            nonce: nonce,
            timestamp: timestamp,
        )
    }
}
