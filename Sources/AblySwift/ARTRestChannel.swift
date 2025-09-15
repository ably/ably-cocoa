import Foundation

// swift-migration: original location ARTRestChannel.h, line 14
/**
 The protocol upon which the `ARTRestChannel` is implemented.
 */
public protocol ARTRestChannelProtocol: ARTChannelProtocol {
    
    // swift-migration: original location ARTRestChannel.h, line 17
    /// :nodoc: TODO: docstring
    var options: ARTChannelOptions? { get set }
    
    // swift-migration: original location ARTRestChannel.h, line 28
    /**
     * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTMessage` objects for the channel. If the channel is configured to persist messages, then messages can be retrieved from history for up to 72 hours in the past. If not, messages can only be retrieved from history for up to two minutes in the past.
     *
     * @param query An `ARTDataQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTMessage` objects.
     * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
     *
     * @return In case of failure returns `false` and the error information can be retrived via the `error` parameter.
     */
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    func history(_ query: ARTDataQuery?, callback: @escaping ARTPaginatedMessagesCallback) throws -> Bool
    
    // swift-migration: original location ARTRestChannel.h, line 35
    /**
     * Retrieves a `ARTChannelDetails` object for the channel, which includes status and occupancy metrics.
     *
     * @param callback A callback for receiving the `ARTChannelDetails` object.
     */
    func status(_ callback: @escaping ARTChannelDetailsCallback)
    
    // swift-migration: original location ARTRestChannel.h, line 42
    /**
     * Sets the `ARTChannelOptions` for the channel.
     *
     * @param options A `ARTChannelOptions` object.
     */
    func setOptions(_ options: ARTChannelOptions?)
}

// swift-migration: original location ARTRestChannel.h, line 50 and ARTRestChannel.m, lines 21-106
/**
 * Enables messages to be published and historic messages to be retrieved for a channel.
 */
public class ARTRestChannel: NSObject, ARTRestChannelProtocol, @unchecked Sendable {
    internal let _internal: ARTRestChannelInternal
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRestChannel.m, line 25
    internal init(internal internalInstance: ARTRestChannelInternal, queuedDealloc: ARTQueuedDealloc) {
        _internal = internalInstance
        _dealloc = queuedDealloc
        super.init()
    }
    
    // swift-migration: original location ARTRestChannel+Private.h, line 45 and ARTRestChannel.m, line 25
    internal var `internal`: ARTRestChannelInternal {
        return _internal
    }
    
