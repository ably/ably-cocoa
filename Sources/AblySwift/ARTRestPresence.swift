import Foundation

// swift-migration: original location ARTRestPresence.h, line 44
/**
 The protocol upon which the `ARTRestPresence` is implemented.
 */
public protocol ARTRestPresenceProtocol {
    
    // swift-migration: original location ARTRestPresence.h, line 47
    /// :nodoc: TODO: docstring
    func get(_ callback: @escaping ARTPaginatedPresenceCallback)
    
    // swift-migration: original location ARTRestPresence.h, line 50
    /// :nodoc: TODO: docstring
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    func get(_ callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool
    
    // swift-migration: original location ARTRestPresence.h, line 61
    /**
     * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns a `ARTPaginatedResult` object, containing an array of `ARTPresenceMessage` objects.
     *
     * @param query An `ARTPresenceQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
     * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
     *
     * @return In case of failure returns `false` and the error information can be retrived via the `error` parameter.
     */
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    func get(_ query: ARTPresenceQuery, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool
    
    // swift-migration: original location ARTRestPresence.h, line 63
    func history(_ callback: @escaping ARTPaginatedPresenceCallback)
    
    // swift-migration: original location ARTRestPresence.h, line 74
    /**
     * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTPresenceMessage` objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
     *
     * @param query An `ARTDataQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
     * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
     *
     * @return In case of failure returns `false` and the error information can be retrived via the `error` parameter.
     */
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    func history(_ query: ARTDataQuery?, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool
}

// swift-migration: original location ARTRestPresence.h, lines 13-39 and ARTRestPresence.m, lines 17-52
/**
 This object is used for providing parameters into `ARTRestPresence`'s methods with paginated results.
 */
public class ARTPresenceQuery: NSObject {
    // swift-migration: original location ARTRestPresence.h, line 18 and ARTRestPresence.m, line 30
    public var limit: UInt
    
    // swift-migration: original location ARTRestPresence.h, line 23 and ARTRestPresence.m, line 31
    public var clientId: String?
    
    // swift-migration: original location ARTRestPresence.h, line 28 and ARTRestPresence.m, line 32
    public var connectionId: String?
    
    // swift-migration: original location ARTRestPresence.h, line 31 and ARTRestPresence.m, line 19
    public override init() {
        self.limit = 100
        self.clientId = nil
        self.connectionId = nil
        super.init()
    }
    
    // swift-migration: original location ARTRestPresence.h, line 34 and ARTRestPresence.m, line 23
    public init(clientId: String?, connectionId: String?) {
        self.limit = 100
        self.clientId = clientId
        self.connectionId = connectionId
        super.init()
    }
    
    // swift-migration: original location ARTRestPresence.h, line 37 and ARTRestPresence.m, line 27
    public init(limit: UInt, clientId: String?, connectionId: String?) {
        self.limit = limit
        self.clientId = clientId
        self.connectionId = connectionId
        super.init()
    }
    
    // swift-migration: original location ARTRestPresence.m, line 37
    internal func asQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let clientId = clientId {
            items.append(URLQueryItem(name: "clientId", value: clientId))
        }
        if let connectionId = connectionId {
            items.append(URLQueryItem(name: "connectionId", value: connectionId))
        }
        
        items.append(URLQueryItem(name: "limit", value: String(limit)))
        
        return items
    }
}

// swift-migration: original location ARTRestPresence.h, lines 84-85 and ARTRestPresence.m, lines 54-87
public class ARTRestPresence: ARTPresence, ARTRestPresenceProtocol, @unchecked Sendable {
    internal let _internal: ARTRestPresenceInternal
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRestPresence+Private.h, line 30 and ARTRestPresence.m, line 58
    internal init(internal internalInstance: ARTRestPresenceInternal, queuedDealloc: ARTQueuedDealloc) {
        _internal = internalInstance
        _dealloc = queuedDealloc
        super.init()
    }
    
    // swift-migration: original location ARTRestPresence+Private.h, line 28
    internal var `internal`: ARTRestPresenceInternal {
        return _internal
    }
    
    // swift-migration: original location ARTRestPresence.h, line 47 and ARTRestPresence.m, line 67
    public func get(_ callback: @escaping ARTPaginatedPresenceCallback) {
        // Explicitly call the void version
        let _: Void = _internal.get(callback)
    }
    
    // swift-migration: original location ARTRestPresence.h, line 50 and ARTRestPresence.m, line 71
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    public func get(_ callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        return try _internal.get(callback)
    }
    
    // swift-migration: original location ARTRestPresence.h, line 61 and ARTRestPresence.m, line 75
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    public func get(_ query: ARTPresenceQuery, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        return try _internal.get(query, callback: callback)
    }
    
    // swift-migration: original location ARTRestPresence.h, line 74 and ARTRestPresence.m, line 79
    // swift-migration: Changed from inout NSError? parameter to throws pattern per PRD requirements
    public func history(_ query: ARTDataQuery?, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        return try _internal.history(query, wrapperSDKAgents: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRestPresence.h, line 63 and ARTRestPresence.m, line 83
    public func history(_ callback: @escaping ARTPaginatedPresenceCallback) {
        _internal.historyWithWrapperSDKAgents(nil, completion: callback)
    }
}

// swift-migration: original location ARTRestPresence.m, lines 99-226
internal class ARTRestPresenceInternal: NSObject {
    private weak var _channel: ARTRestChannelInternal? // weak because channel owns self
    private let _userQueue: DispatchQueue
    private let _queue: DispatchQueue
    
    // swift-migration: original location ARTRestPresence.m, line 93
    let logger: ARTInternalLog
    
    // swift-migration: original location ARTRestPresence+Private.h, line 11 and ARTRestPresence.m, line 105
    internal init(channel: ARTRestChannelInternal, logger: ARTInternalLog) {
        self._channel = channel
        self._userQueue = channel.rest?.userQueue ?? DispatchQueue.main
        self._queue = channel.rest?.queue ?? DispatchQueue.main
        self.logger = logger
        super.init()
    }
    
    // swift-migration: original location ARTRestPresence+Private.h, line 13 and ARTRestPresence.m, line 115
    internal func get(_ callback: @escaping ARTPaginatedPresenceCallback) {
        let _ = get(ARTPresenceQuery(), callback: callback, error: nil)
    }
    
    // swift-migration: New throws version for migration
    internal func get(_ callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        return try get(ARTPresenceQuery(), callback: callback)
    }
    
    // swift-migration: New throws version for migration
    internal func get(_ query: ARTPresenceQuery, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        var error: NSError?
        let result = get(query, callback: callback, error: &error)
        if let error = error {
            throw error
        }
        return result
    }
    
    // swift-migration: New throws version for migration  
    internal func history(_ query: ARTDataQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        var error: NSError?
        let result = history(query, wrapperSDKAgents: wrapperSDKAgents, callback: callback, error: &error)
        if let error = error {
            throw error
        }
        return result
    }
    
    // swift-migration: original location ARTRestPresence+Private.h, line 15 and ARTRestPresence.m, line 119
    internal func get(_ callback: @escaping ARTPaginatedPresenceCallback, error errorPtr: UnsafeMutablePointer<NSError?>?) -> Bool {
        return get(ARTPresenceQuery(), callback: callback, error: errorPtr)
    }
    
    // swift-migration: original location ARTRestPresence+Private.h, line 17 and ARTRestPresence.m, line 123
    internal func get(_ query: ARTPresenceQuery, callback: @escaping ARTPaginatedPresenceCallback, error errorPtr: UnsafeMutablePointer<NSError?>?) -> Bool {
        let userCallback = callback
        let wrappedCallback: ARTPaginatedPresenceCallback = { result, error in
            self._userQueue.async {
                userCallback(result, error)
            }
        }
        
        if query.limit > 1000 {
            if let errorPtr = errorPtr {
                errorPtr.pointee = NSError(domain: ARTAblyErrorDomain,
                                         code: ARTDataQueryError.limit.rawValue,
                                         userInfo: [NSLocalizedDescriptionKey: "Limit supports up to 1000 results only"])
            }
            return false
        }
        
        guard let channel = _channel,
              let requestUrl = URLComponents(string: channel.basePath.appending("/presence")) else {
            return false
        }
        
        var components = requestUrl
        components.queryItems = query.asQueryItems()
        
        guard let url = components.url else { return false }
        let request = URLRequest(url: url)
        
        // swift-migration: Updated responseProcessor to use throws pattern instead of inout error parameter
        let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data in
            guard let encoder = channel.rest?.encoders[response?.mimeType ?? ""] else {
                return []
            }
            
            let presenceMessages = try? encoder.decodePresenceMessages(data ?? Data())
            
            return presenceMessages?.artMap { message in
                // swift-migration: FIXME comment preserved from original
                // FIXME: This should be refactored to be done by ART{Json,...}Encoder.
                // The ART{Json,...}Encoder should take a ARTDataEncoder and use it every
                // time it is enc/decoding a message. This also applies for REST and Realtime
                // ARTMessages.
                return try? message.decode(withEncoder: channel.dataEncoder)
            }
        }
        
        _queue.async {
            ARTPaginatedResult.executePaginated(channel.rest!, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: nil, logger: self.logger, callback: wrappedCallback)
        }
        return true
    }
    
    // swift-migration: original location ARTRestPresence+Private.h, line 21 and ARTRestPresence.m, line 164
    internal func historyWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion callback: @escaping ARTPaginatedPresenceCallback) {
        let _ = history(ARTDataQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: callback, error: nil)
    }
    
    // swift-migration: original location ARTRestPresence+Private.h, line 19 and ARTRestPresence.m, line 169
    internal func history(_ query: ARTDataQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedPresenceCallback, error errorPtr: UnsafeMutablePointer<NSError?>?) -> Bool {
        let userCallback = callback
        let wrappedCallback: ARTPaginatedPresenceCallback = { result, error in
            self._userQueue.async {
                userCallback(result, error)
            }
        }
        
        if let query = query, query.limit > 1000 {
            if let errorPtr = errorPtr {
                errorPtr.pointee = NSError(domain: ARTAblyErrorDomain,
                                         code: ARTDataQueryError.limit.rawValue,
                                         userInfo: [NSLocalizedDescriptionKey: "Limit supports up to 1000 results only"])
            }
            return false
        }
        
        if let query = query, let start = query.start, let end = query.end, start.compare(end) == .orderedDescending {
            if let errorPtr = errorPtr {
                errorPtr.pointee = NSError(domain: ARTAblyErrorDomain,
                                         code: ARTDataQueryError.timestampRange.rawValue,
                                         userInfo: [NSLocalizedDescriptionKey: "Start must be equal to or less than end"])
            }
            return false
        }
        
        guard let channel = _channel,
              let requestUrl = URLComponents(string: channel.basePath.appending("/presence/history")) else {
            return false
        }
        
        var components = requestUrl
        if let query = query {
            do {
                components.queryItems = try query.asQueryItems()
            } catch {
                errorPtr?.pointee = error as NSError?
                return false
            }
        }
        
        guard let url = components.url else { return false }
        let request = URLRequest(url: url)
        
        // swift-migration: Updated responseProcessor to use throws pattern instead of inout error parameter
        let responseProcessor: ARTPaginatedResultResponseProcessor = { response, data in
            guard let encoder = channel.rest?.encoders[response?.mimeType ?? ""] else {
                return []
            }
            
            let presenceMessages = try? encoder.decodePresenceMessages(data ?? Data())
            
            return presenceMessages?.artMap { message in
                let decodedMessage = try? message.decode(withEncoder: channel.dataEncoder)
                if decodedMessage == nil {
                    let errorInfo = ARTErrorInfo.create(withCode: ARTErrorCode.unableToDecodeMessage.rawValue, message: "Failed to decode message")
                    ARTLogError(self.logger, "RS:\(Unmanaged.passUnretained(channel.rest!).toOpaque()) \(errorInfo.message)")
                }
                return decodedMessage
            }
        }
        
        _queue.async {
            ARTPaginatedResult.executePaginated(channel.rest!, withRequest: request, andResponseProcessor: responseProcessor, wrapperSDKAgents: wrapperSDKAgents, logger: self.logger, callback: wrappedCallback)
        }
        return true
    }
}
