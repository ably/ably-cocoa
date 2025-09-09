import Foundation

// swift-migration: original location ARTPushActivationEvent.m, line 6
let ARTCoderErrorKey = "error"
// swift-migration: original location ARTPushActivationEvent.m, line 7
let ARTCoderIdentityTokenDetailsKey = "identityTokenDetails"

// swift-migration: original location ARTPushActivationEvent.h, line 10 and ARTPushActivationEvent.m, line 9
internal class ARTPushActivationEvent: NSObject, NSSecureCoding {
    
    // swift-migration: original location ARTPushActivationEvent.m, line 11
    func copy(with zone: NSZone?) -> Any {
        // Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.
        return self
    }

    // MARK: - NSCoding

    // swift-migration: original location ARTPushActivationEvent.m, line 18
    required init?(coder aDecoder: NSCoder) {
        super.init()
    }

    // swift-migration: original location ARTPushActivationEvent.m, line 23
    func encode(with aCoder: NSCoder) {
        // Just to persist the class info, no properties
    }

    // MARK: - NSSecureCoding

    // swift-migration: original location ARTPushActivationEvent.m, line 29
    static var supportsSecureCoding: Bool {
        return true
    }

    // MARK: - Archive/Unarchive

    // swift-migration: original location ARTPushActivationEvent.h, line 12 and ARTPushActivationEvent.m, line 35
    internal func archiveWithLogger(_ logger: ARTInternalLog?) -> Data {
        return self.art_archive(withLogger: logger) ?? Data()
    }

    // swift-migration: original location ARTPushActivationEvent.h, line 13 and ARTPushActivationEvent.m, line 39
    // swift-migration: Fixed return type from ARTPushActivationState to ARTPushActivationEvent (header error)
    internal static func unarchive(_ data: Data, withLogger logger: ARTInternalLog?) -> ARTPushActivationEvent? {
        return self.art_unarchive(fromData: data, withLogger: logger) as? ARTPushActivationEvent
    }

    override init() {
        super.init()
    }
}

// MARK: - Event with Error info

// swift-migration: original location ARTPushActivationEvent.h, line 18 and ARTPushActivationEvent.m, line 47
internal class ARTPushActivationErrorEvent: ARTPushActivationEvent {
    
    // swift-migration: original location ARTPushActivationEvent.h, line 20
    internal let error: ARTErrorInfo

    // swift-migration: original location ARTPushActivationEvent.h, line 22 and ARTPushActivationEvent.m, line 49
    internal init(error: ARTErrorInfo) {
        self.error = error
        super.init()
    }

    // swift-migration: original location ARTPushActivationEvent.h, line 23 and ARTPushActivationEvent.m, line 56
    internal static func new(withError error: ARTErrorInfo) -> ARTPushActivationErrorEvent {
        return ARTPushActivationErrorEvent(error: error)
    }

    // swift-migration: original location ARTPushActivationEvent.m, line 60
    required init?(coder aDecoder: NSCoder) {
        if let decodedError = aDecoder.decodeObject(forKey: ARTCoderErrorKey) as? ARTErrorInfo {
            self.error = decodedError
        } else {
            // Handle case where error cannot be decoded
            self.error = ARTErrorInfo(code: 0, message: "Failed to decode error")
        }
        super.init(coder: aDecoder)
    }

    // swift-migration: original location ARTPushActivationEvent.m, line 67
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.error, forKey: ARTCoderErrorKey)
    }
}

// MARK: - Event with Device Identity Token details

// swift-migration: original location ARTPushActivationEvent.h, line 28 and ARTPushActivationEvent.m, line 76
internal class ARTPushActivationDeviceIdentityEvent: ARTPushActivationEvent {
    
    // swift-migration: original location ARTPushActivationEvent.h, line 30
    internal let identityTokenDetails: ARTDeviceIdentityTokenDetails?

    // swift-migration: original location ARTPushActivationEvent.h, line 35 and ARTPushActivationEvent.m, line 78
    internal init(identityTokenDetails: ARTDeviceIdentityTokenDetails?) {
        self.identityTokenDetails = identityTokenDetails
        super.init()
    }

    // swift-migration: original location ARTPushActivationEvent.h, line 33 and ARTPushActivationEvent.m, line 85
    internal static func new() -> ARTPushActivationDeviceIdentityEvent {
        return ARTPushActivationDeviceIdentityEvent(identityTokenDetails: nil)
    }

    // swift-migration: original location ARTPushActivationEvent.h, line 36 and ARTPushActivationEvent.m, line 89
    internal static func new(withIdentityTokenDetails identityTokenDetails: ARTDeviceIdentityTokenDetails) -> ARTPushActivationDeviceIdentityEvent {
        return ARTPushActivationDeviceIdentityEvent(identityTokenDetails: identityTokenDetails)
    }

    // swift-migration: original location ARTPushActivationEvent.m, line 93
    required init?(coder aDecoder: NSCoder) {
        self.identityTokenDetails = aDecoder.decodeObject(forKey: ARTCoderIdentityTokenDetailsKey) as? ARTDeviceIdentityTokenDetails
        super.init(coder: aDecoder)
    }

    // swift-migration: original location ARTPushActivationEvent.m, line 100
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.identityTokenDetails, forKey: ARTCoderIdentityTokenDetailsKey)
    }
}

// MARK: - Activation Events

// swift-migration: original location ARTPushActivationEvent.h, line 42 and ARTPushActivationEvent.m, line 109
internal class ARTPushActivationEventCalledActivate: ARTPushActivationEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 45 and ARTPushActivationEvent.m, line 112
internal class ARTPushActivationEventCalledDeactivate: ARTPushActivationEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 48 and ARTPushActivationEvent.m, line 115
internal class ARTPushActivationEventGotPushDeviceDetails: ARTPushActivationEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 51 and ARTPushActivationEvent.m, line 118
internal class ARTPushActivationEventGettingPushDeviceDetailsFailed: ARTPushActivationErrorEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 54 and ARTPushActivationEvent.m, line 121
internal class ARTPushActivationEventGotDeviceRegistration: ARTPushActivationDeviceIdentityEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 57 and ARTPushActivationEvent.m, line 124
internal class ARTPushActivationEventGettingDeviceRegistrationFailed: ARTPushActivationErrorEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 60 and ARTPushActivationEvent.m, line 127
internal class ARTPushActivationEventRegistrationSynced: ARTPushActivationDeviceIdentityEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 63 and ARTPushActivationEvent.m, line 130
internal class ARTPushActivationEventSyncRegistrationFailed: ARTPushActivationErrorEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 66 and ARTPushActivationEvent.m, line 133
internal class ARTPushActivationEventDeregistered: ARTPushActivationEvent {
}

// swift-migration: original location ARTPushActivationEvent.h, line 69 and ARTPushActivationEvent.m, line 136
internal class ARTPushActivationEventDeregistrationFailed: ARTPushActivationErrorEvent {
}