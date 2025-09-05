//
//  ARTConnection.swift
//  AblySwift
//
//  Created during Swift migration from Objective-C.
//  Copyright © 2024 Ably Real-time Ltd. All rights reserved.
//

import Foundation

// MARK: - Connection Recovery Key

public class ARTConnectionRecoveryKey: NSObject, @unchecked Sendable {
    
    public let connectionKey: String
    public let msgSerial: Int64
    public let channelSerials: [String: String]
    
    public init(connectionKey: String, msgSerial: Int64, channelSerials: [String: String]) {
        self.connectionKey = connectionKey
        self.msgSerial = msgSerial
        self.channelSerials = channelSerials
        super.init()
    }
    
    public func jsonString() -> String {
        let object: [String: Any] = [
            "msgSerial": msgSerial,
            "connectionKey": connectionKey,
            "channelSerials": channelSerials
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            fatalError("ARTConnectionRecoveryKey: This JSON serialization should pass without errors.")
        }
    }
    
    public static func fromJsonString(_ json: String) -> (ARTConnectionRecoveryKey?, Error?) {
        guard let jsonData = json.data(using: .utf8) else {
            return (nil, NSError(domain: "ARTConnectionRecoveryKey", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"]))
        }
        
        do {
            guard let object = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                return (nil, NSError(domain: "ARTConnectionRecoveryKey", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"]))
            }
            
            let connectionKey = object["connectionKey"] as? String ?? ""
            let msgSerial = object["msgSerial"] as? NSNumber ?? 0
            let channelSerials = object["channelSerials"] as? [String: String] ?? [:]
            
            let recoveryKey = ARTConnectionRecoveryKey(
                connectionKey: connectionKey,
                msgSerial: msgSerial.int64Value,
                channelSerials: channelSerials
            )
            
            return (recoveryKey, nil)
        } catch {
            return (nil, error)
        }
    }
}

// MARK: - Connection Internal

internal class ARTConnectionInternal: NSObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let queue: DispatchQueue
    private var _id: String?
    private var _key: String?
    private var _maxMessageSize: Int = 0
    private var _state: ARTRealtimeConnectionState = .initialized
    private var _errorReason: ARTErrorInfo?
    
    internal let eventEmitter: ARTEventEmitter<ARTEvent, ARTConnectionStateChange>
    internal weak var realtime: ARTRealtimeInternal?
    
    // MARK: - Initializers
    
    internal init(realtime: ARTRealtimeInternal, logger: ARTInternalLog) {
        self.queue = DispatchQueue(label: "com.ably.connection", qos: .default)
        self.eventEmitter = ARTEventEmitter<ARTEvent, ARTConnectionStateChange>()
        self.realtime = realtime
        super.init()
    }
    
    // MARK: - Public Properties (Thread-Safe)
    
    internal var id: String? {
        return queue.sync { _id }
    }
    
    internal var key: String? {
        return queue.sync { _key }
    }
    
    internal var maxMessageSize: Int {
        return queue.sync {
            if _maxMessageSize > 0 {
                return _maxMessageSize
            }
            // Return default based on environment - placeholder logic
            return 65536 // Default max message size
        }
    }
    
    internal var state: ARTRealtimeConnectionState {
        return queue.sync { _state }
    }
    
    internal var errorReason: ARTErrorInfo? {
        return queue.sync { _errorReason }
    }
    
    // MARK: - Nosync Properties (Queue Already Held)
    
    internal var id_nosync: String? { return _id }
    internal var key_nosync: String? { return _key }
    internal var state_nosync: ARTRealtimeConnectionState { return _state }
    internal var errorReason_nosync: ARTErrorInfo? { return _errorReason }
    
    internal var isActive_nosync: Bool {
        return realtime?.isActive ?? false
    }
    
    internal var error_nosync: ARTErrorInfo? {
        if let errorReason = _errorReason {
            return errorReason
        }
        
        switch _state {
        case .disconnected:
            return ARTErrorInfo.create(withCode: 80003, message: "Connection to server temporarily unavailable")
        case .suspended:
            return ARTErrorInfo.create(withCode: 80002, message: "Connection to server unavailable")
        case .failed:
            return ARTErrorInfo.create(withCode: 80000, message: "Connection failed or disconnected by server")
        case .closing:
            return ARTErrorInfo.create(withCode: 80017, message: "Connection closing")
        case .closed:
            return ARTErrorInfo.create(withCode: 80003, message: "Connection closed")
        default:
            return ARTErrorInfo.create(withCode: 80013, message: "Invalid operation (connection state is \(_state.rawValue) - \(ARTRealtimeConnectionStateToStr(_state)))")
        }
    }
    
    // MARK: - Setters (Thread-Safe)
    
    internal func setId(_ newId: String?) {
        queue.sync { _id = newId }
    }
    
    internal func setKey(_ key: String?) {
        queue.sync { _key = key }
    }
    
    internal func setMaxMessageSize(_ maxMessageSize: Int) {
        queue.sync { _maxMessageSize = maxMessageSize }
    }
    
    internal func setState(_ state: ARTRealtimeConnectionState) {
        queue.sync {
            _state = state
            if isInactiveConnectionState(state) {
                _id = nil
                _key = nil
            }
        }
    }
    
    internal func setErrorReason(_ errorReason: ARTErrorInfo?) {
        queue.sync { _errorReason = errorReason }
    }
    
    // MARK: - Recovery Key
    
    @available(*, deprecated, message: "Use createRecoveryKey method instead.")
    internal var recoveryKey: String? {
        return createRecoveryKey()
    }
    
    internal func createRecoveryKey() -> String? {
        return queue.sync { createRecoveryKey_nosync() }
    }
    
    internal func createRecoveryKey_nosync() -> String? {
        guard let key = _key, !isInactiveConnectionState(_state) else {
            return nil
        }
        
        var channelSerials: [String: String] = [:]
        
        // Placeholder for channel serials collection
        // Will be implemented when realtime channels are available
        
        let recoveryKey = ARTConnectionRecoveryKey(
            connectionKey: key,
            msgSerial: 0, // Placeholder - will use realtime.msgSerial
            channelSerials: channelSerials
        )
        
        return recoveryKey.jsonString()
    }
    
    // MARK: - Connection Operations
    
    internal func connect() {
        realtime?.connect()
    }
    
    internal func close() {
        realtime?.close()
    }
    
    internal func ping(_ callback: @escaping ARTCallback) {
        realtime?.ping(callback)
    }
    
    // MARK: - Event Emitter Methods
    
    internal func emit(_ event: ARTRealtimeConnectionEvent, with data: ARTConnectionStateChange) {
        let artEvent = ARTEvent(connectionEvent: event)
        eventEmitter.emit(artEvent, with: data)
    }
    
    // MARK: - Helper Methods
    
    private func isInactiveConnectionState(_ state: ARTRealtimeConnectionState) -> Bool {
        return state == .closing || state == .closed || state == .failed || state == .suspended
    }
}

// MARK: - Public Connection

public class ARTConnection: NSObject, @unchecked Sendable {
    
    internal let _internal: ARTConnectionInternal
    private let _dealloc: ARTQueuedDealloc?
    
    // MARK: - Initializers
    
    internal init(internal: ARTConnectionInternal, queuedDealloc: ARTQueuedDealloc?) {
        self._internal = `internal`
        self._dealloc = queuedDealloc
        super.init()
    }
    
    // MARK: - Public Properties
    
    public var id: String? {
        return _internal.id
    }
    
    public var key: String? {
        return _internal.key
    }
    
    public var maxMessageSize: Int {
        return _internal.maxMessageSize
    }
    
    public var state: ARTRealtimeConnectionState {
        return _internal.state
    }
    
    public var errorReason: ARTErrorInfo? {
        return _internal.errorReason
    }
    
    @available(*, deprecated, message: "Use createRecoveryKey method instead.")
    public var recoveryKey: String? {
        return _internal.recoveryKey
    }
    
    // MARK: - Public Methods
    
    public func createRecoveryKey() -> String? {
        return _internal.createRecoveryKey()
    }
    
    public func connect() {
        _internal.connect()
    }
    
    public func close() {
        _internal.close()
    }
    
    public func ping(_ callback: @escaping ARTCallback) {
        _internal.ping(callback)
    }
    
    // MARK: - Internal Access
    
    internal var internal_nosync: ARTConnectionInternal {
        return _internal
    }
}

// MARK: - Event Extensions

extension ARTEvent {
    convenience init(connectionEvent: ARTRealtimeConnectionEvent) {
        self.init()
        // Store the connection event - placeholder implementation for now
    }
    
    static func newWithConnectionEvent(_ event: ARTRealtimeConnectionEvent) -> ARTEvent {
        return ARTEvent(connectionEvent: event)
    }
}

// MARK: - Forward Declarations

// Placeholder for ARTRealtimeInternal - will be migrated in Phase 7
internal class ARTRealtimeInternal: @unchecked Sendable {
    internal var isActive: Bool { return false }
    internal func connect() {}
    internal func close() {}
    internal func ping(_ callback: @escaping ARTCallback) {
        callback(nil)
    }
}