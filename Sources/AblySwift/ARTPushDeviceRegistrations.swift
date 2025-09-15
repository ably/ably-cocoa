import Foundation

/**
 The protocol upon which the `ARTPushDeviceRegistrations` is implemented.
 */
// swift-migration: original location ARTPushDeviceRegistrations.h, line 12
public protocol ARTPushDeviceRegistrationsProtocol {
    
    /**
     * Registers or updates a `ARTDeviceDetails` object with Ably.
     *
     * @param deviceDetails The `ARTDeviceDetails` object to create or update.
     * @param callback A success or failure callback function.
     */
    func save(_ deviceDetails: ARTDeviceDetails, callback: @escaping ARTCallback)
    
    /**
     * Retrieves the `ARTDeviceDetails` of a device registered to receive push notifications using its `deviceId`.
     *
     * @param deviceId The unique ID of the device.
     * @param callback A callback for receiving the `ARTDeviceDetails` object.
     */
    func get(_ deviceId: String, callback: @escaping (ARTDeviceDetails?, ARTErrorInfo?) -> Void)
    
    /**
     * Retrieves all devices matching the filter `params` provided. Returns a `ARTPaginatedResult` object, containing an array of `ARTDeviceDetails` objects.
     *
     * @param params An object containing key-value pairs to filter devices by. Can contain `clientId`, `deviceId` and a `limit` on the number of devices returned, up to 1,000.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTDeviceDetails` objects.
     */
    func list(_ params: [String: String], callback: @escaping ARTPaginatedDeviceDetailsCallback)
    
    /**
     * Removes a device registered to receive push notifications from Ably using its `deviceId`.
     *
     * @param deviceId The unique ID of the device.
     * @param callback A success or failure callback function.
     */
    func remove(_ deviceId: String, callback: @escaping ARTCallback)
    
    /**
     * Removes all devices registered to receive push notifications from Ably matching the filter `params` provided.
     *
     * @param params An object containing key-value pairs to filter devices by. Can contain `clientId` and `deviceId`.
     * @param callback A success or failure callback function.
     */
    func removeWhere(_ params: [String: String], callback: @escaping ARTCallback)
}

/**
 * Enables the management of push notification registrations with Ably.
 *
 * @see See `ARTPushDeviceRegistrationsProtocol` for details.
 */
// swift-migration: original location ARTPushDeviceRegistrations.h, line 65 and ARTPushDeviceRegistrations.m, line 14
public class ARTPushDeviceRegistrations: NSObject, ARTPushDeviceRegistrationsProtocol, @unchecked Sendable {