    // swift-migration: original location ARTRestChannel.h, line 55 and ARTRestChannel.m, line 34
    public var presence: ARTRestPresence {
        return ARTRestPresence(internal: _internal.presence, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRestChannel.h, line 60 and ARTRestChannel.m, line 38
    public var push: ARTPushChannel {
        return ARTPushChannel(internal: _internal.push, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 42
    public var name: String {
        return _internal.name
    }
    
    // swift-migration: original location ARTRestChannel.h, line 28 and ARTRestChannel.m, line 46
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    public func history(_ query: ARTDataQuery?, callback: @escaping ARTPaginatedMessagesCallback) throws -> Bool {
        return try _internal.history(query, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRestChannel.h, line 35 and ARTRestChannel.m, line 50
    public func status(_ callback: @escaping ARTChannelDetailsCallback) {
        _internal.status(callback)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 54
    public func publish(_ name: String?, data: Any?) {
        _internal.publish(name, data: data)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 58
    public func publish(_ name: String?, data: Any?, callback: ARTCallback?) {
        _internal.publish(name, data: data, callback: callback)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 62
    public func publish(_ name: String?, data: Any?, clientId: String) {
        _internal.publish(name, data: data, clientId: clientId)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 66
    public func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?) {
        _internal.publish(name, data: data, clientId: clientId, callback: callback)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 70
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?) {
        _internal.publish(name, data: data, extras: extras)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 74
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        _internal.publish(name, data: data, extras: extras, callback: callback)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 78
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?) {
        _internal.publish(name, data: data, clientId: clientId, extras: extras)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 82
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        _internal.publish(name, data: data, clientId: clientId, extras: extras, callback: callback)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 86
    public func publish(_ messages: [ARTMessage]) {
        _internal.publish(messages)
    }
    
    // swift-migration: original location ARTChannelProtocol.h and ARTRestChannel.m, line 90
    public func publish(_ messages: [ARTMessage], callback: ARTCallback?) {
        _internal.publish(messages, callback: callback)
    }
    
    // swift-migration: original location ARTRestChannel.m, line 94
    public func history(_ callback: @escaping ARTPaginatedMessagesCallback) {
        _internal.historyWithWrapperSDKAgents(nil, completion: callback)
    }
    
    // swift-migration: original location ARTRestChannel.h, line 17 and ARTRestChannel.m, line 98
    public var options: ARTChannelOptions? {
        get {
            return _internal.options
        }
        set {
            _internal.setOptions(newValue)
        }
    }
    
    // swift-migration: original location ARTRestChannel.h, line 42 and ARTRestChannel.m, line 102
    public func setOptions(_ options: ARTChannelOptions?) {
        _internal.setOptions(options)
    }
}

// swift-migration: original location ARTRestChannel.m, line 108
private let kIdempotentLibraryGeneratedIdLength: Int = 9 // bytes

// swift-migration: original location ARTRestChannel.m, lines 110-378
internal class ARTRestChannelInternal: ARTChannel {
    private let _userQueue: DispatchQueue
    private var _presence: ARTRestPresenceInternal?
    private var _pushChannel: ARTPushChannelInternal?
    internal let _basePath: String
    
    weak var rest: ARTRestInternal? // weak because rest owns self
    var queue: DispatchQueue
    
    // swift-migration: original location ARTRestChannel.m, line 119 - @dynamic options indicates computed property
    
    // swift-migration: original location ARTRestChannel.m, line 121
    internal init(name: String, withOptions options: ARTChannelOptions, andRest rest: ARTRestInternal, logger: InternalLog) {
        self._userQueue = rest.userQueue
        self.rest = rest
        self.queue = rest.queue
        self._basePath = "/channels/\(name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? name)"
        super.init(name: name, andOptions: options, rest: rest, logger: logger)
        ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(self).toOpaque()) instantiating under '\(name)'")
    }
    
    // swift-migration: original location ARTRestChannel.m, line 132
    internal func getBasePath() -> String {
        return _basePath
    }
    
    // swift-migration: original location ARTRestChannel+Private.h, line 39 and ARTRestChannel.m, line 132
    internal var basePath: String {
        return getBasePath()
    }
    
    // swift-migration: original location ARTRestChannel+Private.h, line 19 and ARTRestChannel.m, line 136
    internal var presence: ARTRestPresenceInternal {
        if let presence = _presence {
            return presence
        }
        let presence = ARTRestPresenceInternal(channel: self, logger: logger)
        _presence = presence
        return presence
    }
    
    // swift-migration: original location ARTRestChannel+Private.h, line 20 and ARTRestChannel.m, line 143
    internal var push: ARTPushChannelInternal {
        if let pushChannel = _pushChannel {
            return pushChannel
        }
        let pushChannel = ARTPushChannelInternal(rest: rest!, withChannel: self, logger: logger)
        _pushChannel = pushChannel
        return pushChannel
    }
    
    // swift-migration: original location ARTRestChannel.m, line 150
    internal override func historyWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion callback: @escaping ARTPaginatedMessagesCallback) {
        // swift-migration: Updated to use try/catch instead of error parameter per PRD requirements
        do {
            let _ = try history(ARTDataQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: callback)
        } catch {
            // If error occurs, call the callback with the error
            callback(nil, ARTErrorInfo.createFromNSError(error as NSError))
        }
    }
    
    // swift-migration: original location ARTRestChannel+Private.h, line 29 and ARTRestChannel.m, line 154
    // swift-migration: Changed from UnsafeMutablePointer<NSError?>? parameter to throws pattern per PRD requirements
    internal func history(_ query: ARTDataQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedMessagesCallback) throws -> Bool {
        let userCallback = callback
        let wrappedCallback: ARTPaginatedMessagesCallback = { result, error in
            self._userQueue.async {
                userCallback(result, error)
            }
        }
        
        var ret = false
        var thrownError: NSError?
        queue.sync {
            if let query = query, query.limit > 1000 {
                thrownError = NSError(domain: ARTAblyErrorDomain,
                                     code: ARTDataQueryError.limit.rawValue,
                                     userInfo: [NSLocalizedDescriptionKey: "Limit supports up to 1000 results only"])
                ret = false
                return
            }
            if let query = query, let start = query.start, let end = query.end, start.compare(end) == .orderedDescending {
                thrownError = NSError(domain: ARTAblyErrorDomain,
                                     code: ARTDataQueryError.timestampRange.rawValue,
                                     userInfo: [NSLocalizedDescriptionKey: "Start must be equal to or less than end"])
                ret = false
                return
            }
            
            guard let componentsUrl = URLComponents(string: _basePath.appending("/messages")) else {
                ret = false
                return
            }
            var components = componentsUrl
            
            if let query = query {
                do {
                    components.queryItems = try query.asQueryItems()
                } catch {
                    thrownError = error as NSError?
                    ret = false
                    return
                }
            }
            
            guard let url = components.url else {
                ret = false
                return
            }
            let request = URLRequest(url: url)
            
            let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data in
                guard let encoder = self.rest?.encoders[response?.mimeType ?? ""] else {
                    return []
                }
                
                let messages = try? encoder.decodeMessages(data ?? Data())
                
                return messages?.artMap { message in
                    let decodedMessage = try? message.decode(withEncoder: self.dataEncoder)
                    if decodedMessage == nil {
                        let errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.unableToDecodeMessage.rawValue, message: "Failed to decode message")
                        ARTLogError(self.logger, "RS:\(Unmanaged.passUnretained(self.rest!).toOpaque()) C:\(Unmanaged.passUnretained(self).toOpaque()) (\(self.name)) \(errorInfo.message)")
                    }
                    return decodedMessage
                }
            }
            
            ARTLogDebug(logger, "RS:\(Unmanaged.passUnretained(rest!).toOpaque()) C:\(Unmanaged.passUnretained(self).toOpaque()) (\(name)) stats request \(request)")
            ARTPaginatedResult.executePaginated(rest!, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: logger, callback: wrappedCallback)
            ret = true
        }
        
        if let error = thrownError {
            throw error
        }
        return ret
    }
    
    // swift-migration: original location ARTRestChannel+Private.h, line 31 and ARTRestChannel.m, line 218
    internal func status(_ callback: @escaping ARTChannelDetailsCallback) {
        let userCallback = callback
        let wrappedCallback: ARTChannelDetailsCallback = { details, error in
            self._userQueue.async {
                userCallback(details, error)
            }
        }
        queue.async {
            guard let url = URL(string: self._basePath) else { return }
            let request = NSMutableURLRequest(url: url)
            
            ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self.rest!).toOpaque()) C:\(Unmanaged.passUnretained(self).toOpaque()) (\(self.name)) channel details request \(request)")
            
            self.rest?.executeRequest(request as URLRequest, withAuthOption: .on, wrapperSDKAgents: nil) { response, data, error in
                
                if response?.statusCode == 200 {
                    var decodeError: NSError?
                    guard let decoder = self.rest?.encoders[response?.mimeType ?? ""] else {
                        let errorMessage = "Decoder for MIMEType '\(response?.mimeType ?? "")' wasn't found."
                        ARTLogDebug(self.logger, "\(String(describing: type(of: self))): \(errorMessage)")
                        wrappedCallback(nil, ARTErrorInfo.create(withCode: ARTErrorCode.unableToDecodeMessage.rawValue, message: errorMessage))
                        return
                    }
                    
                    let channelDetails = try? decoder.decodeChannelDetails(data ?? Data())
                    if let decodeError = decodeError {
                        ARTLogDebug(self.logger, "\(String(describing: type(of: self))): decode channel details failed (\(error?.localizedDescription ?? ""))")
                        wrappedCallback(nil, ARTErrorInfo.createFromNSError(decodeError))
                    } else if let channelDetails = channelDetails {
                        ARTLogDebug(self.logger, "\(String(describing: type(of: self))): successfully got channel details \(channelDetails.channelId)")
                        wrappedCallback(channelDetails, nil)
                    }
                } else {
                    ARTLogDebug(self.logger, "\(String(describing: type(of: self))): get channel details failed (\(error?.localizedDescription ?? ""))")
                    var errorInfo: ARTErrorInfo?
                    if let error = error {
                        if self.rest?.options.addRequestIds == true {
                            errorInfo = ARTErrorInfo.wrap(ARTErrorInfo.createFromNSError(error), prepend: "Request '\(request.url!)' failed with ")
                        } else {
                            errorInfo = ARTErrorInfo.createFromNSError(error)
                        }
                    }
                    wrappedCallback(nil, errorInfo)
                }
            }
        }
    }
    
    // swift-migration: original location ARTRestChannel.m, line 279
    private func internalPostMessages(_ data: Any, callback: @escaping ARTCallback) {
        let userCallback = callback
        let wrappedCallback: ARTCallback = { error in
            self._userQueue.async {
                userCallback(error)
            }
        }
        
        queue.async {
            var encodedMessage: Data?
            
            if let message = data as? ARTMessage {
                var baseId: String?
                if self.rest?.options.idempotentRestPublishing == true && message.isIdEmpty {
                    if let baseIdData = ARTCrypto.generateSecureRandomData(kIdempotentLibraryGeneratedIdLength) {
                        baseId = baseIdData.base64EncodedString()
                        message.id = "\(baseId!):0"
                    }
                }
                
                if let messageClientId = message.clientId,
                   let authClientId = self.rest?.auth.clientId_nosync(),
                   messageClientId != authClientId {
                    wrappedCallback(ARTErrorInfo.create(withCode: ARTState.mismatchedClientId.rawValue, message: "attempted to publish message with an invalid clientId"))
                    return
                }
                
                var encodeError: NSError?
                encodedMessage = try? self.rest?.defaultEncoder.encodeMessage(message)
                if let encodeError = encodeError {
                    wrappedCallback(ARTErrorInfo.createFromNSError(encodeError))
                    return
                }
            } else if let messages = data as? [ARTMessage] {
                var baseId: String?
                if self.rest?.options.idempotentRestPublishing == true {
                    let messagesHaveEmptyId = messages.artFilter { !$0.isIdEmpty }.count <= 0
                    if messagesHaveEmptyId {
                        if let baseIdData = ARTCrypto.generateSecureRandomData(kIdempotentLibraryGeneratedIdLength) {
                            baseId = baseIdData.base64EncodedString()
                        }
                    }
                }
                
                var serial = 0
                for message in messages {
                    if let messageClientId = message.clientId,
                       let authClientId = self.rest?.auth.clientId_nosync(),
                       messageClientId != authClientId {
                        wrappedCallback(ARTErrorInfo.create(withCode: ARTState.mismatchedClientId.rawValue, message: "attempted to publish message with an invalid clientId"))
                        return
                    }
                    if let baseId = baseId {
                        message.id = "\(baseId):\(serial)"
                    }
                    serial += 1
                }
                
                var encodeError: NSError?
                encodedMessage = try? self.rest?.defaultEncoder.encodeMessages(data as! [ARTMessage])
                if let encodeError = encodeError {
                    wrappedCallback(ARTErrorInfo.createFromNSError(encodeError))
                    return
                }
            }
            
            guard var components = URLComponents(url: URL(string: self._basePath.appending("/messages"))!, resolvingAgainstBaseURL: true) else { return }
            let queryItems: [URLQueryItem] = []
            
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            
            guard let url = components.url else { return }
            let request = NSMutableURLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = encodedMessage
            
            if let defaultEncoding = self.rest?.defaultEncoding {
                request.setValue(defaultEncoding, forHTTPHeaderField: "Content-Type")
            }
            
            ARTLogDebug(self.logger, "RS:\(Unmanaged.passUnretained(self.rest!).toOpaque()) C:\(Unmanaged.passUnretained(self).toOpaque()) (\(self.name)) post message \(String(data: encodedMessage ?? Data(), encoding: .utf8) ?? "")")
            
            self.rest?.executeRequest(request as URLRequest, withAuthOption: .on, wrapperSDKAgents: nil) { response, data, error in
                let errorInfo: ARTErrorInfo?
                if self.rest?.options.addRequestIds == true {
                    errorInfo = error != nil ? ARTErrorInfo.wrap(ARTErrorInfo.createFromNSError(error!), prepend: "Request '\(request.url!)' failed with ") : nil
                } else {
                    errorInfo = error != nil ? ARTErrorInfo.createFromNSError(error!) : nil
                }
                
                wrappedCallback(errorInfo)
            }
        }
    }
}
