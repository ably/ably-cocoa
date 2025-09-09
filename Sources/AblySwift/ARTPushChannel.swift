import Foundation

// MARK: - ARTPushChannelProtocol

// swift-migration: original location ARTPushChannel.h, line 12
public protocol ARTPushChannelProtocol {

    // swift-migration: original location ARTPushChannel.h, line 20
    func subscribeDevice()

    // swift-migration: original location ARTPushChannel.h, line 27
    func subscribeDevice(_ callback: ARTCallback?)

    // swift-migration: original location ARTPushChannel.h, line 32
    func subscribeClient()

    // swift-migration: original location ARTPushChannel.h, line 39
    func subscribeClient(_ callback: ARTCallback?)

    // swift-migration: original location ARTPushChannel.h, line 44
    func unsubscribeDevice()

    // swift-migration: original location ARTPushChannel.h, line 51
    func unsubscribeDevice(_ callback: ARTCallback?)

    // swift-migration: original location ARTPushChannel.h, line 56
    func unsubscribeClient()

    // swift-migration: original location ARTPushChannel.h, line 63
    func unsubscribeClient(_ callback: ARTCallback?)

    // swift-migration: original location ARTPushChannel.h, line 74
    @discardableResult
    func listSubscriptions(_ params: NSStringDictionary, callback: @escaping ARTPaginatedPushChannelCallback) throws -> Bool
}

// MARK: - ARTPushChannel

// swift-migration: original location ARTPushChannel.h, line 86 and ARTPushChannel.m, line 13
public class ARTPushChannel: NSObject, ARTPushChannelProtocol {
    
    // swift-migration: original location ARTPushChannel+Private.h, line 43
    internal let `internal`: ARTPushChannelInternal
    
    // swift-migration: original location ARTPushChannel.m, line 14
    private let dealloc: ARTQueuedDealloc

    // swift-migration: original location ARTPushChannel+Private.h, line 45 and ARTPushChannel.m, line 17
    internal init(internal: ARTPushChannelInternal, queuedDealloc: ARTQueuedDealloc) {
        self.internal = `internal`
        self.dealloc = queuedDealloc
        super.init()
    }

    // swift-migration: original location ARTPushChannel.h, line 20 and ARTPushChannel.m, line 26
    public func subscribeDevice() {
        `internal`.subscribeDevice(withWrapperSDKAgents: nil)
    }

    // swift-migration: original location ARTPushChannel.h, line 27 and ARTPushChannel.m, line 30
    public func subscribeDevice(_ callback: ARTCallback?) {
        `internal`.subscribeDevice(withWrapperSDKAgents: nil, completion: callback)
    }

    // swift-migration: original location ARTPushChannel.h, line 32 and ARTPushChannel.m, line 34
    public func subscribeClient() {
        `internal`.subscribeClient(withWrapperSDKAgents: nil)
    }

    // swift-migration: original location ARTPushChannel.h, line 39 and ARTPushChannel.m, line 38
    public func subscribeClient(_ callback: ARTCallback?) {
        `internal`.subscribeClient(withWrapperSDKAgents: nil, completion: callback)
    }

    // swift-migration: original location ARTPushChannel.h, line 44 and ARTPushChannel.m, line 42
    public func unsubscribeDevice() {
        `internal`.unsubscribeDevice(withWrapperSDKAgents: nil)
    }

    // swift-migration: original location ARTPushChannel.h, line 51 and ARTPushChannel.m, line 46
    public func unsubscribeDevice(_ callback: ARTCallback?) {
        `internal`.unsubscribeDevice(withWrapperSDKAgents: nil, completion: callback)
    }

    // swift-migration: original location ARTPushChannel.h, line 56 and ARTPushChannel.m, line 50
    public func unsubscribeClient() {
        `internal`.unsubscribeClient(withWrapperSDKAgents: nil)
    }

    // swift-migration: original location ARTPushChannel.h, line 63 and ARTPushChannel.m, line 54
    public func unsubscribeClient(_ callback: ARTCallback?) {
        `internal`.unsubscribeClient(withWrapperSDKAgents: nil, completion: callback)
    }