    // swift-migration: original location ARTPushDeviceRegistrations+Private.h, line 27
    internal let internalInstance: ARTPushDeviceRegistrationsInternal
    
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 18
    internal init(internal internalInstance: ARTPushDeviceRegistrationsInternal, queuedDealloc dealloc: ARTQueuedDealloc) {
        self.internalInstance = internalInstance
        self._dealloc = dealloc
        super.init()
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 27
    public func save(_ deviceDetails: ARTDeviceDetails, callback: @escaping ARTCallback) {
        internalInstance.save(deviceDetails, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 31
    public func get(_ deviceId: String, callback: @escaping (ARTDeviceDetails?, ARTErrorInfo?) -> Void) {
        internalInstance.get(deviceId, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 35
    public func list(_ params: [String: String], callback: @escaping ARTPaginatedDeviceDetailsCallback) {
        internalInstance.list(params, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 39
    public func remove(_ deviceId: String, callback: @escaping ARTCallback) {
        internalInstance.remove(deviceId, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 43
    public func removeWhere(_ params: [String: String], callback: @escaping ARTCallback) {
        internalInstance.removeWhere(params, wrapperSDKAgents: nil, callback: callback)
    }
}

// swift-migration: original location ARTPushDeviceRegistrations+Private.h, line 9 and ARTPushDeviceRegistrations.m, line 49
internal class ARTPushDeviceRegistrationsInternal: NSObject {
    
    private weak var _rest: ARTRestInternal? // weak because rest owns self
    private let _logger: InternalLog
    private let _queue: DispatchQueue
    private let _userQueue: DispatchQueue
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 56
    internal init(rest: ARTRestInternal, logger: InternalLog) {
        self._rest = rest
        self._logger = logger
        self._queue = rest.queue
        self._userQueue = rest.userQueue
        super.init()
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 66
    internal func save(_ deviceDetails: ARTDeviceDetails, wrapperSDKAgents: [String: String]?, callback: @escaping ARTCallback) {
        let wrappedCallback: ARTCallback = { error in
            self._userQueue.async {
                callback(error)
            }
        }
        
    #if os(iOS)
        let local = _rest?.device
    #else
        let local: ARTLocalDevice? = nil
    #endif
        
        _queue.async {
            guard let rest = self._rest else {
                wrappedCallback(ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            let baseURL = URL(string: "/push/deviceRegistrations")!
            let deviceURL = baseURL.appendingPathComponent(deviceDetails.id ?? "")
            var components = URLComponents(url: deviceURL, resolvingAgainstBaseURL: false)!
            if rest.options.pushFullWait {
                components.queryItems = [URLQueryItem(name: "fullWait", value: "true")]
            }
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "PUT"
            do {
                request.httpBody = try rest.defaultEncoder.encodeDeviceDetails(deviceDetails)
            } catch {
                request.httpBody = nil
            }
            request.setValue(rest.defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")
            
            if let deviceId = deviceDetails.id, let localDevice = local,
               let mutableRequest = (request.settingDeviceAuthentication(deviceId, localDevice: localDevice, logger: self._logger) as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
                request = mutableRequest as URLRequest
            }
            
            ARTLogDebug(self._logger, "save device with request \(request)")
            _ = rest.executeRequest(request, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
                if let response {
                    if response.statusCode == 200 {
                        if let data = data {
                            do {
                                let deviceDetails = try rest.defaultEncoder.decodeDeviceDetails(data)
                                if let deviceDetails = deviceDetails {
                                    ARTLogDebug(self._logger, "\(String(describing: type(of: self))): successfully saved device \(deviceDetails.id ?? "")")
                                }
                                wrappedCallback(nil)
                            } catch {
                                ARTLogDebug(self._logger, "\(String(describing: type(of: self))): decode device failed (\(error.localizedDescription))")
                                wrappedCallback(ARTErrorInfo.createFromNSError(error))
                            }
                        } else {
                            wrappedCallback(nil)
                        }
                    } else {
                        ARTLogError(self._logger, "\(String(describing: type(of: self))): save device failed with status code \(response.statusCode)")
                        let plain = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        wrappedCallback(ARTErrorInfo.create(withCode: response.statusCode * 100, status: response.statusCode, message: plain.art_shortString))
                    }
                } else if let error = error {
                    ARTLogError(self._logger, "\(String(describing: type(of: self))): save device failed (\(error.localizedDescription))")
                    wrappedCallback(ARTErrorInfo.createFromNSError(error))
                }
            }
        }
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 120
    internal func get(_ deviceId: String, wrapperSDKAgents: [String: String]?, callback: @escaping (ARTDeviceDetails?, ARTErrorInfo?) -> Void) {
        let wrappedCallback: (ARTDeviceDetails?, ARTErrorInfo?) -> Void = { device, error in
            self._userQueue.async {
                callback(device, error)
            }
        }
        
    #if os(iOS)
        let local = _rest?.device
    #else
        let local: ARTLocalDevice? = nil
    #endif
        
        _queue.async {
            guard let rest = self._rest else {
                wrappedCallback(nil, ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            let baseURL = URL(string: "/push/deviceRegistrations")!
            let deviceURL = baseURL.appendingPathComponent(deviceId)
            var request = URLRequest(url: deviceURL)
            request.httpMethod = "GET"
            
            if let localDevice = local,
               let mutableRequest = (request.settingDeviceAuthentication(deviceId, localDevice: localDevice, logger: self._logger) as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
                request = mutableRequest as URLRequest
            }
            
            ARTLogDebug(self._logger, "get device with request \(request)")
            _ = rest.executeRequest(request, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
                if let response {
                    if response.statusCode == 200 {
                        if let data = data,
                           let mimeType = response.mimeType,
                           let encoder = rest.encoders[mimeType] {
                            do {
                                let device = try encoder.decodeDeviceDetails(data)
                                if let device = device {
                                    ARTLogDebug(self._logger, "\(String(describing: type(of: self))): get device successfully")
                                    wrappedCallback(device, nil)
                                } else {
                                    ARTLogDebug(self._logger, "\(String(describing: type(of: self))): get device failed with unknown error")
                                    wrappedCallback(nil, ARTErrorInfo.createUnknownError())
                                }
                            } catch {
                                ARTLogDebug(self._logger, "\(String(describing: type(of: self))): decode device failed (\(error.localizedDescription))")
                                wrappedCallback(nil, ARTErrorInfo.createFromNSError(error))
                            }
                        } else {
                            ARTLogDebug(self._logger, "\(String(describing: type(of: self))): get device failed with unknown error")
                            wrappedCallback(nil, ARTErrorInfo.createUnknownError())
                        }
                    } else {
                        ARTLogError(self._logger, "\(String(describing: type(of: self))): get device failed with status code \(response.statusCode)")
                        let plain = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        wrappedCallback(nil, ARTErrorInfo.create(withCode: response.statusCode * 100, status: response.statusCode, message: plain.art_shortString))
                    }
                } else if let error = error {
                    ARTLogError(self._logger, "\(String(describing: type(of: self))): get device failed (\(error.localizedDescription))")
                    wrappedCallback(nil, ARTErrorInfo.createFromNSError(error))
                }
            }
        }
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 172
    internal func list(_ params: [String: String], wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedDeviceDetailsCallback) {
        let wrappedCallback: ARTPaginatedDeviceDetailsCallback = { result, error in
            self._userQueue.async {
                callback(result, error)
            }
        }
        
        _queue.async {
            guard let rest = self._rest else {
                wrappedCallback(nil, ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            var components = URLComponents(url: URL(string: "/push/deviceRegistrations")!, resolvingAgainstBaseURL: false)!
            components.queryItems = params.art_asURLQueryItems()
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            
            // swift-migration: Updated responseProcessor to use throws pattern instead of inout error parameter
            let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data in
                guard let response,
                      let data = data,
                      let mimeType = response.mimeType,
                      let encoder = rest.encoders[mimeType] else {
                    return []
                }
                return try encoder.decodeDevicesDetails(data) ?? []
            }
            
            ARTPaginatedResult.executePaginated(rest, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: self._logger, callback: wrappedCallback)
        }
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 195
    internal func remove(_ deviceId: String, wrapperSDKAgents: [String: String]?, callback: @escaping ARTCallback) {
        let wrappedCallback: ARTCallback = { error in
            self._userQueue.async {
                callback(error)
            }
        }
        
        _queue.async {
            guard let rest = self._rest else {
                wrappedCallback(ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            let baseURL = URL(string: "/push/deviceRegistrations")!
            let deviceURL = baseURL.appendingPathComponent(deviceId)
            var components = URLComponents(url: deviceURL, resolvingAgainstBaseURL: false)!
            if rest.options.pushFullWait {
                components.queryItems = [URLQueryItem(name: "fullWait", value: "true")]
            }
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "DELETE"
            request.setValue(rest.defaultEncoder.mimeType(), forHTTPHeaderField: "Content-Type")
            
            ARTLogDebug(self._logger, "remove device with request \(request)")
            _ = rest.executeRequest(request, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
                if let response {
                    if response.statusCode == 200 || response.statusCode == 204 {
                        ARTLogDebug(self._logger, "\(String(describing: type(of: self))): save device successfully")
                        wrappedCallback(nil)
                    } else {
                        ARTLogError(self._logger, "\(String(describing: type(of: self))): remove device failed with status code \(response.statusCode)")
                        let plain = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        wrappedCallback(ARTErrorInfo.create(withCode: response.statusCode * 100, status: response.statusCode, message: plain.art_shortString))
                    }
                } else if let error = error {
                    ARTLogError(self._logger, "\(String(describing: type(of: self))): remove device failed (\(error.localizedDescription))")
                    wrappedCallback(ARTErrorInfo.createFromNSError(error))
                }
            }
        }
    }
    
    // swift-migration: original location ARTPushDeviceRegistrations.m, line 233
    internal func removeWhere(_ params: [String: String], wrapperSDKAgents: [String: String]?, callback: @escaping ARTCallback) {
        let wrappedCallback: ARTCallback = { error in
            self._userQueue.async {
                callback(error)
            }
        }
        
    #if os(iOS)
        let local = _rest?.device
    #else
        let local: ARTLocalDevice? = nil
    #endif
        
        _queue.async {
            guard let rest = self._rest else {
                wrappedCallback(ARTErrorInfo.create(withCode: 0, message: "ARTRest instance is nil"))
                return
            }
            
            var components = URLComponents(url: URL(string: "/push/deviceRegistrations")!, resolvingAgainstBaseURL: false)!
            components.queryItems = params.art_asURLQueryItems()
            if rest.options.pushFullWait {
                let existingItems = components.queryItems ?? []
                components.queryItems = existingItems + [URLQueryItem(name: "fullWait", value: "true")]
            }
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "DELETE"
            
            if let deviceId = params["deviceId"], let localDevice = local,
               let mutableRequest = (request.settingDeviceAuthentication(deviceId, localDevice: localDevice) as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
                request = mutableRequest as URLRequest
            }
            
            ARTLogDebug(self._logger, "remove devices with request \(request)")
            _ = rest.executeRequest(request, withAuthOption: .on, wrapperSDKAgents: wrapperSDKAgents) { response, data, error in
                if let response {
                    if response.statusCode == 200 || response.statusCode == 204 {
                        ARTLogDebug(self._logger, "\(String(describing: type(of: self))): remove devices successfully")
                        wrappedCallback(nil)
                    } else {
                        ARTLogError(self._logger, "\(String(describing: type(of: self))): remove devices failed with status code \(response.statusCode)")
                        let plain = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        wrappedCallback(ARTErrorInfo.create(withCode: response.statusCode * 100, status: response.statusCode, message: plain.art_shortString))
                    }
                } else if let error = error {
                    ARTLogError(self._logger, "\(String(describing: type(of: self))): remove devices failed (\(error.localizedDescription))")
                    wrappedCallback(ARTErrorInfo.createFromNSError(error))
                }
            }
        }
    }
}
