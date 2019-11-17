//
//  SoakTestWebSocket.swift
//  Ably-iOS-SoakTest
//
//  Copyright © 2019 Ably. All rights reserved.
//

import Foundation
import Ably.Private
import SocketRocketAblyFork

class SoakTestWebSocket: NSObject, ARTWebSocket {
    var readyState: SRReadyState
    var queue: DispatchQueue!
    var delegate: ARTWebSocketDelegate?

    let id = nextGlobalSerial()
    let nextConnectionSerial: () -> Int64

    required init(urlRequest request: URLRequest) {
        readyState = .CLOSED
        // TODO (maybe?): Extract connectionKey from params, resume conn state if
        // connectionStateTtl hasn't passed yet.
        nextConnectionSerial = serialSequence(label: "fakeConnection.\(id)", first: -1)
    }
    
    func setDelegateDispatchQueue(_ queue: DispatchQueue) {
        self.queue = queue
    }
    
    func open() {
        readyState = .CONNECTING
        queue.afterSeconds(between: 0.1 ... 3.0) {
            if true.times(9, outOf: 10) {
                self.readyState = .OPEN
                self.delegate?.webSocketDidOpen(self)
                
                self.doIfStillOpen(afterSecondsBetween: 0.1 ... 3.0) {
                    if true.times(9, outOf: 10) {
                        self.messageToClient(action: .connected) { m in
                            m.connectionId = "fakeConnection.\(self.id)"
                            m.connectionDetails = ARTConnectionDetails(
                                clientId: "*",
                                connectionKey: "fakeConnectionKey.\(self.id))",
                                maxMessageSize: 999999999,
                                maxFrameSize: 999999999,
                                maxInboundRate: 999999999,
                                connectionStateTtl: 2.0,
                                serverId: "fakeServer",
                                maxIdleInterval: (0.0 ... 60.0).randomWithin()
                            )
                        }
                        self.ackMessages()
                        self.sendHeartbeats()
                    } else {
                        self.messageToClient(action: .error) { m in
                            m.error = ARTErrorInfo.create(from: fakeError)
                        }
                    }
                }
                
                self.doIfStillOpen(afterSecondsBetween: 3.0 ... 300.0) {
                    self.delegate?.webSocket(self, didCloseWithCode: SRStatusCode.codeAbnormal.rawValue, reason: "fake abrupt close", wasClean: false)
                }
            } else {
                self.delegate?.webSocket(self, didFailWithError: fakeError)
            }
        }
    }
    
    func sendHeartbeats() {
        doIfStillOpen(afterSecondsBetween: (2.0 ... 30.0)) {
            self.messageToClient(action: .heartbeat)
            self.sendHeartbeats()
        }
    }
    
    func protocolMessage(action: ARTProtocolMessageAction, setUp: (ARTProtocolMessage) -> Void = { _ in }) -> ARTProtocolMessage {
        return ARTProtocolMessage.build(action: action) { m in
            m.connectionSerial = self.nextConnectionSerial()
            m.timestamp = Date()
            setUp(m)
        }
    }
    
    func messageToClient(action: ARTProtocolMessageAction, setUp: (ARTProtocolMessage) -> Void = { _ in }) {
        let message = protocolMessage(action: action, setUp: setUp)
        self.delegate?.webSocket(self, didReceiveMessage: message)
    }
    
    func close(withCode code: Int, reason: String?) {
        readyState = .CLOSING
        queue.afterSeconds(between: 0.1 ... 3.0) {
            if self.readyState != .CLOSING {
                return
            }
            self.readyState = .CLOSED
        }
    }
    
    var pendingSerials: [NSNumber] = []
    
    func ackMessages() {
        doIfStillOpen(afterSecondsBetween: 0.1 ... 3.0) {
            self.ackMessages()

            if self.pendingSerials.count == 0 {
                return
            }
            self.messageToClient(action: .ack) { m in
                m.msgSerial = self.pendingSerials.first!
                m.count = Int32(self.pendingSerials.count)
            }
            self.pendingSerials.removeAll()
        }
    }
    
    func send(_ msgPackEncodedMessage: Any?) {
        let message = try! msgPackEncoder.decodeProtocolMessage(msgPackEncodedMessage as! Data)
        
        switch message.action {
        case .close:
            doIfStillOpen(afterSecondsBetween: 0.1 ... 3.0) {
                self.messageToClient(action: .closed)
                self.doIfStillOpen(afterSecondsBetween: 0.1 ... 0.5) {
                    self.delegate?.webSocket(self, didCloseWithCode: 1000, reason: nil, wasClean: true)
                }
            }
        case .message:
            queue.async {
                self.pendingSerials.append(message.msgSerial!)
            }
        case .attach:
            doIfStillOpen(afterSecondsBetween: 0.1 ... 3.0) {
                let serial: Int64
                if let s = self.serialForAttachedChannel[message.channel!] {
                    serial = s
                } else {
                    serial = -1
                    self.serialForAttachedChannel[message.channel!] = -1
                }
                self.messageToClient(action: .attached) { m in
                    m.channel = message.channel
                    m.channelSerial = "somethingsomething:\(serial)"
                }

                self.sendMessages(channel: message.channel!)
            }
        default:
            break
        }
    }
    
    var serialForAttachedChannel: [String: Int64] = [:]
    
    func sendMessages(channel: String) {
        doIfStillOpen(afterSecondsBetween: 0.1 ... 2.0) {
            guard var channelSerial = self.serialForAttachedChannel[channel] else {
                return
            }
            channelSerial += 1
            self.serialForAttachedChannel[channel] = channelSerial
            
            self.messageToClient(action: .message) { m in
                m.id = "message.\(nextGlobalSerial())"
                m.channel = channel
                m.channelSerial = "somethingsomething:\(channelSerial)"
                m.messages = [ARTMessage(
                    name: "fakeMessage",
                    data: messageFixtures.randomElement(using: &seededRandomNumberGenerator) as Any
                )]
            }
            
            self.sendMessages(channel: channel)
        }
    }
    
    func doIfStillOpen(afterSecondsBetween between: ClosedRange<TimeInterval>, execute: @escaping () -> Void) {
        queue.afterSeconds(between: between) {
            if self.readyState != .OPEN {
                return
            }
            execute()
        }
    }
}

let msgPackEncoder = ARTJsonLikeEncoder(delegate: ARTMsgPackEncoder())

let fakeError = NSError(domain: "io.ably", code: 1, userInfo: [NSLocalizedDescriptionKey: "fake error for soak test"])

func serialSequence(label: String, first: Int64 = 0) -> (() -> Int64) {
    let queue = DispatchQueue(label: "io.ably.soakTest.\(label)")
    var serial: Int64 = first
    
    return {
        var assigned: Int64!
        queue.sync {
            assigned = serial
            serial += 1
        }
        return assigned
    }
}

let nextGlobalSerial = serialSequence(label: "globalSerial")

extension ARTProtocolMessage {
    class func build(action: ARTProtocolMessageAction, setUp: (ARTProtocolMessage) -> Void) -> ARTProtocolMessage {
        let m = ARTProtocolMessage()
        m.action = action
        m.id = "fakeProtocolMessage.\(nextGlobalSerial())"
        setUp(m)
        return m
    }
}
