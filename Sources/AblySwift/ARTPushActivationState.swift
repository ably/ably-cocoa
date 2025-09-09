import Foundation

// swift-migration: original location ARTPushActivationState.h, line 9 and ARTPushActivationState.m, line 23
internal class ARTPushActivationState: NSObject, NSSecureCoding {
    
    // swift-migration: original location ARTPushActivationState.h, line 16
    internal weak var machine: ARTPushActivationStateMachine?
    
    // swift-migration: original location ARTPushActivationState.m, line 17
    internal let logger: ARTInternalLog

    // swift-migration: original location ARTPushActivationState.h, line 12 and ARTPushActivationState.m, line 25
    internal required init(machine: ARTPushActivationStateMachine?, logger: ARTInternalLog) {
        self.machine = machine
        self.logger = logger
        super.init()
    }

    // swift-migration: original location ARTPushActivationState.h, line 14 and ARTPushActivationState.m, line 33
    internal static func new(withMachine machine: ARTPushActivationStateMachine?, logger: ARTInternalLog) -> Self {
        return self.init(machine: machine, logger: logger)
    }

    // swift-migration: original location ARTPushActivationState.m, line 37
    internal func logEventTransition(_ event: ARTPushActivationEvent, file: String = #fileID, line: UInt = #line) {
        ARTLogDebug(logger, "ARTPush Activation: \(type(of: self)) state: handling \(type(of: event)) event")
    }

    // swift-migration: original location ARTPushActivationState.h, line 18 and ARTPushActivationState.m, line 41
    internal func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        fatalError("-[\(type(of: self)):\(#line) \(#function)] should always be overriden; class \(type(of: self)) doesn't.")
    }

    // swift-migration: original location ARTPushActivationState.m, line 46
    func copy(with zone: NSZone?) -> Any {
        // Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.
        return self
    }

    // MARK: - NSCoding

    // swift-migration: original location ARTPushActivationState.m, line 53
    required init?(coder aDecoder: NSCoder) {
        // swift-migration: Note - logger and machine cannot be decoded from archive, will need to be set after unarchiving
        // Create a placeholder logger - this will be replaced when the state is actually used
        let placeholderCore = PlaceholderLogCore()
        self.logger = ARTInternalLog(core: placeholderCore)
        super.init()
    }

    // swift-migration: original location ARTPushActivationState.m, line 58
    func encode(with aCoder: NSCoder) {
        // Just to persist the class info, no properties
    }

    // MARK: - NSSecureCoding

    // swift-migration: original location ARTPushActivationState.m, line 64
    static var supportsSecureCoding: Bool {
        return true
    }

    // MARK: - Archive/Unarchive

    // swift-migration: original location ARTPushActivationState.h, line 20 and ARTPushActivationState.m, line 70
    internal func archive() -> Data {
        return self.art_archive(withLogger: self.logger)
    }

    // swift-migration: original location ARTPushActivationState.h, line 21 and ARTPushActivationState.m, line 74
    internal static func unarchive(_ data: Data, withLogger logger: ARTInternalLog?) -> ARTPushActivationState? {
        return self.art_unarchive(fromData: data, withLogger: logger)
    }
}

// MARK: - Persistent State

// swift-migration: original location ARTPushActivationState.h, line 26 and ARTPushActivationState.m, line 82
internal class ARTPushActivationPersistentState: ARTPushActivationState {
}

// MARK: - Helper function