    // swift-migration: original location ARTPushChannel.h, line 74 and ARTPushChannel.m, line 58
    @discardableResult
    public func listSubscriptions(_ params: NSStringDictionary, callback: @escaping ARTPaginatedPushChannelCallback) throws -> Bool {
        var error: NSError?
        let result = `internal`.listSubscriptions(params, wrapperSDKAgents: nil, callback: callback, error: &error)
        if let error = error {
            throw error
        }
        return result
    }
}

// swift-migration: original location ARTPushChannel.m, line 66
private let ARTDefaultLimit: UInt = 100

// MARK: - ARTPushChannelInternal

// swift-migration: original location ARTPushChannel+Private.h, line 10 and ARTPushChannel.m, line 68
internal class ARTPushChannelInternal: NSObject {
    
    // swift-migration: original location ARTPushChannel.m, line 70
    private let queue: DispatchQueue
    // swift-migration: original location ARTPushChannel.m, line 71
    private let userQueue: DispatchQueue
    // swift-migration: original location ARTPushChannel.m, line 73
    private weak var rest: ARTRestInternal? // weak because rest may own self and always outlives it
    // swift-migration: original location ARTPushChannel.m, line 74
    private let logger: ARTInternalLog
    // swift-migration: original location ARTPushChannel.m, line 75
    private weak var channel: ARTChannel? // weak because channel owns self

