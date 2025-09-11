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

// swift-migration: original location ARTRealtimePresence.m, line 160
private enum ARTPresenceSyncState: UInt {
    case initialized = 0  // ARTPresenceSyncInitialized
    case started = 1      // ARTPresenceSyncStarted, ItemType: nil  
    case ended = 2        // ARTPresenceSyncEnded, ItemType: NSArray<ARTPresenceMessage *>*
    case failed = 3       // ARTPresenceSyncFailed, ItemType: ARTErrorInfo*
}

// swift-migration: original location ARTRealtimePresence+Private.h, line 6 and ARTRealtimePresence.m, line 174
public class ARTRealtimePresenceInternal {
}
