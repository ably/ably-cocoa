import Foundation
#if os(iOS)
import UIKit
#endif

// swift-migration: original location ARTPush.h, line 17
#if os(iOS)

// ARTPushRegistererDelegate already defined in MigrationPlaceholders.swift

#endif

// swift-migration: original location ARTPush.h, line 60
public protocol ARTPushProtocol: AnyObject {
    
    // swift-migration: original location ARTPush.h, line 63
    // Note: init() is NS_UNAVAILABLE in Objective-C, handled in implementation

#if os(iOS)
    
    // swift-migration: original location ARTPush.h, line 70 and ARTPush.m, line 40
    static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data, rest: ARTRest)
    
    // swift-migration: original location ARTPush.h, line 73 and ARTPush.m, line 44
    static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data, realtime: ARTRealtime)
    
    // swift-migration: original location ARTPush.h, line 76 and ARTPush.m, line 48
    static func didFailToRegisterForRemoteNotificationsWithError(_ error: Error, rest: ARTRest)
    
    // swift-migration: original location ARTPush.h, line 79 and ARTPush.m, line 52
    static func didFailToRegisterForRemoteNotificationsWithError(_ error: Error, realtime: ARTRealtime)
    
    // swift-migration: original location ARTPush.h, line 84 and ARTPush.m, line 56
    static func didRegisterForLocationNotificationsWithDeviceToken(_ deviceToken: Data, rest: ARTRest)
    
    // swift-migration: original location ARTPush.h, line 87 and ARTPush.m, line 60
    static func didRegisterForLocationNotificationsWithDeviceToken(_ deviceToken: Data, realtime: ARTRealtime)
    
    // swift-migration: original location ARTPush.h, line 90 and ARTPush.m, line 64
    static func didFailToRegisterForLocationNotificationsWithError(_ error: Error, rest: ARTRest)
    
    // swift-migration: original location ARTPush.h, line 93 and ARTPush.m, line 68
    static func didFailToRegisterForLocationNotificationsWithError(_ error: Error, realtime: ARTRealtime)
    
    // swift-migration: original location ARTPush.h, line 99 and ARTPush.m, line 72
    func activate()
    
    // swift-migration: original location ARTPush.h, line 105 and ARTPush.m, line 76
    func deactivate()
    
#endif
}

// swift-migration: original location ARTPush.h, line 115 and ARTPush.m, line 21
public class ARTPush: NSObject, ARTPushProtocol, @unchecked Sendable { // NS_SWIFT_SENDABLE
    
    // swift-migration: original location ARTPush.m, line 22
    private let dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTPush+Private.h, line 57 and ARTPush.m, line 28
    internal let `internal`: ARTPushInternal
    
    // swift-migration: original location ARTPush+Private.h, line 59 and ARTPush.m, line 25
    internal init(internal: ARTPushInternal, queuedDealloc: ARTQueuedDealloc) {
        self.internal = `internal`
        self.dealloc = queuedDealloc
        super.init()
    }

    // swift-migration: Override NSObject init but make it unavailable to match NS_UNAVAILABLE
    private override init() {
        fatalError("init() is unavailable - use init(internal:queuedDealloc:) instead")
    }
    
    // swift-migration: original location ARTPush.h, line 120 and ARTPush.m, line 34
    public var admin: ARTPushAdmin {
        return ARTPushAdmin(internal: `internal`.admin, queuedDealloc: dealloc)
    }
    
#if os(iOS)
    
