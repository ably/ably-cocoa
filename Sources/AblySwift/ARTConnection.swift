import Foundation

// swift-migration: original location ARTConnection.m, line 11
private func isInactiveConnectionState(_ state: ARTRealtimeConnectionState) -> Bool {
    return state == .closing || state == .closed || state == .failed || state == .suspended
}

// swift-migration: original location ARTConnection.h, line 94 and ARTConnection.m, line 15
public class ARTConnection: NSObject, ARTConnectionProtocol {
    private let _dealloc: ARTQueuedDealloc
    internal let _internal: ARTConnectionInternal
    
    // swift-migration: original location ARTConnection+Private.h, line 88
    internal var `internal`: ARTConnectionInternal {
        return _internal
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 92 and ARTConnection.m, line 19
    internal var internal_nosync: ARTConnectionInternal {
        return _internal
    }
    
    // swift-migration: original location ARTConnection.h, line 19 and ARTConnection.m, line 23
    public var id: String? {
        return _internal.id
    }
    
    // swift-migration: original location ARTConnection.h, line 24 and ARTConnection.m, line 27
    public var key: String? {
        return _internal.key
    }
    
    // swift-migration: original location ARTConnection.h, line 44 and ARTConnection.m, line 33
    @available(*, deprecated, message: "Use `createRecoveryKey` method instead.")
    public var recoveryKey: String? {
        return _internal.createRecoveryKey()
    }
    
    // swift-migration: original location ARTConnection.h, line 50 and ARTConnection.m, line 39
    public func createRecoveryKey() -> String? {
        return _internal.createRecoveryKey()
    }
    
    // swift-migration: original location ARTConnection.h, line 29 and ARTConnection.m, line 43
    public var maxMessageSize: Int {
        return _internal.maxMessageSize
    }
    
    // swift-migration: original location ARTConnection.h, line 34 and ARTConnection.m, line 47
    public var state: ARTRealtimeConnectionState {
        return _internal.state
    }
    
    // swift-migration: original location ARTConnection.h, line 39 and ARTConnection.m, line 51
    public var errorReason: ARTErrorInfo? {
        return _internal.errorReason
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 90 and ARTConnection.m, line 55
    internal init(internal internalInstance: ARTConnectionInternal, queuedDealloc: ARTQueuedDealloc) {
        self._internal = internalInstance
        self._dealloc = queuedDealloc
        super.init()
    }
    
    // swift-migration: original location ARTConnection.h, line 60 and ARTConnection.m, line 64
    public func close() {
        _internal.close()
    }
    
    // swift-migration: original location ARTConnection.h, line 55 and ARTConnection.m, line 68
    public func connect() {
        _internal.connect()
    }
    
    // swift-migration: original location ARTConnection.h, line 83 and ARTConnection.m, line 72
    public func off() {
        _internal.off()
    }
    
    // swift-migration: original location ARTConnection.h, line 82 and ARTConnection.m, line 76
    public func off(_ listener: ARTEventListener) {
        _internal.off(listener)
    }
    
    // swift-migration: original location ARTConnection.h, line 81 and ARTConnection.m, line 80
    public func off(_ event: ARTRealtimeConnectionEvent, listener: ARTEventListener) {
        _internal.off(event, listener: listener)
    }
    
    // swift-migration: original location ARTConnection.h, line 76 and ARTConnection.m, line 84
    public func on(_ cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return _internal.on(cb)
    }
    
    // swift-migration: original location ARTConnection.h, line 75 and ARTConnection.m, line 88
    public func on(_ event: ARTRealtimeConnectionEvent, callback cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return _internal.on(event, callback: cb)
    }
    
    // swift-migration: original location ARTConnection.h, line 79 and ARTConnection.m, line 92
    public func once(_ cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return _internal.once(cb)
    }
    
    // swift-migration: original location ARTConnection.h, line 78 and ARTConnection.m, line 96
    public func once(_ event: ARTRealtimeConnectionEvent, callback cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return _internal.once(event, callback: cb)
    }
    
    // swift-migration: original location ARTConnection.h, line 67 and ARTConnection.m, line 100
    public func ping(_ cb: @escaping ARTCallback) {
        _internal.ping(cb)
    }
}

// swift-migration: original location ARTConnection+Private.h, line 26 and ARTConnection.m, line 106
internal class ARTConnectionInternal: NSObject {
    private let _queue: DispatchQueue
    private var _id: String?
    private var _key: String?
    private var _maxMessageSize: Int = 0
    private var _state: ARTRealtimeConnectionState = .initialized
    private var _errorReason: ARTErrorInfo?
    
    // swift-migration: original location ARTConnection+Private.h, line 44
    internal let eventEmitter: ARTEventEmitter<ARTEvent, ARTConnectionStateChange>
    // swift-migration: original location ARTConnection+Private.h, line 45
    internal weak var realtime: ARTRealtimeInternal?
    
    // swift-migration: original location ARTConnection+Private.h, line 55
    internal var queue: DispatchQueue {
        return _queue
    }
    
    // swift-migration: Simplified init for when we need to break circular dependencies
    internal override init() {
        // swift-migration: Using placeholder values - full implementation would handle circular dependencies properly
        let placeholderOptions = ARTClientOptions()
        let placeholderRest = ARTRestInternal(options: placeholderOptions)
        let placeholderLogger = InternalLog(clientOptions: placeholderOptions)
        
        self.eventEmitter = ARTPublicEventEmitter(rest: placeholderRest, logger: placeholderLogger)
        self.realtime = nil
        self._queue = DispatchQueue.main // Temporary placeholder
        super.init()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 34 and ARTConnection.m, line 115
    internal init(realtime: ARTRealtimeInternal, logger: InternalLog) {
        self.eventEmitter = ARTPublicEventEmitter(rest: realtime.rest, logger: logger)
        self.realtime = realtime
        self._queue = realtime.rest.queue
        super.init()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 61 and ARTConnection.m, line 124
    internal func connect() {
        realtime?.connect()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 63 and ARTConnection.m, line 128
    internal func close() {
        realtime?.close()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 65 and ARTConnection.m, line 132
    internal func ping(_ cb: @escaping ARTCallback) {
        realtime?.ping(cb)
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 28 and ARTConnection.m, line 136
    internal var id: String? {
        var ret: String?
        _queue.sync {
            ret = self.id_nosync
        }
        return ret
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 29 and ARTConnection.m, line 144
    internal var key: String? {
        var ret: String?
        _queue.sync {
            ret = self.key_nosync
        }
        return ret
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 31 and ARTConnection.m, line 152
    internal var state: ARTRealtimeConnectionState {
        var ret: ARTRealtimeConnectionState = .initialized
        _queue.sync {
            ret = self.state_nosync
        }
        return ret
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 32 and ARTConnection.m, line 160
    internal var errorReason: ARTErrorInfo? {
        var ret: ARTErrorInfo?
        _queue.sync {
            ret = self.errorReason_nosync
        }
        return ret
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 41 and ARTConnection.m, line 168
    internal var error_nosync: ARTErrorInfo? {
        if let errorReason = self.errorReason_nosync {
            return errorReason
        }
        switch self.state_nosync {
        case .disconnected:
            return ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorDisconnected.rawValue, status: 400, message: "Connection to server temporarily unavailable")
        case .suspended:
            return ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorConnectionSuspended.rawValue, status: 400, message: "Connection to server unavailable")
        case .failed:
            return ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorConnectionFailed.rawValue, status: 400, message: "Connection failed or disconnected by server")
        case .closing:
            return ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorConnectionClosed.rawValue, status: 400, message: "Connection closing")
        case .closed:
            return ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorDisconnected.rawValue, status: 400, message: "Connection closed")
        default:
            return ARTErrorInfo.create(withCode: ARTErrorCode.ARTErrorInvalidTransportHandle.rawValue, status: 400, message: "Invalid operation (connection state is \(self.state_nosync.rawValue) - \(ARTRealtimeConnectionStateToStr(self.state_nosync)))")
        }
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 38 and ARTConnection.m, line 188
    internal var isActive_nosync: Bool {
        return realtime?.isActive ?? false
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 36 and ARTConnection.m, line 192
    internal var id_nosync: String? {
        return _id
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 37 and ARTConnection.m, line 196
    internal var key_nosync: String? {
        return _key
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 30 and ARTConnection.m, line 200
    internal var maxMessageSize: Int {
        if _maxMessageSize != 0 {
            return _maxMessageSize
        }
        return (realtime?.options.isProductionEnvironment ?? false) ? ARTDefault.maxProductionMessageSize() : ARTDefault.maxSandboxMessageSize()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 39 and ARTConnection.m, line 206
    internal var state_nosync: ARTRealtimeConnectionState {
        return _state
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 40 and ARTConnection.m, line 210
    internal var errorReason_nosync: ARTErrorInfo? {
        return _errorReason
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 47 and ARTConnection.m, line 214
    internal func setId(_ newId: String?) {
        _id = newId
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 48 and ARTConnection.m, line 218
    internal func setKey(_ key: String?) {
        _key = key
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 49 and ARTConnection.m, line 222
    internal func setMaxMessageSize(_ maxMessageSize: Int) {
        _maxMessageSize = maxMessageSize
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 50 and ARTConnection.m, line 226
    internal func setState(_ state: ARTRealtimeConnectionState) {
        _state = state
        if isInactiveConnectionState(state) {
            _id = nil // RTN8c
            _key = nil // RTN9c
        }
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 51 and ARTConnection.m, line 234
    internal func setErrorReason(_ errorReason: ARTErrorInfo?) {
        _errorReason = errorReason
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 73 and ARTConnection.m, line 238
    internal func on(_ event: ARTRealtimeConnectionEvent, callback cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return eventEmitter.on(ARTEvent.newWithConnectionEvent(event), callback: cb)
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 74 and ARTConnection.m, line 242
    internal func on(_ cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return eventEmitter.on(cb)
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 76 and ARTConnection.m, line 246
    internal func once(_ event: ARTRealtimeConnectionEvent, callback cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return eventEmitter.once(ARTEvent.newWithConnectionEvent(event), callback: cb)
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 77 and ARTConnection.m, line 250
    internal func once(_ cb: @escaping ARTConnectionStateCallback) -> ARTEventListener {
        return eventEmitter.once(cb)
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 81 and ARTConnection.m, line 254
    internal func off() {
        if realtime?.rest != nil {
            eventEmitter.off()
        } else {
            eventEmitter.off()
        }
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 79 and ARTConnection.m, line 261
    internal func off(_ event: ARTRealtimeConnectionEvent, listener: ARTEventListener) {
        eventEmitter.off(ARTEvent.newWithConnectionEvent(event), listener: listener)
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 80 and ARTConnection.m, line 265
    internal func off(_ listener: ARTEventListener) {
        eventEmitter.off(listener)
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 57 and ARTConnection.m, line 271
    @available(*, deprecated, message: "Use `createRecoveryKey` method instead.")
    internal var recoveryKey: String? {
        return createRecoveryKey()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 42 and ARTConnection.m, line 276
    internal func createRecoveryKey_nosync() -> String? {
        if _key == nil || isInactiveConnectionState(_state) { // RTN16g2
            return nil
        }
        
        var channelSerials: [String: String] = [:]
        // swift-migration: Lawrence Changed this to not use NSFastEnumeration because that's not compiling in Swift
        let channelsCollection = realtime?.channels.collection
        if let channelsCollection {
            for value in channelsCollection.allValues {
                // swift-migration: Lawrence introduced this force cast because the dictionary isn't generic
                let channel = value as! ARTRealtimeChannelInternal
                if channel.state_nosync == .attached {
                    if let channelSerial = channel.channelSerial {
                        channelSerials[channel.name] = channelSerial
                    }
                }
            }
        }
        
        let recoveryKey = ARTConnectionRecoveryKey(connectionKey: _key!, 
                                                  msgSerial: realtime?.msgSerial ?? 0, 
                                                  channelSerials: channelSerials)
        return recoveryKey.jsonString()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 59 and ARTConnection.m, line 294
    internal func createRecoveryKey() -> String? {
        var ret: String?
        _queue.sync {
            ret = self.createRecoveryKey_nosync()
        }
        return ret
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 53 and ARTConnection.m, line 302
    internal func emit(_ event: ARTRealtimeConnectionEvent, with data: ARTConnectionStateChange) {
        eventEmitter.emit(ARTEvent.newWithConnectionEvent(event), with: data)
    }
}

// swift-migration: original location ARTConnection.h, line 101 and ARTConnection.m, line 310
extension ARTEvent {
    
    // swift-migration: original location ARTConnection.h, line 102 and ARTConnection.m, line 312
    convenience init(connectionEvent value: ARTRealtimeConnectionEvent) {
        self.init(string: "ARTRealtimeConnectionEvent\(ARTRealtimeConnectionEventToStr(value))")
    }
    
    // swift-migration: original location ARTConnection.h, line 103 and ARTConnection.m, line 316
    class func newWithConnectionEvent(_ value: ARTRealtimeConnectionEvent) -> ARTEvent {
        return ARTEvent(connectionEvent: value)
    }
}

// swift-migration: original location ARTConnection+Private.h, line 11 and ARTConnection.m, line 322
internal class ARTConnectionRecoveryKey: NSObject {
    // swift-migration: original location ARTConnection+Private.h, line 13
    internal let connectionKey: String
    // swift-migration: original location ARTConnection+Private.h, line 14
    internal let msgSerial: Int64
    // swift-migration: original location ARTConnection+Private.h, line 15
    internal let channelSerials: [String: String]
    
    // swift-migration: original location ARTConnection+Private.h, line 17 and ARTConnection.m, line 324
    internal init(connectionKey: String, msgSerial: Int64, channelSerials: [String: String]) {
        self.connectionKey = connectionKey
        self.msgSerial = msgSerial
        self.channelSerials = channelSerials
        super.init()
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 21 and ARTConnection.m, line 336
    internal func jsonString() -> String {
        let object: [String: Any] = [
            "msgSerial": msgSerial,
            "connectionKey": connectionKey,
            "channelSerials": channelSerials
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
            return String(data: jsonData, encoding: .utf8)!
        } catch {
            fatalError("\(type(of: self)): This JSON serialization should pass without errors.")
        }
    }
    
    // swift-migration: original location ARTConnection+Private.h, line 22 and ARTConnection.m, line 356
    class func fromJsonString(_ json: String) throws -> ARTConnectionRecoveryKey {
        guard let jsonData = json.data(using: .utf8) else {
            throw NSError(domain: "ARTConnectionRecoveryKey", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"])
        }
        
        do {
            let object = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            return ARTConnectionRecoveryKey(
                connectionKey: object["connectionKey"] as! String,
                msgSerial: (object["msgSerial"] as! NSNumber).int64Value,
                channelSerials: object["channelSerials"] as! [String: String]
            )
        } catch {
            throw error
        }
    }
}