// swift-migration: original location ARTPushActivationState.m, line 87
private func validateAndSync(_ machine: ARTPushActivationStateMachine, _ event: ARTPushActivationEvent, _ logger: ARTInternalLog) -> ARTPushActivationState {
    #if os(iOS)
    let local = machine.rest.device_nosync
    
    if let identityTokenDetails = local.identityTokenDetails {
        // Already registered.
        let instanceClientId = machine.rest.auth.clientId_nosync
        if let localClientId = local.clientId, let instanceClientId = instanceClientId, localClientId != instanceClientId {
            let error = ARTErrorInfo(code: 61002, message: "Activation failed: present clientId is not compatible with existing device registration")
            machine.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: error))
        } else {
            machine.syncDevice()
        }
        
        return ARTPushActivationStateWaitingForRegistrationSync.new(withMachine: machine, logger: logger, fromEvent: event)
    } else if local.apnsDeviceToken() != nil {
        machine.sendEvent(ARTPushActivationEventGotPushDeviceDetails())
    }
    machine.rest.setupLocalDevice_nosync()
    machine.registerForAPNS()
    #endif
    
    return ARTPushActivationStateWaitingForPushDeviceDetails.new(withMachine: machine, logger: logger)
}

// MARK: - Activation States

// swift-migration: original location ARTPushActivationState.h, line 31 and ARTPushActivationState.m, line 112
internal class ARTPushActivationStateNotActivated: ARTPushActivationPersistentState {

    // swift-migration: original location ARTPushActivationState.m, line 114
    internal override func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        logEventTransition(event)
        if event is ARTPushActivationEventCalledDeactivate {
            #if os(iOS)
            let device = self.machine?.rest.device_nosync
            #else
            let device: ARTLocalDevice? = nil
            #endif
            // RSH3a1c
            if device?.isRegistered() == true {
                self.machine?.deviceUnregistration(nil)
                return ARTPushActivationStateWaitingForDeregistration.new(withMachine: self.machine!, logger: self.logger)
            // RSH3a1d
            } else {
                #if os(iOS)
                self.machine?.rest.resetLocalDevice_nosync()
                #endif
                self.machine?.callDeactivatedCallback(nil)
                return self
            }
        }
        else if event is ARTPushActivationEventCalledActivate {
            return validateAndSync(self.machine!, event, self.logger)
        }
        else if event is ARTPushActivationEventGotPushDeviceDetails {
            return self // Consuming event (RSH3a3a)
        }
        return nil
    }
}

// swift-migration: original location ARTPushActivationState.h, line 34 and ARTPushActivationState.m, line 146
internal class ARTPushActivationStateWaitingForDeviceRegistration: ARTPushActivationState {

    // swift-migration: original location ARTPushActivationState.m, line 148
    internal override func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        logEventTransition(event)
        if event is ARTPushActivationEventCalledActivate {
            return self
        }
        else if let gotDeviceRegistrationEvent = event as? ARTPushActivationEventGotDeviceRegistration {
            #if os(iOS)
            let local = self.machine?.rest.device_nosync
            local?.setAndPersistIdentityTokenDetails(gotDeviceRegistrationEvent.identityTokenDetails)
            #endif
            self.machine?.callActivatedCallback(nil)
            return ARTPushActivationStateWaitingForNewPushDeviceDetails.new(withMachine: self.machine!, logger: self.logger)
        }
        else if let gettingDeviceRegistrationFailedEvent = event as? ARTPushActivationEventGettingDeviceRegistrationFailed {
            self.machine?.callActivatedCallback(gettingDeviceRegistrationFailedEvent.error)
            return ARTPushActivationStateNotActivated.new(withMachine: self.machine!, logger: self.logger)
        }
        return nil
    }
}

// swift-migration: original location ARTPushActivationState.h, line 37 and ARTPushActivationState.m, line 171
internal class ARTPushActivationStateWaitingForPushDeviceDetails: ARTPushActivationPersistentState {

