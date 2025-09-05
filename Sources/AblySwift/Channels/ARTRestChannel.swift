import Foundation

/**
 * A REST channel provides the ability to send and retrieve messages, and obtain presence information.
 */
public class ARTRestChannel: NSObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    /**
     * Internal REST channel implementation
     */
    internal let _internal: ARTRestChannelInternal
    
    /**
     * Queued deallocation helper
     */
    private let _dealloc: ARTQueuedDealloc
    
    // MARK: - Initialization
    
    /**
     * Initialize with internal implementation
     */
    internal init(internal: ARTRestChannelInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = `internal`
        self._dealloc = queuedDealloc
        super.init()
    }
    
    // MARK: - Public Properties
    
    /**
     * The channel name
     */
    public var name: String {
        return _internal.name
    }
    
    /**
     * Channel options
     */
    public var options: ARTChannelOptions {
        return _internal.options
    }
    
    /**
     * Set channel options
     */
    public func setOptions(_ options: ARTChannelOptions?) {
        _internal.setOptions(options)
    }
    
    // MARK: - Sub-objects
    
    /**
     * A `ARTRestPresence` object.
     */
    public var presence: ARTRestPresence {
        return ARTRestPresence(internal: _internal.presence, queuedDealloc: _dealloc)
    }
    
    /**
     * A `ARTPushChannel` object.
     */
    public var push: ARTPushChannel {
        return ARTPushChannel(internal: _internal.push, queuedDealloc: _dealloc)
    }
    
    // MARK: - Channel Status
    
    /**
     * Retrieves the channel's status, including its occupancy metrics and metadata.
     */
    public func status(_ callback: @escaping ARTChannelDetailsCallback) {
        _internal.status(callback)
    }
    
    /**
     * Gets the message history for the channel with default parameters
     */
    public func history(_ callback: @escaping ARTPaginatedMessagesCallback) {
        _internal.historyWithWrapperSDKAgents(nil, completion: callback)
    }
}

// MARK: - ARTChannelProtocol Implementation

extension ARTRestChannel: ARTChannelProtocol {
    
    public func publish(_ name: String?, data: Any?) {
        _internal.publish(name, data: data)
    }
    
    public func publish(_ name: String?, data: Any?, callback: ARTCallback?) {
        _internal.publish(name, data: data, callback: callback)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String) {
        _internal.publish(name, data: data, clientId: clientId)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?) {
        _internal.publish(name, data: data, clientId: clientId, callback: callback)
    }
    
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?) {
        _internal.publish(name, data: data, extras: extras)
    }
    
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        _internal.publish(name, data: data, extras: extras, callback: callback)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?) {
        _internal.publish(name, data: data, clientId: clientId, extras: extras)
    }
    
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        _internal.publish(name, data: data, clientId: clientId, extras: extras, callback: callback)
    }
    
    public func publish(_ messages: [ARTMessage]) {
        _internal.publish(messages)
    }
    
    public func publish(_ messages: [ARTMessage], callback: ARTCallback?) {
        _internal.publish(messages, callback: callback)
    }
}

// MARK: - ARTRestChannelInternal

/**
 * Internal implementation of REST channel
 */
internal class ARTRestChannelInternal: ARTChannel {
    
    // MARK: - Properties
    
    /**
     * REST client instance
     */
    internal weak var rest: ARTRestInternal?
    
    /**
     * User queue for callbacks
     */
    private let userQueue: DispatchQueue
    
    /**
     * Presence implementation
     */
    private var _presence: ARTRestPresenceInternal?
    
    /**
     * Push channel implementation  
     */
    private var _pushChannel: ARTPushChannelInternal?
    
    /**
     * Base path for REST API calls
     */
    private let basePath: String
    
    // MARK: - Initialization
    
    /**
     * Initialize REST channel with dependencies
     */
    internal init(name: String, options: ARTChannelOptions, rest: ARTRestInternal, logger: ARTInternalLog) throws {
        self.rest = rest
        self.userQueue = rest.userQueue
        self.basePath = "/channels/\(name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? name)"
        
        try super.init(name: name, options: options, queue: rest.queue, logger: logger)
        
        logger.debug("RS:\(String(describing: rest)) instantiating under '\(name)'")
    }
    
