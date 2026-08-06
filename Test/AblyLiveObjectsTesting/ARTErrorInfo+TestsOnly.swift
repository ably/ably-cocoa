// Test-only accessor for `ARTErrorInfo`, moved out of the shipped sources so that production
// code carries no test plumbing. Consumed by AblyLiveObjectsTests via
// `@testable import AblyLiveObjectsTesting`. See README.md for the dumb-accessor review rule.

import Ably
@testable import AblyLiveObjects

@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
extension ARTErrorInfo {
    /// Retrieves the underlying `LiveObjectsError` from this `ARTErrorInfo` if it was generated from
    /// one (`toARTErrorInfo()` stores it under `liveObjectsErrorUserInfoKey`), or nil otherwise.
    var testsOnly_underlyingLiveObjectsError: LiveObjectsError? {
        guard let userInfoEntry = userInfo[liveObjectsErrorUserInfoKey] else {
            return nil
        }

        guard let liveObjectsError = userInfoEntry as? LiveObjectsError else {
            preconditionFailure("Expected a LiveObjectsError, got \(userInfoEntry)")
        }

        return liveObjectsError
    }
}
