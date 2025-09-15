import Foundation

// MARK: - ARTPushAdminProtocol

// swift-migration: original location ARTPushAdmin.h, line 11
public protocol ARTPushAdminProtocol {

    // swift-migration: original location ARTPushAdmin.h, line 23
    func publish(_ recipient: ARTPushRecipient, data: ARTJsonObject, callback: ARTCallback?)
}

// MARK: - ARTPushAdmin

// swift-migration: original location ARTPushAdmin.h, line 31 and ARTPushAdmin.m, line 10
public class ARTPushAdmin: NSObject, ARTPushAdminProtocol {
    
    // swift-migration: original location ARTPushAdmin+Private.h, line 23
    internal let `internal`: ARTPushAdminInternal
    
    // swift-migration: original location ARTPushAdmin.m, line 11
    private let dealloc: ARTQueuedDealloc

    // swift-migration: original location ARTPushAdmin+Private.h, line 25 and ARTPushAdmin.m, line 14
    internal init(internal: ARTPushAdminInternal, queuedDealloc: ARTQueuedDealloc) {
        self.internal = `internal`
        self.dealloc = queuedDealloc
        super.init()
    }

    // swift-migration: original location ARTPushAdmin.h, line 23 and ARTPushAdmin.m, line 23
    public func publish(_ recipient: ARTPushRecipient, data: ARTJsonObject, callback: ARTCallback?) {
        `internal`.publish(recipient, data: data, wrapperSDKAgents: nil, callback: callback)
    }

    // swift-migration: original location ARTPushAdmin.h, line 36 and ARTPushAdmin.m, line 27
    public var deviceRegistrations: ARTPushDeviceRegistrations {
        return ARTPushDeviceRegistrations(internal: `internal`.deviceRegistrations, queuedDealloc: dealloc)
    }

    // swift-migration: original location ARTPushAdmin.h, line 41 and ARTPushAdmin.m, line 31
    public var channelSubscriptions: ARTPushChannelSubscriptions {
        return ARTPushChannelSubscriptions(internal: `internal`.channelSubscriptions, queuedDealloc: dealloc)
    }
}

// MARK: - ARTPushAdminInternal

// swift-migration: original location ARTPushAdmin+Private.h, line 10 and ARTPushAdmin.m, line 37
internal class ARTPushAdminInternal: NSObject {
    
    // swift-migration: original location ARTPushAdmin.m, line 38
    private weak var rest: ARTRestInternal? // weak because rest owns self
    // swift-migration: original location ARTPushAdmin.m, line 39
    private let logger: InternalLog
    // swift-migration: original location ARTPushAdmin.m, line 40
    private let userQueue: DispatchQueue
    // swift-migration: original location ARTPushAdmin.m, line 41
    private let queue: DispatchQueue
    
    // swift-migration: original location ARTPushAdmin+Private.h, line 12
    internal let deviceRegistrations: ARTPushDeviceRegistrationsInternal
    // swift-migration: original location ARTPushAdmin+Private.h, line 13
    internal let channelSubscriptions: ARTPushChannelSubscriptionsInternal

    // swift-migration: original location ARTPushAdmin+Private.h, line 15 and ARTPushAdmin.m, line 44
    internal init(rest: ARTRestInternal, logger: InternalLog) {
        self.rest = rest
        self.logger = logger
        self.deviceRegistrations = ARTPushDeviceRegistrationsInternal(rest: rest, logger: logger)
        self.channelSubscriptions = ARTPushChannelSubscriptionsInternal(rest: rest, logger: logger)
        self.userQueue = rest.userQueue
        self.queue = rest.queue
        super.init()
    }

    // swift-migration: original location ARTPushAdmin+Private.h, line 17 and ARTPushAdmin.m, line 56
    internal func publish(_ recipient: ARTPushRecipient, data: ARTJsonObject, wrapperSDKAgents: NSStringDictionary?, callback: ARTCallback?) {
        var wrappedCallback = callback
        if let callback = callback {
            let userCallback = callback
            wrappedCallback = { [weak self] error in
                guard let self = self else { return }
                self.userQueue.async {
                    userCallback(error)
                }
            }
        }

        queue.async { [weak self] in
            guard let self = self else { return }
            guard let rest = self.rest else { return }
            
            if recipient.keys.count == 0 {
                wrappedCallback?(ARTErrorInfo(code: 0, message: "Recipient is missing"))
                return
            }

            if data.keys.count == 0 {
                wrappedCallback?(ARTErrorInfo(code: 0, message: "Data payload is missing"))
                return
            }

            let request = NSMutableURLRequest(url: URL(string: "/push/publish")!)
            request.httpMethod = "POST"
            let body = NSMutableDictionary()
            body.setObject(recipient, forKey: "recipient" as NSString)
            body.addEntries(from: data)
            
            do {
                request.httpBody = try rest.defaultEncoder.encode(body)
                request.setValue(rest.defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")

                ARTLogDebug(self.logger, "push notification to a single device \(request)")
                _ = rest.execute(request as URLRequest, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { [weak self] response, data, error in
                    guard let self = self else { return }
                    if let error = error {
                        ARTLogError(self.logger, "\(type(of: self)): push notification to a single device failed (\(error.localizedDescription))")
                        wrappedCallback?(ARTErrorInfo.createFromNSError(error))
                        return
                    }
                    wrappedCallback?(nil)
                }
            } catch {
                ARTLogError(self.logger, "\(type(of: self)): failed to encode push notification body (\(error.localizedDescription))")
                wrappedCallback?(ARTErrorInfo.createFromNSError(error))
            }
        }
    }
}