    // MARK: - Lazy Properties
    
    /**
     * REST presence interface
     */
    internal var presence: ARTRestPresenceInternal {
        if _presence == nil {
            _presence = ARTRestPresenceInternal(channel: self, logger: logger)
        }
        return _presence!
    }
    
    /**
     * Push channel interface
     */
    internal var push: ARTPushChannelInternal {
        if _pushChannel == nil {
            _pushChannel = ARTPushChannelInternal(rest: rest!, channel: self, logger: logger)
        }
        return _pushChannel!
    }
    
    // MARK: - Channel Status
    
    /**
     * Get channel status/details - simplified implementation
     */
    internal func status(_ callback: @escaping ARTChannelDetailsCallback) {
        // Simplified implementation for now
        userQueue.async {
            callback(nil, ARTErrorInfo.create(withCode: 40000, message: "Channel status not yet implemented"))
        }
    }
    
    // MARK: - History
    
    /**
     * Get message history with wrapper SDK agents
     */
    override internal func historyWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion: @escaping ARTPaginatedMessagesCallback) {
        // Simplified implementation - will be enhanced when ARTPaginatedResult is fully migrated
        userQueue.async {
            completion(nil, ARTErrorInfo.create(withCode: 40000, message: "History not yet implemented"))
        }
    }
    
    // MARK: - Publishing
    
    /**
     * Post messages internally - simplified implementation
     */
    override internal func internalPostMessages(_ data: Any, callback: ARTCallback?) {
        userQueue.async {
            callback?(ARTErrorInfo.create(withCode: 40000, message: "Publishing not yet fully implemented"))
        }
    }
}

// MARK: - Placeholder Classes

/**
 * Placeholder for ARTRestPresence - will be migrated later
 */
public class ARTRestPresence: @unchecked Sendable {
    internal let _internal: ARTRestPresenceInternal
    private let _dealloc: ARTQueuedDealloc
    
    internal init(internal: ARTRestPresenceInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = `internal`
        self._dealloc = queuedDealloc
    }
}

/**
 * Placeholder for ARTRestPresenceInternal - will be migrated later
 */
internal class ARTRestPresenceInternal: @unchecked Sendable {
    weak var channel: ARTRestChannelInternal?
    let logger: ARTInternalLog
    
    init(channel: ARTRestChannelInternal, logger: ARTInternalLog) {
        self.channel = channel
        self.logger = logger
    }
}

/**
 * Placeholder for ARTPushChannel - will be migrated later
 */
public class ARTPushChannel: @unchecked Sendable {
    internal let _internal: ARTPushChannelInternal
    private let _dealloc: ARTQueuedDealloc
    
    internal init(internal: ARTPushChannelInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = `internal`
        self._dealloc = queuedDealloc
    }
}

/**
 * Placeholder for ARTPushChannelInternal - will be migrated later
 */
internal class ARTPushChannelInternal: @unchecked Sendable {
    weak var rest: ARTRestInternal?
    weak var channel: ARTRestChannelInternal?
    let logger: ARTInternalLog
    
    init(rest: ARTRestInternal, channel: ARTRestChannelInternal, logger: ARTInternalLog) {
        self.rest = rest
        self.channel = channel
        self.logger = logger
    }
}

/**
 * Extension for ARTPaginatedResult to handle execution
 */
extension ARTPaginatedResult where ItemType == ARTMessage {
    internal static func executePaginated(
        _ rest: ARTRestInternal,
        request: URLRequest,
        responseProcessor: @escaping (HTTPURLResponse, Data) throws -> [ARTMessage],
        wrapperSDKAgents: [String: String]?,
        logger: ARTInternalLog,
        callback: @escaping ARTPaginatedMessagesCallback
    ) {
        // Placeholder implementation - will be completed when migrating ARTPaginatedResult
        callback(nil, ARTErrorInfo.create(withCode: 40000, message: "ARTPaginatedResult not yet implemented"))
    }
}
