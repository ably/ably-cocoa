import Foundation

// MARK: - ARTRealtimePresenceQuery

// swift-migration: original location ARTRealtimePresence.h, line 13 and ARTRealtimePresence.m, line 23
/**
 This object is used for providing parameters into `ARTRealtimePresence`'s methods with paginated results.
 */
public class ARTRealtimePresenceQuery: ARTPresenceQuery {
    
    // swift-migration: original location ARTRealtimePresence.h, line 18
    /**
     * Sets whether to wait for a full presence set synchronization between Ably and the clients on the channel to complete before returning the results. Synchronization begins as soon as the channel is `ARTRealtimeChannelState.ARTRealtimeChannelAttached`. When set to `true` the results will be returned as soon as the sync is complete. When set to `false` the current list of members will be returned without the sync completing. The default is `true`.
     */
    public var waitForSync: Bool
    
    // swift-migration: original location ARTRealtimePresence.m, line 25
    public override init(limit: UInt, clientId: String?, connectionId: String?) {
        waitForSync = true
        super.init(limit: limit, clientId: clientId, connectionId: connectionId)
    }
}

// MARK: - ARTRealtimePresenceProtocol

// swift-migration: original location ARTRealtimePresence.h, line 25
/**
 The protocol upon which the `ARTRealtimePresence` is implemented.
 */
public protocol ARTRealtimePresenceProtocol {
    
    // swift-migration: original location ARTRealtimePresence.h, line 30
    /**
     * Indicates whether the presence set synchronization between Ably and the clients on the channel has been completed. Set to `true` when the sync is complete.
     */
    var syncComplete: Bool { get }
    
    // swift-migration: original location ARTRealtimePresence.h, line 33
    /// :nodoc: TODO: docstring
    func get(_ callback: @escaping ARTPresenceMessagesCallback)
    
    // swift-migration: original location ARTRealtimePresence.h, line 41
    /**
     * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns an array of `ARTPresenceMessage` objects.
     *
     * @param query An `ARTRealtimePresenceQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
     */
    func get(_ query: ARTRealtimePresenceQuery, callback: @escaping ARTPresenceMessagesCallback)
    
