import Foundation

/**
 The protocol upon which the `ARTPushChannelSubscriptions` is implemented.
 */
// swift-migration: original location ARTPushChannelSubscriptions.h, line 13
public protocol ARTPushChannelSubscriptionsProtocol {
    
    /**
     * Subscribes a device, or a group of devices sharing the same `clientId` to push notifications on a channel.
     *
     * @param channelSubscription An `ARTPushChannelSubscription` object.
     * @param callback A success or failure callback function.
     */
    func save(_ channelSubscription: ARTPushChannelSubscription, callback: @escaping ARTCallback)
    
    /**
     * Retrieves all channels with at least one device subscribed to push notifications. Returns a `ARTPaginatedResult` object, containing an array of channel names.
     *
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of channel names.
     */
    func listChannels(_ callback: @escaping ARTPaginatedTextCallback)
    
    /**
     * Retrieves all push channel subscriptions matching the filter `params` provided. Returns a `ARTPaginatedResult` object, containing an array of `ARTPushChannelSubscription` objects.
     *
     * @param params An object containing key-value pairs to filter subscriptions by. Can contain `channel`, `clientId`, `deviceId` and a `limit` on the number of devices returned, up to 1,000.
     *
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPushChannelSubscription` objects.
     */
    func list(_ params: [String: String], callback: @escaping ARTPaginatedPushChannelCallback)
    
    /**
     * Unsubscribes a device, or a group of devices sharing the same `clientId` from receiving push notifications on a channel.
     *
     * @param subscription An `ARTPushChannelSubscription` object.
     * @param callback A success or failure callback function.
     */
    func remove(_ subscription: ARTPushChannelSubscription, callback: @escaping ARTCallback)
    
    /**
     * Unsubscribes all devices from receiving push notifications on a channel that match the filter `params` provided.
     *
     * @param params An object containing key-value pairs to filter subscriptions by. Can contain `channel`, and optionally either `clientId` or `deviceId`.
     * @param callback A success or failure callback function.
     */
    func removeWhere(_ params: [String: String], callback: @escaping ARTCallback)
}

/**
 * Enables device push channel subscriptions.
 *
 * @see See `ARTPushChannelSubscriptionsProtocol` for details.
 */
// swift-migration: original location ARTPushChannelSubscriptions.h, line 66 and ARTPushChannelSubscriptions.m, line 13
public class ARTPushChannelSubscriptions: NSObject, ARTPushChannelSubscriptionsProtocol, Sendable {
    