    // swift-migration: original location ARTPush.h, line 70 and ARTPush.m, line 40
    public static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data, rest: ARTRest) {
        return ARTPushInternal.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken, rest: rest)
    }
    
    // swift-migration: original location ARTPush.h, line 73 and ARTPush.m, line 44
    public static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data, realtime: ARTRealtime) {
        return ARTPushInternal.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken, realtime: realtime)
    }
    
    // swift-migration: original location ARTPush.h, line 76 and ARTPush.m, line 48
    public static func didFailToRegisterForRemoteNotificationsWithError(_ error: Error, rest: ARTRest) {
        return ARTPushInternal.didFailToRegisterForRemoteNotificationsWithError(error, rest: rest)
    }
    
    // swift-migration: original location ARTPush.h, line 79 and ARTPush.m, line 52
    public static func didFailToRegisterForRemoteNotificationsWithError(_ error: Error, realtime: ARTRealtime) {
        return ARTPushInternal.didFailToRegisterForRemoteNotificationsWithError(error, realtime: realtime)
    }
    
    // swift-migration: original location ARTPush.h, line 84 and ARTPush.m, line 56
    public static func didRegisterForLocationNotificationsWithDeviceToken(_ deviceToken: Data, rest: ARTRest) {
        return ARTPushInternal.didRegisterForLocationNotificationsWithDeviceToken(deviceToken, rest: rest)
    }
    
    // swift-migration: original location ARTPush.h, line 87 and ARTPush.m, line 60
    public static func didRegisterForLocationNotificationsWithDeviceToken(_ deviceToken: Data, realtime: ARTRealtime) {
        return ARTPushInternal.didRegisterForLocationNotificationsWithDeviceToken(deviceToken, realtime: realtime)
    }
    
    // swift-migration: original location ARTPush.h, line 90 and ARTPush.m, line 64
    public static func didFailToRegisterForLocationNotificationsWithError(_ error: Error, rest: ARTRest) {
        return ARTPushInternal.didFailToRegisterForLocationNotificationsWithError(error, rest: rest)
    }
    
    // swift-migration: original location ARTPush.h, line 93 and ARTPush.m, line 68
    public static func didFailToRegisterForLocationNotificationsWithError(_ error: Error, realtime: ARTRealtime) {
        return ARTPushInternal.didFailToRegisterForLocationNotificationsWithError(error, realtime: realtime)
    }
    
    // swift-migration: original location ARTPush.h, line 99 and ARTPush.m, line 72
    public func activate() {
        `internal`.activate()
    }
    
    // swift-migration: original location ARTPush.h, line 105 and ARTPush.m, line 76
    public func deactivate() {
        `internal`.deactivate()
    }
    
#endif
}

// swift-migration: original location ARTPush+Private.h, line 11 and ARTPush.m, line 84
internal class ARTPushInternal: NSObject {
    
    // swift-migration: original location ARTPush.m, line 85
    private weak var rest: ARTRestInternal? // weak because rest owns self
    
    // swift-migration: original location ARTPush.m, line 86
    private let logger: ARTInternalLog
    
    // swift-migration: original location ARTPush.m, line 87
    private var activationMachine: ARTPushActivationStateMachine?
    
    // swift-migration: original location ARTPush.m, line 88
    private let activationMachineLock: NSLock
    
    // swift-migration: original location ARTPush+Private.h, line 13 and ARTPush.m, line 95
    internal let admin: ARTPushAdminInternal
    
    // swift-migration: original location ARTPush+Private.h, line 16 and ARTPush.m, line 91
    internal init(rest: ARTRestInternal, logger: ARTInternalLog) {
        self.rest = rest
        self.logger = logger
        self.admin = ARTPushAdminInternal(rest: rest, logger: logger)
        self.activationMachine = nil
        self.activationMachineLock = NSLock()
        super.init()
        self.activationMachineLock.name = "ActivationMachineLock"
    }
    
    // swift-migration: original location ARTPush+Private.h, line 14 and ARTPush.m, line 103
    internal var queue: DispatchQueue {
        // swift-migration: Original code returns _rest.queue - unclear what to do when rest is nil
        guard let rest = rest else {
            fatalError("rest is nil - original Objective-C code would crash accessing _rest.queue")
        }
        return rest.queue
    }
    
#if os(iOS)
    
