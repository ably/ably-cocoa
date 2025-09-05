//
//  ARTRealtimeTransport.swift
//  AblySwift
//
//  Created during Swift migration from Objective-C.
//  Copyright © 2024 Ably Real-time Ltd. All rights reserved.
//

import Foundation

// MARK: - Transport Error Types

@objc public enum ARTRealtimeTransportErrorType: UInt, @unchecked Sendable {
    case other
    case hostUnreachable
    case noInternet
    case timeout
    case badResponse
    case refused
    
    public var description: String {
        switch self {
        case .other: return "Other"
        case .hostUnreachable: return "Unreachable"
        case .noInternet: return "NoInternet"
        case .timeout: return "Timeout"
        case .badResponse: return "BadResponse"
        case .refused: return "Refused"
        }
    }
}

@objc public enum ARTRealtimeTransportState: UInt, @unchecked Sendable {
    case opening
    case opened
    case closing
    case closed
    
    public var description: String {
        switch self {
        case .opening: return "Connecting"
        case .opened: return "Open"
        case .closing: return "Closing"
        case .closed: return "Closed"
        }
    }
}

// MARK: - Transport Error

@objc public class ARTRealtimeTransportError: NSObject, @unchecked Sendable {
    @objc public let error: NSError
    @objc public let type: ARTRealtimeTransportErrorType
    @objc public let badResponseCode: Int
    @objc public let url: URL
    
    @objc public init(error: NSError, type: ARTRealtimeTransportErrorType, url: URL) {
        self.error = error
        self.type = type
        self.badResponseCode = 0
        self.url = url
        super.init()
    }
    
    @objc public init(error: NSError, badResponseCode: Int, url: URL) {
        self.error = error
        self.type = .badResponse
        self.badResponseCode = badResponseCode
        self.url = url
        super.init()
    }
    
    public override var description: String {
        var description = "<ARTRealtimeTransportError: \(Unmanaged.passUnretained(self).toOpaque()) {\n"
        description += "  type: \(type.description)\n"
        description += "  badResponseCode: \(badResponseCode)\n"
        description += "  url: \(url)\n"
        description += "  error: \(error)\n"
        description += "}>"
        return description
    }
}

// MARK: - Transport Delegate Protocol

public protocol ARTRealtimeTransportDelegate: AnyObject {
    
    // All methods must be called from rest's serial queue.
    
    func realtimeTransport(_ transport: ARTRealtimeTransport, didReceiveMessage message: ARTProtocolMessage)
    
    func realtimeTransportAvailable(_ transport: ARTRealtimeTransport)
    
    func realtimeTransportClosed(_ transport: ARTRealtimeTransport)
    func realtimeTransportDisconnected(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?)
    func realtimeTransportNeverConnected(_ transport: ARTRealtimeTransport)
    func realtimeTransportRefused(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError?)
    func realtimeTransportTooBig(_ transport: ARTRealtimeTransport)
    func realtimeTransportFailed(_ transport: ARTRealtimeTransport, withError error: ARTRealtimeTransportError)
    
    func realtimeTransportSetMsgSerial(_ transport: ARTRealtimeTransport, msgSerial: Int64)
}

// MARK: - Transport Protocol

public protocol ARTRealtimeTransport: AnyObject {
    
    // All methods must be called from rest's serial queue.
    
    var resumeKey: String { get }
    var state: ARTRealtimeTransportState { get }
    var delegate: ARTRealtimeTransportDelegate? { get set }
    var stateEmitter: ARTEventEmitter<ARTEvent, Any> { get }
    
    @discardableResult
    func send(_ data: Data, withSource decodedObject: Any?) -> Bool
    
    func receive(_ message: ARTProtocolMessage)
    
    func receiveWithData(_ data: Data) -> ARTProtocolMessage?
    
    func connectWithKey(_ key: String)
    
    func connectWithToken(_ token: String)
    
    func sendClose()
    
    func sendPing()
    
    func close()
    
    func abort(_ reason: ARTStatus)
    
    var host: String { get set }
}

// MARK: - Event Extensions

public extension ARTEvent {
    convenience init(transportState: ARTRealtimeTransportState) {
        self.init()
        // Store the transport state - placeholder implementation for now
    }
    
    static func newWithTransportState(_ state: ARTRealtimeTransportState) -> ARTEvent {
        return ARTEvent(transportState: state)
    }
}

// MARK: - String Conversion Utilities

public func ARTRealtimeTransportStateToStr(_ state: ARTRealtimeTransportState) -> String {
    return state.description
}