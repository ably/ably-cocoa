import Foundation

#if os(iOS)
import UIKit
#endif

// swift-migration: original location ARTPushActivationStateMachine.m, line 22
let ARTPushActivationCurrentStateKey = "ARTPushActivationCurrentState"
// swift-migration: original location ARTPushActivationStateMachine.m, line 23
let ARTPushActivationPendingEventsKey = "ARTPushActivationPendingEvents"

// swift-migration: original location ARTPushActivationStateMachine.h, line 12 and ARTPushActivationStateMachine.m, line 35
internal class ARTPushActivationStateMachine: NSObject {
    
    
    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 14
    internal let rest: ARTRestInternal
    
    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 21
    internal weak var delegate: (ARTPushRegistererDelegate & NSObjectProtocol)?
    
    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 23
    internal var transitions: ((ARTPushActivationEvent, ARTPushActivationState, ARTPushActivationState) -> Void)?
    
    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 24
    internal var onEvent: ((ARTPushActivationEvent, ARTPushActivationState) -> Void)?
    
    // swift-migration: original location ARTPushActivationStateMachine.m, line 29
    private let logger: ARTInternalLog
    
    // swift-migration: original location ARTPushActivationStateMachine.m, line 36
    private var lastHandledEvent: ARTPushActivationEvent?
    // swift-migration: original location ARTPushActivationStateMachine.m, line 37
    private var current: ARTPushActivationState
    // swift-migration: original location ARTPushActivationStateMachine.m, line 38
    private let queue: DispatchQueue
    // swift-migration: original location ARTPushActivationStateMachine.m, line 39
    private let userQueue: DispatchQueue
    // swift-migration: original location ARTPushActivationStateMachine.m, line 40
    private var pendingEvents: [ARTPushActivationEvent]

    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 16 and ARTPushActivationStateMachine.m, line 43
    internal init(rest: ARTRestInternal, delegate: (ARTPushRegistererDelegate & NSObjectProtocol), logger: ARTInternalLog) {
        self.rest = rest
        self.delegate = delegate
        self.queue = rest.queue
        self.userQueue = rest.userQueue
        self.logger = logger
        
        // swift-migration: Placeholder initialization - machine reference will be updated after super.init()
        self.current = ARTPushActivationStateNotActivated(machine: nil, logger: logger)
        
        if let pendingEventsData = rest.storage.objectForKey(ARTPushActivationPendingEventsKey) as? Data,
           let events = NSArray.art_unarchive(fromData: pendingEventsData, withLogger: logger) as? [ARTPushActivationEvent] {
            self.pendingEvents = events
        } else {
            self.pendingEvents = []
        }
        
        super.init()
        
        // Unarchiving - do this after super.init() so we can pass self as machine
        if let stateData = rest.storage.objectForKey(ARTPushActivationCurrentStateKey) as? Data {
            if let unarchivedState = ARTPushActivationState.art_unarchive(fromData: stateData, withLogger: logger) as? ARTPushActivationState {
                self.current = unarchivedState
            } else {
                self.current = ARTPushActivationStateNotActivated(machine: self, logger: logger)
            }
        } else {
            self.current = ARTPushActivationStateNotActivated(machine: self, logger: logger)
        }
        
        // swift-migration: Set machine reference after init
        self.current.machine = self
        
        // Handle deprecated persistent state migration
        if let deprecatedState = self.current as? ARTPushActivationDeprecatedPersistentState {
            self.current = deprecatedState.migrate()
            self.current.machine = self
        }
        
        // Due to bug #966, old versions of the library might have led us to an illegal
        // persisted state: we have a deviceToken, but the persisted push state is WaitingForPushDeviceDetails.
        // So we need to re-emit the GotPushDeviceDetails event that led us there.
        #if os(iOS)
        if self.current is ARTPushActivationStateWaitingForPushDeviceDetails && rest.device_nosync.apnsDeviceToken() != nil {
            ARTLogDebug(logger, "ARTPush: re-emitting stored device details for stuck state machine")
            self.handleEvent(ARTPushActivationEventGotPushDeviceDetails())
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 16 and ARTPushActivationStateMachine.m, line 80
    internal var pendingEventsProperty: [ARTPushActivationEvent] {
        var result: [ARTPushActivationEvent] = []
        queue.sync {
            result = self.pendingEvents
        }
        return result
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 14 and ARTPushActivationStateMachine.m, line 88
    internal var lastEvent: ARTPushActivationEvent? {
        var result: ARTPushActivationEvent?
        queue.sync {
            result = self.lastEvent_nosync
        }
        return result
    }

    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 25 and ARTPushActivationStateMachine.m, line 96
    internal var lastEvent_nosync: ARTPushActivationEvent? {
        return lastHandledEvent
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 15 and ARTPushActivationStateMachine.m, line 100
    internal var currentState: ARTPushActivationState {
        var result: ARTPushActivationState!
        queue.sync {
            result = self.current_nosync
        }
        return result
    }

    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 26 and ARTPushActivationStateMachine.m, line 108
    internal var current_nosync: ARTPushActivationState {
        return current
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 21 and ARTPushActivationStateMachine.m, line 112
    internal func sendEvent(_ event: ARTPushActivationEvent) {
        queue.async {
            self.handleEvent(event)
        }
    }

    // swift-migration: original location ARTPushActivationStateMachine.m, line 118
    private func handleEvent(_ event: ARTPushActivationEvent) {
        ARTLogDebug(logger, "\(type(of: self)): handling event \(type(of: event)) from \(type(of: current))")
        lastHandledEvent = event

        if let onEvent = self.onEvent {
            onEvent(event, current)
        }
        
        guard let maybeNext = current.transition(event) else {
            ARTLogDebug(logger, "\(type(of: self)): enqueuing event: \(type(of: event))")
            pendingEvents.append(event)
            return
        }
        
        ARTLogDebug(logger, "\(type(of: self)): transition: \(type(of: current)) -> \(type(of: maybeNext))")
        if let transitions = self.transitions {
            transitions(event, current, maybeNext)
        }
        current = maybeNext

        while true {
            guard let pending = pendingEvents.first else {
                break
            }
            ARTLogDebug(logger, "\(type(of: self)): attempting to consume pending event: \(type(of: pending))")
            guard let nextState = current.transition(pending) else {
                break
            }
            pendingEvents.removeFirst() // consuming event

            ARTLogDebug(logger, "\(type(of: self)): transition: \(type(of: current)) -> \(type(of: nextState))")
            if let transitions = self.transitions {
                transitions(event, current, nextState)
            }
            current = nextState
        }

        persist()
    }

    // swift-migration: original location ARTPushActivationStateMachine.m, line 154
    private func persist() {
        // Archiving
        if current is ARTPushActivationPersistentState {
            rest.storage.setObject(current.art_archive(withLogger: logger), forKey: ARTPushActivationCurrentStateKey)
        }
        rest.storage.setObject((pendingEvents as NSArray).art_archive(withLogger: logger), forKey: ARTPushActivationPendingEventsKey)
    }
}

// MARK: - Protected methods

extension ARTPushActivationStateMachine {

    // swift-migration: original location ARTPushActivationStateMachine.h, line 26 and ARTPushActivationStateMachine.m, line 164
    internal func deviceRegistration(_ error: ARTErrorInfo?) {
        #if os(iOS)
        let local = rest.device_nosync

        guard let delegate = self.delegate else { return }

        // Custom register
        if delegate.responds(to: #selector(ARTPushRegistererDelegate.ablyPushCustomRegister(_:deviceDetails:callback:))) {
            userQueue.async {
                delegate.ablyPushCustomRegister!(error, deviceDetails: local) { [weak self] identityTokenDetails, error in
                    if let error = error {
                        // Failed
                        self?.sendEvent(ARTPushActivationEventGettingDeviceRegistrationFailed.new(withError: error))
                    } else if let identityTokenDetails = identityTokenDetails {
                        // Success
                        self?.sendEvent(ARTPushActivationEventGotDeviceRegistration.new(withIdentityTokenDetails: identityTokenDetails))
                    } else {
                        let missingIdentityTokenError = ARTErrorInfo(code: 0, message: "Device Identity Token Details is expected")
                        self?.sendEvent(ARTPushActivationEventGettingDeviceRegistrationFailed.new(withError: missingIdentityTokenError))
                    }
                }
            }
            return
        }

        let doDeviceRegistration = { [weak self] in
            guard let self = self else { return }
            // Asynchronous HTTP request
            let request = NSMutableURLRequest(url: URL(string: "/push/deviceRegistrations")!)
            request.httpMethod = "POST"
            do {
                request.httpBody = try self.rest.defaultEncoder.encode(localDevice: local)
                request.setValue(self.rest.defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")

                ARTLogDebug(self.logger, "\(type(of: self)): device registration with request \(request)")
                _ = self.rest.executeRequest(request as URLRequest, withAuthOption: .on, wrapperSDKAgents: nil) { response, data, error in
                    if let error = error {
                        ARTLogError(self.logger, "\(type(of: self)): device registration failed (\(error.localizedDescription))")
                        self.sendEvent(ARTPushActivationEventGettingDeviceRegistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
                        return
                    }
                    do {
                        if let data = data {
                            let identityTokenDetails = try self.rest.defaultEncoder.decodeDeviceIdentityTokenDetails(data)
                            self.sendEvent(ARTPushActivationEventGotDeviceRegistration.new(withIdentityTokenDetails: identityTokenDetails))
                        }
                    } catch {
                        ARTLogError(self.logger, "\(type(of: self)): decode identity token details failed (\(error.localizedDescription))")
                        self.sendEvent(ARTPushActivationEventGettingDeviceRegistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
                    }
                }
            } catch {
                ARTLogError(self.logger, "\(type(of: self)): failed to encode device for registration (\(error.localizedDescription))")
                self.sendEvent(ARTPushActivationEventGettingDeviceRegistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
            }
        }

        if rest.auth.method == .token {
            rest.auth.authorize { _, _ in
                doDeviceRegistration()
            }
        } else {
            doDeviceRegistration()
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 28 and ARTPushActivationStateMachine.m, line 227
    internal func deviceUpdateRegistration(_ error: ARTErrorInfo?) {
        #if os(iOS)
        let local = rest.device_nosync

        guard let delegate = self.delegate else { return }

        // Custom register
        if delegate.responds(to: #selector(ARTPushRegistererDelegate.ablyPushCustomRegister(_:deviceDetails:callback:))) {
            userQueue.async {
                delegate.ablyPushCustomRegister!(error, deviceDetails: local) { [weak self] identityTokenDetails, error in
                    if let error = error {
                        // Failed
                        self?.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: error))
                    } else if let identityTokenDetails = identityTokenDetails {
                        // Success
                        self?.sendEvent(ARTPushActivationEventRegistrationSynced.new(withIdentityTokenDetails: identityTokenDetails))
                    } else {
                        let missingIdentityTokenError = ARTErrorInfo(code: 0, message: "Device Identity Token Details is expected")
                        self?.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: missingIdentityTokenError))
                    }
                }
            }
            return
        }

        let request = NSMutableURLRequest(url: URL(string: "/push/deviceRegistrations")!.appendingPathComponent(local.id))
        request.httpMethod = "PATCH"
        do {
            let body = [
                "push": [
                    "recipient": local.push.recipient
                ]
            ]
            request.httpBody = try rest.defaultEncoder.encode(any: body)
            request.setValue(rest.defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")
            let authenticatedRequest = request.settingDeviceAuthentication(local).mutableCopy() as! NSMutableURLRequest

            ARTLogDebug(logger, "\(type(of: self)): update device with request \(request)")
            _ = rest.executeRequest(authenticatedRequest as URLRequest, withAuthOption: .on, wrapperSDKAgents: nil) { [weak self] response, data, error in
                guard let self = self else { return }
                if let error = error {
                    ARTLogError(self.logger, "\(type(of: self)): update device failed (\(error.localizedDescription))")
                    self.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
                    return
                }
                self.sendEvent(ARTPushActivationEventRegistrationSynced())
            }
        } catch {
            ARTLogError(logger, "\(type(of: self)): failed to encode update payload (\(error.localizedDescription))")
            sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 27 and ARTPushActivationStateMachine.m, line 276
    internal func syncDevice() {
        #if os(iOS)
        let local = rest.device_nosync

        guard let delegate = self.delegate else { return }

        // Custom register
        if delegate.responds(to: #selector(ARTPushRegistererDelegate.ablyPushCustomRegister(_:deviceDetails:callback:))) {
            userQueue.async {
                delegate.ablyPushCustomRegister!(nil, deviceDetails: local) { [weak self] identityTokenDetails, error in
                    if let error = error {
                        // Failed
                        self?.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: error))
                    } else if let identityTokenDetails = identityTokenDetails {
                        // Success
                        self?.sendEvent(ARTPushActivationEventRegistrationSynced.new(withIdentityTokenDetails: identityTokenDetails))
                    } else {
                        let missingIdentityTokenError = ARTErrorInfo(code: 0, message: "Device Identity Token Details is expected")
                        self?.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: missingIdentityTokenError))
                    }
                }
            }
            return
        }

        let doDeviceSync = { [weak self] in
            guard let self = self else { return }
            // Asynchronous HTTP request
            let path = "/push/deviceRegistrations/\(local.id)"
            let request = NSMutableURLRequest(url: URL(string: path)!)
            request.httpMethod = "PUT"
            do {
                request.httpBody = try self.rest.defaultEncoder.encodeDeviceDetails(local)
                request.setValue(self.rest.defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")
                let authenticatedRequest = request.settingDeviceAuthentication(local).mutableCopy() as! NSMutableURLRequest

                ARTLogDebug(self.logger, "\(type(of: self)): sync device with request \(request)")
                _ = self.rest.executeRequest(authenticatedRequest as URLRequest, withAuthOption: .on, wrapperSDKAgents: nil) { response, data, error in
                    if let error = error {
                        ARTLogError(self.logger, "\(type(of: self)): device registration failed (\(error.localizedDescription))")
                        self.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
                        return
                    }
                    self.sendEvent(ARTPushActivationEventRegistrationSynced.new(withIdentityTokenDetails: local.identityTokenDetails))
                }
            } catch {
                ARTLogError(self.logger, "\(type(of: self)): failed to encode device details (\(error.localizedDescription))")
                self.sendEvent(ARTPushActivationEventSyncRegistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
            }
        }

        if rest.auth.method == .token {
            rest.auth.authorize { _, _ in
                doDeviceSync()
            }
        } else {
            doDeviceSync()
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 29 and ARTPushActivationStateMachine.m, line 334
    internal func deviceUnregistration(_ error: ARTErrorInfo?) {
        #if os(iOS)
        let local = rest.device_nosync

        let delegate = self.delegate

        // Custom register
        let customDeregisterMethodSelector = #selector(ARTPushRegistererDelegate.ablyPushCustomDeregister(_:deviceId:callback:))
        if let delegate = delegate, delegate.responds(to: customDeregisterMethodSelector) {
            userQueue.async {
                delegate.ablyPushCustomDeregister!(error, deviceId: local.id) { [weak self] error in
                    if let error = error {
                        // RSH3d2c1: ignore unauthorized or invalid credentials errors
                        if error.statusCode == 401 || error.code == 40005 {
                            self?.sendEvent(ARTPushActivationEventDeregistered())
                        } else {
                            self?.sendEvent(ARTPushActivationEventDeregistrationFailed.new(withError: error))
                        }
                    } else {
                        // Success
                        self?.sendEvent(ARTPushActivationEventDeregistered())
                    }
                }
            }
            return
        }

        // Asynchronous HTTP request
        let request = NSMutableURLRequest(url: URL(string: "/push/deviceRegistrations")!.appendingPathComponent(local.id))
        request.httpMethod = "DELETE"
        let authenticatedRequest = request.settingDeviceAuthentication(local).mutableCopy() as! NSMutableURLRequest

        ARTLogDebug(logger, "\(type(of: self)): device deregistration with request \(request)")
        _ = rest.executeRequest(authenticatedRequest as URLRequest, withAuthOption: .on, wrapperSDKAgents: nil) { [weak self] response, data, error in
            guard let self = self else { return }
            if let error = error {
                // RSH3d2c1: ignore unauthorized or invalid credentials errors
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 || error.code == 40005 {
                    ARTLogError(self.logger, "\(type(of: self)): unauthorized error during deregistration (\(error.localizedDescription))")
                    self.sendEvent(ARTPushActivationEventDeregistered())
                } else {
                    ARTLogError(self.logger, "\(type(of: self)): device deregistration failed (\(error.localizedDescription))")
                    self.sendEvent(ARTPushActivationEventDeregistrationFailed.new(withError: ARTErrorInfo.createFromNSError(error)))
                }
                return
            }
            ARTLogDebug(self.logger, "successfully deactivate device")
            self.sendEvent(ARTPushActivationEventDeregistered())
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 30 and ARTPushActivationStateMachine.m, line 386
    internal func callActivatedCallback(_ error: ARTErrorInfo?) {
        #if os(iOS)
        userQueue.async { [weak self] in
            guard let delegate = self?.delegate else { return }
            if delegate.responds(to: #selector(ARTPushRegistererDelegate.didActivateAblyPush(_:))) {
                delegate.didActivateAblyPush!(error)
            }
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 31 and ARTPushActivationStateMachine.m, line 397
    internal func callDeactivatedCallback(_ error: ARTErrorInfo?) {
        #if os(iOS)
        userQueue.async { [weak self] in
            guard let delegate = self?.delegate else { return }
            if delegate.responds(to: #selector(ARTPushRegistererDelegate.didDeactivateAblyPush(_:))) {
                delegate.didDeactivateAblyPush!(error)
            }
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine.h, line 32 and ARTPushActivationStateMachine.m, line 408
    internal func callUpdatedCallback(_ error: ARTErrorInfo?) {
        #if os(iOS)
        userQueue.async { [weak self] in
            guard let delegate = self?.delegate else { return }
            if delegate.responds(to: #selector(ARTPushRegistererDelegate.didUpdateAblyPush(_:))) {
                delegate.didUpdateAblyPush!(error)
            } else if let error = error, delegate.responds(to: #selector(ARTPushRegistererDelegate.didAblyPushRegistrationFail(_:))) {
                delegate.didAblyPushRegistrationFail!(error)
            }
        }
        #endif
    }

    // swift-migration: original location ARTPushActivationStateMachine+Private.h, line 28 and ARTPushActivationStateMachine.m, line 422
    internal func registerForAPNS() {
        #if os(iOS)
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif
    }
}