    // swift-migration: original location ARTPush+Private.h, line 19 and ARTPush.m, line 109
    internal func getActivationMachine(_ block: @escaping (ARTPushActivationStateMachine?) -> Void) {
        // swift-migration: original location ARTPush.m, line 110-113
        guard let rest = rest else {
            block(nil)
            return
        }
        
        // swift-migration: original location ARTPush.m, line 115-118
        let timeout = Date(timeIntervalSinceNow: 60)
        guard activationMachineLock.lock(before: timeout) else {
            block(nil)
            return
        }
        
        // swift-migration: original location ARTPush.m, line 120-123
        let callbackWithUnlock: (ARTPushActivationStateMachine?) -> Void = { [weak self] machine in
            self?.activationMachineLock.unlock()
            block(machine)
        }
        
        // swift-migration: original location ARTPush.m, line 125-143
        if activationMachine == nil {
            if let delegate = rest.options.pushRegistererDelegate {
                callbackWithUnlock(createActivationStateMachine(delegate: delegate))
            } else {
                DispatchQueue.main.async { [weak self] in
                    // swift-migration: original location ARTPush.m, line 132-133
                    // -[UIApplication delegate] is an UI API call, so needs to be called from main thread.
                    let legacyDelegate = UIApplication.shared.delegate
                    self?.createActivationStateMachine(delegate: legacyDelegate) { machine in
                        callbackWithUnlock(machine)
                    }
                }
            }
        } else {
            callbackWithUnlock(activationMachine)
        }
    }
    