    // swift-migration: original location ARTPushActivationState.m, line 173
    internal override func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        logEventTransition(event)
        if event is ARTPushActivationEventCalledActivate {
            return ARTPushActivationStateWaitingForPushDeviceDetails.new(withMachine: self.machine!, logger: self.logger)
        }
        else if event is ARTPushActivationEventCalledDeactivate {
            self.machine?.callDeactivatedCallback(nil)
            return ARTPushActivationStateNotActivated.new(withMachine: self.machine!, logger: self.logger)
        }
        else if event is ARTPushActivationEventGotPushDeviceDetails {
            self.machine?.deviceRegistration(nil)
            return ARTPushActivationStateWaitingForDeviceRegistration.new(withMachine: self.machine!, logger: self.logger)
        }
        else if let gettingPushDeviceDetailsFailedEvent = event as? ARTPushActivationEventGettingPushDeviceDetailsFailed {
            self.machine?.callActivatedCallback(gettingPushDeviceDetailsFailedEvent.error)
            return ARTPushActivationStateNotActivated.new(withMachine: self.machine!, logger: self.logger)
        }
        return nil
    }
}

// swift-migration: original location ARTPushActivationState.h, line 40 and ARTPushActivationState.m, line 195
internal class ARTPushActivationStateWaitingForNewPushDeviceDetails: ARTPushActivationPersistentState {

    // swift-migration: original location ARTPushActivationState.m, line 197
    internal override func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        logEventTransition(event)
        if event is ARTPushActivationEventCalledActivate {
            self.machine?.callActivatedCallback(nil)
            return self
        }
        else if event is ARTPushActivationEventCalledDeactivate {
            self.machine?.deviceUnregistration(nil)
            return ARTPushActivationStateWaitingForDeregistration.new(withMachine: self.machine!, logger: self.logger)
        }
        else if event is ARTPushActivationEventGotPushDeviceDetails {
            self.machine?.deviceUpdateRegistration(nil)
            return ARTPushActivationStateWaitingForRegistrationSync.new(withMachine: self.machine!, logger: self.logger, fromEvent: event)
        }
        return nil
    }
}

// swift-migration: original location ARTPushActivationState.h, line 43 and ARTPushActivationState.m, line 216
internal class ARTPushActivationStateWaitingForRegistrationSync: ARTPushActivationState {
    
    // swift-migration: original location ARTPushActivationState.m, line 217
    private let fromEvent: ARTPushActivationEvent

    // swift-migration: original location ARTPushActivationState.h, line 48 and ARTPushActivationState.m, line 220
    internal init(machine: ARTPushActivationStateMachine, logger: ARTInternalLog, fromEvent: ARTPushActivationEvent) {
        self.fromEvent = fromEvent
        super.init(machine: machine, logger: logger)
    }
    
    // swift-migration: Required initializer
    internal required init(machine: ARTPushActivationStateMachine?, logger: ARTInternalLog) {
        self.fromEvent = ARTPushActivationEvent()
        super.init(machine: machine, logger: logger)
    }

    // swift-migration: original location ARTPushActivationState.h, line 49 and ARTPushActivationState.m, line 227
    internal static func new(withMachine machine: ARTPushActivationStateMachine, logger: ARTInternalLog, fromEvent: ARTPushActivationEvent) -> ARTPushActivationStateWaitingForRegistrationSync {
        return ARTPushActivationStateWaitingForRegistrationSync(machine: machine, logger: logger, fromEvent: fromEvent)
    }

