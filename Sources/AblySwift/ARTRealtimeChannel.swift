import Foundation

// MARK: - ARTRealtimeChannelProtocol

// swift-migration: original location ARTRealtimeChannel.h, line 23
/**
 The protocol upon which the `ARTRealtimeChannel` is implemented. Also embeds `ARTEventEmitter`.
 */
public protocol ARTRealtimeChannelProtocol: ARTChannelProtocol {
    
    // swift-migration: original location ARTRealtimeChannel.h, line 28
    /**
     * The current `ARTRealtimeChannelState` of the channel.
     */
    var state: ARTRealtimeChannelState { get }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 33
    /**
     * An `ARTChannelProperties` object.
     */
    var properties: ARTChannelProperties { get }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 38
    /**
     * An `ARTErrorInfo` object describing the last error which occurred on the channel, if any.
     */
    var errorReason: ARTErrorInfo? { get }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 41
    /// :nodoc: TODO: docstring
    var options: ARTRealtimeChannelOptions? { get }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 46
    /**
     * A shortcut for the `-[ARTRealtimeChannelProtocol attach:]` method.
     */
    func attach()
    
    // swift-migration: original location ARTRealtimeChannel.h, line 53
    /**
     * Attach to this channel ensuring the channel is created in the Ably system and all messages published on the channel are received by any channel listeners registered using `-[ARTRealtimeChannelProtocol subscribe:]`. Any resulting channel state change will be emitted to any listeners registered using the `-[ARTEventEmitter on:]` or `-[ARTEventEmitter once:]` methods. A callback may optionally be passed in to this call to be notified of success or failure of the operation. As a convenience, `attach:` is called implicitly if `-[ARTRealtimeChannelProtocol subscribe:]` is called on the channel or `-[ARTRealtimePresenceProtocol subscribe:]` is called on the `ARTRealtimePresence` object for this channel, unless you've set the `ARTRealtimeChannelOptions.attachOnSubscribe` channel option to `false`. It is also called implicitly if `-[ARTRealtimePresenceProtocol enter:]` is called on the `ARTRealtimePresence` object for this channel.
     *
     * @param callback A success or failure callback function.
     */
    func attach(_ callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimeChannel.h, line 58
    /**
     * A shortcut for the `-[ARTRealtimeChannelProtocol detach:]` method.
     */
    func detach()
    
    // swift-migration: original location ARTRealtimeChannel.h, line 65
    /**
     * Detach from this channel. Any resulting channel state change is emitted to any listeners registered using the `-[ARTEventEmitter on:]` or `-[ARTEventEmitter once:]` methods. A callback may optionally be passed in to this call to be notified of success or failure of the operation. Once all clients globally have detached from the channel, the channel will be released in the Ably service within two minutes.
     *
     * @param callback A success or failure callback function.
     */
    func detach(_ callback: ARTCallback?)
    
    // swift-migration: original location ARTRealtimeChannel.h, line 76
    /**
     * Registers a listener for messages on this channel. The caller supplies a listener function, which is called each time one or more messages arrives on the channel.
     *
     * @param callback An event listener function.
     *
     * @return An `ARTEventListener` object.
     *
     * @see See `subscribeWithAttachCallback:` for more details.
     */
    @discardableResult
    func subscribe(_ callback: @escaping ARTMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimeChannel.h, line 87
    /**
     * Registers a listener for messages on this channel. The caller supplies a listener function, which is called each time one or more messages arrives on the channel.
     * An attach callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannelProtocol attach]` operation. It will not be called if the `ARTRealtimeChannelOptions.attachOnSubscribe` channel option is set to `false`.
     *
     * @param onAttach An attach callback function.
     * @param callback An event listener function.
     *
     * @return An `ARTEventListener` object.
     */
    @discardableResult
    func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimeChannel.h, line 99
    /**
     * Registers a listener for messages with a given event `name` on this channel. The caller supplies a listener function, which is called each time one or more matching messages arrives on the channel.
     *
     * @param name The event name.
     * @param callback An event listener function.
     *
     * @return An `ARTEventListener` object.
     *
     * @see See `subscribeWithAttachCallback:` for more details.
     */
    @discardableResult
    func subscribe(_ name: String, callback: @escaping ARTMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimeChannel.h, line 109
    /**
     * Registers a listener for messages with a given event `name` on this channel. The caller supplies a listener function, which is called each time one or more matching messages arrives on the channel. A callback may optionally be passed in to this call to be notified of success or failure of the channel `-[ARTRealtimeChannelProtocol attach]` operation. It will not be called if the `ARTRealtimeChannelOptions.attachOnSubscribe` channel option is set to `false`.
     *
     * @param name The event name.
     * @param callback An event listener function.
     *
     * @return An `ARTEventListener` object.
     */
    @discardableResult
    func subscribe(_ name: String, onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimeChannel.h, line 114
    /**
     * Deregisters all listeners to messages on this channel. This removes all earlier subscriptions.
     */
    func unsubscribe()
    
    // swift-migration: original location ARTRealtimeChannel.h, line 121
    /**
     * Deregisters the given listener (for any/all event names). This removes an earlier subscription.
     *
     * @param listener An event listener object to unsubscribe.
     */
    func unsubscribe(_ listener: ARTEventListener?)
    
    // swift-migration: original location ARTRealtimeChannel.h, line 129
    /**
     * Deregisters the given listener for the specified event name. This removes an earlier event-specific subscription.
     *
     * @param name The event name.
     * @param listener An event listener object to unsubscribe.
     */
    func unsubscribe(_ name: String, listener: ARTEventListener?)
    
    // swift-migration: original location ARTRealtimeChannel.h, line 140
    /**
     * Retrieves an `ARTPaginatedResult` object, containing an array of historical `ARTMessage` objects for the channel. If the channel is configured to persist messages, then messages can be retrieved from history for up to 72 hours in the past. If not, messages can only be retrieved from history for up to two minutes in the past.
     *
     * @param query An `ARTRealtimeHistoryQuery` object.
     * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTMessage` objects.
     * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
     *
     * @return In case of failure returns `false` and the error information can be retrived via the `error` parameter.
     */
    // swift-migration: Per PRD requirements, converting from NSError** pattern to Swift throws
    func history(_ query: ARTRealtimeHistoryQuery?) throws -> ARTPaginatedResult<ARTMessage>
    
    // swift-migration: original location ARTRealtimeChannel.h, line 148
    /**
     * Sets the `ARTRealtimeChannelOptions` for the channel. An optional callback may be provided to notify of the success or failure of the operation.
     *
     * @param options An `ARTRealtimeChannelOptions` object.
     * @param callback A success or failure callback function.
     */
    func setOptions(_ options: ARTRealtimeChannelOptions?, callback: ARTCallback?)
    
    // MARK: ARTEventEmitter
    
    // swift-migration: original location ARTRealtimeChannel.h, line 156
    /**
     * `ARTRealtimeChannel` implements `ARTEventEmitter` and emits `ARTChannelEvent` events, where a `ARTChannelEvent` is either a `ARTRealtimeChannelState` or an `ARTChannelEventUpdate`.
     */
    @discardableResult
    func on(_ event: ARTChannelEvent, callback: @escaping ARTChannelStateCallback) -> ARTEventListener
    
    // swift-migration: original location ARTRealtimeChannel.h, line 157  
    @discardableResult
    func on(_ cb: @escaping ARTChannelStateCallback) -> ARTEventListener
    
    // swift-migration: original location ARTRealtimeChannel.h, line 159
    @discardableResult
    func once(_ event: ARTChannelEvent, callback: @escaping ARTChannelStateCallback) -> ARTEventListener
    
    // swift-migration: original location ARTRealtimeChannel.h, line 160
    @discardableResult
    func once(_ cb: @escaping ARTChannelStateCallback) -> ARTEventListener
    
    // swift-migration: original location ARTRealtimeChannel.h, line 162
    func off(_ event: ARTChannelEvent, listener: ARTEventListener)
    
    // swift-migration: original location ARTRealtimeChannel.h, line 163
    func off(_ listener: ARTEventListener)
    
    // swift-migration: original location ARTRealtimeChannel.h, line 164
    func off()
}

// MARK: - ARTRealtimeChannel

// swift-migration: original location ARTRealtimeChannel.h, line 192 and ARTRealtimeChannel.m, line 43
/**
 * Enables messages to be published and subscribed to. Also enables historic messages to be retrieved and provides access to the `ARTRealtimePresence` object of a channel.
 * Also implements `ARTEventEmitter` interface and emits `ARTChannelEvent` events, where a `ARTChannelEvent` is either a `ARTRealtimeChannelState` or an `ARTChannelEvent.ARTChannelEventUpdate`.
 */
public class ARTRealtimeChannel: NSObject, ARTRealtimeChannelProtocol, @unchecked Sendable {

    // MARK: - Private Properties
    private let _internal: ARTRealtimeChannelInternal
    private let _realtimeInternal: ARTRealtimeInternal
    private let _dealloc: ARTQueuedDealloc
    
    // MARK: - Initialization
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 162 and ARTRealtimeChannel.m, line 59
    internal init(internal: ARTRealtimeChannelInternal, realtimeInternal: ARTRealtimeInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = `internal`
        self._realtimeInternal = realtimeInternal
        self._dealloc = queuedDealloc
        super.init()
    }
    
    // MARK: - Internal Helper Methods
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 159 and ARTRealtimeChannel.m, line 47
    internal func internalAsync(_ use: @escaping (ARTRealtimeChannelInternal) -> Void) {
        _internal.queue.async {
            use(self._internal)
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 160 and ARTRealtimeChannel.m, line 53  
    internal func internalSync(_ use: @escaping (ARTRealtimeChannelInternal) -> Void) {
        _internal.queue.sync {
            use(self._internal)
        }
    }
    
    // MARK: - ARTRealtimeChannelProtocol Implementation
    
    // swift-migration: original location ARTRealtimeChannel.h, line 28 and ARTRealtimeChannel.m, line 73
    public var state: ARTRealtimeChannelState {
        return _internal.state
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 33 and ARTRealtimeChannel.m, line 77
    public var properties: ARTChannelProperties {
        return _internal.properties
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 38 and ARTRealtimeChannel.m, line 81
    public var errorReason: ARTErrorInfo? {
        return _internal.errorReason
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 41 and ARTRealtimeChannel.m, line 225
    public var options: ARTRealtimeChannelOptions? {
        return getOptions()
    }
    
    // MARK: - Channel Name (from ARTChannelProtocol)
    
    // swift-migration: original location ARTRealtimeChannel.m, line 69
    public var name: String {
        return _internal.name
    }
    
    // MARK: - Associated Objects
    
    // swift-migration: original location ARTRealtimeChannel.h, line 197 and ARTRealtimeChannel.m, line 85
    public var presence: ARTRealtimePresence {
        return ARTRealtimePresence(internal: _internal.presence, queuedDealloc: _dealloc)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 202 and ARTRealtimeChannel.m, line 89
    public var annotations: ARTRealtimeAnnotations {
        return ARTRealtimeAnnotations(internal: _internal.annotations, queuedDealloc: _dealloc)
    }
    
    #if os(iOS)
    // swift-migration: original location ARTRealtimeChannel.h, line 208 and ARTRealtimeChannel.m, line 95
    public var push: ARTPushChannel {
        return ARTPushChannel(internal: _internal.push, queuedDealloc: _dealloc)
    }
    #endif
    
    // MARK: - Attach/Detach Methods
    
    // swift-migration: original location ARTRealtimeChannel.h, line 46 and ARTRealtimeChannel.m, line 149
    public func attach() {
        _internal.attach()
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 53 and ARTRealtimeChannel.m, line 153
    public func attach(_ callback: ARTCallback?) {
        _internal.attach(callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 58 and ARTRealtimeChannel.m, line 157
    public func detach() {
        _internal.detach()
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 65 and ARTRealtimeChannel.m, line 161
    public func detach(_ callback: ARTCallback?) {
        _internal.detach(callback)
    }
    
    // MARK: - Publishing Methods
    
    // swift-migration: original location ARTRealtimeChannel.m, line 101
    public func publish(_ name: String?, data: Any?) {
        _internal.publish(name, data: data)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 105
    public func publish(_ name: String?, data: Any?, callback: ARTCallback?) {
        _internal.publish(name, data: data, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 109
    public func publish(_ name: String?, data: Any?, clientId: String) {
        _internal.publish(name, data: data, clientId: clientId)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 113
    public func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?) {
        _internal.publish(name, data: data, clientId: clientId, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 117
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?) {
        _internal.publish(name, data: data, extras: extras)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 121
    public func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        _internal.publish(name, data: data, extras: extras, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 125
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?) {
        _internal.publish(name, data: data, clientId: clientId, extras: extras)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 129
    public func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        _internal.publish(name, data: data, clientId: clientId, extras: extras, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 133
    public func publish(_ messages: [ARTMessage]) {
        _internal.publish(messages)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 137
    public func publish(_ messages: [ARTMessage], callback: ARTCallback?) {
        _internal.publish(messages, callback: callback)
    }
    
    // MARK: - History Methods
    
    // swift-migration: original location ARTRealtimeChannel.m, line 141
    public func history(_ callback: @escaping ARTPaginatedMessagesCallback) {
        _internal.historyWithWrapperSDKAgents(nil, completion: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 141
    // swift-migration: Per PRD requirements, making this a simple Swift throwing method instead of NSError pointer
    public func history() throws -> ARTPaginatedResult<ARTMessage> {
        return try _internal.history()
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 140 and ARTRealtimeChannel.m, line 193
    // swift-migration: Per PRD requirements, converting from NSError** pattern to Swift throws
    public func history(_ query: ARTRealtimeHistoryQuery?) throws -> ARTPaginatedResult<ARTMessage> {
        return try _internal.history(query)
    }
    
    // MARK: - Subscribe/Unsubscribe Methods
    
    // swift-migration: original location ARTRealtimeChannel.h, line 76 and ARTRealtimeChannel.m, line 165
    @discardableResult
    public func subscribe(_ callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _internal.subscribe(callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 87 and ARTRealtimeChannel.m, line 169
    @discardableResult
    public func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _internal.subscribeWithAttachCallback(onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 99 and ARTRealtimeChannel.m, line 173
    @discardableResult
    public func subscribe(_ name: String, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _internal.subscribe(name, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 109 and ARTRealtimeChannel.m, line 177
    @discardableResult
    public func subscribe(_ name: String, onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _internal.subscribe(name, onAttach: onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 114 and ARTRealtimeChannel.m, line 181
    public func unsubscribe() {
        _internal.unsubscribe()
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 121 and ARTRealtimeChannel.m, line 185
    public func unsubscribe(_ listener: ARTEventListener?) {
        _internal.unsubscribe(listener)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 129 and ARTRealtimeChannel.m, line 189
    public func unsubscribe(_ name: String, listener: ARTEventListener?) {
        _internal.unsubscribe(name, listener: listener)
    }
    
    // MARK: - Event Emitter Methods
    
    // swift-migration: original location ARTRealtimeChannel.h, line 156 and ARTRealtimeChannel.m, line 197
    @discardableResult
    public func on(_ cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return _internal.on(cb)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 156 and ARTRealtimeChannel.m, line 221
    @discardableResult
    public func on(_ event: ARTChannelEvent, callback cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return _internal.on(event, callback: cb)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 159 and ARTRealtimeChannel.m, line 201
    @discardableResult
    public func once(_ event: ARTChannelEvent, callback cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return _internal.once(event, callback: cb)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 160 and ARTRealtimeChannel.m, line 205
    @discardableResult  
    public func once(_ cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return _internal.once(cb)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 162 and ARTRealtimeChannel.m, line 209
    public func off(_ event: ARTChannelEvent, listener: ARTEventListener) {
        _internal.off(event, listener: listener)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 163 and ARTRealtimeChannel.m, line 213
    public func off(_ listener: ARTEventListener) {
        _internal.off(listener)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 164 and ARTRealtimeChannel.m, line 217
    public func off() {
        _internal.off()
    }
    
    // MARK: - Options Methods
    
    // swift-migration: original location ARTRealtimeChannel.m, line 225
    public func getOptions() -> ARTRealtimeChannelOptions? {
        return _internal.getOptions()
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 148 and ARTRealtimeChannel.m, line 229
    public func setOptions(_ options: ARTRealtimeChannelOptions?, callback: ARTCallback?) {
        _internal.setOptions(options, callback: callback)
    }
    
    // MARK: - Utility Methods
    
    // swift-migration: original location ARTRealtimeChannel.m, line 145
    public func exceedMaxSize(_ messages: [ARTBaseMessage]) -> Bool {
        return _internal.exceedMaxSize(messages)
    }
}

// MARK: - ARTChannelProperties

// swift-migration: original location ARTRealtimeChannel.h, line 172 and ARTRealtimeChannel.m, line 1240
/**
 * Describes the properties of the channel state.
 */
public class ARTChannelProperties: NSObject {
    
    // swift-migration: original location ARTRealtimeChannel.h, line 176 and ARTRealtimeChannel.m, line 1245
    /**
     * Starts unset when a channel is instantiated, then updated with the `channelSerial` from each `ARTChannelEventAttached` event that matches the channel. Used as the value for `ARTRealtimeHistoryQuery.untilAttach`.
     */
    public let attachSerial: String?
    
    // swift-migration: original location ARTRealtimeChannel.h, line 180 and ARTRealtimeChannel.m, line 1246
    /**
     * Updated by the framework whenever there is some activity on the channel (user message received, presence updated or a channel attached).
     */
    public let channelSerial: String?
    
    // swift-migration: original location ARTRealtimeChannel.h, line 183 and ARTRealtimeChannel.m, line 1242
    // Exposed for mocking/testing purposes in conjunction with `ARTRealtimeChannelProtocol`.
    public init(attachSerial: String?, channelSerial: String?) {
        self.attachSerial = attachSerial
        self.channelSerial = channelSerial
        super.init()
    }
}

// MARK: - ARTEvent (ChannelEvent)

// swift-migration: original location ARTRealtimeChannel.h, line 216 and ARTRealtimeChannel.m, line 1255
extension ARTEvent {
    
    // swift-migration: original location ARTRealtimeChannel.h, line 217 and ARTRealtimeChannel.m, line 1257
    public convenience init(channelEvent: ARTChannelEvent) {
        let eventString = String(format: "ARTChannelEvent%@", ARTChannelEventToStr(channelEvent))
        self.init(string: eventString)
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 218 and ARTRealtimeChannel.m, line 1261
    public class func newWithChannelEvent(_ value: ARTChannelEvent) -> ARTEvent {
        return ARTEvent(channelEvent: value)
    }
}

// MARK: - ARTRealtimeChannelInternal Placeholder

// swift-migration: Lawrence — this doesn't have the correct migration comment because of the piecemeal way in which I migrated this class
internal class ARTRealtimeChannelInternal: ARTChannel, APRealtimeChannel {

    // MARK: - Basic Stored Properties
    
    // swift-migration: original location ARTRealtimeChannel.m, line 263 (ivar _queue)
    internal var _queue: DispatchQueue
    
    // swift-migration: original location ARTRealtimeChannel.m, line 264 (ivar _userQueue)
    internal var _userQueue: DispatchQueue
    
    // swift-migration: original location ARTRealtimeChannel.m, line 265 (ivar _errorReason)
    private var _errorReason: ARTErrorInfo?
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 48 (weak property)
    internal weak var realtime: ARTRealtimeInternal?
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 49 (readonly property)
    internal var restChannel: ARTRestChannelInternal!

    // swift-migration: original location ARTRealtimeChannel+Private.h, line 50 (readwrite property)
    internal var attachSerial: String?
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 51 (readwrite property)
    internal var channelSerial: String?
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 57 (readwrite property)
    internal var attachResume: Bool = false

    // swift-migration: original location ARTRealtimeChannel.m, line 255 (readonly property)
    private var _attachRetryState: ARTAttachRetryState!

    // swift-migration: original location ARTRealtimeChannel.m, line 256 (readonly property)
    private var _pluginData: [String: Any]
    
    // MARK: - Instance Variables from Interface
    
    // swift-migration: original location ARTRealtimeChannel.m, line 236 (ivar)
    private var _realtimePresence: ARTRealtimePresenceInternal!

    // swift-migration: original location ARTRealtimeChannel.m, line 237 (ivar)
    private var _realtimeAnnotations: ARTRealtimeAnnotationsInternal!

    #if os(iOS)
    // swift-migration: original location ARTRealtimeChannel.m, line 239 (ivar)
    private var _pushChannel: ARTPushChannelInternal?
    #endif
    
    // swift-migration: original location ARTRealtimeChannel.m, line 241 (ivar)
    private var _attachTimer: CFRunLoopTimer?
    
    // swift-migration: original location ARTRealtimeChannel.m, line 242 (ivar)
    private var _detachTimer: CFRunLoopTimer?
    
    // swift-migration: original location ARTRealtimeChannel.m, line 243 (ivar)
    private var _attachedEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>
    
    // swift-migration: original location ARTRealtimeChannel.m, line 244 (ivar)
    private var _detachedEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo>
    
    // swift-migration: original location ARTRealtimeChannel.m, line 245 (ivar)
    private var _lastPayloadMessageId: String?
    
    // swift-migration: original location ARTRealtimeChannel.m, line 246 (ivar)
    private var _decodeFailureRecoveryInProgress: Bool = false

    // MARK: - Event Emitters
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 53 (readonly property)
    internal var internalEventEmitter: ARTEventEmitter<ARTEvent, ARTChannelStateChange>
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 54 (readonly property)
    internal var statesEventEmitter: ARTEventEmitter<ARTEvent, ARTChannelStateChange>
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 55 (readonly property)
    // swift-migration: Lawrence changed this type
    internal var messagesEventEmitter: ARTEventEmitter<String, ARTMessage>

    // swift-migration: original location ARTRealtimeChannel+Private.h, line 59 and ARTRealtimeChannel.m, line 268
    init(realtime: ARTRealtimeInternal, name: String, options: ARTRealtimeChannelOptions, logger: ARTInternalLog) {
        // swift-migration: Lawrence — some things moved around here so that we can avoid circular initialization problems (i.e. referring to self before super init called), which Swift is more strict about; we also make some properties implicitly-unwrapped optionals for the same reason

        self.realtime = realtime
        self._queue = realtime.rest.queue
        self._userQueue = realtime.rest.userQueue
        self._state = .initialized
        self.attachSerial = nil
        self._pluginData = [:]
        self.statesEventEmitter = ARTPublicEventEmitter(rest: realtime.rest, logger: logger)
        self.messagesEventEmitter = ARTInternalEventEmitter(queues: _queue, userQueue: _userQueue)
        self._attachedEventEmitter = ARTInternalEventEmitter(queue: _queue)
        self._detachedEventEmitter = ARTInternalEventEmitter(queue: _queue)
        self.internalEventEmitter = ARTInternalEventEmitter(queue: _queue)
        let attachRetryDelayCalculator = ARTBackoffRetryDelayCalculator(initialRetryTimeout: realtime.options.channelRetryTimeout,
                                                                        jitterCoefficientGenerator: realtime.options.testOptions.jitterCoefficientGenerator)

        super.init(name: name, andOptions: options, rest: realtime.rest, logger: logger)

        self.restChannel = realtime.rest.channels._getChannel(self.name, options: options, addPrefix: true)
        self._attachRetryState = ARTAttachRetryState(retryDelayCalculator: attachRetryDelayCalculator,
                                                     logger: logger,
                                                     logMessagePrefix: String(format: "RT: %p C:%p ", realtime, self))
        self._realtimePresence = ARTRealtimePresenceInternal(channel: self, logger: self.logger)
        self._realtimeAnnotations = ARTRealtimeAnnotationsInternal(channel: self, logger: self.logger)


        // We need to register the pluginAPI before the LiveObjects plugin tries to fetch it in the call to prepareChannel below (and also before the LiveObjects plugin later tries to use it in its extension of ARTRealtimeChannel).
        ARTPluginAPI.registerSelf()

        // If the LiveObjects plugin has been provided, set up LiveObjects functionality for this channel.
        let liveObjectsPlugin = realtime.options.liveObjectsPlugin
        if liveObjectsPlugin != nil {
            liveObjectsPlugin!.nosync_prepareChannel(self, client: realtime)
        }
    }

    // MARK: - Properties with Custom Getters
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 69 and ARTRealtimeChannel.m, line 303
    internal var queue: DispatchQueue {
        return _queue
    }

    // swift-migration: Lawrence: This is backing storage for `state`; for whatever reason it didn't migrate properly
    private var _state: ARTRealtimeChannelState
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 36 and ARTRealtimeChannel.m, line 303
    internal var state: ARTRealtimeChannelState {
        return _queue.sync {
            self.state_nosync
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 41 and ARTRealtimeChannel.m, line 319
    internal var state_nosync: ARTRealtimeChannelState {
        return _state
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 37 and ARTRealtimeChannel.m, line 311
    internal var errorReason: ARTErrorInfo? {
        var result: ARTErrorInfo?
        _queue.sync {
            result = self.errorReason_nosync()
        }
        return result
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 42 and ARTRealtimeChannel.m, line 345
    internal func errorReason_nosync() -> ARTErrorInfo? {
        return _errorReason
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 29 and ARTRealtimeChannel.m, line 349
    internal var presence: ARTRealtimePresenceInternal {
        return _realtimePresence
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 30 and ARTRealtimeChannel.m, line 353
    internal var annotations: ARTRealtimeAnnotationsInternal {
        return _realtimeAnnotations
    }
    
    #if os(iOS)
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 33 and ARTRealtimeChannel.m, line 358
    internal var push: ARTPushChannelInternal {
        if _pushChannel == nil {
            guard let realtime = self.realtime else {
                fatalError("ARTRealtimeChannelInternal realtime is nil")
            }
            _pushChannel = ARTPushChannelInternal(rest: realtime.rest, channel: self, logger: self.logger)
        }
        return _pushChannel!
    }
    #endif
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 44 and ARTRealtimeChannel.m, line 334
    internal var shouldAttach: Bool {
        switch state_nosync {
        case .initialized, .detaching, .detached:
            return true
        default:
            return false
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 44 and ARTRealtimeChannel.m, line 323
    internal func canBeReattached() -> Bool {
        switch state_nosync {
        case .attaching, .attached, .suspended:
            return true
        default:
            return false
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 52 and ARTRealtimeChannel.m, line 1125
    internal var clientId: String? {
        return getClientId()
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 43 and ARTRealtimeChannel.m, line 1129
    internal var clientId_nosync: String? {
        guard let realtime = self.realtime else { return nil }
        return realtime.rest.auth.clientId_nosync()
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1125
    private func getClientId() -> String? {
        var result: String?
        _queue.sync {
            result = self.clientId_nosync
        }
        return result
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 39 and ARTRealtimeChannel.m, line 1156
    internal var connectionId: String {
        guard let realtime = self.realtime else { return "" }
        return realtime.connection.id ?? ""
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 71 and ARTRealtimeChannel.m, line 1177
    internal var properties: ARTChannelProperties {
        return _queue.sync {
            self.properties_nosync
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 46 and ARTRealtimeChannel.m, line 1185
    internal var properties_nosync: ARTChannelProperties {
        return ARTChannelProperties(attachSerial: self.attachSerial, channelSerial: self.channelSerial)
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 73 and ARTRealtimeChannel.m, line 1169
    internal override var options: ARTRealtimeChannelOptions? {
        return getOptions()
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1169
    internal func getOptions() -> ARTRealtimeChannelOptions? {
        var result: ARTRealtimeChannelOptions?
        _queue.sync {
            result = self.getOptions_nosync()
        }
        return result
    }
    
    // swift-migration: original location ARTRealtimeChannel+Private.h, line 38 and ARTRealtimeChannel.m, line 1173
    internal func getOptions_nosync() -> ARTRealtimeChannelOptions? {
        return super.options as? ARTRealtimeChannelOptions
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 255
    internal var attachRetryState: ARTAttachRetryState {
        return _attachRetryState
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 256
    internal var pluginData: [String: Any] {
        return _pluginData
    }
    
    // MARK: - Methods needed by ARTRealtimeChannel
    
    internal func attach() {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func attach(_ callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func _attach(_ callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func detach() {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func detach(_ callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func _detach(_ callback: @escaping (ARTErrorInfo?) -> Void) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    internal override func publish(_ name: String?, data: Any?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ name: String?, data: Any?, callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ name: String?, data: Any?, clientId: String) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ name: String?, data: Any?, clientId: String, callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ name: String?, data: Any?, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ name: String?, data: Any?, clientId: String, extras: ARTJsonCompatible?, callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ messages: [ARTMessage]) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func publish(_ messages: [ARTMessage], callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }

    // swift-migration: Per PRD requirements, making history methods throw instead of using NSError pointers
    internal func history() throws -> ARTPaginatedResult<ARTMessage> {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func history(_ query: ARTRealtimeHistoryQuery?) throws -> ARTPaginatedResult<ARTMessage> {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func historyWithWrapperSDKAgents(_ wrapperSDKAgents: NSStringDictionary?, completion callback: @escaping ARTPaginatedMessagesCallback) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func subscribe(_ callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func subscribe(_ name: String, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func subscribe(_ name: String, onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func unsubscribe() {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func unsubscribe(_ listener: ARTEventListener?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func unsubscribe(_ name: String, listener: ARTEventListener?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func on(_ cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func on(_ event: ARTChannelEvent, callback cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func once(_ event: ARTChannelEvent, callback cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    @discardableResult
    internal func once(_ cb: @escaping ARTChannelStateCallback) -> ARTEventListener {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func off(_ event: ARTChannelEvent, listener: ARTEventListener) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func off(_ listener: ARTEventListener) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func off() {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func off_nosync() {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func _unsubscribe() {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }

    internal func setOptions(_ options: ARTRealtimeChannelOptions?, callback: ARTCallback?) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal override func exceedMaxSize(_ messages: [ARTBaseMessage]) -> Bool {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
    
    internal func emit(_ event: ARTChannelEvent, with data: ARTChannelStateChange) {
        fatalError("ARTRealtimeChannelInternal not yet migrated")
    }
}
