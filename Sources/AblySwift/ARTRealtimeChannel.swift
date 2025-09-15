import Foundation
import _AblyPluginSupportPrivate

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
        // swift-migration: Lawrence - need to implement a synchronous throws version
        fatalError("Not yet implemented - need synchronous history method")
    }
    
    // swift-migration: original location ARTRealtimeChannel.h, line 140 and ARTRealtimeChannel.m, line 193
    // swift-migration: Per PRD requirements, converting from NSError** pattern to Swift throws
    public func history(_ query: ARTRealtimeHistoryQuery?) throws -> ARTPaginatedResult<ARTMessage> {
        // swift-migration: Lawrence - need to implement a synchronous throws version
        fatalError("Not yet implemented - need synchronous history method")
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
    // swift-migration: nullability of error changed by Lawrence
    private var _attachedEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo?>

    // swift-migration: original location ARTRealtimeChannel.m, line 244 (ivar)
    // swift-migration: nullability of error changed by Lawrence
    private var _detachedEventEmitter: ARTEventEmitter<ARTEvent, ARTErrorInfo?>

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
    init(realtime: ARTRealtimeInternal, name: String, options: ARTRealtimeChannelOptions, logger: InternalLog) {
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
        let attachRetryDelayCalculator = BackoffRetryDelayCalculator(initialRetryTimeout: realtime.options.channelRetryTimeout,
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

    // swift-migration: Lawrence got rid of the connectionId property because wasn't being used and this ?? "" is suspicious
//    // swift-migration: original location ARTRealtimeChannel+Private.h, line 39 and ARTRealtimeChannel.m, line 1156
//    internal var connectionId: String {
//        guard let realtime = self.realtime else { return "" }
//        return realtime.connection.id ?? ""
//    }
    
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
    
    // MARK: - ARTRealtimeChannelInternal Methods
    
    // swift-migration: original location ARTRealtimeChannel.m, line 366
    internal func internalPostMessages(_ data: Any, callback: @escaping ARTCallback) {
        var callbackWrapper: ARTCallback? = callback
        if callbackWrapper != nil {
            let userCallback = callbackWrapper!
            callbackWrapper = { error in
                self._userQueue.async {
                    userCallback(error)
                }
            }
        }
        
        var messageData = data
        if !(messageData is [Any]) {
            messageData = [messageData]
        }
        
        _queue.sync {
            if let message = messageData as? ARTMessage {
                if let messageClientId = message.clientId,
                   let authClientId = self.realtime?.rest.auth.clientId_nosync(),
                   messageClientId != authClientId {
                    if let callback = callbackWrapper {
                        callback(ARTErrorInfo.create(withCode: ARTState.mismatchedClientId.rawValue, message: "attempted to publish message with an invalid clientId"))
                    }
                    return
                }
            } else if let messages = messageData as? [ARTMessage] {
                for message in messages {
                    if let messageClientId = message.clientId,
                       let authClientId = self.realtime?.rest.auth.clientId_nosync(),
                       messageClientId != authClientId {
                        if let callback = callbackWrapper {
                            callback(ARTErrorInfo.create(withCode: ARTState.mismatchedClientId.rawValue, message: "attempted to publish message with an invalid clientId"))
                        }
                        return
                    }
                }
            }
            
            guard let realtime = self.realtime else {
                if let callback = callbackWrapper {
                    callback(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailed.rawValue, message: "realtime connection is nil"))
                }
                return
            }
            
            if !realtime.connection.isActive_nosync {
                if let callback = callbackWrapper {
                    callback(realtime.connection.error_nosync)
                }
                return
            }
            
            let pm = ARTProtocolMessage()
            pm.action = .message
            pm.channel = self.name
            pm.messages = messageData as? [ARTMessage]
            
            self.publishProtocolMessage(pm) { status in
                if let callback = callbackWrapper {
                    callback(status.errorInfo)
                }
            }
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 418
    internal func sendObject(withObjectMessages objectMessages: [_AblyPluginSupportPrivate.ObjectMessageProtocol], completion: @escaping ARTCallback) {
        let pm = ARTProtocolMessage()
        pm.action = .object
        pm.channel = self.name
        pm.state = objectMessages
        
        publishProtocolMessage(pm) { status in
            completion(status.errorInfo)
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 432
    internal func publishProtocolMessage(_ pm: ARTProtocolMessage, callback: @escaping ARTStatusCallback) {
        switch self.state_nosync {
        case .suspended, .failed:
            let errorMessage = "channel operation failed (invalid channel state: \(ARTRealtimeChannelStateToStr(self.state_nosync)))"
            let statusInvalidChannelState = ARTStatus(state: .error, errorInfo: ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailedInvalidState.rawValue, message: errorMessage))
            callback(statusInvalidChannelState)
        case .initialized, .detaching, .detached, .attaching, .attached:
            guard let realtime = self.realtime else {
                let status = ARTStatus(state: .error, errorInfo: ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailed.rawValue, message: "realtime connection is nil"))
                callback(status)
                return
            }
            realtime.send(pm, sentCallback: nil) { status in
                callback(status)
            }
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 455
    internal func _subscribe(_ name: String?, onAttach: ARTCallback?, callback: ARTMessageCallback?) -> ARTEventListener? {
        var messageCallback = callback
        if messageCallback != nil {
            let userCallback = messageCallback!
            messageCallback = { message in
                if self.state_nosync != .attached { // RTL17
                    return
                }
                self._userQueue.async {
                    userCallback(message)
                }
            }
        }
        
        var attachCallback = onAttach
        if attachCallback != nil {
            let userOnAttach = attachCallback!
            attachCallback = { error in
                self._userQueue.async {
                    userOnAttach(error)
                }
            }
        }
        
        var listener: ARTEventListener?
        _queue.sync {
            let options = self.getOptions_nosync()
            let attachOnSubscribe = options?.attachOnSubscribe ?? true
            
            if self.state_nosync == .failed {
                if let onAttach = attachCallback, attachOnSubscribe { // RTL7h
                    onAttach(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailedInvalidState.rawValue, message: "attempted to subscribe while channel is in FAILED state."))
                }
                ARTLogWarn(self.logger, "\(pointer: self.realtime) C:\(pointer: self) (\(self.name)) subscribe of '\(name ?? "all")' has been ignored (attempted to subscribe while channel is in FAILED state)")
                return
            }
            
            if self.shouldAttach && attachOnSubscribe { // RTL7g
                self._attach(attachCallback)
            }
            
            if let name = name {
                listener = self.messagesEventEmitter.on(name, callback: messageCallback)
            } else {
                listener = self.messagesEventEmitter.on(messageCallback)
            }
            
            ARTLogVerbose(self.logger, "\(pointer: self.realtime) C:\(pointer: self) (\(self.name)) subscribe to '\(name ?? "all")' event(s)")
        }
        
        return listener
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 496
    internal func subscribe(_ callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _subscribe(nil, onAttach: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 500
    internal func subscribeWithAttachCallback(_ onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _subscribe(nil, onAttach: onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 504
    internal func subscribe(_ name: String, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _subscribe(name, onAttach: nil, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 508
    internal func subscribe(_ name: String, onAttach: ARTCallback?, callback: @escaping ARTMessageCallback) -> ARTEventListener? {
        return _subscribe(name, onAttach: onAttach, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 512
    internal func unsubscribe() {
        _queue.sync {
            self._unsubscribe()
            ARTLogVerbose(self.logger, "\(pointer: self.realtime) C:\(pointer: self) (\(self.name)) unsubscribe to all events")
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 519
    internal func _unsubscribe() {
        messagesEventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 523
    internal func unsubscribe(_ listener: ARTEventListener?) {
        _queue.sync {
            self.messagesEventEmitter.off(listener)
            ARTLogVerbose(self.logger, "RT:\(pointer: self.realtime) C:\(pointer: self) (\(self.name)) unsubscribe to all events")
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 530
    internal func unsubscribe(_ name: String, listener: ARTEventListener?) {
        _queue.sync {
            self.messagesEventEmitter.off(name, listener: listener)
            ARTLogVerbose(self.logger, "RT:\(pointer: self.realtime) C:\(pointer: self) (\(self.name)) unsubscribe to event '\(name)'")
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 537
    internal func on(_ event: ARTChannelEvent, callback: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return statesEventEmitter.on(ARTEvent.newWithChannelEvent(event), callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 541
    internal func on(_ callback: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return statesEventEmitter.on(callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 545
    internal func once(_ event: ARTChannelEvent, callback: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return statesEventEmitter.once(ARTEvent.newWithChannelEvent(event), callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 549
    internal func once(_ callback: @escaping ARTChannelStateCallback) -> ARTEventListener {
        return statesEventEmitter.once(callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 553
    internal func off() {
        statesEventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 558
    internal func off_nosync() {
        (statesEventEmitter as? ARTPublicEventEmitter)?.off_nosync()
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 562
    internal func off(_ event: ARTChannelEvent, listener: ARTEventListener) {
        statesEventEmitter.off(ARTEvent.newWithChannelEvent(event), listener: listener)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 566
    internal func off(_ listener: ARTEventListener) {
        statesEventEmitter.off(listener)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 570
    internal func emit(_ event: ARTChannelEvent, with data: ARTChannelStateChange) {
        statesEventEmitter.emit(ARTEvent.newWithChannelEvent(event), with: data)
        internalEventEmitter.emit(ARTEvent.newWithChannelEvent(event), with: data)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 575
    internal func performTransitionToState(_ state: ARTRealtimeChannelState, withParams params: ARTChannelStateChangeParams) {
        guard let realtime = self.realtime else { return }
        
        ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) channel state transitions from \(self.state_nosync.rawValue) - \(ARTRealtimeChannelStateToStr(self.state_nosync)) to \(state.rawValue) - \(ARTRealtimeChannelStateToStr(state))\(params.retryAttempt != nil ? " (result of \(params.retryAttempt!.id))" : "")")
        
        let stateChange = ARTChannelStateChange(current: state, previous: self.state_nosync, event: ARTChannelEvent(rawValue: state.rawValue)!, reason: params.errorInfo, resumed: params.resumed, retryAttempt: params.retryAttempt)
        self._state = state
        
        if params.storeErrorInfo {
            self._errorReason = params.errorInfo
        }
        
        attachRetryState.channelWillTransition(to: state)
        
        var channelRetryListener: ARTEventListener?
        switch state {
        case .attached:
            self.attachResume = true
        case .suspended:
            self.channelSerial = nil // RTP5a1
            let retryAttempt = attachRetryState.addRetryAttempt()
            
            _attachedEventEmitter.emit(nil, with: params.errorInfo)
            if realtime.shouldSendEvents {
                channelRetryListener = unlessStateChangesBefore(retryAttempt.delay) {
                    ARTLogDebug(self.logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) reattach initiated by retry timeout, acting on retry attempt \(retryAttempt.id)")
                    let attachParams = ARTAttachRequestParams(reason: nil, channelSerial: nil, retryAttempt: retryAttempt)
                    self.reattach(withParams: attachParams)
                }
            }
        case .detaching:
            self.attachResume = false
        case .detached:
            self.channelSerial = nil // RTP5a1
            // swift-migration: Unwrap added by Lawrence
            presence.failsSync(unwrapValueWithAmbiguousObjectiveCNullability(params.errorInfo)) // RTP5a
        case .failed:
            self.channelSerial = nil // RTP5a1
            self.attachResume = false
            _attachedEventEmitter.emit(nil, with: params.errorInfo)
            _detachedEventEmitter.emit(nil, with: params.errorInfo)
            // swift-migration: Unwrap added by Lawrence
            presence.failsSync(unwrapValueWithAmbiguousObjectiveCNullability(params.errorInfo)) // RTP5a
        default:
            break
        }
        
        emit(stateChange.event, with: stateChange)
        
        if let channelRetryListener = channelRetryListener {
            channelRetryListener.startTimer()
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 630
    internal func unlessStateChangesBefore(_ deadline: TimeInterval, do callback: @escaping () -> Void) -> ARTEventListener {
        return internalEventEmitter.once { _ in
            // Any state change cancels the timeout.
        }.setTimer(deadline) {
            callback()
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 640
    internal func onChannelMessage(_ message: ARTProtocolMessage) {
        guard let realtime = self.realtime else { return }
        
        ARTLogDebug(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) received channel message \(message.action.rawValue) - \(ARTProtocolMessageActionToStr(message.action))")
        
        switch message.action {
        case .attached:
            ARTLogDebug(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) \(message.description)")
            setAttached(message)
        case .detach, .detached:
            setDetached(message)
        case .message:
            if _decodeFailureRecoveryInProgress {
                ARTLogDebug(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) message decode recovery in progress, message skipped: \(message.description)")
                break
            }
            onMessage(message)
        case .presence:
            onPresence(message)
        case .annotation:
            onAnnotation(message)
        case .error:
            onError(message)
        case .sync:
            onSync(message)
        case .object:
            onObject(message)
        case .objectSync:
            onObjectSync(message)
        default:
            ARTLogWarn(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) unknown ARTProtocolMessage action: \(message.action.rawValue)")
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 682
    internal func setAttached(_ message: ARTProtocolMessage) {
        guard let realtime = self.realtime else { return }
        
        let state = self.state_nosync
        switch state {
        case .detaching, .failed:
            // Ignore
            return
        default:
            break
        }
        
        if message.resumed {
            ARTLogDebug(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) channel has resumed")
        }
        
        // RTL15a
        self.attachSerial = message.channelSerial
        // RTL15b
        if let channelSerial = message.channelSerial {
            self.channelSerial = channelSerial
        }
        
        realtime.options.liveObjectsPlugin?.nosync_onChannelAttached(self, hasObjects: message.hasObjects)
        
        if state == .attached {
            if !message.resumed { // RTL12
                if let error = message.error {
                    _errorReason = error
                }
                let stateChange = ARTChannelStateChange(current: state, previous: state, event: .update, reason: message.error, resumed: message.resumed)
                emit(stateChange.event, with: stateChange)
                presence.onAttached(message)
            }
            return
        }
        
        let params: ARTChannelStateChangeParams
        if let error = message.error {
            params = ARTChannelStateChangeParams(state: .error, errorInfo: error)
        } else {
            params = ARTChannelStateChangeParams(state: .ok)
        }
        params.resumed = message.resumed
        performTransitionToState(.attached, withParams: params)
        presence.onAttached(message)
        _attachedEventEmitter.emit(nil, with: nil)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 730
    internal func setDetached(_ message: ARTProtocolMessage) {
        guard let realtime = self.realtime else { return }
        
        switch self.state_nosync {
        case .attached, .suspended:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) reattach initiated by DETACHED message")
            let params = ARTAttachRequestParams(reason: message.error)
            reattach(withParams: params)
            return
        case .attaching:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) reattach initiated by DETACHED message but it is currently attaching")
            let state: ARTState = message.error != nil ? .error : .ok
            let params = ARTChannelStateChangeParams(state: state, errorInfo: message.error, storeErrorInfo: false)
            setSuspended(params)
            return
        case .failed:
            return
        default:
            break
        }
        
        self.attachSerial = nil
        
        let errorInfo = message.error ?? ARTErrorInfo.create(withCode: 0, message: "channel has detached")
        let params = ARTChannelStateChangeParams(state: .notAttached, errorInfo: errorInfo)
        detachChannel(params)
        _detachedEventEmitter.emit(nil, with: nil)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 762
    internal func failPendingPresence(withState state: ARTState, info: ARTErrorInfo?) {
        let status = ARTStatus(state: state, errorInfo: info)
        presence.failPendingPresence(status)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 767
    internal func detachChannel(_ params: ARTChannelStateChangeParams) {
        if self.state_nosync == .detached {
            return
        }
        failPendingPresence(withState: params.state, info: params.errorInfo) // RTP5a
        performTransitionToState(.detached, withParams: params)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 775
    internal func setFailed(_ params: ARTChannelStateChangeParams) {
        failPendingPresence(withState: params.state, info: params.errorInfo) // RTP5a
        performTransitionToState(.failed, withParams: params)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 780
    internal func setSuspended(_ params: ARTChannelStateChangeParams) {
        failPendingPresence(withState: params.state, info: params.errorInfo) // RTP5f
        performTransitionToState(.suspended, withParams: params)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 785
    internal func onMessage(_ pm: ARTProtocolMessage) {
        guard let realtime = self.realtime else { return }
        
        var i = 0
        
        if let firstMessage = pm.messages?.first,
           let extras = firstMessage.extras {
            do {
                let extrasDict = try extras.toJSON()
                
                // swift-migration: Lawrence - using do-catch instead of inout error parameter
                if let extrasDict = extrasDict {
                if let deltaDict = extrasDict["delta"] as? [String: Any],
                   let deltaFrom = deltaDict["from"] as? String,
                   let lastPayloadMessageId = _lastPayloadMessageId,
                   deltaFrom != lastPayloadMessageId {
                        let incompatibleIdError = ARTErrorInfo.create(withCode: ARTErrorCode.unableToDecodeMessage.rawValue, message: "previous id '\(lastPayloadMessageId)' is incompatible with message delta \(firstMessage)")
                        ARTLogError(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) \(incompatibleIdError.message)")
                    
                        if let messages = pm.messages {
                            for j in (i + 1)..<messages.count {
                                ARTLogVerbose(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) message skipped \(messages[j])")
                            }
                        }
                        startDecodeFailureRecovery(withErrorInfo: incompatibleIdError)
                        return
                    }
                }
            } catch let extrasDecodeError {
                ARTLogError(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) message extras \(extras) decode error: \(extrasDecodeError)")
            }
        }
        
        let dataEncoder = self.dataEncoder
        guard let messages = pm.messages else { return }
        
        for message in messages {
            var msg = message
            
            if msg.data != nil && dataEncoder != nil {
                do {
                    msg = try msg.decode(with: dataEncoder!)
                } catch let decodeError {
                    // swift-migration: Lawrence - using do-catch instead of inout error parameter
                    let errorInfo = ARTErrorInfo.wrap(ARTErrorInfo.create(withCode: ARTErrorCode.unableToDecodeMessage.rawValue, message: decodeError.localizedDescription), prepend: "Failed to decode data: ")
                    ARTLogError(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) \(errorInfo.message)")
                    _errorReason = errorInfo
                    let stateChange = ARTChannelStateChange(current: self.state_nosync, previous: self.state_nosync, event: .update, reason: errorInfo)
                    emit(stateChange.event, with: stateChange)
                    
                    if (decodeError as NSError).code == ARTErrorCode.unableToDecodeMessage.rawValue {
                        startDecodeFailureRecovery(withErrorInfo: errorInfo)
                        return
                    }
                }
            }
            
            if msg.timestamp == nil {
                msg.timestamp = pm.timestamp
            }
            if msg.id == nil {
                msg.id = "\(pm.id ?? ""):\(i)"
            }
            if msg.connectionId == nil {
                // swift-migration: unwrap added by Lawrence (the ProtocolMessage should always have a connectionID AFAIK)
                msg.connectionId = unwrapValueWithAmbiguousObjectiveCNullability(pm.connectionId)
            }
            
            _lastPayloadMessageId = msg.id
            
            messagesEventEmitter.emit(msg.name, with: msg)
            
            i += 1
        }
        
        // RTL15b
        if let channelSerial = pm.channelSerial {
            self.channelSerial = channelSerial
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 853
    internal func onPresence(_ message: ARTProtocolMessage) {
        guard let realtime = self.realtime else { return }
        
        ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) handle PRESENCE message")
        // RTL15b
        if let channelSerial = message.channelSerial {
            self.channelSerial = channelSerial
        }
        presence.onMessage(message)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 862
    internal func onAnnotation(_ message: ARTProtocolMessage) {
        guard let realtime = self.realtime else { return }
        
        ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) handle ANNOTATION message")
        // RTL15b
        if let channelSerial = message.channelSerial {
            self.channelSerial = channelSerial
        }
        annotations.onMessage(message)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 871
    internal func onSync(_ message: ARTProtocolMessage) {
        presence.onSync(message)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 875
    internal func onError(_ msg: ARTProtocolMessage) {
        let params = ARTChannelStateChangeParams(state: .error, errorInfo: msg.error)
        performTransitionToState(.failed, withParams: params)
        failPendingPresence(withState: .error, info: msg.error)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 882
    internal func onObject(_ pm: ARTProtocolMessage) {
        // RTL15b
        if let channelSerial = pm.channelSerial {
            self.channelSerial = channelSerial
        }
        
        guard let state = pm.state else {
            // Because the plugin isn't set up or because decoding failed
            return
        }
        
        guard let realtime = self.realtime else { return }
        realtime.options.liveObjectsPlugin?.nosync_handleObjectProtocolMessage(withObjectMessages: state, channel: self)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 897
    internal func onObjectSync(_ pm: ARTProtocolMessage) {
        guard let state = pm.state else {
            // Because the plugin isn't set up or because decoding failed
            return
        }
        
        guard let realtime = self.realtime else { return }
        realtime.options.liveObjectsPlugin?.nosync_handleObjectSyncProtocolMessage(withObjectMessages: state, protocolMessageChannelSerial: pm.channelSerial, channel: self)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 908
    internal func attach() {
        attach(nil)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 912
    internal func attach(_ callback: ARTCallback?) {
        var callbackWrapper = callback
        if callbackWrapper != nil {
            let userCallback = callbackWrapper!
            callbackWrapper = { error in
                self._userQueue.async {
                    userCallback(error)
                }
            }
        }
        
        _queue.sync {
            self._attach(callbackWrapper)
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 926
    internal func _attach(_ callback: ARTCallback?) {
        guard let realtime = self.realtime else { return }
        
        switch self.state_nosync {
        case .attaching:
            ARTLogVerbose(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) already attaching")
            if let callback = callback {
                _attachedEventEmitter.once(callback)
            }
            return
        case .attached:
            ARTLogVerbose(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) already attached")
            callback?(nil)
            return
        default:
            break
        }
        
        let params = ARTAttachRequestParams(reason: nil)
        internalAttach(callback, withParams: params)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 943
    internal func reattach(withParams params: ARTAttachRequestParams) {
        guard let realtime = self.realtime else { return }
        
        if canBeReattached() {
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) \(ARTRealtimeChannelStateToStr(self.state_nosync)) and will reattach")
            internalAttach(nil, withParams: params)
        } else {
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) \(ARTRealtimeChannelStateToStr(self.state_nosync)) should not reattach")
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 952
    internal func proceedAttachDetach(withParams params: ARTAttachRequestParams) {
        guard let realtime = self.realtime else { return }
        
        if self.state_nosync == .detaching {
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) \(ARTRealtimeChannelStateToStr(self.state_nosync)) proceeding with detach")
            internalDetach(nil)
        } else {
            reattach(withParams: params)
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 961
    internal func internalAttach(_ callback: ARTCallback?, withParams params: ARTAttachRequestParams) {
        guard let realtime = self.realtime else { return }
        
        switch self.state_nosync {
        case .detaching:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) attach after the completion of Detaching")
            _detachedEventEmitter.once { error in
                self._attach(callback)
            }
            return
        default:
            break
        }
        
        _errorReason = nil
        
        if !realtime.isActive {
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) can't attach when not in an active state")
            callback?(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailed.rawValue, message: "Can't attach when not in an active state"))
            return
        }
        
        if let callback = callback {
            _attachedEventEmitter.once(callback)
        }
        
        // Set state: Attaching
        if self.state_nosync != .attaching {
            let state: ARTState = params.reason != nil ? .error : .ok
            let stateChangeParams = ARTChannelStateChangeParams(state: state, errorInfo: params.reason, storeErrorInfo: false, retryAttempt: params.retryAttempt)
            performTransitionToState(.attaching, withParams: stateChangeParams)
        }
        attachAfterChecks()
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 992
    internal func attachAfterChecks() {
        guard let realtime = self.realtime else { return }
        
        let attachMessage = ARTProtocolMessage()
        attachMessage.action = .attach
        attachMessage.channel = self.name
        attachMessage.channelSerial = self.channelSerial // RTL4c1
        // swift-migration: Lawrence - using getOptions_nosync() to access ARTRealtimeChannelOptions properties (params, modes) since inherited options_nosync has type ARTChannelOptions
        attachMessage.params = getOptions_nosync()?.params
        attachMessage.flags = getOptions_nosync()?.modes.rawValue ?? 0

        if self.attachResume {
            attachMessage.flags = attachMessage.flags | ARTProtocolMessageFlag.attachResume.rawValue
        }
        
        realtime.send(attachMessage, sentCallback: { error in
            if error != nil {
                return
            }
            // Set attach timer after the connection is active
            self.unlessStateChangesBefore(realtime.options.testOptions.realtimeRequestTimeout) {
                // Timeout
                let errorInfo = ARTErrorInfo.create(withCode: ARTState.attachTimedOut.rawValue, message: "attach timed out")
                let params = ARTChannelStateChangeParams(state: .attachTimedOut, errorInfo: errorInfo)
                self.setSuspended(params)
            }.startTimer()
        }, ackCallback: nil)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1019
    internal func detach(_ callback: ARTCallback?) {
        var callbackWrapper = callback
        if callbackWrapper != nil {
            let userCallback = callbackWrapper!
            callbackWrapper = { error in
                self._userQueue.async {
                    userCallback(error)
                }
            }
        }
        
        _queue.sync {
            self._detach(callbackWrapper)
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1033
    internal func _detach(_ callback: ARTCallback?) {
        guard let realtime = self.realtime else { return }
        
        switch self.state_nosync {
        case .initialized:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) can't detach when not attached")
            callback?(nil)
            return
        case .detaching:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) already detaching")
            if let callback = callback {
                _detachedEventEmitter.once(callback)
            }
            return
        case .detached:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) already detached")
            callback?(nil)
            return
        case .suspended:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) transitions immediately to the detached")
            let params = ARTChannelStateChangeParams(state: .ok)
            performTransitionToState(.detached, withParams: params)
            callback?(nil)
            return
        case .failed:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) can't detach when in a failed state")
            callback?(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailed.rawValue, message: "can't detach when in a failed state"))
            return
        default:
            break
        }
        
        internalDetach(callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1064
    internal func internalDetach(_ callback: ARTCallback?) {
        guard let realtime = self.realtime else { return }
        
        switch self.state_nosync {
        case .attaching:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) waiting for the completion of the attaching operation")
            _attachedEventEmitter.once { errorInfo in
                if let callback = callback, let errorInfo = errorInfo {
                    callback(errorInfo)
                    return
                }
                self._detach(callback)
            }
            return
        default:
            break
        }
        
        _errorReason = nil
        
        if !realtime.isActive {
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) can't detach when not in an active state")
            callback?(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailed.rawValue, message: "Can't detach when not in an active state"))
            return
        }
        
        if let callback = callback {
            _detachedEventEmitter.once(callback)
        }
        
        // Set state: Detaching
        let params = ARTChannelStateChangeParams(state: .ok)
        performTransitionToState(.detaching, withParams: params)
        
        detachAfterChecks()
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1097
    internal func detachAfterChecks() {
        guard let realtime = self.realtime else { return }
        
        let detachMessage = ARTProtocolMessage()
        detachMessage.action = .detach
        detachMessage.channel = self.name
        
        realtime.send(detachMessage, sentCallback: nil, ackCallback: nil)
        
        unlessStateChangesBefore(realtime.options.testOptions.realtimeRequestTimeout) {
            guard let realtime = self.realtime else {
                return
            }
            // Timeout
            let errorInfo = ARTErrorInfo.create(withCode: ARTState.detachTimedOut.rawValue, message: "detach timed out")
            let params = ARTChannelStateChangeParams(state: .attachTimedOut, errorInfo: errorInfo)
            self.performTransitionToState(.attached, withParams: params)
            self._detachedEventEmitter.emit(nil, with: errorInfo)
        }.startTimer()
        
        if presence.syncInProgress_nosync() {
            presence.failsSync(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailed.rawValue, message: "channel is being DETACHED"))
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1121
    internal func detach() {
        detach(nil)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1133
    internal override func historyWithWrapperSDKAgents(_ wrapperSDKAgents: [String: String]?, completion: @escaping ARTPaginatedMessagesCallback) {
        // swift-migration: Lawrence — absorb the error equivalently to the original
        let _ = try? history(ARTRealtimeHistoryQuery(), wrapperSDKAgents: wrapperSDKAgents, callback: completion)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1138
    internal func history(_ query: ARTRealtimeHistoryQuery?, wrapperSDKAgents: [String: String]?, callback: @escaping ARTPaginatedMessagesCallback) throws {
        // swift-migration: Lawrence — noticed this, this isn't in the original, it's ignored my instruction about not inserting these things
        let historyQuery = query ?? ARTRealtimeHistoryQuery()
        historyQuery.realtimeChannel = self
        try restChannel.history(historyQuery, wrapperSDKAgents: wrapperSDKAgents, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1143
    internal func startDecodeFailureRecovery(withErrorInfo error: ARTErrorInfo) {
        guard let realtime = self.realtime else { return }
        
        if _decodeFailureRecoveryInProgress {
            return
        }
        
        ARTLogWarn(logger, "\(pointer: realtime) C:\(pointer: self) (\(self.name)) starting delta decode failure recovery process")
        _decodeFailureRecoveryInProgress = true
        let params = ARTAttachRequestParams(reason: error)
        internalAttach({ e in
            self._decodeFailureRecoveryInProgress = false
        }, withParams: params)
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1160
    internal override func exceedMaxSize(_ messages: [ARTBaseMessage]) -> Bool {
        guard let realtime = self.realtime else { return false }
        
        var size = 0
        for message in messages {
            size += (message as? ARTMessage)?.messageSize() ?? 0
        }
        let maxSize = realtime.connection.maxMessageSize
        return size > maxSize
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1189
    internal func setOptions(_ options: ARTRealtimeChannelOptions?, callback: ARTCallback?) {
        var callbackWrapper = callback
        if callbackWrapper != nil {
            let userCallback = callbackWrapper!
            callbackWrapper = { error in
                self._userQueue.async {
                    userCallback(error)
                }
            }
        }
        
        _queue.sync {
            self.setOptions_nosync(options, callback: callbackWrapper)
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1203
    internal func setOptions_nosync(_ options: ARTRealtimeChannelOptions?, callback: ARTCallback?) {
        guard let realtime = self.realtime else { return }
        
        setOptions_nosync(options)
        restChannel.setOptions_nosync(options)
        
        if options?.modes == nil && options?.params == nil {
            callback?(nil)
            return
        }
        
        switch self.state_nosync {
        case .attached, .attaching:
            ARTLogDebug(logger, "RT:\(pointer: realtime) C:\(pointer: self) (\(self.name)) set options in \(ARTRealtimeChannelStateToStr(self.state_nosync)) state")
            let params = ARTAttachRequestParams(reason: nil)
            internalAttach(callback, withParams: params)
        default:
            callback?(nil)
        }
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1228
    internal func setPluginDataValue(_ value: Any?, forKey key: String) {
        _pluginData[key] = value
    }
    
    // swift-migration: original location ARTRealtimeChannel.m, line 1232
    internal func pluginDataValue(forKey key: String) -> Any? {
        return _pluginData[key]
    }
}