    // swift-migration: original location ARTPushActivationState.m, line 231
    internal override func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        logEventTransition(event)
        if event is ARTPushActivationEventCalledActivate && !(fromEvent is ARTPushActivationEventCalledActivate) {
            self.machine?.callActivatedCallback(nil)
            return self
        }
        else if let registrationSyncedEvent = event as? ARTPushActivationEventRegistrationSynced {
            #if os(iOS)
            if let identityTokenDetails = registrationSyncedEvent.identityTokenDetails {
                let local = self.machine?.rest.device_nosync
                local?.setAndPersistIdentityTokenDetails(identityTokenDetails)
            }
            #endif

            if fromEvent is ARTPushActivationEventCalledActivate {
                self.machine?.callActivatedCallback(nil)
            } else {
                self.machine?.callUpdatedCallback(nil)
            }

            return ARTPushActivationStateWaitingForNewPushDeviceDetails.new(withMachine: self.machine!, logger: self.logger)
        }
        else if let syncRegistrationFailedEvent = event as? ARTPushActivationEventSyncRegistrationFailed {
            let error = syncRegistrationFailedEvent.error
            if fromEvent is ARTPushActivationEventCalledActivate {
                self.machine?.callActivatedCallback(error)
            } else {
                self.machine?.callUpdatedCallback(error)
            }

            return ARTPushActivationStateAfterRegistrationSyncFailed.new(withMachine: self.machine!, logger: self.logger)
        }
        return nil
    }

    // swift-migration: NSCoding support for fromEvent
    required init?(coder aDecoder: NSCoder) {
        // swift-migration: fromEvent cannot be decoded properly, using placeholder
        self.fromEvent = ARTPushActivationEvent()
        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        // swift-migration: fromEvent encoding - may need adjustment
        aCoder.encode(fromEvent, forKey: "fromEvent")
    }
}

// swift-migration: original location ARTPushActivationState.h, line 55 and ARTPushActivationState.m, line 269
internal class ARTPushActivationStateAfterRegistrationSyncFailed: ARTPushActivationPersistentState {

    // swift-migration: original location ARTPushActivationState.m, line 271
    internal override func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        logEventTransition(event)
        if event is ARTPushActivationEventCalledActivate ||
           event is ARTPushActivationEventGotPushDeviceDetails {

            return validateAndSync(self.machine!, event, self.logger)
        }
        else if event is ARTPushActivationEventCalledDeactivate {
            self.machine?.deviceUnregistration(nil)
            return ARTPushActivationStateWaitingForDeregistration.new(withMachine: self.machine!, logger: self.logger)
        }
        return nil
    }
}

// swift-migration: original location ARTPushActivationState.h, line 58 and ARTPushActivationState.m, line 287
internal class ARTPushActivationStateWaitingForDeregistration: ARTPushActivationState {

    // swift-migration: original location ARTPushActivationState.m, line 289
    internal override func transition(_ event: ARTPushActivationEvent) -> ARTPushActivationState? {
        logEventTransition(event)
        if event is ARTPushActivationEventCalledDeactivate {
            return ARTPushActivationStateWaitingForDeregistration.new(withMachine: self.machine!, logger: self.logger)
        }
        else if event is ARTPushActivationEventDeregistered {
            #if os(iOS)
            self.machine?.rest.resetLocalDevice_nosync()
            #endif
            self.machine?.callDeactivatedCallback(nil)
            return ARTPushActivationStateNotActivated.new(withMachine: self.machine!, logger: self.logger)
        }
        else if let deregistrationFailedEvent = event as? ARTPushActivationEventDeregistrationFailed {
            self.machine?.callDeactivatedCallback(deregistrationFailedEvent.error)
            return ARTPushActivationStateWaitingForDeregistration.new(withMachine: self.machine!, logger: self.logger)
        }
        return nil
    }
}

// MARK: - Deprecated states for backwards compatibility

// swift-migration: original location ARTPushActivationState.h, line 63 and ARTPushActivationState.m, line 310
internal class ARTPushActivationDeprecatedPersistentState: ARTPushActivationPersistentState {

    // swift-migration: original location ARTPushActivationState.m, line 312
    internal func migrate() -> ARTPushActivationPersistentState {
        fatalError("must be implemented by subclass")
    }
}

// swift-migration: original location ARTPushActivationState.h, line 71 and ARTPushActivationState.m, line 319
internal class ARTPushActivationStateAfterRegistrationUpdateFailed: ARTPushActivationDeprecatedPersistentState {

    // swift-migration: original location ARTPushActivationState.m, line 321
    internal override func migrate() -> ARTPushActivationPersistentState {
        return ARTPushActivationStateAfterRegistrationSyncFailed(machine: self.machine!, logger: self.logger)
    }
}