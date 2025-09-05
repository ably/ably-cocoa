//
//  ARTWebSocketFactory.swift
//  AblySwift
//
//  Created during Swift migration from Objective-C.
//  Copyright © 2024 Ably Real-time Ltd. All rights reserved.
//

import Foundation

// MARK: - WebSocket Protocol

public protocol ARTWebSocket: AnyObject {
    var delegate: ARTWebSocketDelegate? { get set }
    var readyState: ARTWebSocketReadyState { get }
    
    func open()
    func close()
    func closeWithCode(_ code: Int, reason: String)
    func send(_ data: Data)
    func send(_ string: String)
    func setDelegateDispatchQueue(_ queue: DispatchQueue)
}

// MARK: - WebSocket Delegate Protocol

public protocol ARTWebSocketDelegate: AnyObject {
    func webSocketDidOpen(_ webSocket: ARTWebSocket)
    func webSocket(_ webSocket: ARTWebSocket, didCloseWithCode code: Int, reason: String, wasClean: Bool)
    func webSocket(_ webSocket: ARTWebSocket, didFailWithError error: Error)
    func webSocket(_ webSocket: ARTWebSocket, didReceiveMessage message: Any)
}

// MARK: - WebSocket Ready State

public enum ARTWebSocketReadyState: Int, @unchecked Sendable {
    case connecting = 0
    case open = 1
    case closing = 2
    case closed = 3
    
    public var description: String {
        switch self {
        case .connecting: return "Connecting"
        case .open: return "Open"
        case .closing: return "Closing"
        case .closed: return "Closed"
        }
    }
}

// MARK: - WebSocket Factory Protocol

/**
 A factory for creating an `ARTWebSocket` object.
 */
public protocol ARTWebSocketFactory {
    func createWebSocketWithURLRequest(_ request: URLRequest, logger: ARTInternalLog?) -> ARTWebSocket
}

/**
 The implementation of `ARTWebSocketFactory` that should be used in non-test code.
 */
public class ARTDefaultWebSocketFactory: ARTWebSocketFactory, @unchecked Sendable {
    public init() {}
    
    public func createWebSocketWithURLRequest(_ request: URLRequest, logger: ARTInternalLog?) -> ARTWebSocket {
        // For now, return a placeholder implementation
        // This will be replaced with the actual SocketRocket wrapper
        return ARTPlaceholderWebSocket()
    }
}

// MARK: - Placeholder WebSocket Implementation

private class ARTPlaceholderWebSocket: ARTWebSocket, @unchecked Sendable {
    weak var delegate: ARTWebSocketDelegate?
    var readyState: ARTWebSocketReadyState = .closed
    
    func open() {
        // Placeholder implementation
    }
    
    func close() {
        // Placeholder implementation
    }
    
    func closeWithCode(_ code: Int, reason: String) {
        // Placeholder implementation
    }
    
    func send(_ data: Data) {
        // Placeholder implementation
    }
    
    func send(_ string: String) {
        // Placeholder implementation
    }
    
    func setDelegateDispatchQueue(_ queue: DispatchQueue) {
        // Placeholder implementation
    }
}

// MARK: - String Conversion Utilities

public func WebSocketStateToStr(_ state: ARTWebSocketReadyState) -> String {
    return state.description
}