//
//  ARTRealtimeTransportFactory.swift
//  AblySwift
//
//  Created during Swift migration from Objective-C.
//  Copyright © 2024 Ably Real-time Ltd. All rights reserved.
//

import Foundation

// MARK: - Transport Factory Protocol

/**
 A factory for creating an `ARTRealtimeTransport` instance.
 */
internal protocol ARTRealtimeTransportFactory {
    func transportWithRest(_ rest: ARTRestInternal,
                          options: ARTClientOptions,
                          resumeKey: String?,
                          logger: ARTInternalLog) -> ARTRealtimeTransport
}

/**
 The implementation of `ARTRealtimeTransportFactory` that should be used in non-test code.
 */
internal class ARTDefaultRealtimeTransportFactory: ARTRealtimeTransportFactory, @unchecked Sendable {
    
    init() {}
    
    func transportWithRest(_ rest: ARTRestInternal,
                          options: ARTClientOptions,
                          resumeKey: String?,
                          logger: ARTInternalLog) -> ARTRealtimeTransport {
        let webSocketFactory: ARTWebSocketFactory = ARTDefaultWebSocketFactory()
        return ARTPlaceholderWebSocketTransport(rest: rest,
                                              options: options,
                                              resumeKey: resumeKey,
                                              logger: logger,
                                              webSocketFactory: webSocketFactory)
    }
}

// MARK: - Placeholder Transport Implementation

private class ARTPlaceholderWebSocketTransport: ARTRealtimeTransport, @unchecked Sendable {
    private let _resumeKey: String
    private let _state: ARTRealtimeTransportState = .closed
    var delegate: ARTRealtimeTransportDelegate?
    var host: String = ""
    
    init(rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, logger: ARTInternalLog, webSocketFactory: ARTWebSocketFactory) {
        self._resumeKey = resumeKey ?? ""
    }
    
    var resumeKey: String { return _resumeKey }
    var state: ARTRealtimeTransportState { return _state }
    
    func send(_ data: Data, withSource decodedObject: Any?) -> Bool { return false }
    func receive(_ message: ARTProtocolMessage) {}
    func receiveWithData(_ data: Data) -> ARTProtocolMessage? { return nil }
    func connectWithKey(_ key: String) {}
    func connectWithToken(_ token: String) {}
    func sendClose() {}
    func sendPing() {}
    func close() {}
    func abort(_ reason: ARTStatus) {}
}