    // swift-migration: original location ARTPushChannel+Private.h, line 12 and ARTPushChannel.m, line 78
    internal init(rest: ARTRestInternal, withChannel channel: ARTChannel, logger: ARTInternalLog) {
        self.rest = rest
        self.queue = rest.queue
        self.userQueue = rest.userQueue
        self.logger = logger
        self.channel = channel
        super.init()
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 14 and ARTPushChannel.m, line 89
    internal func subscribeDevice(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?) {
        subscribeDevice(withWrapperSDKAgents: wrapperSDKAgents, completion: nil)
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 24 and ARTPushChannel.m, line 93
    internal func unsubscribeDevice(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?) {
        unsubscribeDevice(withWrapperSDKAgents: wrapperSDKAgents, completion: nil)
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 19 and ARTPushChannel.m, line 97
    internal func subscribeClient(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?) {
        subscribeClient(withWrapperSDKAgents: wrapperSDKAgents, completion: nil)
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 29 and ARTPushChannel.m, line 101
    internal func unsubscribeClient(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?) {
        unsubscribeClient(withWrapperSDKAgents: wrapperSDKAgents, completion: nil)
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 16 and ARTPushChannel.m, line 105
    internal func subscribeDevice(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?, completion callback: ARTCallback?) {
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
            guard let self = self, let rest = self.rest, let channel = self.channel else { return }
            
            let device = self.getDevice(wrappedCallback)
            guard device.isRegistered() else {
                return
            }
            let deviceId = device.id

            let request = NSMutableURLRequest(url: URL(string: "/push/channelSubscriptions")!)
            request.httpMethod = "POST"
            do {
                let body = [
                    "deviceId": deviceId as Any,
                    "channel": channel.name
                ]
                request.httpBody = try rest.defaultEncoder().encode(any: body)
                request.setValue(rest.defaultEncoder().mimeType(), forHTTPHeaderField: "Content-Type")
                let authenticatedRequest = request.settingDeviceAuthentication(deviceId ?? "", localDevice: device).mutableCopy() as! NSMutableURLRequest

                ARTLogDebug(self.logger, "subscribe notifications for device \(String(describing: deviceId)) in channel \(channel.name)")
                _ = rest.executeRequest(authenticatedRequest as URLRequest, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { [weak self] response, data, error in
                    guard let self = self else { return }
                    if let error = error {
                        ARTLogError(self.logger, "\(type(of: self)): subscribe notifications for device \(String(describing: deviceId)) in channel \(channel.name) failed (\(error.localizedDescription))")
                    }
                    wrappedCallback?(error != nil ? ARTErrorInfo.createFromNSError(error!) : nil)
                }
            } catch {
                ARTLogError(self.logger, "\(type(of: self)): failed to encode subscription body (\(error.localizedDescription))")
                wrappedCallback?(ARTErrorInfo.createFromNSError(error))
            }
        }
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 21 and ARTPushChannel.m, line 141
    internal func subscribeClient(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?, completion callback: ARTCallback?) {
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
            guard let self = self, let rest = self.rest, let channel = self.channel else { return }
            
            guard let clientId = self.getClientId(wrappedCallback) else {
                return
            }

            let request = NSMutableURLRequest(url: URL(string: "/push/channelSubscriptions")!)
            request.httpMethod = "POST"
            do {
                let body = [
                    "clientId": clientId,
                    "channel": channel.name
                ]
                request.httpBody = try rest.defaultEncoder().encode(any: body)
                request.setValue(rest.defaultEncoder().mimeType(), forHTTPHeaderField: "Content-Type")

                ARTLogDebug(self.logger, "subscribe notifications for clientId \(clientId) in channel \(channel.name)")
                _ = rest.executeRequest(request as URLRequest, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { [weak self] response, data, error in
                    guard let self = self else { return }
                    if let error = error {
                        ARTLogError(self.logger, "\(type(of: self)): subscribe notifications for clientId \(clientId) in channel \(channel.name) failed (\(error.localizedDescription))")
                    }
                    wrappedCallback?(error != nil ? ARTErrorInfo.createFromNSError(error!) : nil)
                }
            } catch {
                ARTLogError(self.logger, "\(type(of: self)): failed to encode subscription body (\(error.localizedDescription))")
                wrappedCallback?(ARTErrorInfo.createFromNSError(error))
            }
        }
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 26 and ARTPushChannel.m, line 175
    internal func unsubscribeDevice(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?, completion callback: ARTCallback?) {
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
            guard let self = self, let rest = self.rest, let channel = self.channel else { return }
            
            let device = self.getDevice(wrappedCallback)
            guard device.isRegistered() else {
                return
            }
            let deviceId = device.id

            let components = URLComponents(url: URL(string: "/push/channelSubscriptions")!, resolvingAgainstBaseURL: false)!
            var urlComponents = components
            urlComponents.queryItems = [
                URLQueryItem(name: "deviceId", value: deviceId),
                URLQueryItem(name: "channel", value: channel.name)
            ]

            let request = NSMutableURLRequest(url: urlComponents.url!)
            request.httpMethod = "DELETE"
            let authenticatedRequest = request.settingDeviceAuthentication(deviceId ?? "", localDevice: device).mutableCopy() as! NSMutableURLRequest

            ARTLogDebug(self.logger, "unsubscribe notifications for device \(String(describing: deviceId)) in channel \(channel.name)")
            _ = rest.executeRequest(authenticatedRequest as URLRequest, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { [weak self] response, data, error in
                guard let self = self else { return }
                if let error = error {
                    ARTLogError(self.logger, "\(type(of: self)): unsubscribe notifications for device \(String(describing: deviceId)) in channel \(channel.name) failed (\(error.localizedDescription))")
                }
                wrappedCallback?(error != nil ? ARTErrorInfo.createFromNSError(error!) : nil)
            }
        }
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 31 and ARTPushChannel.m, line 212
    internal func unsubscribeClient(withWrapperSDKAgents wrapperSDKAgents: NSStringDictionary?, completion callback: ARTCallback?) {
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
            guard let self = self, let rest = self.rest, let channel = self.channel else { return }
            
            guard let clientId = self.getClientId(wrappedCallback) else {
                return
            }

            let components = URLComponents(url: URL(string: "/push/channelSubscriptions")!, resolvingAgainstBaseURL: false)!
            var urlComponents = components
            urlComponents.queryItems = [
                URLQueryItem(name: "clientId", value: clientId),
                URLQueryItem(name: "channel", value: channel.name)
            ]

            let request = NSMutableURLRequest(url: urlComponents.url!)
            request.httpMethod = "DELETE"

            ARTLogDebug(self.logger, "unsubscribe notifications for clientId \(clientId) in channel \(channel.name)")
            _ = rest.executeRequest(request as URLRequest, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { [weak self] response, data, error in
                guard let self = self else { return }
                if let error = error {
                    ARTLogError(self.logger, "\(type(of: self)): unsubscribe notifications for clientId \(clientId) in channel \(channel.name) failed (\(error.localizedDescription))")
                }
                wrappedCallback?(error != nil ? ARTErrorInfo.createFromNSError(error!) : nil)
            }
        }
    }

    // swift-migration: original location ARTPushChannel+Private.h, line 34 and ARTPushChannel.m, line 247
    internal func listSubscriptions(_ params: NSStringDictionary, wrapperSDKAgents: NSStringDictionary?, callback: @escaping ARTPaginatedPushChannelCallback, error errorPtr: inout NSError?) -> Bool {
        var wrappedCallback = callback
        let userCallback = callback
        wrappedCallback = { [weak self] result, error in
            guard let self = self else { return }
            self.userQueue.async {
                userCallback(result, error)
            }
        }

        var returnValue = false
        queue.sync { [weak self] in
            guard let self = self, let rest = self.rest else { return }
            
            let mutableParams = NSMutableDictionary(dictionary: params)

            if mutableParams["deviceId"] == nil && mutableParams["clientId"] == nil {
                errorPtr = NSError(domain: ARTAblyErrorDomain,
                                  code: ARTDataQueryError.missingRequiredFields.rawValue,
                                  userInfo: [NSLocalizedDescriptionKey: "cannot list subscriptions with null device ID or null client ID"])
                returnValue = false
                return
            }
            if mutableParams["deviceId"] != nil && mutableParams["clientId"] != nil {
                errorPtr = NSError(domain: ARTAblyErrorDomain,
                                  code: ARTDataQueryError.invalidParameters.rawValue,
                                  userInfo: [NSLocalizedDescriptionKey: "cannot list subscriptions with device ID and client ID"])
                returnValue = false
                return
            }

            mutableParams["concatFilters"] = "true"

            let components = URLComponents(url: URL(string: "/push/channelSubscriptions")!, resolvingAgainstBaseURL: false)!
            var urlComponents = components
            urlComponents.queryItems = (mutableParams as NSDictionary).art_asURLQueryItems()
            let request = NSMutableURLRequest(url: urlComponents.url!)
            request.httpMethod = "GET"

            let responseProcessor: ARTPaginatedResultResponseProcessor = { [weak self] response, data, error in
                guard let self = self, let rest = self.rest else { return nil }
                if let response = response, let mimeType = response.mimeType, let encoder = rest.encoders[mimeType] {
                    do {
                        return try encoder.decodePushChannelSubscriptions(data!)
                    } catch {
                        return nil
                    }
                } else {
                    return nil
                }
            }

            ARTPaginatedResult.executePaginated(rest, withRequest: request as URLRequest, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
            returnValue = true
        }
        return returnValue
    }

    // swift-migration: original location ARTPushChannel.m, line 300
    private func getDevice(_ callback: ARTCallback?) -> ARTLocalDevice {
        #if os(iOS)
        let device = rest?.device_nosync ?? ARTLocalDevice()
        #else
        let device = ARTLocalDevice()
        #endif
        if !device.isRegistered() {
            callback?(ARTErrorInfo(code: 0, message: "cannot use device before device activation has finished"))
        }
        return device
    }

    // swift-migration: original location ARTPushChannel.m, line 312
    private func getClientId(_ callback: ARTCallback?) -> String? {
        let device = getDevice(callback)
        guard device.isRegistered() else {
            return nil
        }
        guard let clientId = device.clientId else {
            callback?(ARTErrorInfo(code: 0, message: "cannot subscribe/unsubscribe with null client ID"))
            return nil
        }
        return clientId
    }
}