    // swift-migration: original location ARTPushChannelSubscriptions+Private.h, line 27
    internal let internalInstance: ARTPushChannelSubscriptionsInternal
    
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 17
    internal init(internal internalInstance: ARTPushChannelSubscriptionsInternal, queuedDealloc dealloc: ARTQueuedDealloc) {
        self.internalInstance = internalInstance
        self._dealloc = dealloc
        super.init()
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 26
    public func save(_ channelSubscription: ARTPushChannelSubscription, callback: @escaping ARTCallback) {
        internalInstance.save(channelSubscription, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 30
    public func listChannels(_ callback: @escaping ARTPaginatedTextCallback) {
        internalInstance.listChannels(wrapperSDKAgents: nil, completion: callback)
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 34
    public func list(_ params: [String: String], callback: @escaping ARTPaginatedPushChannelCallback) {
        internalInstance.list(params, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 38
    public func remove(_ subscription: ARTPushChannelSubscription, callback: @escaping ARTCallback) {
        internalInstance.remove(subscription, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 42
    public func removeWhere(_ params: [String: String], callback: @escaping ARTCallback) {
        internalInstance.removeWhere(params, wrapperSDKAgents: nil, callback: callback)
    }
}

// swift-migration: original location ARTPushChannelSubscriptions+Private.h, line 9 and ARTPushChannelSubscriptions.m, line 48
internal class ARTPushChannelSubscriptionsInternal: NSObject {
    
    private weak var _rest: ARTRestInternal? // weak because rest owns self
    private let _logger: ARTInternalLog
    private let _queue: DispatchQueue
    private let _userQueue: DispatchQueue
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 55
    internal init(rest: ARTRestInternal, logger: ARTInternalLog) {
        self._rest = rest
        self._logger = logger
        self._queue = rest.queue
        self._userQueue = rest.userQueue
        super.init()
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 65
    internal func save(_ channelSubscription: ARTPushChannelSubscription, wrapperSDKAgents: [String: String]?, callback: @escaping ARTCallback) {
        let wrappedCallback: ARTCallback? = { error in
            self._userQueue.async {
                callback(error)
            }
        }
        let finalCallback = wrappedCallback ?? callback
        
    #if os(iOS)
        let local = _rest?.device
    #else
        let local: ARTLocalDevice? = nil
    #endif
        
        _queue.async {
            guard let rest = self._rest else {
                finalCallback(ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            let components = URLComponents(url: URL(string: "/push/channelSubscriptions")!, resolvingAgainstBaseURL: false)!
            var finalComponents = components
            if rest.options.pushFullWait {
                finalComponents.queryItems = [URLQueryItem(name: "fullWait", value: "true")]
            }
            
            var request = URLRequest(url: finalComponents.url!)
            request.httpMethod = "POST"
            do {
                request.httpBody = try rest.defaultEncoder().encodePushChannelSubscription(channelSubscription)
            } catch {
                // If encoding fails, continue with nil body
                request.httpBody = nil
            }
            request.setValue(rest.defaultEncoder().mimeType(), forHTTPHeaderField: "Content-Type")
            
            if let mutableRequest = (request.settingDeviceAuthentication(channelSubscription.deviceId, localDevice: local) as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
                request = mutableRequest as URLRequest
            }
            
            ARTLogDebug(self._logger, "save channel subscription with request \(request)")
            rest.executeRequest(request, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        ARTLogDebug(self._logger, "channel subscription saved successfully")
                        finalCallback(nil)
                    } else {
                        ARTLogError(self._logger, "\(String(describing: type(of: self))): save channel subscription failed with status code \(httpResponse.statusCode)")
                        let plain = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        finalCallback(ARTErrorInfo.create(withCode: httpResponse.statusCode * 100, status: httpResponse.statusCode, message: plain.art_shortString))
                    }
                } else if let error = error {
                    ARTLogError(self._logger, "\(String(describing: type(of: self))): save channel subscription failed (\(error.localizedDescription))")
                    finalCallback(ARTErrorInfo.createFromNSError(error))
                }
            }
        }
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 111
    internal func listChannels(wrapperSDKAgents: [String: String]?, completion callback: @escaping ARTPaginatedTextCallback) {
        let wrappedCallback: ARTPaginatedTextCallback? = { result, error in
            self._userQueue.async {
                callback(result, error)
            }
        }
        let finalCallback = wrappedCallback ?? callback
        
        _queue.async {
            guard let rest = self._rest else {
                finalCallback(nil, ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            let components = URLComponents(url: URL(string: "/push/channels")!, resolvingAgainstBaseURL: false)!
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            
            let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data, errorPtr in
                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data,
                      let mimeType = httpResponse.mimeType,
                      let encoder = rest.encoders[mimeType] else {
                    return []
                }
                do {
                    return try encoder.decode(data) as? [Any] ?? []
                } catch let swiftError {
                    errorPtr = swiftError
                    return []
                }
            }
            
            ARTPaginatedResult.executePaginated(rest, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: self._logger, callback: finalCallback)
        }
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 134
    internal func list(_ params: [String: String], wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedPushChannelCallback) {
        let wrappedCallback: ARTPaginatedPushChannelCallback? = { result, error in
            self._userQueue.async {
                callback(result, error)
            }
        }
        let finalCallback = wrappedCallback ?? callback
        
        _queue.async {
            guard let rest = self._rest else {
                finalCallback(nil, ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            var components = URLComponents(url: URL(string: "/push/channelSubscriptions")!, resolvingAgainstBaseURL: false)!
            components.queryItems = params.art_asURLQueryItems()
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            
            let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data, errorPtr in
                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data,
                      let mimeType = httpResponse.mimeType,
                      let encoder = rest.encoders[mimeType] else {
                    return []
                }
                do {
                    return try encoder.decodePushChannelSubscriptions(data) ?? []
                } catch let swiftError {
                    errorPtr = swiftError
                    return []
                }
            }
            
            ARTPaginatedResult.executePaginated(rest, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: self._logger, callback: finalCallback)
        }
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 157
    internal func remove(_ subscription: ARTPushChannelSubscription, wrapperSDKAgents: [String: String]?, callback: @escaping ARTCallback) {
        let wrappedCallback: ARTCallback? = { error in
            self._userQueue.async {
                callback(error)
            }
        }
        let finalCallback = wrappedCallback ?? callback
        
        _queue.async {
            if (subscription.deviceId != nil && subscription.clientId != nil) || (subscription.deviceId == nil && subscription.clientId == nil) {
                finalCallback(ARTErrorInfo.create(withCode: 0, message: "ARTChannelSubscription cannot be for both a deviceId and a clientId"))
                return
            }
            
            var whereParams: [String: String] = [:]
            whereParams["channel"] = subscription.channel
            if let deviceId = subscription.deviceId {
                whereParams["deviceId"] = deviceId
            } else if let clientId = subscription.clientId {
                whereParams["clientId"] = clientId
            }
            
            self._removeWhere(whereParams, wrapperSDKAgents: wrapperSDKAgents, callback: finalCallback)
        }
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 183
    internal func removeWhere(_ params: [String: String], wrapperSDKAgents: [String: String]?, callback: @escaping ARTCallback) {
        let wrappedCallback: ARTCallback? = { error in
            self._userQueue.async {
                callback(error)
            }
        }
        let finalCallback = wrappedCallback ?? callback
        
        _queue.async {
            self._removeWhere(params, wrapperSDKAgents: wrapperSDKAgents, callback: finalCallback)
        }
    }
    
    // swift-migration: original location ARTPushChannelSubscriptions.m, line 198
    private func _removeWhere(_ params: [String: String], wrapperSDKAgents: [String: String]?, callback: @escaping ARTCallback) {
        guard let rest = _rest else {
            callback(ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
            return
        }
        
        var components = URLComponents(url: URL(string: "/push/channelSubscriptions")!, resolvingAgainstBaseURL: false)!
        components.queryItems = params.art_asURLQueryItems()
        if rest.options.pushFullWait {
            let existingItems = components.queryItems ?? []
            components.queryItems = existingItems + [URLQueryItem(name: "fullWait", value: "true")]
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        
    #if os(iOS)
        if let deviceId = params["deviceId"],
           let mutableRequest = (request.settingDeviceAuthentication(deviceId, localDevice: rest.device_nosync) as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
            request = mutableRequest as URLRequest
        }
    #endif
        
        ARTLogDebug(_logger, "remove channel subscription with request \(request)")
        rest.executeRequest(request, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                    ARTLogDebug(self._logger, "\(String(describing: type(of: self))): channel subscription removed successfully")
                    callback(nil)
                } else {
                    ARTLogError(self._logger, "\(String(describing: type(of: self))): remove channel subscription failed with status code \(httpResponse.statusCode)")
                    let plain = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    callback(ARTErrorInfo.create(withCode: httpResponse.statusCode * 100, status: httpResponse.statusCode, message: plain.art_shortString))
                }
            } else if let error = error {
                ARTLogError(self._logger, "\(String(describing: type(of: self))): remove channel subscription failed (\(error.localizedDescription))")
                callback(ARTErrorInfo.createFromNSError(error))
            }
        }
    }
}