internal import AblyPlugin

/// This is the equivalent of the `LiveObject` abstract class described in RTLO.
///
/// ``DefaultLiveCounter`` and ``DefaultLiveMap`` include it by composition.
internal struct LiveObjectMutableState {
    // RTLO3a
    internal var objectID: String
    // RTLO3b
    internal var siteTimeserials: [String: String] = [:]
    // RTLO3c
    internal var createOperationIsMerged = false

    /// Represents parameters of an operation that `canApplyOperation` has decided can be applied to a `LiveObject`.
    ///
    /// The key thing is that it offers a non-nil `serial` and `siteCode`, which will be needed when subsequently performing the operation.
    internal struct ApplicableOperation: Equatable {
        internal let objectMessageSerial: String
        internal let objectMessageSiteCode: String
    }

    /// Indicates whether an operation described by an `ObjectMessage` should be applied or discarded, per RTLO4a.
    ///
    /// Instead of returning a `Bool`, in the case where the operation can be applied it returns a non-nil `ApplicableOperation` (whose non-nil `serial` and `siteCode` will be needed as part of subsequently performing this operation).
    internal func canApplyOperation(objectMessageSerial: String?, objectMessageSiteCode: String?, logger: Logger) -> ApplicableOperation? {
        // RTLO4a3: Both ObjectMessage.serial and ObjectMessage.siteCode must be non-empty strings
        guard let serial = objectMessageSerial, !serial.isEmpty,
              let siteCode = objectMessageSiteCode, !siteCode.isEmpty
        else {
            // RTLO4a3: Otherwise, log a warning that the object operation message has invalid serial values
            logger.log("Object operation message has invalid serial values: serial=\(objectMessageSerial ?? "nil"), siteCode=\(objectMessageSiteCode ?? "nil")", level: .warn)
            return nil
        }

        // RTLO4a4: Get the siteSerial value stored for this LiveObject in the siteTimeserials map using the key ObjectMessage.siteCode
        let siteSerial = siteTimeserials[siteCode]

        // RTLO4a5: If the siteSerial for this LiveObject is null or an empty string, return true
        guard let siteSerial, !siteSerial.isEmpty else {
            return ApplicableOperation(objectMessageSerial: serial, objectMessageSiteCode: siteCode)
        }

        // RTLO4a6: If the siteSerial for this LiveObject is not an empty string, return true if ObjectMessage.serial is greater than siteSerial when compared lexicographically
        if serial > siteSerial {
            return ApplicableOperation(objectMessageSerial: serial, objectMessageSiteCode: siteCode)
        }

        return nil
    }
}