    // swift-migration: original location ARTPush.m, line 146-151
    private func createActivationStateMachine(delegate: Any?, completion: @escaping (ARTPushActivationStateMachine?) -> Void) {
        queue.async { [weak self] in
            if let self = self, let delegate = delegate {
                completion(self.createActivationStateMachine(delegate: delegate))
            } else {
                completion(nil)
            }
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 26 and ARTPush.m, line 153
    @discardableResult
    internal func createActivationStateMachine(delegate: Any) -> ARTPushActivationStateMachine? {
        // swift-migration: original location ARTPush.m, line 154-157
        guard activationMachine == nil else {
            fatalError("_activationMachine already set.")
        }
        
        guard let rest = rest else {
            return nil
        }
        
        // swift-migration: original location ARTPush.m, line 159-161
        activationMachine = ARTPushActivationStateMachine(rest: rest, delegate: delegate, logger: logger)
        return activationMachine
    }
    
    // swift-migration: original location ARTPush+Private.h, line 23 and ARTPush.m, line 163
    internal var activationMachineForTesting: ARTPushActivationStateMachine {
        // swift-migration: original location ARTPush.m, line 164-167
        guard activationMachineLock.try() else {
            fatalError("Failed to immediately acquire lock for internal testing purposes.")
        }
        
        // swift-migration: original location ARTPush.m, line 169-173
        guard let machine = activationMachine else {
            activationMachineLock.unlock()
            fatalError("There is no activation machine for internal testing purposes.")
        }
        
        // swift-migration: original location ARTPush.m, line 175-177
        activationMachineLock.unlock()
        return machine
    }
    
    // swift-migration: original location ARTPush.m, line 180-183
    private static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceTokenData: Data, restInternal rest: ARTRestInternal) {
        ARTLogDebug(rest.logger_onlyForUseInClassMethodsAndTests, "ARTPush: device token data received: \(deviceTokenData.base64EncodedString())")
        rest.setAndPersistAPNSDeviceTokenData(deviceTokenData, tokenType: ARTAPNSDeviceDefaultTokenType)
    }
    
    // swift-migration: original location ARTPush+Private.h, line 33 and ARTPush.m, line 185
    internal static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data, realtime: ARTRealtime) {
        realtime.internalAsync { realtime in
            ARTPushInternal.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken, restInternal: realtime.rest)
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 31 and ARTPush.m, line 191  
    internal static func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data, rest: ARTRest) {
        rest.internalAsync { rest in
            ARTPushInternal.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken, restInternal: rest)
        }
    }
    
    // swift-migration: original location ARTPush.m, line 197-202
    private static func didFailToRegisterForRemoteNotificationsWithError(_ error: Error, restInternal rest: ARTRestInternal) {
        ARTLogError(rest.logger_onlyForUseInClassMethodsAndTests, "ARTPush: device token not received (\(error.localizedDescription))")
        rest.push.getActivationMachine { stateMachine in
            stateMachine?.sendEvent(ARTPushActivationEventGettingPushDeviceDetailsFailed.new(error: ARTErrorInfo.createFromNSError(error)))
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 37 and ARTPush.m, line 204
    internal static func didFailToRegisterForRemoteNotificationsWithError(_ error: Error, realtime: ARTRealtime) {
        realtime.internalAsync { realtime in
            ARTPushInternal.didFailToRegisterForRemoteNotificationsWithError(error, restInternal: realtime.rest)
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 35 and ARTPush.m, line 210
    internal static func didFailToRegisterForRemoteNotificationsWithError(_ error: Error, rest: ARTRest) {
        rest.internalAsync { rest in
            ARTPushInternal.didFailToRegisterForRemoteNotificationsWithError(error, restInternal: rest)
        }
    }
    
    // swift-migration: original location ARTPush.m, line 216-219
    private static func didRegisterForLocationNotificationsWithDeviceToken(_ deviceTokenData: Data, restInternal rest: ARTRestInternal) {
        ARTLogDebug(rest.logger_onlyForUseInClassMethodsAndTests, "ARTPush: location push device token data received: \(deviceTokenData.base64EncodedString())")
        rest.setAndPersistAPNSDeviceTokenData(deviceTokenData, tokenType: ARTAPNSDeviceLocationTokenType)
    }
    
    // swift-migration: original location ARTPush+Private.h, line 41 and ARTPush.m, line 221
    internal static func didRegisterForLocationNotificationsWithDeviceToken(_ deviceToken: Data, realtime: ARTRealtime) {
        realtime.internalAsync { realtime in
            ARTPushInternal.didRegisterForLocationNotificationsWithDeviceToken(deviceToken, restInternal: realtime.rest)
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 39 and ARTPush.m, line 227
    internal static func didRegisterForLocationNotificationsWithDeviceToken(_ deviceToken: Data, rest: ARTRest) {
        rest.internalAsync { rest in
            ARTPushInternal.didRegisterForLocationNotificationsWithDeviceToken(deviceToken, restInternal: rest)
        }
    }
    
    // swift-migration: original location ARTPush.m, line 233-238
    private static func didFailToRegisterForLocationNotificationsWithError(_ error: Error, restInternal rest: ARTRestInternal) {
        ARTLogError(rest.logger_onlyForUseInClassMethodsAndTests, "ARTPush: location push device token not received (\(error.localizedDescription))")
        rest.push.getActivationMachine { stateMachine in
            stateMachine?.sendEvent(ARTPushActivationEventGettingPushDeviceDetailsFailed.new(error: ARTErrorInfo.createFromNSError(error)))
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 45 and ARTPush.m, line 240
    internal static func didFailToRegisterForLocationNotificationsWithError(_ error: Error, realtime: ARTRealtime) {
        realtime.internalAsync { realtime in
            ARTPushInternal.didFailToRegisterForLocationNotificationsWithError(error, restInternal: realtime.rest)
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 43 and ARTPush.m, line 246
    internal static func didFailToRegisterForLocationNotificationsWithError(_ error: Error, rest: ARTRest) {
        rest.internalAsync { rest in
            ARTPushInternal.didFailToRegisterForLocationNotificationsWithError(error, restInternal: rest)
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 47 and ARTPush.m, line 252
    internal func activate() {
        getActivationMachine { stateMachine in
            stateMachine?.sendEvent(ARTPushActivationEventCalledActivate())
        }
    }
    
    // swift-migration: original location ARTPush+Private.h, line 49 and ARTPush.m, line 258
    internal func deactivate() {
        getActivationMachine { stateMachine in
            stateMachine?.sendEvent(ARTPushActivationEventCalledDeactivate())
        }
    }
    
#endif
    
}