    // swift-migration: original location ARTRealtimePresence.h, line 48
    /**
     * Enters the presence set for the channel, optionally passing a `data` payload. A `clientId` is required to be present on a channel.
     *
     * @param data The payload associated with the presence member.
     */
    func enter(_ data: Any?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 56
    /**
     * Enters the presence set for the channel, optionally passing a `data` payload. A `clientId` is required to be present on a channel. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param data The payload associated with the presence member.
     * @param callback A success or failure callback function.
     */
    func enter(_ data: Any?, callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 63
    /**
     * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceAction.ARTPresenceEnter` event.
     *
     * @param data The payload to update for the presence member.
     */
    func update(_ data: Any?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 71
    /**
     * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceAction.ARTPresenceEnter` event. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param data The payload to update for the presence member.
     * @param callback A success or failure callback function.
     */
    func update(_ data: Any?, callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 78
    /**
     * Leaves the presence set for the channel. A client must have previously entered the presence set before they can leave it.
     *
     * @param data The payload associated with the presence member.
     */
    func leave(_ data: Any?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 86
    /**
     * Leaves the presence set for the channel. A client must have previously entered the presence set before they can leave it. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param data The payload associated with the presence member.
     * @param callback A success or failure callback function.
     */
    func leave(_ data: Any?, callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 94
    /**
     * Enters the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`.
     *
     * @param clientId The ID of the client to enter into the presence set.
     * @param data The payload associated with the presence member.
     */
    func enterClient(_ clientId: String, data: Any?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 103
    /**
     * Enters the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param clientId The ID of the client to enter into the presence set.
     * @param data The payload associated with the presence member.
     * @param callback A success or failure callback function.
     */
    func enterClient(_ clientId: String, data: Any?, callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 111
    /**
     * Updates the `data` payload for a presence member using a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`.
     *
     * @param clientId The ID of the client to update in the presence set.
     * @param data The payload to update for the presence member.
     */
    func updateClient(_ clientId: String, data: Any?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 120
    /**
     * Updates the `data` payload for a presence member using a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param clientId The ID of the client to update in the presence set.
     * @param data The payload to update for the presence member.
     * @param callback A success or failure callback function.
     */
    func updateClient(_ clientId: String, data: Any?, callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 128
    /**
     * Leaves the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param clientId The ID of the client to leave the presence set for.
     * @param data The payload associated with the presence member.
     */
    func leaveClient(_ clientId: String, data: Any?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 137
    /**
     * Leaves the presence set of the channel for a given `clientId`. Enables a single client to update presence on behalf of any number of clients using a single connection. The library must have been instantiated with an API key or a token bound to a wildcard `clientId`. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param clientId The ID of the client to leave the presence set for.
     * @param data The payload associated with the presence member.
     * @param callback A success or failure callback function.
     */
    func leaveClient(_ clientId: String, data: Any?, callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimePresence.h, line 146
    /**
     * Registers a listener that is called each time a `ARTPresenceMessage` is received on the channel, such as a new member entering the presence set.
     *
     * @param callback An event listener function.
     *
     * @return An event listener object.
     */
    func subscribe(_ callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimePresence.h, line 156
    /**
     * Registers a listener that is called each time a `ARTPresenceMessage` is received on the channel, such as a new member entering the presence set. A callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannelProtocol attach]` operation. It will not be called if the `ARTRealtimeChannelOptions.attachOnSubscribe` channel option is set to `false`.
     *
     * @param onAttach An attach callback function.
     * @param callback An event listener function.
     *
     * @return An event listener object.
     */
    func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimePresence.h, line 166
    /**
     * Registers a listener that is called each time a `ARTPresenceMessage` matching a given `ARTPresenceAction` is received on the channel, such as a new member entering the presence set.
     *
     * @param action A `ARTPresenceAction` to register the listener for.
     * @param callback An event listener function.
     *
     * @return An event listener object.
     */
    func subscribe(_ action: ARTPresenceAction, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimePresence.h, line 177
    /**
     * Registers a listener that is called each time a `ARTPresenceMessage` matching a given `ARTPresenceAction` is received on the channel, such as a new member entering the presence set. A callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannelProtocol attach]` operation. It will not be called if the `ARTRealtimeChannelOptions.attachOnSubscribe` channel option is set to `false`.
     *
     * @param action A `ARTPresenceAction` to register the listener for.
     * @param onAttach An attach callback function.
     * @param callback An event listener function.
     *
     * @return An event listener object.
     */
    func subscribe(_ action: ARTPresenceAction, onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimePresence.h, line 182
    /**
     * Deregisters all listeners currently receiving `ARTPresenceMessage` for the channel.
     */
    func unsubscribe()
    
    // swift-migration: original location ARTRealtimePresence.h, line 189
    /**
     * Deregisters a specific listener that is registered to receive `ARTPresenceMessage` on the channel.
     *
     * @param listener An event listener to unsubscribe.
     */
    func unsubscribe(_ listener: ARTEventListener)
    
    // swift-migration: original location ARTRealtimePresence.h, line 197
    /**
     * Deregisters a specific listener that is registered to receive `ARTPresenceMessage` on the channel for a given `ARTPresenceAction`.
     *
     * @param action A specific `ARTPresenceAction` to deregister the listener for.
     * @param listener An event listener to unsubscribe.
     */
    func unsubscribe(_ action: ARTPresenceAction, listener: ARTEventListener)
    
    // swift-migration: original location ARTRealtimePresence.h, line 200
    /// :nodoc:
    func history(_ callback: @escaping ARTPaginatedPresenceCallback)
    
    // swift-migration: original location ARTRealtimePresence.h, line 211
    /**
     * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTPresenceMessage` objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
     *
     * @param query An `ARTRealtimeHistoryQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
     * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
     *
     * @return In case of failure returns `false` and the error information can be retrived via the `error` parameter.
     */
    func history(_ query: ARTRealtimeHistoryQuery?, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool
}

// MARK: - ARTRealtimePresence

// swift-migration: original location ARTRealtimePresence.h, line 221 and ARTRealtimePresence.m, line 35
/**
 * Enables the presence set to be entered and subscribed to, and the historic presence set to be retrieved for a channel.
 *
 * @see See `ARTRealtimePresenceProtocol` for details.
 */
public class ARTRealtimePresence: ARTPresence, ARTRealtimePresenceProtocol {
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 79 and ARTRealtimePresence.m, line 36
    internal let `internal`: ARTRealtimePresenceInternal
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 81 and ARTRealtimePresence.m, line 39
    internal init(internal: ARTRealtimePresenceInternal, queuedDealloc dealloc: ARTQueuedDealloc) {
        self._dealloc = dealloc
        self.`internal` = `internal`
        super.init()
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 48
    public var syncComplete: Bool {
        return `internal`.syncComplete
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 52
    public func get(_ callback: @escaping ARTPresenceMessagesCallback) {
        `internal`.get(callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 56
    public func get(_ query: ARTRealtimePresenceQuery, callback: @escaping ARTPresenceMessagesCallback) {
        `internal`.get(query, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 60
    public func enter(_ data: Any?) {
        `internal`.enter(data)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 64
    public func enter(_ data: Any?, callback: ARTCallback?) {
        `internal`.enter(data, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 68
    public func update(_ data: Any?) {
        `internal`.update(data)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 72
    public func update(_ data: Any?, callback: ARTCallback?) {
        `internal`.update(data, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 76
    public func leave(_ data: Any?) {
        `internal`.leave(data)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 80
    public func leave(_ data: Any?, callback: ARTCallback?) {
        `internal`.leave(data, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 84
    public func enterClient(_ clientId: String, data: Any?) {
        `internal`.enterClient(clientId, data: data)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 88
    public func enterClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        `internal`.enterClient(clientId, data: data, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 92
    public func updateClient(_ clientId: String, data: Any?) {
        `internal`.updateClient(clientId, data: data)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 96
    public func updateClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        `internal`.updateClient(clientId, data: data, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 100
    public func leaveClient(_ clientId: String, data: Any?) {
        `internal`.leaveClient(clientId, data: data)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 104
    public func leaveClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        `internal`.leaveClient(clientId, data: data, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 108
    public func subscribe(_ callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return `internal`.subscribe(callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 112
    public func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return `internal`.subscribeWithAttachCallback(onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 116
    public func subscribe(_ action: ARTPresenceAction, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return `internal`.subscribe(action, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 120
    public func subscribe(_ action: ARTPresenceAction, onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return `internal`.subscribe(action, onAttach: onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 124
    public func unsubscribe() {
        `internal`.unsubscribe()
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 128
    public func unsubscribe(_ listener: ARTEventListener) {
        `internal`.unsubscribe(listener)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 132
    public func unsubscribe(_ action: ARTPresenceAction, listener: ARTEventListener) {
        `internal`.unsubscribe(action, listener: listener)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 136
    public func history(_ callback: @escaping ARTPaginatedPresenceCallback) {
        `internal`.historyWithWrapperSDKAgents(nil, completion: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 140
    public func history(_ query: ARTRealtimeHistoryQuery?, callback: @escaping ARTPaginatedPresenceCallback, error errorPtr: UnsafeMutablePointer<Error?>?) throws {
        return try `internal`.history(query, wrapperSDKAgents: nil, callback: callback)
    }
}

// MARK: - ARTRealtimePresenceInternal

// swift-migration: original location ARTRealtimePresence.m, line 148
private let ARTPresenceActionAll = Int.max

// swift-migration: original location ARTRealtimePresence.m, line 160
private enum ARTPresenceSyncState: UInt {
    case initialized = 0  // ARTPresenceSyncInitialized
    case started = 1      // ARTPresenceSyncStarted, ItemType: nil  
    case ended = 2        // ARTPresenceSyncEnded, ItemType: NSArray<ARTPresenceMessage *>*
    case failed = 3       // ARTPresenceSyncFailed, ItemType: ARTErrorInfo*
}

// swift-migration: original location ARTRealtimePresence+Private.h, line 6 and ARTRealtimePresence.m, line 174
public class ARTRealtimePresenceInternal {

    // swift-migration: original location ARTRealtimePresence+Private.h, line 8 and ARTRealtimePresence.m, line 755
    internal var connectionId: String {
        return realtime.connection.id_nosync
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 9 and ARTRealtimePresence.m, line 179
    internal let eventEmitter: ARTEventEmitter<ARTEvent, ARTPresenceMessage>
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 23 and ARTRealtimePresence.m, line 177
    internal let queue: DispatchQueue
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 24 and ARTRealtimePresence.m, line 178
    internal let pendingPresence: NSMutableArray<ARTQueuedMessage>
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 26 and ARTRealtimePresence.m, line 466
    internal var syncComplete: Bool {
        var result: Bool = false
        queue.sync {
            result = syncComplete_nosync
        }
        return result
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 89 and ARTRealtimePresence.m, line 185
    /// List of members.
    /// The key is the memberKey and the value is the latest relevant ARTPresenceMessage for that clientId.
    internal var members: [String: ARTPresenceMessage] {
        return _members as [String: ARTPresenceMessage]
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 93 and ARTRealtimePresence.m, line 186
    /// List of internal members.
    /// The key is the clientId and the value is the latest relevant ARTPresenceMessage for that clientId.
    internal let internalMembers: NSMutableDictionary<NSString, ARTPresenceMessage>
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 95
    internal var syncComplete_atomic: Bool {
        return syncComplete_nosync
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 96
    internal var syncInProgress: Bool {
        var result: Bool = false
        queue.sync {
            result = syncInProgress_nosync
        }
        return result
    }
    
    // Private properties from implementation
    private weak var channel: ARTRealtimeChannelInternal? // weak because channel owns self
    private weak var realtime: ARTRealtimeInternal?
    private let userQueue: DispatchQueue
    private let logger: ARTInternalLog
    private let dataEncoder: ARTDataEncoder
    
    private var syncState: ARTPresenceSyncState
    private let syncEventEmitter: ARTEventEmitter<ARTEvent, Any>
    
    private var _members: NSMutableDictionary<NSString, ARTPresenceMessage> // RTP2
    private let _internalMembers: NSMutableDictionary<NSString, ARTPresenceMessage> // RTP17h
    
    private var beforeSyncMembers: NSMutableDictionary<NSString, ARTPresenceMessage>? // RTP19
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 11 and ARTRealtimePresence.m, line 191
    internal init(channel: ARTRealtimeChannelInternal, logger: ARTInternalLog) {
        self.channel = channel
        self.realtime = channel.realtime
        self.userQueue = channel.realtime.rest.userQueue
        self.queue = channel.realtime.rest.queue
        self.pendingPresence = NSMutableArray<ARTQueuedMessage>()
        self.logger = logger
        self.eventEmitter = ARTInternalEventEmitter(queue: queue)
        self.dataEncoder = channel.dataEncoder
        self._members = NSMutableDictionary()
        self._internalMembers = NSMutableDictionary()
        self.internalMembers = _internalMembers
        self.syncState = .initialized
        self.syncEventEmitter = ARTInternalEventEmitter(queue: queue)
        self.beforeSyncMembers = nil
    }
    
    // RTP11
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 28 and ARTRealtimePresence.m, line 211
    internal func get(_ callback: @escaping ARTPresenceMessagesCallback) {
        get(ARTRealtimePresenceQuery(), callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 30 and ARTRealtimePresence.m, line 215
    internal func get(_ query: ARTRealtimePresenceQuery, callback: @escaping ARTPresenceMessagesCallback) {
        var userCallback = callback
        let callbackWrapper: ARTPresenceMessagesCallback = { messages, error in
            self.userQueue.async {
                userCallback(messages, error)
            }
        }
        
        queue.async {
            switch self.channel?.state_nosync {
            case .detached, .failed:
                callbackWrapper(nil, ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailedInvalidState ARTErrorChannelOperationFailedInvalidState, 
                    message: "unable to return the list of current members (incompatible channel state: \(ARTRealtimeChannelStateToStr(self.channel?.state_nosync ?? .failed)))"))
                return
            case .suspended:
                if !query.waitForSync { // RTP11d
                    callbackWrapper(self._members.allValues as? [ARTPresenceMessage], nil)
                    return
                }
                callbackWrapper(nil, ARTErrorInfo.create(withCode: ARTErrorPresenceStateIsOutOfSync, 
                    message: "presence state is out of sync due to the channel being SUSPENDED"))
                return
            default:
                break
            }
            
            // RTP11c
            let filterMemberBlock: (ARTPresenceMessage) -> Bool = { message in
                return (query.clientId == nil || message.clientId == query.clientId) &&
                    (query.connectionId == nil || message.connectionId == query.connectionId)
            }
            
            self.channel?._attach { error in // RTP11b
                if let error = error {
                    callbackWrapper(nil, error)
                    return
                }
                let syncInProgress = self.syncInProgress_nosync
                if syncInProgress && query.waitForSync {
                    ARTLogDebug(self.logger, "R:%p C:%p (%@) sync is in progress, waiting until the presence members is synchronized", self.realtime, self.channel, self.channel?.name)
                    self.onceSyncEnds { members in
                        let filteredMembers = members.filter(filterMemberBlock)
                        callbackWrapper(filteredMembers, nil)
                    }
                    self.onceSyncFails { error in
                        callbackWrapper(nil, error)
                    }
                } else {
                    ARTLogDebug(self.logger, "R:%p C:%p (%@) returning presence members (syncInProgress=%d)", self.realtime, self.channel, self.channel?.name, syncInProgress)
                    let members = self._members.allValues as? [ARTPresenceMessage] ?? []
                    let filteredMembers = members.filter(filterMemberBlock)
                    callbackWrapper(filteredMembers, nil)
                }
            }
        }
    }
    
    // RTP12
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 71 and ARTRealtimePresence.m, line 275
    internal func historyWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion callback: @escaping ARTPaginatedPresenceCallback) {
        _ = history(ARTRealtimeHistoryQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: callback, error: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 73 and ARTRealtimePresence.m, line 280
    internal func history(_ query: ARTRealtimeHistoryQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedPresenceCallback, error errorPtr: UnsafeMutablePointer<Error?>?) -> Bool {
        let actualQuery = query ?? ARTRealtimeHistoryQuery()
        actualQuery.realtimeChannel = channel
        return channel?.restChannel.presence.history(actualQuery, wrapperSDKAgents: wrapperSDKAgents, callback: callback, error: errorPtr) ?? false
    }
    
    // RTP8
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 32 and ARTRealtimePresence.m, line 287
    internal func enter(_ data: Any?) {
        enter(data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 34 and ARTRealtimePresence.m, line 291
    internal func enter(_ data: Any?, callback: ARTCallback?) {
        var userCallback = callback
        let callbackWrapper: ARTCallback? = userCallback.map { cb in
            return { error in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        
        queue.async {
            self.enterOrUpdateAfterChecks(.enter, messageId: nil, clientId: nil, data: data, callback: callbackWrapper)
        }
    }
    
    // RTP14, RTP15
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 44 and ARTRealtimePresence.m, line 308
    internal func enterClient(_ clientId: String, data: Any?) {
        enterClient(clientId, data: data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 46 and ARTRealtimePresence.m, line 312
    internal func enterClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        var userCallback = callback
        let callbackWrapper: ARTCallback? = userCallback.map { cb in
            return { error in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        
        queue.async {
            self.enterOrUpdateAfterChecks(.enter, messageId: nil, clientId: clientId, data: data, callback: callbackWrapper)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 327
    internal func enterWithPresenceMessageId(_ messageId: String, clientId: String, data: Any?, callback: ARTCallback?) {
        var userCallback = callback
        let callbackWrapper: ARTCallback? = userCallback.map { cb in
            return { error in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        queue.async {
            self.enterOrUpdateAfterChecks(.enter, messageId: messageId, clientId: clientId, data: data, callback: callbackWrapper)
        }
    }
    
    // RTP9
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 36 and ARTRealtimePresence.m, line 343
    internal func update(_ data: Any?) {
        update(data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 38 and ARTRealtimePresence.m, line 347
    internal func update(_ data: Any?, callback: ARTCallback?) {
        var userCallback = callback
        let callbackWrapper: ARTCallback? = userCallback.map { cb in
            return { error in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        
        queue.async {
            self.enterOrUpdateAfterChecks(.update, messageId: nil, clientId: nil, data: data, callback: callbackWrapper)
        }
    }
    
    // RTP15
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 48 and ARTRealtimePresence.m, line 364
    internal func updateClient(_ clientId: String, data: Any?) {
        updateClient(clientId, data: data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 50 and ARTRealtimePresence.m, line 368
    internal func updateClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        var userCallback = callback
        let callbackWrapper: ARTCallback? = userCallback.map { cb in
            return { error in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        
        queue.async {
            self.enterOrUpdateAfterChecks(.update, messageId: nil, clientId: clientId, data: data, callback: callbackWrapper)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 383
    private func enterOrUpdateAfterChecks(_ action: ARTPresenceAction, messageId: String?, clientId: String?, data: Any?, callback: ARTCallback?) {
        switch channel?.state_nosync {
        case .detached, .failed:
            if let callback = callback {
                let channelError = ARTErrorInfo.create(withCode: ARTErrorUnableToEnterPresenceChannelInvalidState, 
                    message: "unable to enter presence channel (incompatible channel state: \(ARTRealtimeChannelStateToStr(channel?.state_nosync ?? .failed)))")
                callback(channelError)
            }
            return
        default:
            break
        }
        
        let msg = ARTPresenceMessage()
        msg.action = action
        msg.id = messageId
        msg.clientId = clientId
        msg.data = data
        msg.connectionId = realtime?.connection.id_nosync
        
        publishPresence(msg, callback: callback)
    }
    
    // RTP10
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 40 and ARTRealtimePresence.m, line 409
    internal func leave(_ data: Any?) {
        leave(data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 42 and ARTRealtimePresence.m, line 413
    internal func leave(_ data: Any?, callback: ARTCallback?) {
        var userCallback = callback
        let callbackWrapper: ARTCallback? = userCallback.map { cb in
            return { error in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        
        // swift-migration: Using sync here to preserve exception handling from original code
        queue.sync {
            leaveAfterChecks(nil, data: data, callback: callbackWrapper)
        }
    }
    
    // RTP15
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 52 and ARTRealtimePresence.m, line 438
    internal func leaveClient(_ clientId: String, data: Any?) {
        leaveClient(clientId, data: data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 54 and ARTRealtimePresence.m, line 442
    internal func leaveClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        var userCallback = callback
        let callbackWrapper: ARTCallback? = userCallback.map { cb in
            return { error in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        
        queue.sync {
            leaveAfterChecks(clientId, data: data, callback: callbackWrapper)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 457
    private func leaveAfterChecks(_ clientId: String?, data: Any?, callback: ARTCallback?) {
        let msg = ARTPresenceMessage()
        msg.action = .leave
        msg.data = data
        msg.clientId = clientId
        msg.connectionId = realtime?.connection.id_nosync
        publishPresence(msg, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 13 and ARTRealtimePresence.m, line 476
    internal func syncComplete_nosync() -> Bool {
        return syncState == .ended || syncState == .failed
    }
    
    // RTP6
    
    // swift-migration: original location ARTRealtimePresence.m, line 482
    private func _subscribe(_ action: ARTPresenceAction, onAttach: ARTCallback?, callback: ARTPresenceMessageCallback?) -> ARTEventListener? {
        let userCallback = callback.map { cb in
            return { (message: ARTPresenceMessage?) in
                self.userQueue.async {
                    cb(message)
                }
            }
        }
        let userOnAttach = onAttach.map { cb in
            return { (error: ARTErrorInfo?) in
                self.userQueue.async {
                    cb(error)
                }
            }
        }
        
        var listener: ARTEventListener? = nil
        queue.sync {
            let options = self.channel?.getOptions_nosync
            let attachOnSubscribe = options?.attachOnSubscribe ?? true
            if self.channel?.state_nosync == .failed {
                if let onAttach = userOnAttach, attachOnSubscribe { // RTL7h
                    onAttach(ARTErrorInfo.create(withCode: ARTErrorChannelOperationFailedInvalidState, 
                        message: "attempted to subscribe while channel is in Failed state."))
                }
                ARTLogWarn(self.logger, "R:%p C:%p (%@) presence subscribe to '%@' action(s) has been ignored (attempted to subscribe while channel is in FAILED state)", 
                    self.realtime, self.channel, self.channel?.name, ARTPresenceActionToStr(action))
                return
            }
            if self.channel?.shouldAttach == true && attachOnSubscribe { // RTP6c
                self.channel?._attach(userOnAttach)
            }
            listener = action.rawValue == ARTPresenceActionAll ? eventEmitter.on(userCallback) : eventEmitter.on(ARTEvent.new(with: action), callback: userCallback)
            ARTLogVerbose(self.logger, "R:%p C:%p (%@) presence subscribe to '%@' action(s)", 
                self.realtime, self.channel, self.channel?.name, ARTPresenceActionToStr(action))
        }
        return listener
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 56 and ARTRealtimePresence.m, line 520
    internal func subscribe(_ callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(ARTPresenceAction(rawValue: UInt(ARTPresenceActionAll)) ?? .enter, onAttach: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 58 and ARTRealtimePresence.m, line 524
    internal func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(ARTPresenceAction(rawValue: UInt(ARTPresenceActionAll)) ?? .enter, onAttach: onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 60 and ARTRealtimePresence.m, line 528
    internal func subscribe(_ action: ARTPresenceAction, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(action, onAttach: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 62 and ARTRealtimePresence.m, line 532
    internal func subscribe(_ action: ARTPresenceAction, onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(action, onAttach: onAttach, callback: callback)
    }
    
    // RTP7
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 64 and ARTRealtimePresence.m, line 538
    internal func unsubscribe() {
        queue.sync {
            _unsubscribe()
            ARTLogVerbose(self.logger, "R:%p C:%p (%@) presence unsubscribe to all actions", self.realtime, self.channel, self.channel?.name)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 12 and ARTRealtimePresence.m, line 545
    internal func _unsubscribe() {
        eventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 66 and ARTRealtimePresence.m, line 549
    internal func unsubscribe(_ listener: ARTEventListener) {
        queue.sync {
            eventEmitter.off(listener)
            ARTLogVerbose(self.logger, "R:%p C:%p (%@) presence unsubscribe to all actions", self.realtime, self.channel, self.channel?.name)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 68 and ARTRealtimePresence.m, line 556
    internal func unsubscribe(_ action: ARTPresenceAction, listener: ARTEventListener) {
        queue.sync {
            eventEmitter.off(ARTEvent.new(with: action), listener: listener)
            ARTLogVerbose(self.logger, "R:%p C:%p (%@) presence unsubscribe to action %@", self.realtime, self.channel, self.channel?.name, ARTPresenceActionToStr(action))
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 563
    private func addPendingPresence(_ msg: ARTProtocolMessage, callback: @escaping ARTStatusCallback) {
        let qm = ARTQueuedMessage(protocolMessage: msg, sentCallback: nil, ackCallback: callback)
        pendingPresence.add(qm)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 568
    private func publishPresence(_ msg: ARTPresenceMessage, callback: ARTCallback?) {
        if msg.clientId == nil {
            let authClientId = realtime?.auth.clientId_nosync // RTP8c
            let connected = realtime?.connection.state_nosync == .connected
            if connected && (authClientId == nil || authClientId == "*") { // RTP8j
                if let callback = callback {
                    callback(ARTErrorInfo.create(withCode: ARTStateNoClientId, 
                        message: "Invalid attempt to publish presence message without clientId."))
                }
                return
            }
        }
        
        if !(realtime?.connection.isActive_nosync ?? false) {
            if let callback = callback {
                callback(realtime?.connection.error_nosync)
            }
            return
        }
        
        if channel?.exceedMaxSize([msg]) == true {
            if let callback = callback {
                let sizeError = ARTErrorInfo.create(withCode: ARTErrorMaxMessageLengthExceeded,
                    message: "Maximum message length exceeded.")
                callback(sizeError)
            }
            return
        }
        
        if let data = msg.data, let dataEncoder = channel?.dataEncoder {
            let encoded = dataEncoder.encode(data)
            if let errorInfo = encoded.errorInfo {
                ARTLogWarn(self.logger, "RT:%p C:%p (%@) error encoding presence message: %@", realtime, self, channel?.name, errorInfo)
            }
            msg.data = encoded.data
            msg.encoding = encoded.encoding
        }
        
        let pm = ARTProtocolMessage()
        pm.action = .presence
        pm.channel = channel?.name
        pm.presence = [msg]
        
        let channelState = channel?.state_nosync
        switch channelState {
        case .attached:
            realtime?.send(pm, sentCallback: nil) { status in // RTP16a
                if let callback = callback {
                    callback(status?.errorInfo)
                }
            }
        case .initialized:
            if realtime?.options.queueMessages == true { // RTP16b
                channel?._attach(nil)
            }
            fallthrough
        case .attaching:
            if realtime?.options.queueMessages == true { // RTP16b
                addPendingPresence(pm) { status in
                    if let callback = callback {
                        callback(status?.errorInfo)
                    }
                }
                break
            }
            fallthrough
        // RTP16c
        case .suspended, .detaching, .detached, .failed:
            if let callback = callback {
                let invalidChannelError = ARTErrorInfo.create(withCode: ARTErrorUnableToEnterPresenceChannelInvalidState, 
                    message: "channel operation failed (invalid channel state: \(ARTRealtimeChannelStateToStr(channelState ?? .failed)))")
                callback(invalidChannelError)
            }
        default:
            if let callback = callback {
                let invalidChannelError = ARTErrorInfo.create(withCode: ARTErrorUnableToEnterPresenceChannelInvalidState, 
                    message: "channel operation failed (invalid channel state: unknown)")
                callback(invalidChannelError)
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 646
    internal var pendingPresenceProperty: NSMutableArray<ARTQueuedMessage> {
        var result: NSMutableArray<ARTQueuedMessage>!
        queue.sync {
            result = pendingPresence
        }
        return result
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 654
    internal func sendPendingPresence() {
        let pendingPresenceArray = Array(pendingPresence as! [ARTQueuedMessage])
        let channelState = channel?.state_nosync
        pendingPresence.removeAllObjects()
        for qm in pendingPresenceArray {
            if qm.msg.action == .presence &&
                channelState != .attached {
                // Presence messages should only be sent when the channel is attached.
                pendingPresence.add(qm)
                continue
            }
            realtime?.send(qm.msg, sentCallback: nil, ackCallback: qm.ackCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 16 and ARTRealtimePresence.m, line 669
    internal func failPendingPresence(_ status: ARTStatus) {
        let pendingPresenceArray = Array(pendingPresence as! [ARTQueuedMessage])
        pendingPresence.removeAllObjects()
        for qm in pendingPresenceArray {
            qm.ackCallback(status)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 17 and ARTRealtimePresence.m, line 677
    internal func broadcast(_ pm: ARTPresenceMessage) {
        eventEmitter.emit(ARTEvent.new(with: pm.action), with: pm)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 685
    /*
     * Checks that a channelSerial is the final serial in a sequence of sync messages,
     * by checking that there is nothing after the colon - RTP18b, RTP18c
     */
    private func isLastChannelSerial(_ channelSerial: String?) -> Bool {
        guard let channelSerial = channelSerial, !channelSerial.isEmpty else {
            return true
        }
        let components = channelSerial.components(separatedBy: ":")
        if components.count > 1 && !components[1].isEmpty {
            return false
        }
        return true
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 21 and ARTRealtimePresence.m, line 696
    internal func onAttached(_ message: ARTProtocolMessage) {
        startSync()
        if !message.hasPresence {
            // RTP1 - when an ATTACHED message is received without a HAS_PRESENCE flag, reset PresenceMap (also RTP19a)
            endSync()
            ARTLogDebug(logger, "R:%p C:%p (%@) PresenceMap has been reset", realtime, self, channel?.name)
        }
        sendPendingPresence() // RTP5b
        reenterInternalMembers() // RTP17i
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 19 and ARTRealtimePresence.m, line 707
    internal func onMessage(_ message: ARTProtocolMessage) {
        var i = 0
        for p in message.presence ?? [] {
            var member = p
            if let data = member.data, dataEncoder != nil {
                var decodeError: Error? = nil
                member = p.decode(with: dataEncoder, error: &decodeError) ?? p
                if let decodeError = decodeError {
                    let errorInfo = ARTErrorInfo.wrap(ARTErrorInfo.create(withCode: ARTErrorUnableToDecodeMessage, 
                        message: (decodeError as NSError).localizedFailureReason), prepend: "Failed to decode data: ")
                    ARTLogError(logger, "RT:%p C:%p (%@) %@", realtime, channel, channel?.name, errorInfo.message)
                }
            }
            
            if member.timestamp == nil {
                member.timestamp = message.timestamp
            }
            
            if member.id == nil {
                member.id = "\(message.id ?? ""):\(i)"
            }
            
            if member.connectionId == nil {
                member.connectionId = message.connectionId
            }
            
            processMember(member)
            
            i += 1
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 20 and ARTRealtimePresence.m, line 738
    internal func onSync(_ message: ARTProtocolMessage) {
        if !syncInProgress_nosync {
            startSync()
        } else {
            ARTLogDebug(logger, "RT:%p C:%p (%@) PresenceMap sync is in progress", realtime, channel, channel?.name)
        }
        
        onMessage(message)
        
        // TODO: RTP18a (previous in-flight sync should be discarded)
        if isLastChannelSerial(message.channelSerial) { // RTP18b, RTP18c
            endSync()
            ARTLogDebug(logger, "RT:%p C:%p (%@) PresenceMap sync ended", realtime, channel, channel?.name)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 759
    private func didRemovedMemberNoLongerPresent(_ pm: ARTPresenceMessage) {
        pm.action = .leave
        pm.id = nil
        pm.timestamp = Date()
        broadcast(pm)
        ARTLogDebug(logger, "RT:%p C:%p (%@) member \"%@\" no longer present", realtime, channel, channel?.name, pm.memberKey)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 767
    private func reenterInternalMembers() {
        ARTLogDebug(logger, "%p reentering local members", self)
        for member in internalMembers.allValues {
            enterWithPresenceMessageId(member.id ?? "", clientId: member.clientId ?? "", data: member.data) { error in // RTP17g
                if let error = error {
                    let message = "Re-entering member \"\(member.memberKey ?? "")\" is failed with code \(error.code) (\(error.message))"
                    let reenterError = ARTErrorInfo.create(withCode: ARTErrorUnableToAutomaticallyReEnterPresenceChannel, message: message)
                    let stateChange = ARTChannelStateChange(current: self.channel?.state_nosync ?? .failed, 
                        previous: self.channel?.state_nosync ?? .failed, event: .update, reason: reenterError, resumed: true) // RTP17e
                    
                    self.channel?.emit(stateChange.event, with: stateChange)
                    
                    ARTLogWarn(self.logger, "RT:%p C:%p (%@) Re-entering member \"%@\" is failed with code %ld (%@)", 
                        self.realtime, self.channel, self.channel?.name, member.memberKey, error.code, error.message)
                } else {
                    ARTLogDebug(self.logger, "RT:%p C:%p (%@) re-entered local member \"%@\"", 
                        self.realtime, self.channel, self.channel?.name, member.memberKey)
                }
            }
            ARTLogDebug(logger, "RT:%p C:%p (%@) re-entering local member \"%@\"", realtime, channel, channel?.name, member.memberKey)
        }
    }
    
    // MARK: - Presence Map
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 101 and ARTRealtimePresence.m, line 798
    internal func processMember(_ message: ARTPresenceMessage) {
        let messageCopy = message.copy() as! ARTPresenceMessage
        // Internal member
        if message.connectionId == connectionId { // RTP17b
            switch message.action {
            case .enter, .update, .present:
                messageCopy.action = .present
                addInternalMember(messageCopy)
            case .leave:
                if !message.isSynthesized {
                    removeInternalMember(messageCopy)
                }
            default:
                break
            }
        }
        
        var memberUpdated = false
        switch message.action {
        case .enter, .update, .present:
            beforeSyncMembers?.removeObject(forKey: message.memberKey ?? "") // RTP19
            messageCopy.action = .present // RTP2d
            memberUpdated = addMember(messageCopy)
        case .leave:
            if syncInProgress_nosync {
                messageCopy.action = .absent // RTP2f
                memberUpdated = addMember(messageCopy)
            } else {
                memberUpdated = removeMember(messageCopy) // RTP2e
            }
        default:
            break
        }
        
        if memberUpdated {
            broadcast(message) // RTP2g (original action)
        } else {
            ARTLogDebug(logger, "Presence member \"%@\" with action %@ has been ignored", message.memberKey, ARTPresenceActionToStr(message.action))
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 102
    internal func reset() {
        _members = NSMutableDictionary()
        _internalMembers.removeAllObjects()
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 104 and ARTRealtimePresence.m, line 931
    internal func startSync() {
        ARTLogDebug(logger, "%p PresenceMap sync started", self)
        beforeSyncMembers = _members.mutableCopy() as? NSMutableDictionary<NSString, ARTPresenceMessage>
        syncState = .started
        syncEventEmitter.emit(ARTEvent.newWithPresenceSyncState(syncState), with: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 105 and ARTRealtimePresence.m, line 938
    internal func endSync() {
        ARTLogVerbose(logger, "%p PresenceMap sync ending", self)
        cleanUpAbsentMembers()
        leaveMembersNotPresentInSync()
        syncState = .ended
        beforeSyncMembers = nil
        
        syncEventEmitter.emit(ARTEvent.newWithPresenceSyncState(.ended), with: _members.allValues)
        syncEventEmitter.off()
        ARTLogDebug(logger, "%p PresenceMap sync ended", self)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 106 and ARTRealtimePresence.m, line 950
    internal func failsSync(_ error: ARTErrorInfo) {
        reset()
        syncState = .failed
        syncEventEmitter.emit(ARTEvent.newWithPresenceSyncState(.failed), with: error)
        syncEventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 108 and ARTRealtimePresence.m, line 957
    internal func onceSyncEnds(_ callback: @escaping ([ARTPresenceMessage]) -> Void) {
        syncEventEmitter.once(ARTEvent.newWithPresenceSyncState(.ended), callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 109 and ARTRealtimePresence.m, line 961
    internal func onceSyncFails(_ callback: @escaping ARTCallback) {
        syncEventEmitter.once(ARTEvent.newWithPresenceSyncState(.failed), callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 111 and ARTRealtimePresence.m, line 867
    internal func addMember(_ message: ARTPresenceMessage) -> Bool {
        if let existing = _members.object(forKey: message.memberKey ?? "" as NSString) {
            if member(message, isNewerThan: existing) {
                _members[message.memberKey ?? "" as NSString] = message
                return true
            }
            return false
        }
        _members[message.memberKey ?? "" as NSString] = message
        return true
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 112 and ARTRealtimePresence.m, line 891
    internal func addInternalMember(_ message: ARTPresenceMessage) {
        if let clientId = message.clientId {
            let existing = _internalMembers.object(forKey: clientId as NSString)
            if existing == nil || member(message, isNewerThan: existing!) {
                _internalMembers[clientId as NSString] = message
                ARTLogDebug(logger, "local member %@ with action %@ has been added", clientId, ARTPresenceActionToStr(message.action).uppercased)
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 114 and ARTRealtimePresence.m, line 880
    internal func removeMember(_ message: ARTPresenceMessage) -> Bool {
        if let existing = _members.object(forKey: message.memberKey ?? "" as NSString) {
            if member(message, isNewerThan: existing) {
                _members.removeObject(forKey: message.memberKey ?? "" as NSString)
                return existing.action != .absent
            }
        }
        return false
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 115 and ARTRealtimePresence.m, line 899
    internal func removeInternalMember(_ message: ARTPresenceMessage) {
        if let clientId = message.clientId {
            if let existing = _internalMembers.object(forKey: clientId as NSString) {
                if member(message, isNewerThan: existing) {
                    _internalMembers.removeObject(forKey: clientId as NSString)
                }
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 117 and ARTRealtimePresence.m, line 906
    internal func cleanUpAbsentMembers() {
        ARTLogDebug(logger, "%p cleaning up absent members...", self)
        let absentMembers = _members.allKeys.filter { key in
            return _members.object(forKey: key)?.action == .absent
        }
        for key in absentMembers {
            _members.removeObject(forKey: key)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 916
    private func leaveMembersNotPresentInSync() {
        ARTLogDebug(logger, "%p leaving members not present in sync...", self)
        if let beforeSyncMembers = beforeSyncMembers {
            for member in beforeSyncMembers.allValues {
                // Handle members that have not been added or updated in the PresenceMap during the sync process
                let leave = member.copy() as! ARTPresenceMessage
                _members.removeObject(forKey: leave.memberKey ?? "" as NSString)
                didRemovedMemberNoLongerPresent(leave)
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 119 and ARTRealtimePresence.m, line 848
    internal func member(_ msg1: ARTPresenceMessage, isNewerThan msg2: ARTPresenceMessage) -> Bool {
        if msg1.isSynthesized || msg2.isSynthesized { // RTP2b1
            return msg1.timestamp?.timeIntervalSince1970 ?? 0 >= msg2.timestamp?.timeIntervalSince1970 ?? 0
        }
        
        let msg1Serial = msg1.msgSerialFromId()
        let msg1Index = msg1.indexFromId()
        let msg2Serial = msg2.msgSerialFromId()
        let msg2Index = msg2.indexFromId()
        
        // RTP2b2
        if msg1Serial == msg2Serial {
            return msg1Index > msg2Index
        } else {
            return msg1Serial > msg2Serial
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 14 and ARTRealtimePresence.m, line 965
    internal func syncInProgress_nosync() -> Bool {
        return syncState == .started
    }
}

// MARK: - ARTEvent Extension

// swift-migration: original location ARTRealtimePresence.m, line 981
private func ARTPresenceSyncStateToStr(_ state: ARTPresenceSyncState) -> String {
    switch state {
    case .initialized:
        return "Initialized" // 0
    case .started:
        return "Started" // 1
    case .ended:
        return "Ended" // 2
    case .failed:
        return "Failed" // 3
    }
}

// swift-migration: original location ARTRealtimePresence.m, line 994
extension ARTEvent {
    
    // swift-migration: original location ARTRealtimePresence.m, line 996
    convenience init(presenceSyncState value: ARTPresenceSyncState) {
        self.init(string: "ARTPresenceSyncState\(ARTPresenceSyncStateToStr(value))")
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 1000
    static func newWithPresenceSyncState(_ value: ARTPresenceSyncState) -> ARTEvent {
        return ARTEvent(presenceSyncState: value)
    }
}
