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

    // swift-migration: Lawrence added (initializers not inherited in Swift)
    public override init() {
        waitForSync = true
        super.init()
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
    func subscribe(attachCallback onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener?
    
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
    public func subscribe(attachCallback onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
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
    public func history(_ query: ARTRealtimeHistoryQuery?, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        return try `internal`.history(query, wrapperSDKAgents: nil, callback: callback)
    }
}

// MARK: - ARTRealtimePresenceInternal

// swift-migration: original location ARTRealtimePresence.m, line 160
internal enum ARTPresenceSyncState: UInt {
    case initialized = 0  // ARTPresenceSyncInitialized
    case started = 1      // ARTPresenceSyncStarted, ItemType: nil  
    case ended = 2        // ARTPresenceSyncEnded, ItemType: NSArray<ARTPresenceMessage *>*
    case failed = 3       // ARTPresenceSyncFailed, ItemType: ARTErrorInfo*
}

// swift-migration: Handle ARTPresenceActionAll migration - internal enum to replace the problematic constant
// swift-migration: ARTPresenceActionAll was defined as NSIntegerMax in Objective-C (line 148) but can't be used in Swift enum
private enum PresenceActionFilter {
    case action(ARTPresenceAction)
    case all
}

// swift-migration: original location ARTRealtimePresence+Private.h, line 6 and ARTRealtimePresence.m, line 174
internal class ARTRealtimePresenceInternal {
    
    // MARK: - Instance Variables (from .m file line 175-189)
    
    // swift-migration: original location ARTRealtimePresence.m, line 175
    private weak var _channel: ARTRealtimeChannelInternal? // weak because channel owns self
    // swift-migration: original location ARTRealtimePresence.m, line 176
    private weak var _realtime: ARTRealtimeInternal?
    // swift-migration: original location ARTRealtimePresence.m, line 177
    private let _userQueue: DispatchQueue
    // swift-migration: original location ARTRealtimePresence+Private.h, line 23 and ARTRealtimePresence.m, line 196
    private let _queue: DispatchQueue
    // swift-migration: original location ARTRealtimePresence.m, line 178
    private var _pendingPresence: [ARTQueuedMessage]
    // swift-migration: original location ARTRealtimePresence.m, line 179
    private let _eventEmitter: ARTEventEmitter<ARTEvent, ARTPresenceMessage>
    // swift-migration: original location ARTRealtimePresence.m, line 180
    private let _dataEncoder: ARTDataEncoder
    
    // swift-migration: original location ARTRealtimePresence.m, line 182
    private var _syncState: ARTPresenceSyncState
    // swift-migration: original location ARTRealtimePresence.m, line 183
    private let _syncEventEmitter: ARTEventEmitter<ARTEvent, Any>
    
    // swift-migration: original location ARTRealtimePresence.m, line 185 - RTP2
    // swift-migration: Atomic property - using NSLock for thread-safety per PRD
    // swift-migration: Using Swift Dictionary instead of NSMutableDictionary per PRD section 5.1
    private let _membersLock = NSLock()
    private var _members: [String: ARTPresenceMessage]
    
    // swift-migration: original location ARTRealtimePresence.m, line 186 - RTP17h
    // swift-migration: Atomic property - using NSLock for thread-safety per PRD
    // swift-migration: Using Swift Dictionary instead of NSMutableDictionary per PRD section 5.1
    private let _internalMembersLock = NSLock()
    private var _internalMembers: [String: ARTPresenceMessage]
    
    // swift-migration: original location ARTRealtimePresence.m, line 188 - RTP19
    // swift-migration: Using Swift Dictionary instead of NSMutableDictionary per PRD section 5.1
    private var _beforeSyncMembers: [String: ARTPresenceMessage]?
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 154 and ARTRealtimePresence.m, line 198
    private let logger: InternalLog
    
    // MARK: - Properties
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 8 and ARTRealtimePresence.m, line 755
    // swift-migration: Custom getter - preserves original logic accessing _realtime.connection.id_nosync
    internal var connectionId: String? {
        // swift-migration: Lawrence made this nullable, seems like an issue in the Objective-C
        return _realtime?.connection.id_nosync
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 9
    internal var eventEmitter: ARTEventEmitter<ARTEvent, ARTPresenceMessage> {
        return _eventEmitter
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 23
    internal var queue: DispatchQueue {
        return _queue
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 24
    internal var pendingPresence: [ARTQueuedMessage] {
        return _pendingPresence
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 89 and ARTRealtimePresence.m, line 790
    // swift-migration: Property marked as atomic in header - implementing atomic access pattern per PRD
    // swift-migration: Using Swift Dictionary instead of NSDictionary per PRD section 5.1 - returns defensive copy
    internal var members: [String: ARTPresenceMessage] {
        get { _membersLock.withLock { _members } }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 93 and ARTRealtimePresence.m, line 794
    // swift-migration: Property marked as atomic in header - implementing atomic access pattern per PRD  
    // swift-migration: Using Swift Dictionary instead of NSDictionary per PRD section 5.1 - returns defensive copy
    internal var internalMembers: [String: ARTPresenceMessage] {
        get { _internalMembersLock.withLock { _internalMembers } }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 26 and ARTRealtimePresence.m, line 466
    // swift-migration: Custom getter with thread-safe dispatch pattern from original - preserves exact behavior
    internal var syncComplete: Bool {
        var result = false
        queue.sync {
            result = syncComplete_nosync()
        }
        return result
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 96 and ARTRealtimePresence.m, line 969
    // swift-migration: Custom getter with thread-safe dispatch pattern from original - preserves exact behavior
    internal var syncInProgress: Bool {
        var result = false
        queue.sync {
            result = syncInProgress_nosync()
        }
        return result
    }
    
    // MARK: - Internal Helper Properties/Methods
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 13 and ARTRealtimePresence.m, line 476
    internal func syncComplete_nosync() -> Bool {
        return _syncState == .ended || _syncState == .failed
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 14 and ARTRealtimePresence.m, line 965
    internal func syncInProgress_nosync() -> Bool {
        return _syncState == .started
    }
    
    // MARK: - Initialization (placeholder for now as per user request)
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 11 and ARTRealtimePresence.m, line 191
    internal init(channel: ARTRealtimeChannelInternal, logger: InternalLog) {
        // swift-migration: Preserving original initialization logic from line 192-206
        self._channel = channel
        self._realtime = channel.realtime
        // swift-migration: Lawrence added all these unwraps of channel.realtime
        self._userQueue = unwrapValueWithAmbiguousObjectiveCNullability(channel.realtime).rest.userQueue
        self._queue = unwrapValueWithAmbiguousObjectiveCNullability(channel.realtime).rest.queue
        self._pendingPresence = []
        self.logger = logger
        self._eventEmitter = ARTInternalEventEmitter(queue: unwrapValueWithAmbiguousObjectiveCNullability(channel.realtime).rest.queue)
        self._dataEncoder = channel.dataEncoder
        self._members = [:]
        self._internalMembers = [:]
        self._syncState = .initialized
        self._syncEventEmitter = ARTInternalEventEmitter(queue: unwrapValueWithAmbiguousObjectiveCNullability(channel.realtime).rest.queue)
    }
    
    // MARK: - Public API Implementation
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 28 and ARTRealtimePresence.m, line 211
    // RTP11
    internal func get(_ callback: @escaping ARTPresenceMessagesCallback) {
        get(ARTRealtimePresenceQuery(limit: 100, clientId: nil, connectionId: nil), callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 30 and ARTRealtimePresence.m, line 215
    internal func get(_ query: ARTRealtimePresenceQuery, callback: @escaping ARTPresenceMessagesCallback) {
        var userCallback: ARTPresenceMessagesCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { messages, error in
                self._userQueue.async {
                    originalCallback(messages, error)
                }
            }
        }
        
        _queue.async {
            guard let channel = self._channel else { return }
            
            switch channel.state_nosync {
            case .detached, .failed:
                if let callback = userCallback {
                    callback(nil, ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailedInvalidState.rawValue, message: "unable to return the list of current members (incompatible channel state: \(ARTRealtimeChannelStateToStr(channel.state_nosync)))"))
                }
                return
            case .suspended:
                if let query = query as ARTRealtimePresenceQuery?, !query.waitForSync { // RTP11d
                    if let callback = userCallback {
                        callback(Array(self._members.values), nil)
                    }
                    return
                }
                if let callback = userCallback {
                    callback(nil, ARTErrorInfo.create(withCode: ARTErrorCode.presenceStateIsOutOfSync.rawValue, message: "presence state is out of sync due to the channel being SUSPENDED"))
                }
                return
            default:
                break
            }
            
            // RTP11c
            let filterMemberBlock: (ARTPresenceMessage) -> Bool = { message in
                return (query.clientId == nil || message.clientId == query.clientId) &&
                       (query.connectionId == nil || message.connectionId == query.connectionId)
            }
            
            channel._attach { error in // RTP11b
                if let error = error {
                    userCallback?(nil, error)
                    return
                }
                
                let syncInProgress = self.syncInProgress_nosync()
                if syncInProgress && query.waitForSync {
                    ARTLogDebug(self.logger, "R:\(String(describing: self._realtime)) C:\(String(describing: self._channel)) (\(self._channel?.name ?? "")) sync is in progress, waiting until the presence members is synchronized")
                    self.onceSyncEnds { members in
                        let filteredMembers = members.filter(filterMemberBlock)
                        userCallback?(filteredMembers, nil)
                    }
                    self.onceSyncFails { error in
                        userCallback?(nil, error)
                    }
                } else {
                    ARTLogDebug(self.logger, "R:\(String(describing: self._realtime)) C:\(String(describing: self._channel)) (\(self._channel?.name ?? "")) returning presence members (syncInProgress=\(syncInProgress))")
                    let members = Array(self._members.values)
                    let filteredMembers = members.filter(filterMemberBlock)
                    userCallback?(filteredMembers, nil)
                }
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 70 and ARTRealtimePresence.m, line 275
    // RTP12
    internal func historyWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion callback: @escaping ARTPaginatedPresenceCallback) {
        _ = try! history(ARTRealtimeHistoryQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 73 and ARTRealtimePresence.m, line 280
    // swift-migration: Updated to be throwing as requested by the user
    internal func history(_ query: ARTRealtimeHistoryQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedPresenceCallback) throws -> Bool {
        let effectiveQuery = query ?? ARTRealtimeHistoryQuery()
        effectiveQuery.realtimeChannel = _channel
        return try _channel?.restChannel.presence.history(effectiveQuery, wrapperSDKAgents: wrapperSDKAgents, callback: callback) ?? false
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 32 and ARTRealtimePresence.m, line 287
    // RTP8
    internal func enter(_ data: Any?) {
        enter(data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 34 and ARTRealtimePresence.m, line 291
    internal func enter(_ data: Any?, callback: ARTCallback?) {
        var userCallback: ARTCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { error in
                self._userQueue.async {
                    originalCallback(error)
                }
            }
        }
        
        _queue.async {
            self.enterOrUpdateAfterChecks(.enter, messageId: nil, clientId: nil, data: data, callback: userCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 44 and ARTRealtimePresence.m, line 308
    // RTP14, RTP15
    internal func enterClient(_ clientId: String, data: Any?) {
        enterClient(clientId, data: data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 46 and ARTRealtimePresence.m, line 312
    internal func enterClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        var userCallback: ARTCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { error in
                self._userQueue.async {
                    originalCallback(error)
                }
            }
        }
        
        _queue.async {
            self.enterOrUpdateAfterChecks(.enter, messageId: nil, clientId: clientId, data: data, callback: userCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 327
    internal func enterWithPresenceMessageId(_ messageId: String?, clientId: String?, data: Any?, callback: ARTCallback?) {
        var userCallback: ARTCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { error in
                self._userQueue.async {
                    originalCallback(error)
                }
            }
        }
        
        _queue.async {
            self.enterOrUpdateAfterChecks(.enter, messageId: messageId, clientId: clientId, data: data, callback: userCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 36 and ARTRealtimePresence.m, line 343
    // RTP9
    internal func update(_ data: Any?) {
        update(data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 38 and ARTRealtimePresence.m, line 347
    internal func update(_ data: Any?, callback: ARTCallback?) {
        var userCallback: ARTCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { error in
                self._userQueue.async {
                    originalCallback(error)
                }
            }
        }
        
        _queue.async {
            self.enterOrUpdateAfterChecks(.update, messageId: nil, clientId: nil, data: data, callback: userCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 48 and ARTRealtimePresence.m, line 364
    // RTP15
    internal func updateClient(_ clientId: String, data: Any?) {
        updateClient(clientId, data: data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 50 and ARTRealtimePresence.m, line 368
    internal func updateClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        var userCallback: ARTCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { error in
                self._userQueue.async {
                    originalCallback(error)
                }
            }
        }
        
        _queue.async {
            self.enterOrUpdateAfterChecks(.update, messageId: nil, clientId: clientId, data: data, callback: userCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 383
    private func enterOrUpdateAfterChecks(_ action: ARTPresenceAction, messageId: String?, clientId: String?, data: Any?, callback: ARTCallback?) {
        guard let channel = _channel else { return }
        
        switch channel.state_nosync {
        case .detached, .failed:
            if let callback = callback {
                let channelError = ARTErrorInfo.create(withCode: ARTErrorCode.unableToEnterPresenceChannelInvalidState.rawValue, message: "unable to enter presence channel (incompatible channel state: \(ARTRealtimeChannelStateToStr(channel.state_nosync)))")
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
        // swift-migration: unwrap added by Lawrence
        msg.connectionId = unwrapValueWithAmbiguousObjectiveCNullability(_realtime?.connection.id_nosync)

        publishPresence(msg, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 40 and ARTRealtimePresence.m, line 409
    // RTP10
    internal func leave(_ data: Any?) {
        leave(data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 42 and ARTRealtimePresence.m, line 413
    internal func leave(_ data: Any?, callback: ARTCallback?) {
        var userCallback: ARTCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { error in
                self._userQueue.async {
                    originalCallback(error)
                }
            }
        }
        
        _queue.sync {
            // swift-migration: Lawrence removed exception checks here
            self.leaveAfterChecks(nil, data: data, callback: userCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 52 and ARTRealtimePresence.m, line 438
    // RTP15
    internal func leaveClient(_ clientId: String, data: Any?) {
        leaveClient(clientId, data: data, callback: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 54 and ARTRealtimePresence.m, line 442
    internal func leaveClient(_ clientId: String, data: Any?, callback: ARTCallback?) {
        var userCallback: ARTCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { error in
                self._userQueue.async {
                    originalCallback(error)
                }
            }
        }
        
        _queue.sync {
            leaveAfterChecks(clientId, data: data, callback: userCallback)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 457
    private func leaveAfterChecks(_ clientId: String?, data: Any?, callback: ARTCallback?) {
        let msg = ARTPresenceMessage()
        msg.action = .leave
        msg.data = data
        msg.clientId = clientId
        // swift-migration: unwrap added by Lawrence
        msg.connectionId = unwrapValueWithAmbiguousObjectiveCNullability(_realtime?.connection.id_nosync)
        publishPresence(msg, callback: callback)
    }
    
    // MARK: - Subscription Methods
    
    // swift-migration: original location ARTRealtimePresence.m, line 482
    // RTP6
    private func _subscribe(_ actionFilter: PresenceActionFilter, onAttach: ARTCallback?, callback: ARTPresenceMessageCallback?) -> ARTEventListener? {
        var userCallback: ARTPresenceMessageCallback? = callback
        if userCallback != nil {
            let originalCallback = userCallback!
            userCallback = { message in
                self._userQueue.async {
                    originalCallback(message)
                }
            }
        }
        
        var userOnAttach: ARTCallback? = onAttach
        if userOnAttach != nil {
            let originalOnAttach = userOnAttach!
            userOnAttach = { error in
                self._userQueue.async {
                    originalOnAttach(error)
                }
            }
        }
        
        var listener: ARTEventListener?
        _queue.sync {
            guard let channel = self._channel else { return }
            
            let options = channel.getOptions_nosync()
            let attachOnSubscribe = options?.attachOnSubscribe ?? true
            
            if channel.state_nosync == .failed {
                if let onAttach = userOnAttach, attachOnSubscribe { // RTL7h
                    onAttach(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailedInvalidState.rawValue, message: "attempted to subscribe while channel is in Failed state."))
                }
                ARTLogWarn(self.logger, "R:\(String(describing: self._realtime)) C:\(String(describing: self._channel)) (\(self._channel?.name ?? "")) presence subscribe to '\(self.actionFilterDescription(actionFilter))' action(s) has been ignored (attempted to subscribe while channel is in FAILED state)")
                return
            }
            
            if channel.shouldAttach && attachOnSubscribe { // RTP6c
                channel._attach(userOnAttach)
            }
            
            switch actionFilter {
            case .all:
                if let callback = userCallback {
                    listener = self._eventEmitter.on(callback)
                }
            case .action(let action):
                if let callback = userCallback {
                    listener = self._eventEmitter.on(ARTEvent.new(withPresenceAction: action), callback: callback)
                }
            }
            
            ARTLogVerbose(self.logger, "R:\(String(describing: self._realtime)) C:\(String(describing: self._channel)) (\(self._channel?.name ?? "")) presence subscribe to '\(self.actionFilterDescription(actionFilter))' action(s)")
        }
        
        return listener
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 56 and ARTRealtimePresence.m, line 520
    internal func subscribe(_ callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(.all, onAttach: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 58 and ARTRealtimePresence.m, line 524
    internal func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(.all, onAttach: onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 60 and ARTRealtimePresence.m, line 528
    internal func subscribe(_ action: ARTPresenceAction, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(.action(action), onAttach: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 62 and ARTRealtimePresence.m, line 532
    internal func subscribe(_ action: ARTPresenceAction, onAttach: ARTCallback?, callback: @escaping ARTPresenceMessageCallback) -> ARTEventListener? {
        return _subscribe(.action(action), onAttach: onAttach, callback: callback)
    }
    
    // MARK: - Unsubscription Methods
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 64 and ARTRealtimePresence.m, line 538
    // RTP7
    internal func unsubscribe() {
        _queue.sync {
            _unsubscribe()
            ARTLogVerbose(logger, "R:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) presence unsubscribe to all actions")
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 12 and ARTRealtimePresence.m, line 545
    internal func _unsubscribe() {
        _eventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 66 and ARTRealtimePresence.m, line 549
    internal func unsubscribe(_ listener: ARTEventListener) {
        _queue.sync {
            _eventEmitter.off(listener)
            ARTLogVerbose(logger, "R:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) presence unsubscribe to all actions")
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 68 and ARTRealtimePresence.m, line 556
    internal func unsubscribe(_ action: ARTPresenceAction, listener: ARTEventListener) {
        _queue.sync {
            _eventEmitter.off(ARTEvent.new(withPresenceAction: action), listener: listener)
            ARTLogVerbose(logger, "R:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) presence unsubscribe to action \(ARTPresenceActionToStr(action))")
        }
    }
    
    // MARK: - Internal Message Handling
    
    // swift-migration: original location ARTRealtimePresence.m, line 563
    internal func addPendingPresence(_ msg: ARTProtocolMessage, callback: @escaping ARTStatusCallback) {
        let qm = ARTQueuedMessage(protocolMessage: msg, sentCallback: nil, ackCallback: callback)
        _pendingPresence.append(qm)
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 568
    internal func publishPresence(_ msg: ARTPresenceMessage, callback: ARTCallback?) {
        guard let realtime = _realtime, let channel = _channel else { return }
        
        if msg.clientId == nil {
            let authClientId = realtime.auth.clientId_nosync() // RTP8c
            let connected = realtime.connection.state_nosync == .connected
            if connected && (authClientId == nil || authClientId == "*") { // RTP8j
                if let callback = callback {
                    callback(ARTErrorInfo.create(withCode: ARTState.noClientId.rawValue, message: "Invalid attempt to publish presence message without clientId."))
                }
                return
            }
        }
        
        if !realtime.connection.isActive_nosync {
            if let callback = callback {
                callback(realtime.connection.error_nosync)
            }
            return
        }
        
        if channel.exceedMaxSize([msg]) {
            if let callback = callback {
                let sizeError = ARTErrorInfo.create(withCode: ARTErrorCode.maxMessageLengthExceeded.rawValue, message: "Maximum message length exceeded.")
                callback(sizeError)
            }
            return
        }
        
        if let data = msg.data, let dataEncoder = channel.dataEncoder {
            let encoded = dataEncoder.encode(data)
            if let errorInfo = encoded.errorInfo {
                ARTLogWarn(logger, "RT:\(String(describing: realtime)) C:\(String(describing: self)) (\(channel.name)) error encoding presence message: \(errorInfo)")
            }
            msg.data = encoded.data
            msg.encoding = encoded.encoding
        }
        
        let pm = ARTProtocolMessage()
        pm.action = .presence
        pm.channel = channel.name
        pm.presence = [msg]
        
        let channelState = channel.state_nosync
        switch channelState {
        case .attached:
            realtime.send(pm, sentCallback: nil, ackCallback: { status in // RTP16a
                if let callback = callback {
                    callback(status.errorInfo)
                }
            })
        case .initialized:
            if realtime.options.queueMessages { // RTP16b
                channel._attach(nil)
            }
            fallthrough
        case .attaching:
            if realtime.options.queueMessages { // RTP16b
                addPendingPresence(pm) { status in
                    if let callback = callback {
                        callback(status.errorInfo)
                    }
                }
                break
            }
            fallthrough
        // RTP16c
        case .suspended, .detaching, .detached, .failed:
            if let callback = callback {
                let invalidChannelError = ARTErrorInfo.create(withCode: ARTErrorCode.unableToEnterPresenceChannelInvalidState.rawValue, message: "channel operation failed (invalid channel state: \(ARTRealtimeChannelStateToStr(channelState)))")
                callback(invalidChannelError)
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 654
    internal func sendPendingPresence() {
        guard let channel = _channel, let realtime = _realtime else { return }
        
        let pendingPresence = _pendingPresence
        let channelState = channel.state_nosync
        _pendingPresence = []
        
        for qm in pendingPresence {
            if qm.msg.action == .presence && channelState != .attached {
                // Presence messages should only be sent when the channel is attached.
                _pendingPresence.append(qm)
                continue
            }
            realtime.send(qm.msg, sentCallback: nil, ackCallback: qm.ackCallback())
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 16 and ARTRealtimePresence.m, line 669
    internal func failPendingPresence(_ status: ARTStatus) {
        let pendingPresence = _pendingPresence
        _pendingPresence = []
        for qm in pendingPresence {
            qm.ackCallback()(status)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 17 and ARTRealtimePresence.m, line 677
    internal func broadcast(_ pm: ARTPresenceMessage) {
        _eventEmitter.emit(ARTEvent.new(withPresenceAction: pm.action), with: pm)
    }
    
    // MARK: - Protocol Message Handling
    
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
            ARTLogDebug(logger, "R:\(String(describing: _realtime)) C:\(String(describing: self)) (\(_channel?.name ?? "")) PresenceMap has been reset")
        }
        sendPendingPresence() // RTP5b
        reenterInternalMembers() // RTP17i
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 19 and ARTRealtimePresence.m, line 707
    internal func onMessage(_ message: ARTProtocolMessage) {
        guard let presence = message.presence else { return }
        
        for (i, p) in presence.enumerated() {
            var member = p
            
            // swift-migration: Lawrence commented out this nil check, haven't compared to the Obj-C
            if member.data != nil /*, let dataEncoder = _dataEncoder */ {
                do {
                    // swift-migration: Lawrence added this cast, haven't checked
                    member = try p.decode(withEncoder: _dataEncoder) as! ARTPresenceMessage
                } catch {
                    let errorInfo = ARTErrorInfo.wrap(ARTErrorInfo.create(withCode: ARTErrorCode.unableToDecodeMessage.rawValue, message: error.localizedDescription), prepend: "Failed to decode data: ")
                    ARTLogError(logger, "RT:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) \(errorInfo.message)")
                }
            }
            
            if member.timestamp == nil {
                member.timestamp = message.timestamp
            }
            
            if member.id == nil {
                member.id = "\(message.id ?? ""):\(i)"
            }
            
            if member.connectionId == nil {
                // swift-migration: Added by Lawrence
                member.connectionId = unwrapValueWithAmbiguousObjectiveCNullability(message.connectionId)
            }
            
            processMember(member)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 20 and ARTRealtimePresence.m, line 738
    internal func onSync(_ message: ARTProtocolMessage) {
        if !syncInProgress_nosync() {
            startSync()
        } else {
            ARTLogDebug(logger, "RT:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) PresenceMap sync is in progress")
        }
        
        onMessage(message)
        
        // TODO: RTP18a (previous in-flight sync should be discarded)
        if isLastChannelSerial(message.channelSerial) { // RTP18b, RTP18c
            endSync()
            ARTLogDebug(logger, "RT:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) PresenceMap sync ended")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func actionFilterDescription(_ filter: PresenceActionFilter) -> String {
        switch filter {
        case .all:
            return "ALL"
        case .action(let action):
            return ARTPresenceActionToStr(action)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 759
    private func didRemovedMemberNoLongerPresent(_ pm: ARTPresenceMessage) {
        pm.action = .leave
        pm.id = nil
        pm.timestamp = Date()
        broadcast(pm)
        ARTLogDebug(logger, "RT:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) member \"\(pm.memberKey() ?? "")\" no longer present")
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 767
    private func reenterInternalMembers() {
        ARTLogDebug(logger, "\(String(describing: self)) reentering local members")
        
        for member in internalMembers.values {
            enterWithPresenceMessageId(member.id, clientId: member.clientId, data: member.data) { error in // RTP17g
                if let error = error {
                    let message = "Re-entering member \"\(member.memberKey() ?? "")\" is failed with code \(error.code) (\(error.message))"
                    let reenterError = ARTErrorInfo.create(withCode: ARTErrorCode.unableToAutomaticallyReEnterPresenceChannel.rawValue, message: message)
                    let stateChange = ARTChannelStateChange(current: self._channel?.state_nosync ?? .initialized, previous: self._channel?.state_nosync ?? .initialized, event: .update, reason: reenterError, resumed: true) // RTP17e
                    
                    self._channel?.emit(.update, with: stateChange)
                    
                    ARTLogWarn(self.logger, "RT:\(String(describing: self._realtime)) C:\(String(describing: self._channel)) (\(self._channel?.name ?? "")) Re-entering member \"\(member.memberKey() ?? "")\" is failed with code \(error.code) (\(error.message))")
                } else {
                    ARTLogDebug(self.logger, "RT:\(String(describing: self._realtime)) C:\(String(describing: self._channel)) (\(self._channel?.name ?? "")) re-entered local member \"\(member.memberKey() ?? "")\"")
                }
            }
            ARTLogDebug(logger, "RT:\(String(describing: _realtime)) C:\(String(describing: _channel)) (\(_channel?.name ?? "")) re-entering local member \"\(member.memberKey() ?? "")\"")
        }
    }
    
    // MARK: - Presence Map Methods (PresenceMap category from private header)
    
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
                if !message.isSynthesized() {
                    removeInternalMember(messageCopy)
                }
            default:
                break
            }
        }
        
        var memberUpdated = false
        switch message.action {
        case .enter, .update, .present:
            _membersLock.withLock {
                // swift-migration: unwrap added by Lawrence
                _beforeSyncMembers?.removeValue(forKey: unwrapValueWithAmbiguousObjectiveCNullability(message.memberKey())) // RTP19
            }
            messageCopy.action = .present // RTP2d
            memberUpdated = addMember(messageCopy)
        case .leave:
            if syncInProgress_nosync() {
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
            ARTLogDebug(logger, "Presence member \"\(message.memberKey() ?? "")\" with action \(ARTPresenceActionToStr(message.action)) has been ignored")
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 119 and ARTRealtimePresence.m, line 848
    internal func member(_ msg1: ARTPresenceMessage, isNewerThan msg2: ARTPresenceMessage) -> Bool {
        if msg1.isSynthesized() || msg2.isSynthesized() { // RTP2b1
            guard let timestamp1 = msg1.timestamp, let timestamp2 = msg2.timestamp else {
                return msg1.timestamp != nil
            }
            return timestamp1.timeIntervalSince1970 >= timestamp2.timeIntervalSince1970
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
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 111 and ARTRealtimePresence.m, line 867
    internal func addMember(_ message: ARTPresenceMessage) -> Bool {
        return _membersLock.withLock {
            // swift-migration: Lawrence removed a guard because for some reason memberKey is non-nil
//            guard let memberKey = message.memberKey else { return false }
            let memberKey = message.memberKey()

            if let existing = _members[memberKey] {
                if member(message, isNewerThan: existing) {
                    _members[memberKey] = message
                    return true
                }
                return false
            }
            _members[memberKey] = message
            return true
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 114 and ARTRealtimePresence.m, line 880
    internal func removeMember(_ message: ARTPresenceMessage) -> Bool {
        return _membersLock.withLock {
            // swift-migration: Lawrence removed a guard because for some reason memberKey is non-nil
            //            guard let memberKey = message.memberKey() else { return false }
            let memberKey = message.memberKey()

            if let existing = _members[memberKey] {
                if member(message, isNewerThan: existing) {
                    _members.removeValue(forKey: memberKey)
                    return existing.action != .absent
                }
            }
            return false
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 112 and ARTRealtimePresence.m, line 891
    internal func addInternalMember(_ message: ARTPresenceMessage) {
        _internalMembersLock.withLock {
            guard let clientId = message.clientId else { return }
            
            if let existing = _internalMembers[clientId] {
                if !member(message, isNewerThan: existing) {
                    return
                }
            }
            
            _internalMembers[clientId] = message
            ARTLogDebug(logger, "local member \(clientId) with action \(ARTPresenceActionToStr(message.action).uppercased()) has been added")
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 115 and ARTRealtimePresence.m, line 899
    internal func removeInternalMember(_ message: ARTPresenceMessage) {
        _internalMembersLock.withLock {
            guard let clientId = message.clientId else { return }
            
            if let existing = _internalMembers[clientId], member(message, isNewerThan: existing) {
                _internalMembers.removeValue(forKey: clientId)
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 117 and ARTRealtimePresence.m, line 906
    internal func cleanUpAbsentMembers() {
        ARTLogDebug(logger, "\(String(describing: self)) cleaning up absent members...")
        
        _membersLock.withLock {
            let absentKeys = _members.compactMap { key, message in
                message.action == .absent ? key : nil
            }
            
            for key in absentKeys {
                _members.removeValue(forKey: key)
            }
        }
    }
    
    // swift-migration: original location ARTRealtimePresence.m, line 916
    private func leaveMembersNotPresentInSync() {
        ARTLogDebug(logger, "\(String(describing: self)) leaving members not present in sync...")
        
        guard let beforeSyncMembers = _beforeSyncMembers else { return }
        
        for member in beforeSyncMembers.values {
            // Handle members that have not been added or updated in the PresenceMap during the sync process
            let leave = member.copy() as! ARTPresenceMessage
            _membersLock.withLock {
                // swift-migration: unwrap added by Lawrence
                _members.removeValue(forKey: unwrapValueWithAmbiguousObjectiveCNullability(leave.memberKey()))
            }
            didRemovedMemberNoLongerPresent(leave)
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 102 and ARTRealtimePresence.m, line 926
    internal func reset() {
        _membersLock.withLock {
            _members = [:]
        }
        _internalMembersLock.withLock {
            _internalMembers = [:]
        }
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 104 and ARTRealtimePresence.m, line 931
    internal func startSync() {
        ARTLogDebug(logger, "\(String(describing: self)) PresenceMap sync started")
        _beforeSyncMembers = _membersLock.withLock { _members }
        _syncState = .started
        _syncEventEmitter.emit(ARTEvent.newWithPresenceSyncState(_syncState), with: nil)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 105 and ARTRealtimePresence.m, line 938
    internal func endSync() {
        ARTLogVerbose(logger, "\(String(describing: self)) PresenceMap sync ending")
        cleanUpAbsentMembers()
        leaveMembersNotPresentInSync()
        _syncState = .ended
        _beforeSyncMembers = nil
        
        let membersValues = _membersLock.withLock { Array(_members.values) }
        _syncEventEmitter.emit(ARTEvent.newWithPresenceSyncState(.ended), with: membersValues)
        _syncEventEmitter.off()
        ARTLogDebug(logger, "\(String(describing: self)) PresenceMap sync ended")
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 106 and ARTRealtimePresence.m, line 950
    internal func failsSync(_ error: ARTErrorInfo) {
        reset()
        _syncState = .failed
        _syncEventEmitter.emit(ARTEvent.newWithPresenceSyncState(.failed), with: error)
        _syncEventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 108 and ARTRealtimePresence.m, line 957
    internal func onceSyncEnds(_ callback: @escaping ([ARTPresenceMessage]) -> Void) {
        // swift-migration: Lawrence added this upcast, we can do better than this in Swift though
        let upcastingCallback: (Any) -> Void = { item in
            guard let presenceMessages = item as? [ARTPresenceMessage] else {
                preconditionFailure()
            }
            callback(presenceMessages)
        }
        _syncEventEmitter.once(ARTEvent.newWithPresenceSyncState(.ended), callback: upcastingCallback)
    }
    
    // swift-migration: original location ARTRealtimePresence+Private.h, line 109 and ARTRealtimePresence.m, line 961
    internal func onceSyncFails(_ callback: @escaping ARTCallback) {
        // swift-migration: Lawrence added this upcast, we can do better than this in Swift though
        let upcastingCallback: (Any) -> Void = { item in
            guard let presenceMessages = item as? ARTErrorInfo? else {
                preconditionFailure()
            }
            callback(presenceMessages)
        }
        _syncEventEmitter.once(ARTEvent.newWithPresenceSyncState(.failed), callback: upcastingCallback)
    }
}

// MARK: - ARTEvent Extensions

// swift-migration: original location ARTRealtimePresence.m, line 981
internal func ARTPresenceSyncStateToStr(_ state: ARTPresenceSyncState) -> String {
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
