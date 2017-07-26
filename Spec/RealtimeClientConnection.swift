//
//  RealtimeClient.connection.swift
//  ably
//
//  Created by Ricardo Pereira on 03/11/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

import Ably
import Quick
import Nimble
import SwiftyJSON

func countChannels(_ channels: ARTRealtimeChannels) -> Int {
    var i = 0
    for _ in channels {
        i += 1
    }
    return i
}

class RealtimeClientConnection: QuickSpec {

    override func spec() {
        describe("Connection") {
            // RTN2
            context("url") {
                it("should connect to the default host") {
                    let options = ARTClientOptions(key: "keytest:secret")
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }

                    if let transport = client.transport as? TestProxyTransport, let url = transport.lastUrl {
                        expect(url.host).to(equal("realtime.ably.io"))
                    }
                    else {
                        XCTFail("MockTransport isn't working")
                    }
                }

                it("should connect with query string params") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .failed:
                                AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .connected:
                                if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                                    expect(query).to(haveParam("key", withValue: options.key ?? ""))
                                    expect(query).to(haveParam("echo", withValue: "true"))
                                    expect(query).to(haveParam("format", withValue: "msgpack"))
                                }
                                else {
                                    XCTFail("MockTransport isn't working")
                                }
                                done()
                                break
                            default:
                                break
                            }
                        }
                    }
                }

                it("should connect with query string params including clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    options.autoConnect = false
                    options.echoMessages = false

                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .failed:
                                AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .connected:
                                if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                                    expect(query).to(haveParam("accessToken", withValue: client.auth.tokenDetails?.token ?? ""))
                                    expect(query).to(haveParam("echo", withValue: "false"))
                                    expect(query).to(haveParam("format", withValue: "msgpack"))
                                    expect(query).to(haveParam("clientId", withValue: "client_string"))
                                }
                                else {
                                    XCTFail("MockTransport isn't working")
                                }
                                done()
                                break
                            default:
                                break
                            }
                        }
                    }
                }
            }

            // RTN3
            it("should connect automatically") {
                let options = AblyTests.commonAppSetup()
                var connected = false

                // Default
                expect(options.autoConnect).to(beTrue(), description: "autoConnect should be true by default")

                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                // The only way to control this functionality is with the options flag
                client.connection.on { stateChange in
                    let stateChange = stateChange!
                    let state = stateChange.current
                    let errorInfo = stateChange.reason
                    switch state {
                    case .connected:
                        connected = true
                    default:
                        break
                    }
                }
                expect(connected).toEventually(beTrue(), timeout: 10.0, description: "Can't connect automatically")
            }

            it("should connect manually") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false

                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                var waiting = true

                waitUntil(timeout: testTimeout) { done in
                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .connected:
                            if waiting {
                                XCTFail("Expected to be disconnected")
                            }
                            done()
                        default:
                            break
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
                        waiting = false
                        client.connect()
                    }
                }
            }

            // RTN2f
            it("API version param must be included in all connections") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.connecting) { _ in
                        guard let webSocketTransport = client.transport as? ARTWebSocketTransport else {
                            fail("Transport should be of type ARTWebSocketTransport"); done()
                            return
                        }
                        expect(webSocketTransport.websocketURL).toNot(beNil())
                        expect(webSocketTransport.websocketURL?.query).to(haveParam("v", withValue: ARTDefault.version()))
                        done()
                    }
                    client.connect()
                }
            }
            
            // RTN2g
            it("Library and version param `lib` should include the `X-Ably-Lib` header value") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                
                let client = ARTRealtime(options: options)
                client.setTransport(TestProxyTransport.self)
                client.connect()
                
                waitUntil(timeout: testTimeout) { done in
                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .failed:
                            AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                            done()
                        case .connected:
                            if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                                expect(query).to(haveParam("lib", withValue: "ios-1.0.7"))
                            }
                            else {
                                XCTFail("MockTransport isn't working")
                            }
                            done()
                            break
                        default:
                            break
                        }
                    }
                }
                client.close()
            }

            // RTN4
            context("event emitter") {

                // RTN4a
                it("should emit events for state changes") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.disconnectedRetryTimeout = 0.0

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let connection = client.connection
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        var alreadyDisconnected = false
                        var alreadyClosed = false

                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connecting:
                                if !alreadyDisconnected {
                                    events += [state]
                                }
                            case .connected:
                                if alreadyClosed {
                                    delay(0) {
                                        client.onSuspended()
                                    }
                                } else if alreadyDisconnected {
                                    client.close()
                                } else {
                                    events += [state]
                                    delay(0) {
                                        client.onDisconnected()
                                    }
                                }
                            case .disconnected:
                                events += [state]
                                alreadyDisconnected = true
                            case .suspended:
                                events += [state]
                                client.onError(AblyTests.newErrorProtocolMessage())
                            case .closing:
                                events += [state]
                            case .closed:
                                events += [state]
                                alreadyClosed = true
                                client.connect()
                            case .failed:
                                events += [state]
                                expect(errorInfo).toNot(beNil(), description: "Error is nil")
                                connection.off()
                                done()
                            default:
                                break
                            }
                        }
                        events += [connection.state]
                        connection.connect()
                    }

                    if events.count != 8 {
                        fail("Missing some states, got \(events)")
                        return
                    }

                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.initialized.rawValue), description: "Should be INITIALIZED state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.connecting.rawValue), description: "Should be CONNECTING state")
                    expect(events[2].rawValue).to(equal(ARTRealtimeConnectionState.connected.rawValue), description: "Should be CONNECTED state")
                    expect(events[3].rawValue).to(equal(ARTRealtimeConnectionState.disconnected.rawValue), description: "Should be DISCONNECTED state")
                    expect(events[4].rawValue).to(equal(ARTRealtimeConnectionState.closing.rawValue), description: "Should be CLOSING state")
                    expect(events[5].rawValue).to(equal(ARTRealtimeConnectionState.closed.rawValue), description: "Should be CLOSED state")
                    expect(events[6].rawValue).to(equal(ARTRealtimeConnectionState.suspended.rawValue), description: "Should be SUSPENDED state")
                    expect(events[7].rawValue).to(equal(ARTRealtimeConnectionState.failed.rawValue), description: "Should be FAILED state")
                }

                // RTN4h
                it("should never emit a ConnectionState event for a state equal to the previous state") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                    }

                    client.connection.once(.connected) { stateChange in
                        fail("Should not emit a Connected state")
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.update) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); done(); return
                            }
                            expect(stateChange.reason).to(beNil())
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                            expect(stateChange.current).to(equal(ARTRealtimeConnectionState.connected))
                            expect(stateChange.current).to(equal(stateChange.previous))
                            done()
                        }

                        let authMessage = ARTProtocolMessage()
                        authMessage.action = .auth
                        client.transport?.receive(authMessage)
                    }
                }

                // RTN4b
                it("should emit states on a new connection") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let connection = client.connection
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connecting:
                                events += [state]
                            case .connected:
                                events += [state]
                                done()
                            default:
                                break
                            }
                        }
                        connection.connect()
                    }

                    expect(events).to(haveCount(2), description: "Missing CONNECTING or CONNECTED state")

                    if events.count != 2 {
                        return
                    }

                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.connecting.rawValue), description: "Should be CONNECTING state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.connected.rawValue), description: "Should be CONNECTED state")
                }

                // RTN4c
                it("should emit states when connection is closed") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    let connection = client.connection
                    defer { client.dispose(); client.close() }
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connected:
                                connection.close()
                            case .closing:
                                events += [state]
                            case .closed:
                                events += [state]
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(events).to(haveCount(2), description: "Missing CLOSING or CLOSED state")

                    if events.count != 2 {
                        return
                    }

                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.closing.rawValue), description: "Should be CLOSING state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.closed.rawValue), description: "Should be CLOSED state")
                }

                // RTN4d
                it("should have the current state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let connection = client.connection
                    expect(connection.state.rawValue).to(equal(ARTRealtimeConnectionState.initialized.rawValue), description: "Missing INITIALIZED state")

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connecting:
                                expect(connection.state.rawValue).to(equal(ARTRealtimeConnectionState.connecting.rawValue), description: "Missing CONNECTING state")
                            case .connected:
                                expect(connection.state.rawValue).to(equal(ARTRealtimeConnectionState.connected.rawValue), description: "Missing CONNECTED state")
                                done()
                            default:
                                break
                            }
                        }
                        client.connect()
                    }
                }

                // RTN4e
                it("should have a ConnectionStateChange as first argument for every connection state change") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(ARTRealtimeConnectionEvent.connected) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is empty"); done()
                                return
                            }
                            expect(stateChange).to(beAKindOf(ARTConnectionStateChange.self))
                            expect(stateChange.current).to(equal(ARTRealtimeConnectionState.connected))
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connecting))
                            done()
                        }
                        client.connect()
                    }
                }

                // RTN4f
                it("should have the reason which contains an ErrorInfo") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let connection = client.connection

                    var errorInfo: ARTErrorInfo?
                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); done(); return
                            }
                            let state = stateChange.current
                            let reason = stateChange.reason
                            switch state {
                            case .connected:
                                expect(stateChange.event).to(equal(ARTRealtimeConnectionEvent.connected))
                                client.onError(AblyTests.newErrorProtocolMessage())
                            case .failed:
                                expect(stateChange.event).to(equal(ARTRealtimeConnectionEvent.failed))
                                errorInfo = reason
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(errorInfo).toNot(beNil())
                }

                // RTN4f
                it("any state change triggered by a ProtocolMessage that contains an Error member should populate the Reason property") {
                    let options = AblyTests.commonAppSetup()
                    options.useTokenAuth = true
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                    }

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }
                    guard let originalConnectedMessage = transport.protocolMessagesReceived.filter({ $0.action == .connected }).first else {
                        fail("First CONNECTED message not received"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.update) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); done(); return
                            }
                            guard let error = stateChange.reason else {
                                fail("Reason error is nil"); done(); return
                            }
                            expect(error.code) == 1234
                            expect(error.message) == "fabricated error"
                            expect(stateChange.event).to(equal(ARTRealtimeConnectionEvent.update))
                            done()
                        }

                        let connectedMessageWithError = originalConnectedMessage
                        connectedMessageWithError.error = ARTErrorInfo.create(withCode: 1234, message: "fabricated error")
                        client.transport?.receive(connectedMessageWithError)
                    }
                }
            }

            // RTN5
            it("basic operations should work simultaneously") {
                let options = AblyTests.commonAppSetup()
                options.echoMessages = false
                var disposable = [ARTRealtime]()
                let max = 50
                let channelName = "chat"
                let sync = NSLock()

                defer {
                    for client in disposable {
                        client.dispose()
                        client.close()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(max, done: done)
                    for _ in 1...max {
                        let client = ARTRealtime(options: options)
                        disposable.append(client)
                        let channel = client.channels.get(channelName)
                        channel.attach() { error in
                            if let error = error {
                                fail(error.message); done()
                            }
                            sync.lock()
                            partialDone()
                            sync.unlock()
                        }
                    }
                }

                var i = 0
                waitUntil(timeout: testTimeout) { done in
                    // Sends 50 messages from different clients to the same channel
                    // 50 messages for 50 clients = 50*50 total messages
                    // echo is off, so we need to subtract one message per client
                    let total = max*max - max
                    for client in disposable {
                        let channel = client.channels.get(channelName)
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attached))

                        channel.subscribe { message in
                            expect(message.data as? String).to(equal("message_string"))
                            sync.lock()
                            i += 1
                            if i == total {
                                done()
                            }
                            sync.unlock()
                        }

                        channel.publish(nil, data: "message_string", callback: nil)
                    }
                }

                expect(disposable.count).to(equal(max))
                expect(countChannels(disposable.first!.channels)).to(equal(1))
                expect(countChannels(disposable.last!.channels)).to(equal(1))
            }

            // RTN6
            it("should have an opened websocket connection and received a CONNECTED ProtocolMessage") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                client.setTransport(TestProxyTransport.self)
                client.connect()
                defer {
                    client.dispose()
                    client.close()
                }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let error = stateChange.reason
                        expect(error).to(beNil())
                        if state == .connected && error == nil {
                            done()
                        }
                    }
                }

                if let webSocketTransport = client.transport as? ARTWebSocketTransport {
                    expect(webSocketTransport.state).to(equal(ARTRealtimeTransportState.opened))
                }
                else {
                    XCTFail("WebSocket is not the default transport")
                }

                if let transport = client.transport as? TestProxyTransport {
                    // CONNECTED ProtocolMessage
                    expect(transport.protocolMessagesReceived.map{ $0.action }).to(contain(ARTProtocolMessageAction.connected))
                }
                else {
                    XCTFail("MockTransport is not working")
                }
            }

            // RTN7
            context("ACK and NACK") {

                // RTN7a
                context("should expect either an ACK or NACK to confirm") {

                    it("successful receipt and acceptance of message") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            publishFirstTestMessage(client, completion: { error in
                                expect(error).to(beNil())
                                done()
                            })
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .message }).last else {
                            XCTFail("No MESSAGE action was sent"); return
                        }

                        guard let receivedAck = transport.protocolMessagesReceived.filter({ $0.action == .ack }).last else {
                            XCTFail("No ACK action was received"); return
                        }

                        expect(publishedMessage.msgSerial).to(equal(receivedAck.msgSerial))
                    }

                    it("successful receipt and acceptance of presence") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .connected {
                                    let channel = client.channels.get("test")
                                    channel.attach() { error in
                                        expect(error).to(beNil())
                                        channel.presence.enterClient("client_string", data: nil, callback: { errorInfo in
                                            expect(errorInfo).to(beNil())
                                            done()
                                        })
                                    }
                                }
                            }
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .presence }).last else {
                            XCTFail("No PRESENCE action was sent"); return
                        }

                        guard let receivedAck = transport.protocolMessagesReceived.filter({ $0.action == .ack }).last else {
                            XCTFail("No ACK action was received"); return
                        }

                        expect(publishedMessage.msgSerial).to(equal(receivedAck.msgSerial))
                    }

                    it("message failure") {
                        let options = AblyTests.commonAppSetup()
                        options.token = getTestToken(key: options.key, capability: "{ \"\(ARTChannels_getChannelNamePrefix!())-test\":[\"subscribe\"] }")
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            publishFirstTestMessage(client, completion: { error in
                                expect(error).toNot(beNil())
                                done()
                            })
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .message }).last else {
                            XCTFail("No MESSAGE action was sent"); return
                        }

                        guard let receivedNack = transport.protocolMessagesReceived.filter({ $0.action == .nack }).last else {
                            XCTFail("No NACK action was received"); return
                        }

                        expect(publishedMessage.msgSerial).to(equal(receivedNack.msgSerial))
                    }

                    it("presence failure") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .connected {
                                    let channel = client.channels.get("test")
                                    channel.attach() { error in
                                        expect(error).to(beNil())
                                        channel.presence.enterClient("invalid", data: nil, callback: { errorInfo in
                                            expect(errorInfo).toNot(beNil())
                                            done()
                                        })
                                    }
                                }
                            }
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .presence }).last else {
                            XCTFail("No PRESENCE action was sent"); return
                        }

                        guard let receivedNack = transport.protocolMessagesReceived.filter({ $0.action == .nack }).last else {
                            XCTFail("No NACK action was received"); return
                        }

                        expect(publishedMessage.msgSerial).to(equal(receivedNack.msgSerial))
                    }

                }

                // RTN7b
                context("ProtocolMessage") {

                    class TotalMessages {
                        static var expected: Int32 = 0
                        static var succeeded: Int32 = 0
                        fileprivate init() {}
                    }

                    it("should contain unique serially incrementing msgSerial along with the count") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("channel")
                        channel.attach()

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: "message") { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            }
                        }

                        TotalMessages.expected = 5
                        for index in 1...TotalMessages.expected {
                            channel.publish(nil, data: "message\(index)") { errorInfo in
                                if errorInfo == nil {
                                    TotalMessages.succeeded += 1
                                }
                            }
                        }
                        expect(TotalMessages.succeeded).toEventually(equal(TotalMessages.expected), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence.enterClient("invalid", data: nil, callback: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                done()
                            })
                        }

                        let transport = client.transport as! TestProxyTransport
                        let acks = transport.protocolMessagesReceived.filter({ $0.action == .ack })
                        let nacks = transport.protocolMessagesReceived.filter({ $0.action == .nack })

                        if acks.count != 2 {
                            fail("Received invalid number of ACK responses: \(acks.count)")
                            return
                        }

                        expect(acks[0].msgSerial).to(equal(0))
                        expect(acks[0].count).to(equal(1))

                        // Messages covered in a single ACK response
                        expect(acks[1].msgSerial).to(equal(1))
                        expect(acks[1].count).to(equal(TotalMessages.expected))

                        if nacks.count != 1 {
                            fail("Received invalid number of NACK responses: \(nacks.count)")
                            return
                        }

                        expect(nacks[0].msgSerial).to(equal(6))
                        expect(nacks[0].count).to(equal(1))
                    }

                    it("should continue incrementing msgSerial serially if the connection resumes successfully") {
                        let options = AblyTests.commonAppSetup()
                        options.clientId = "tester"
                        options.tokenDetails = getTestTokenDetails(key: options.key!, clientId: options.clientId, ttl: 5.0)
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: "message") { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        guard let initialConnectionId = client.connection.id else {
                            fail("Connection ID is empty"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            (1...3).forEach { index in
                                channel.publish(nil, data: "message\(index)") { error in
                                    if error == nil {
                                        partialDone()
                                    }
                                }
                            }
                            channel.presence.enterClient("invalid", data: nil) { error in
                                expect(error).toNot(beNil())
                                partialDone()
                            }
                        }

                        expect(client.msgSerial) == 5

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.disconnected) { stateChange in
                                expect(stateChange?.reason).toNot(beNil())
                                // Token expired
                                done()
                            }
                        }

                        // Reconnected and resumed
                        expect(client.connection.id).to(equal(initialConnectionId))
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            (1...3).forEach { index in
                                channel.publish(nil, data: "message\(index)") { error in
                                    if error == nil {
                                        partialDone()
                                    }
                                }
                            }
                            channel.presence.enterClient("invalid", data: nil) { error in
                                expect(error).toNot(beNil())
                                partialDone()
                            }
                        }

                        guard let reconnectedTransport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }
                        let acks = reconnectedTransport.protocolMessagesReceived.filter({ $0.action == .ack })
                        let nacks = reconnectedTransport.protocolMessagesReceived.filter({ $0.action == .nack })

                        if acks.count != 1 {
                            fail("Received invalid number of ACK responses: \(acks.count)")
                            return
                        }
                        // Messages covered in a single ACK response
                        expect(acks[0].msgSerial) == 5 // [0] 1st publish + [1,2,3] publish + [4] enter with invalid client + [5] queued messages
                        expect(acks[0].count) == 1

                        if nacks.count != 1 {
                            fail("Received invalid number of NACK responses: \(nacks.count)")
                            return
                        }
                        expect(nacks[0].msgSerial) == 6
                        expect(nacks[0].count) == 1

                        expect(client.msgSerial) == 7
                    }

                    it("should reset msgSerial serially if the connection does not resume") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        options.clientId = "tester"
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: "message") { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        guard let initialConnectionId = client.connection.id else {
                            fail("Connection ID is empty"); return
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            (1...3).forEach { index in
                                channel.publish(nil, data: "message\(index)") { error in
                                    if error == nil {
                                        partialDone()
                                    }
                                }
                            }
                            channel.presence.enterClient("invalid", data: nil) { error in
                                expect(error).toNot(beNil())
                                partialDone()
                            }

                        }

                        expect(client.msgSerial) == 5

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            client.connection.once(.disconnected) { _ in
                                partialDone()
                            }
                            client.connection.once(.connected) { _ in
                                channel.attach()
                                partialDone()
                            }
                            client.simulateLostConnectionAndState()
                        }

                        // Reconnected but not resumed
                        expect(client.connection.id).toNot(equal(initialConnectionId))
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(4, done: done)
                            (1...3).forEach { index in
                                channel.publish(nil, data: "message\(index)") { error in
                                    if error == nil {
                                        partialDone()
                                    }
                                }
                            }
                            channel.presence.enterClient("invalid", data: nil) { error in
                                expect(error).toNot(beNil())
                                partialDone()
                            }
                        }

                        guard let reconnectedTransport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }
                        let acks = reconnectedTransport.protocolMessagesReceived.filter({ $0.action == .ack })
                        let nacks = reconnectedTransport.protocolMessagesReceived.filter({ $0.action == .nack })

                        if acks.count != 1 {
                            fail("Received invalid number of ACK responses: \(acks.count)")
                            return
                        }
                        // Messages covered in a single ACK response
                        expect(acks[0].msgSerial) == 0
                        expect(acks[0].count) == 1

                        if nacks.count != 1 {
                            fail("Received invalid number of NACK responses: \(nacks.count)")
                            return
                        }
                        expect(nacks[0].msgSerial) == 1
                        expect(nacks[0].count) == 1
                        
                        expect(client.msgSerial) == 2
                    }
                }

                // RTN7c
                context("should trigger the failure callback for the remaining pending messages if") {

                    it("connection is closed") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("channel")
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.ack, .nack]

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                channel.publish(nil, data: "message", callback: { error in
                                    guard let error = error else {
                                        fail("Error is nil"); done(); return
                                    }
                                    expect(error.message).to(contain("connection broken before receiving publishing acknowledgement"))
                                    done()
                                })
                                // Wait until the message is pushed to Ably first
                                delay(1.0) {
                                    transport.simulateIncomingNormalClose()
                                }
                            }
                        }

                        // This verifies that the pending message as been released and the publish callback is called only once!
                        waitUntil(timeout: testTimeout) { done in
                            delay(1.0) {
                                done()
                            }
                        }
                    }

                    it("connection state enters FAILED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("channel")
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.ack, .nack]

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                channel.publish(nil, data: "message", callback: { errorInfo in
                                    expect(errorInfo).toNot(beNil())
                                    done()
                                })
                                // Wait until the message is pushed to Ably first
                                delay(1.0) {
                                    transport.simulateIncomingError()
                                }
                            }
                        }
                    }

                    it("lost connection state") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.disconnectedRetryTimeout = 0.1
                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        let channel = client.channels.get("channel")

                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.ack, .nack]

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { _ in
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(3, done: done)

                            channel.publish(nil, data: "message") { error in
                                guard let error = error else {
                                    fail("Error is nil"); return
                                }
                                expect(error.code) == 80008
                                expect(error.message).to(contain("Unable to recover connection"))
                                partialDone()
                            }

                            let oldConnectionId = client.connection.id!

                            // Wait until the message is pushed to Ably first
                            delay(1.0) {
                                client.connection.once(.disconnected) { _ in
                                    partialDone()
                                }
                                client.connection.once(.connected) { stateChange in
                                    expect(client.connection.id).toNot(equal(oldConnectionId))
                                    partialDone()
                                }
                                client.simulateLostConnectionAndState()
                            }
                        }
                    }

                }

            }

            // RTN8
            context("connection#id") {

                // RTN8a
                it("should be null until connected") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    let connection = client.connection
                    defer {
                        client.dispose()
                        client.close()
                    }

                    expect(connection.id).to(beNil())

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            expect(errorInfo).to(beNil())
                            if state == .connected {
                                expect(connection.id).toNot(beNil())
                                done()
                            }
                            else if state == .connecting {
                                expect(connection.id).to(beNil())
                            }
                        }
                    }
                }

                // RTN8b
                it("should have unique IDs") {
                    let options = AblyTests.commonAppSetup()
                    var disposable = [ARTRealtime]()
                    defer {
                        for client in disposable {
                            client.dispose()
                            client.close()
                        }
                    }
                    var ids = [String]()
                    let max = 25
                    let sync = NSLock()

                    waitUntil(timeout: testTimeout) { done in
                        for _ in 1...max {
                            disposable.append(ARTRealtime(options: options))
                            let currentConnection = disposable.last!.connection
                            currentConnection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let errorInfo = stateChange.reason
                                if state == .connected {
                                    guard let connectionId = currentConnection.id else {
                                        fail("connectionId is nil on CONNECTED")
                                        done()
                                        return
                                    }
                                    expect(ids).toNot(contain(connectionId))

                                    sync.lock()
                                    ids.append(connectionId)
                                    if ids.count == max {
                                        done()
                                    }
                                    sync.unlock()

                                    currentConnection.off()
                                    currentConnection.close()
                                }
                            }
                        }
                    }

                    expect(ids).to(haveCount(max))
                }
            }

            // RTN9
            context("connection#key") {

                // RTN9a
                it("should be null until connected") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer {
                        client.dispose()
                        client.close()
                    }
                    let connection = client.connection

                    expect(connection.key).to(beNil())

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            expect(errorInfo).to(beNil())
                            if state == .connected {
                                expect(connection.id).toNot(beNil())
                                done()
                            }
                            else if state == .connecting {
                                expect(connection.key).to(beNil())
                            }
                        }
                    }
                }

                // RTN9b
                it("should have unique connection keys") {
                    let options = AblyTests.commonAppSetup()
                    var disposable = [ARTRealtime]()
                    defer {
                        for client in disposable {
                            client.dispose()
                            client.close()
                        }
                    }
                    var keys = [String]()
                    let max = 25

                    waitUntil(timeout: testTimeout) { done in
                        for _ in 1...max {
                            disposable.append(ARTRealtime(options: options))
                            let currentConnection = disposable.last!.connection
                            currentConnection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let errorInfo = stateChange.reason
                                if state == .connected {
                                    guard let connectionKey = currentConnection.key else {
                                        fail("connectionKey is nil on CONNECTED")
                                        done()
                                        return
                                    }
                                    expect(keys).toNot(contain(connectionKey))
                                    keys.append(connectionKey)

                                    if keys.count == max {
                                        done()
                                    }

                                    currentConnection.off()
                                    currentConnection.close()
                                }
                            }
                        }
                    }

                    expect(keys).to(haveCount(max))
                }

            }

            // RTN10
            context("serial") {

                // RTN10a
                it("should be -1 once connected") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer {
                        client.dispose()
                        client.close()
                    }
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            if state == .connected {
                                expect(client.connection.serial).to(equal(-1))
                                done()
                            }
                        }
                    }
                }

                // RTN10b
                it("should not update when a message is sent but increments by one when ACK is received") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer {
                        client.dispose()
                        client.close()
                    }
                    let channel = client.channels.get("test")

                    expect(client.connection.serial).to(equal(-1))
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    expect(client.connection.serial).to(equal(-1))

                    for index in 0...3 {
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.publish(nil, data: "message", callback: { errorInfo in
                                expect(errorInfo).to(beNil())
                                partialDone()
                            })
                            channel.subscribe() { _ in
                                // Updated
                                expect(client.connection.serial).to(equal(Int64(index)))
                                channel.unsubscribe()
                                partialDone()
                            }
                            // Not updated
                            expect(client.connection.serial).to(equal(Int64(index - 1)))
                        }
                    }
                }

                // RTN10c
                it("should have last known connection serial from restored connection") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer {
                        client.dispose()
                        client.close()
                    }
                    let channel = client.channels.get("test")

                    // Attach first to avoid bundling publishes in the same ProtocolMessage.
                    channel.attach()
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    for _ in 1...5 {
                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            channel.publish(nil, data: "message", callback: { errorInfo in
                                expect(errorInfo).to(beNil())
                                partialDone()
                            })
                            channel.subscribe() { _ in
                                channel.unsubscribe()
                                partialDone()
                            }
                        }
                    }
                    let lastSerial = client.connection.serial
                    expect(lastSerial).to(equal(4))

                    options.recover = client.connection.recoveryKey

                    let recoveredClient = ARTRealtime(options: options)
                    defer { recoveredClient.close() }
                    expect(recoveredClient.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        expect(recoveredClient.connection.serial).to(equal(lastSerial))
                        let recoveredChannel = recoveredClient.channels.get("test")
                        recoveredChannel.publish(nil, data: "message", callback: { errorInfo in
                            expect(errorInfo).to(beNil())
                        })
                        recoveredChannel.subscribe() { _ in
                            expect(recoveredClient.connection.serial).to(equal(lastSerial + 1))
                            recoveredChannel.unsubscribe()
                            done()
                        }
                    }
                }

            }

            // RTN11b
            it("should make a new connection with a new transport instance if the state is CLOSING") {
                let client = ARTRealtime(options: AblyTests.commonAppSetup())
                defer { client.dispose(); client.close() }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.connected) { _ in
                        done()
                    }
                }

                weak var oldTransport: ARTRealtimeTransport?
                weak var newTransport: ARTRealtimeTransport?

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(2, done: done)

                    client.connection.once(.closing) { _ in
                        oldTransport = client.transport
                        client.connect()
                        newTransport = client.transport
                        expect(newTransport).toNot(beIdenticalTo(oldTransport))
                        partialDone()
                    }

                    client.connection.once(.connected) { stateChange in
                        guard let stateChange = stateChange else {
                            fail("Missing ConnectionStateChange"); partialDone()
                            return
                        }
                        expect(stateChange.reason).to(beNil())
                        expect(client.connection.errorReason).to(beNil())
                        partialDone()
                    }

                    client.close()
                }

                expect(newTransport).toNot(beNil())
                expect(oldTransport).to(beNil())
            }

            // RTN11b
            it("it should make sure that, when the CLOSED ProtocolMessage arrives for the old connection, it doesn’t affect the new one") {
                let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                defer { client.dispose(); client.close() }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.connected) { _ in
                        done()
                    }
                }

                var oldTransport: ARTRealtimeTransport? //retain
                weak var newTransport: ARTRealtimeTransport?

                autoreleasepool {
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.closing) { _ in
                            oldTransport = client.transport
                            // Old connection must complete the close request
                            weak var oldTestProxyTransport = oldTransport as? TestProxyTransport
                            oldTestProxyTransport?.beforeProcessingReceivedMessage = { protocolMessage in
                                if protocolMessage.action == .closed {
                                    partialDone()
                                }
                            }

                            client.connect()

                            newTransport = client.transport
                            expect(newTransport).toNot(beIdenticalTo(oldTransport))
                            expect(newTransport).toNot(beNil())
                            expect(oldTransport).toNot(beNil())
                            partialDone()
                        }

                        client.connection.once(.closed) { _ in
                            fail("New connection should not receive the old connection event")
                        }
                        
                        client.connection.once(.connected) { _ in
                            partialDone()
                        }

                        client.close()
                    }

                    oldTransport = nil
                }

                expect(newTransport).toNot(beNil())
                expect(oldTransport).to(beNil())
            }

            // RTN12
            context("close") {
                // RTN12f
                it("if CONNECTING, do the operation once CONNECTED") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose() }

                    client.connect()
                    var lastStateChange: ARTConnectionStateChange?
                    client.connection.on { stateChange in
                        lastStateChange = stateChange
                    }

                    client.close()
                    expect(lastStateChange).to(beNil())


                    expect(lastStateChange).toEventuallyNot(beNil(), timeout: testTimeout)
                    expect(lastStateChange!.current).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)
                }

                // RTN12a
                it("if CONNECTED, should send a CLOSE action, change state to CLOSING and receive a CLOSED action") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer {
                        client.dispose()
                    }

                    let transport = client.transport as! TestProxyTransport
                    var states: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connected:
                                client.close()
                            case .closing:
                                expect(transport.protocolMessagesSent.filter({ $0.action == .close })).to(haveCount(1))
                                states += [state]
                            case.closed:
                                expect(transport.protocolMessagesReceived.filter({ $0.action == .closed })).to(haveCount(1))
                                states += [state]
                                done()
                            default:
                                break;
                            }
                        }
                    }

                    if states.count != 2 {
                        fail("Invalid number of connection states. Expected CLOSING and CLOSE states")
                        return
                    }
                    expect(states[0]).to(equal(ARTRealtimeConnectionState.closing))
                    expect(states[1]).to(equal(ARTRealtimeConnectionState.closed))
                }

                // RTN12b
                it("should transition to CLOSED action when the close process timeouts") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer {
                        client.dispose()
                        client.close()
                    }

                    let transport = client.transport as! TestProxyTransport
                    transport.actionsIgnored += [.closed]

                    var states: [ARTRealtimeConnectionState] = []
                    var start: NSDate?
                    var end: NSDate?

                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .connected:
                            client.close()
                        case .closing:
                            start = NSDate()
                            states += [state]
                        case .closed:
                            end = NSDate()
                            states += [state]
                        case .disconnected:
                            states += [state]
                        default:
                            break
                        }
                    }

                    expect(start).toEventuallyNot(beNil(), timeout: testTimeout)
                    expect(end).toEventuallyNot(beNil(), timeout: ARTDefault.realtimeRequestTimeout())

                    if states.count != 2 {
                        fail("Invalid number of connection states. Expected CLOSING and CLOSE states")
                        return
                    }

                    expect(states[0]).to(equal(ARTRealtimeConnectionState.closing))
                    expect(states[1]).to(equal(ARTRealtimeConnectionState.closed))
                }

                // RTN12c
                it("transitions to the CLOSING state and then to the CLOSED state if the transport is abruptly closed") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    client.connect()
                    defer {
                        client.dispose()
                        client.close()
                    }

                    let transport = client.transport as! TestProxyTransport
                    var states: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connected:
                                states += [state]
                                client.close()
                            case .closing:
                                states += [state]
                                transport.simulateIncomingAbruptlyClose()
                            case .closed:
                                states += [state]
                                done()
                            case .disconnected, .suspended, .failed:
                                states += [state]
                            default:
                                break
                            }
                        }
                    }

                    if states.count != 3 {
                        fail("Invalid number of connection states. Expected CONNECTED, CLOSING and CLOSE states (got \(states.map{ $0.rawValue }))")
                        return
                    }

                    expect(states[0]).to(equal(ARTRealtimeConnectionState.connected))
                    expect(states[1]).to(equal(ARTRealtimeConnectionState.closing))
                    expect(states[2]).to(equal(ARTRealtimeConnectionState.closed))
                }

                // RTN12d
                it("if DISCONNECTED, aborts the retry and moves immediately to CLOSED") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0
                    let client = ARTRealtime(options: options)
                    defer {
                        client.close()
                        client.dispose()
                    }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    client.onDisconnected()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.disconnected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        client.connection.once { stateChange in
                            expect(stateChange!.current).to(equal(ARTRealtimeConnectionState.closed))
                            partialDone()
                        }

                        client.close()

                        delay(options.disconnectedRetryTimeout + 0.5) {
                            // Make sure the retry doesn't happen.
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closed))
                            partialDone()
                        }
                    }
                }

                // RTN12e
                it("if SUSPENDED, aborts the retry and moves immediately to CLOSED") {
                    let options = AblyTests.commonAppSetup()
                    options.suspendedRetryTimeout = 1.0
                    let client = ARTRealtime(options: options)
                    defer {
                        client.close()
                        client.dispose()
                    }

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    client.onSuspended()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.suspended), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        client.connection.once { stateChange in
                            expect(stateChange!.current).to(equal(ARTRealtimeConnectionState.closed))
                            partialDone()
                        }

                        client.close()

                        delay(options.suspendedRetryTimeout + 0.5) {
                            // Make sure the retry doesn't happen.
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closed))
                            partialDone()
                        }
                    }
                }
            }

            // RTN13
            context("ping") {
                // RTN13b
                it("fails if in the INITIALIZED, SUSPENDED, CLOSING, CLOSED or FAILED state") {
                    let options = AblyTests.commonAppSetup()
                    options.suspendedRetryTimeout = 0.1
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    defer {
                        client.close()
                        client.dispose()
                    }

                    var error: ARTErrorInfo?
                    func ping() {
                        error = nil
                        client.ping() { error = $0 }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.initialized))
                    ping()
                    expect(error).toNot(beNil())

                    client.connect()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    client.onSuspended()

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.suspended))
                    ping()
                    expect(error).toNot(beNil())

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    client.close()

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closing))
                    ping()
                    expect(error).toNot(beNil())

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)
                    ping()
                    expect(error).toNot(beNil())

                    client.onError(AblyTests.newErrorProtocolMessage())

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.failed))
                    ping()
                    expect(error).toNot(beNil())
                }

                // RTN13a
                it("should send a ProtocolMessage with action HEARTBEAT and expects a HEARTBEAT message in response") {
                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.ping() { error in
                            expect(error).to(beNil())
                            let transport = client.transport as! TestProxyTransport
                            expect(transport.protocolMessagesSent.filter{ $0.action == .heartbeat }).to(haveCount(1))
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .heartbeat }).to(haveCount(1))
                            done()
                        }
                    }
                }

                // RTN13c
                it("should fail if a HEARTBEAT ProtocolMessage is not received within the default realtime request timeout") {
                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.dispose(); client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        let start = NSDate()
                        let transport = client.transport as! TestProxyTransport
                        transport.ignoreSends = true
                        ARTDefault.setRealtimeRequestTimeout(3.0)
                        client.ping() { error in
                            guard let error = error else {
                                fail("expected error"); done(); return
                            }
                            let end = NSDate()
                            expect(error.message).to(contain("timed out"))
                            expect(end.timeIntervalSince(start as Date)).to(beCloseTo(ARTDefault.realtimeRequestTimeout(), within: 1.5))
                            done()
                        }
                    }
                }

            }

            // RTN14a
            it("should enter FAILED state when API key is invalid") {
                let options = AblyTests.commonAppSetup()
                options.key = String(options.key!.characters.reversed())
                let client = ARTRealtime(options: options)
                defer {
                    client.dispose()
                    client.close()
                }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .failed:
                            expect(errorInfo).toNot(beNil())
                            done()
                        default:
                            break
                        }
                    }
                }
            }

            // RTN14b
            context("connection request fails") {
                it("should not emit error with a renewable token") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.authCallback = { tokenParams, callback in
                        delay(0) {
                            callback(getTestTokenDetails(key: options.key, capability: tokenParams.capability, ttl: tokenParams.ttl as! TimeInterval?), nil)
                        }
                    }
                    let tokenTtl = 3.0
                    options.token = getTestToken(key: options.key, ttl: tokenTtl)

                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    defer {
                        client.dispose()
                        client.close()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        // Let the token expire
                        client.connection.once(.disconnected) { stateChange in
                            guard let reason = stateChange?.reason else {
                                fail("Token error is missing"); done(); return
                            }
                            expect(reason.code) == 40142

                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let errorInfo = stateChange.reason
                                switch state {
                                case .connected:
                                    expect(errorInfo).to(beNil())
                                    // New token
                                    expect(client.auth.tokenDetails!.token).toNot(equal(options.token))
                                    done()
                                case .failed, .suspended:
                                    fail("Should not emit error (\(String(describing: errorInfo)))")
                                    done()
                                default:
                                    break
                                }
                            }
                        }
                        client.connect()
                    }
                }

                it("should transition to Failed when the token renewal fails") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let tokenTtl = 3.0
                    let tokenDetails = getTestTokenDetails(key: options.key, capability: nil, ttl: tokenTtl)!
                    options.token = tokenDetails.token
                    options.authCallback = { tokenParams, callback in
                        delay(0) {
                            callback(tokenDetails, nil) // Return the same expired token again.
                        }
                    }

                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    defer {
                        client.dispose()
                        client.close()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            partialDone()
                        }
                        client.connection.once(.disconnected) { stateChange in
                            guard let reason = stateChange?.reason else {
                                fail("Reason is nil"); done(); return;
                            }
                            expect(reason.code) == 40142
                            partialDone()
                        }
                        client.connection.once(.failed) { stateChange in
                            guard let reason = stateChange?.reason else {
                                fail("Reason is nil"); done(); return;
                            }
                            expect(reason.code) == 40142
                            partialDone()
                        }
                        client.connect()
                    }
                }

                it("should transition to Failed state because the token is invalid and not renewable") {
                    let options = AblyTests.clientOptions()
                    options.autoConnect = false
                    let tokenTtl = 1.0
                    options.token = getTestToken(ttl: tokenTtl)

                    // Let the token expire
                    waitUntil(timeout: testTimeout) { done in
                        delay(tokenTtl) {
                            done()
                        }
                    }

                    let client = ARTRealtime(options: options)
                    client.setTransport(TestProxyTransport.self)
                    defer {
                        client.dispose()
                        client.close()
                    }

                    var transport: TestProxyTransport!

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connected:
                                fail("Should not be connected")
                                done()
                            case .failed, .disconnected, .suspended:
                                guard let errorInfo = errorInfo else {
                                    fail("ErrorInfo is nil"); done(); return
                                }
                                expect(UInt(errorInfo.code)).to(equal(ARTState.requestTokenFailed.rawValue))
                                done()
                            default:
                                break
                            }
                        }
                        client.connect()
                        transport = client.transport as! TestProxyTransport
                    }

                    let failures = transport.protocolMessagesReceived.filter({ $0.action == .error })

                    if failures.count != 1 {
                        fail("Should have only one connection request fail")
                        return
                    }

                    expect(failures[0].error!.code).to(equal(40142))
                }

                // RTN14c
                it("connection attempt should fail if not connected within the default realtime request timeout") {
                    let options = AblyTests.commonAppSetup()
                    options.realtimeHost = "10.255.255.1" //non-routable IP address
                    options.autoConnect = false
                    let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                    defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                    ARTDefault.setRealtimeRequestTimeout(0.5)

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    var start, end: NSDate?
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on(.disconnected) { stateChange in
                            end = NSDate()
                            expect(stateChange!.reason!.message).to(contain("timed out"))
                            expect(client.connection.errorReason!).to(beIdenticalTo(stateChange!.reason))
                            done()
                        }
                        client.connect()
                        start = NSDate()
                    }
                    if let start = start, let end = end {
                        expect(end.timeIntervalSince(start as Date)).to(beCloseTo(ARTDefault.realtimeRequestTimeout(), within: 1.5))
                    }
                    else {
                        fail("Start date or end date are empty")
                    }
                }

                // RTN14d
                it("connection attempt fails for any recoverable reason") {
                    let options = AblyTests.commonAppSetup()
                    options.realtimeHost = "10.255.255.1" //non-routable IP address
                    options.disconnectedRetryTimeout = 1.0
                    options.autoConnect = false
                    let expectedTime = 3.0

                    options.authCallback = { tokenParams, completion in
                        // Ignore `completion` closure to force a time out
                    }

                    let previousConnectionStateTtl = ARTDefault.connectionStateTtl()
                    defer { ARTDefault.setConnectionStateTtl(previousConnectionStateTtl) }
                    ARTDefault.setConnectionStateTtl(expectedTime)

                    let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                    defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                    ARTDefault.setRealtimeRequestTimeout(0.1)

                    let client = ARTRealtime(options: options)
                    defer {
                        client.connection.off()
                        client.close()
                    }

                    var totalRetry = 0
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        var start: NSDate?

                        client.connection.once(.disconnected) { stateChange in
                            expect(stateChange!.reason!.message).to(contain("timed out"))
                            expect(stateChange!.previous).to(equal(ARTRealtimeConnectionState.connecting))
                            expect(stateChange!.retryIn).to(beCloseTo(options.disconnectedRetryTimeout))
                            partialDone()
                            start = NSDate()
                        }

                        client.connection.on(.suspended) { stateChange in
                            let end = NSDate()
                            expect(end.timeIntervalSince(start! as Date)).to(beCloseTo(expectedTime, within: 0.9))
                            partialDone()
                        }

                        client.connect()

                        client.connection.on(.connecting) { stateChange in
                            expect(stateChange!.previous).to(equal(ARTRealtimeConnectionState.disconnected))
                            totalRetry += 1
                        }
                    }

                    expect(totalRetry).to(equal(Int(expectedTime / options.disconnectedRetryTimeout)))
                }

                // RTN14e
                it("connection state has been in the DISCONNECTED state for more than the default connectionStateTtl should change the state to SUSPENDED") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 0.1
                    options.suspendedRetryTimeout = 0.5
                    options.autoConnect = false
                    let expectedTime: TimeInterval = 1.0

                    options.authCallback = { _ in
                        // Force a timeout
                    }

                    let previousConnectionStateTtl = ARTDefault.connectionStateTtl()
                    defer { ARTDefault.setConnectionStateTtl(previousConnectionStateTtl) }
                    ARTDefault.setConnectionStateTtl(expectedTime)

                    let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                    defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                    ARTDefault.setRealtimeRequestTimeout(0.1)

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on(.suspended) { stateChange in
                            expect(client.connection.errorReason!.message).to(contain("timed out"))

                            let start = NSDate()
                            client.connection.once(.connecting) { stateChange in
                                let end = NSDate()
                                expect(end.timeIntervalSince(start as Date)).to(beCloseTo(options.suspendedRetryTimeout, within: 0.5))
                                done()
                            }
                        }
                        client.connect()
                    }
                }

                it("on CLOSE the connection should stop connection retries") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 0.1
                    options.suspendedRetryTimeout = 0.5
                    options.autoConnect = false
                    let expectedTime: TimeInterval = 1.0

                    options.authCallback = { _ in
                        // Force a timeout
                    }

                    let previousConnectionStateTtl = ARTDefault.connectionStateTtl()
                    defer { ARTDefault.setConnectionStateTtl(previousConnectionStateTtl) }
                    ARTDefault.setConnectionStateTtl(expectedTime)

                    let previousRealtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
                    defer { ARTDefault.setRealtimeRequestTimeout(previousRealtimeRequestTimeout) }
                    ARTDefault.setRealtimeRequestTimeout(0.1)

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on(.suspended) { stateChange in
                            expect(client.connection.errorReason!.message).to(contain("timed out"))

                            let start = NSDate()
                            client.connection.once(.connecting) { stateChange in
                                let end = NSDate()
                                expect(end.timeIntervalSince(start as Date)).to(beCloseTo(options.suspendedRetryTimeout, within: 0.5))
                                done()
                            }
                        }
                        client.connect()
                    }

                    client.close()

                    // Check if the connection gets closed
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connecting) { stateChange in
                            fail("Should be closing the connection"); done(); return
                        }
                        delay(2.0) {
                            done()
                        }
                    }
                }

            }

            // RTN15
            context("connection failures once CONNECTED") {

                // RTN15a
                it("should not receive published messages until the connection reconnects successfully") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.disconnectedRetryTimeout = 1.0

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    var states = [ARTRealtimeConnectionState]()
                    client1.connection.on() { stateChange in
                        states = states + [stateChange!.current]
                    }
                    client1.connect()

                    let client2 = ARTRealtime(options: options)
                    client2.connect()
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    channel1.subscribe { message in
                        fail("Shouldn't receive the messsage")
                    }

                    expect(channel1.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                    let firstConnection: (id: String, key: String) = (client1.connection.id!, client1.connection.key!)

                    // Connection state cannot be resumed
                    client1.simulateLostConnectionAndState()

                    channel2.publish(nil, data: "message") { errorInfo in
                        expect(errorInfo).to(beNil())
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        client1.connection.once(.connecting) { _ in
                            expect(client1.resuming).to(beTrue())
                            partialDone()
                        }
                        client1.connection.once(.connected) { _ in
                            expect(client1.resuming).to(beFalse())
                            expect(client1.connection.id).toNot(equal(firstConnection.id))
                            expect(client1.connection.key).toNot(equal(firstConnection.key))
                            partialDone()
                        }
                    }

                    expect(states).toEventually(equal([.connecting, .connected, .disconnected, .connecting, .connected]), timeout: testTimeout)
                }

                // RTN15b
                context("reconnects to the websocket endpoint with additional querystring params") {

                    // RTN15b1, RTN15b2
                    it("resume is the private connection key and connection_serial is the most recent ProtocolMessage#connectionSerial received") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 0.1
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        let expectedConnectionKey = client.connection.key!
                        let expectedConnectionSerial = client.connection.serial
                        client.onDisconnected()

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connected) { _ in
                                let transport = client.transport as! TestProxyTransport
                                let query = transport.lastUrl!.query
                                expect(query).to(haveParam("resume", withValue: expectedConnectionKey))
                                expect(query).to(haveParam("connectionSerial", withValue: "\(expectedConnectionSerial)"))
                                done()
                            }
                        }
                    }

                }

                // RTN15c
                context("System's response to a resume request") {

                    // RTN15c1
                    it("CONNECTED ProtocolMessage with the same connectionId as the current client, and no error") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        let expectedConnectionId = client.connection.id
                        client.onDisconnected()

                        channel.publish(nil, data: "queued message")
                        expect(client.queuedMessages).toEventually(haveCount(1), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connected) { stateChange in
                                let transport = client.transport as! TestProxyTransport
                                let connectedPM = transport.protocolMessagesReceived.filter{ $0.action == .connected }[0]
                                expect(connectedPM.connectionId).to(equal(expectedConnectionId))
                                expect(stateChange!.reason).to(beNil())
                                done()
                            }
                        }
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                        expect(client.queuedMessages).toEventually(haveCount(0), timeout: testTimeout)
                    }

                    // RTN15c2
                    it("CONNECTED ProtocolMessage with the same connectionId as the current client and an non-fatal error") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                        let expectedConnectionId = client.connection.id
                        client.onDisconnected()

                        channel.publish(nil, data: "queued message")
                        expect(client.queuedMessages).toEventually(haveCount(1), timeout: testTimeout)

                        client.connection.once(.connecting) { _ in
                            let transport = client.transport as! TestProxyTransport
                            transport.beforeProcessingReceivedMessage = { protocolMessage in
                                if protocolMessage.action == .connected {
                                    protocolMessage.error = ARTErrorInfo.create(withCode: 0, message: "Injected error")
                                }
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connected) { stateChange in
                                expect(stateChange!.reason!.message).to(equal("Injected error"))
                                expect(client.connection.errorReason).to(beIdenticalTo(stateChange!.reason))
                                let transport = client.transport as! TestProxyTransport
                                let connectedPM = transport.protocolMessagesReceived.filter{ $0.action == .connected }[0]
                                expect(connectedPM.connectionId).to(equal(expectedConnectionId))
                                expect(client.connection.id).to(equal(expectedConnectionId))
                                done()
                            }
                        }

                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }
                        transport.beforeProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .attached {
                                protocolMessage.error = ARTErrorInfo.create(withCode: 0, message: "Channel injected error")
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            channel.once(.attached) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Reason error is nil"); done(); return
                                }
                                expect(error.message).to(equal("Channel injected error"))
                                expect(channel.errorReason).to(beIdenticalTo(error))
                                done()
                            }
                        }

                        expect(client.queuedMessages).toEventually(haveCount(0), timeout: testTimeout)
                    }

                    // RTN15c3
                    it("CONNECTED ProtocolMessage with a new connectionId and an error") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        let oldConnectionId = client.connection.id
                        client.simulateLostConnectionAndState()

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connected) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Connection resume failed and error should be propagated to the channel"); done(); return
                                }
                                expect(error.code).to(equal(80008))
                                expect(error.message).to(contain("Unable to recover connection"))
                                expect(client.connection.errorReason).to(beIdenticalTo(stateChange!.reason))
                                let transport = client.transport as! TestProxyTransport
                                let connectedPM = transport.protocolMessagesReceived.filter{ $0.action == .connected }[0]
                                expect(connectedPM.connectionId).toNot(equal(oldConnectionId))
                                expect(client.connection.id).to(equal(connectedPM.connectionId))
                                done()
                            }
                        }
                        expect(client.msgSerial).to(equal(0))
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                        guard let channelError = channel.errorReason else {
                            fail("Channel error is nil"); return
                        }
                        expect(channelError.code).to(equal(80008))
                        expect(channelError.message).to(contain("Unable to recover connection"))
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                    }

                    // RTN15c4
                    it("ERROR ProtocolMessage indicating a fatal error in the connection") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                        client.onDisconnected()

                        let protocolError = AblyTests.newErrorProtocolMessage()
                        client.connection.once(.connecting) { _ in
                            // Resuming
                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); return
                            }
                            transport.actionsIgnored += [.connected]
                            client.onError(protocolError)
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.failed) { stateChange in
                                expect(stateChange!.reason).to(beIdenticalTo(protocolError.error))
                                expect(client.connection.errorReason).to(beIdenticalTo(protocolError.error))
                                done()
                            }
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.failed))
                        expect(channel.errorReason).to(beIdenticalTo(protocolError.error))
                    }

                    it("should resume the connection after an auth renewal") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        options.tokenDetails = getTestTokenDetails(ttl: 5.0)
                        let client = AblyTests.newRealtime(options)
                        defer { client.dispose(); client.close() }

                        let channel = client.channels.get("test")
                        waitUntil(timeout: testTimeout) { done in
                            channel.attach() { error in
                                expect(error).to(beNil())
                                done()
                            }
                        }

                        let initialConnectionId = client.connection.id

                        guard let firstTransport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        channel.once(.detached) { _ in
                            fail("Should not detach channels")
                        }
                        defer { channel.off() }

                        waitUntil(timeout: testTimeout) { done in
                            // Wait for token to expire
                            client.connection.once(.disconnected) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Error is nil"); done(); return
                                }
                                expect(error.code) == 40142
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            // Wait for connection resume
                            client.connection.once(.connected) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                done()
                            }
                        }

                        guard let secondTransport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }

                        let connectedMessages = secondTransport.protocolMessagesReceived.filter{ $0.action == .connected }
                        expect(connectedMessages).to(haveCount(1)) //New transport connected
                        guard let receivedConnectionId = connectedMessages.first?.connectionId else {
                            fail("ConnectionID is nil"); return
                        }
                        expect(client.connection.id).to(equal(receivedConnectionId))
                        expect(client.connection.id).to(equal(initialConnectionId))

                        waitUntil(timeout: testTimeout) { done in
                            let partialDone = AblyTests.splitDone(2, done: done)
                            let expectedMessage = ARTMessage(name: "ios", data: "message1")

                            channel.subscribe() { message in
                                expect(message.name).to(equal(expectedMessage.name))
                                expect(message.data as? String).to(equal(expectedMessage.data as? String))
                                partialDone()
                            }

                            let rest = ARTRest(options: AblyTests.clientOptions(key: options.key!))
                            rest.channels.get("test").publish([expectedMessage]) { error in
                                expect(error).to(beNil())
                                partialDone()
                            }
                        }
                    }

                }

                // RTN15d
                it("should recover from disconnection and messages should be delivered once the connection is resumed") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0

                    let client1 = ARTRealtime(options: options)
                    defer { client1.close() }
                    let channel1 = client1.channels.get("test")

                    let client2 = ARTRealtime(options: options)
                    defer { client2.close() }
                    let channel2 = client2.channels.get("test")

                    let expectedMessages = ["message X", "message Y"]
                    var receivedMessages = [String]()

                    waitUntil(timeout: testTimeout) { done in
                        channel1.subscribe(attachCallback: { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }, callback: { message in
                            receivedMessages.append(message.data as! String)
                        })
                    }

                    client1.onDisconnected()

                    channel2.publish(expectedMessages.map{ ARTMessage(name: nil, data: $0) }) { errorInfo in
                        expect(errorInfo).to(beNil())
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client1.connection.once(.connecting) { _ in
                            expect(receivedMessages).to(beEmpty())
                            done()
                        }
                    }

                    expect(client1.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                    expect(receivedMessages).toEventually(equal(expectedMessages), timeout: testTimeout)
                }

                // RTN15e
                context("when a connection is resumed") {

                    it("the connection#key may change and will be provided in the first CONNECTED ProtocolMessage#connectionDetails") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.disconnectedRetryTimeout = 1.0

                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        client.connect()
                        defer { client.dispose(); client.close() }
                        let channel = client.channels.get("test")

                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

                        client.onDisconnected()

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connecting) { _ in
                                client.connection.setKey("key_to_be_replaced")
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connected) { _ in
                                let transport = client.transport as! TestProxyTransport
                                let firstConnectionDetails = transport.protocolMessagesReceived.filter{ $0.action == .connected }[0].connectionDetails
                                expect(firstConnectionDetails!.connectionKey).toNot(beNil())
                                expect(client.connection.key).to(equal(firstConnectionDetails!.connectionKey))
                                done()
                            }
                        }
                    }

                }

                // RTN15f
                it("ACK and NACK responses for published messages can only ever be received on the transport connection on which those messages were sent") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.5
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    var resumed = false
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { _ in
                            var sentQueuedMessage: ARTMessage?
                            channel.publish(nil, data: "message") { _ in
                                if resumed {
                                    let transport = client.transport as! TestProxyTransport
                                    expect(transport.protocolMessagesReceived.filter{ $0.action == .ack }).to(haveCount(1))
                                    let sentTransportMessage = transport.protocolMessagesSent.filter{ $0.action == .message }.first!.messages![0]
                                    expect(sentQueuedMessage).to(beIdenticalTo(sentTransportMessage))
                                    done()
                                }
                                else {
                                    fail("Shouldn't be called")
                                }
                            }
                            delay(0) {
                                client.onDisconnected()
                            }
                            client.connection.once(.connected) { _ in
                                resumed = true
                                channel.testSuite_injectIntoMethod(before: #selector(channel.sendQueuedMessages)) {
                                    channel.testSuite_getArgument(from: #selector(channel.send), at: 0) { arg0 in
                                        sentQueuedMessage = (arg0 as? ARTProtocolMessage)?.messages?[0]
                                    }
                                }
                            }
                        }
                    }
                }

                // RTN15g
                it("when the connection resume has failed, all channels should be detached with an error reason") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0

                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    client.simulateLostConnectionAndState()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.detached), timeout: testTimeout)
                    expect(channel.errorReason?.message).to(contain("Unable to recover connection"))
                }

                // RTN15h
                context("DISCONNECTED message contains a token error") {

                    it("if the token is renewable then error should not be emitted") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        options.autoConnect = false
                        options.authCallback = { tokenParams, callback in
                            callback(getTestTokenDetails(key: options.key, capability: tokenParams.capability, ttl: TimeInterval(60 * 60)), nil)
                        }
                        let tokenTtl = 5.0
                        options.token = getTestToken(key: options.key, ttl: tokenTtl)

                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        defer {
                            client.dispose()
                            client.close()
                        }

                        client.connect()
                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        weak var firstTransport = client.transport as? TestProxyTransport

                        waitUntil(timeout: testTimeout) { done in
                            // Wait for token to expire
                            client.connection.once(.disconnected) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Error is nil"); done(); return
                                }
                                expect(error.code) == 40142
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.connected) { stateChange in
                                expect(stateChange?.reason).to(beNil())
                                done()
                            }
                        }
                        expect(client.connection.errorReason).to(beNil())

                        // New connection
                        expect(firstTransport).to(beNil())
                        expect(client.transport).toNot(beNil())

                        waitUntil(timeout: testTimeout) { done in 
                            client.ping { error in
                                expect(error).to(beNil())
                                expect((client.transport as! TestProxyTransport).protocolMessagesReceived.filter({ $0.action == .connected })).to(haveCount(1))
                                done()
                            }
                        }                        
                    }

                    it("should transition to Failed when the token renewal fails and the error should be emitted") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        options.autoConnect = false
                        let tokenTtl = 5.0
                        let tokenDetails = getTestTokenDetails(key: options.key, capability: nil, ttl: tokenTtl)!
                        options.token = tokenDetails.token
                        options.authCallback = { tokenParams, callback in
                            // Let the token expire.
                            delay(tokenTtl) {
                                callback(tokenDetails, nil) // Return the same expired token again.
                            }
                        }

                        let client = ARTRealtime(options: options)
                        client.setTransport(TestProxyTransport.self)
                        defer {
                            client.dispose()
                            client.close()
                        }

                        client.connect()
                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                        weak var firstTransport = client.transport as? TestProxyTransport

                        waitUntil(timeout: testTimeout) { done in
                            // Wait for token to expire
                            client.connection.once(.disconnected) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Error is nil"); done(); return
                                }
                                expect(error.code) == 40142
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            // Renewal will fail
                            client.connection.once(.failed) { stateChange in
                                guard let error = stateChange?.reason else {
                                    fail("Error is nil"); done(); return
                                }
                                expect(error.code) == 40142
                                expect(client.connection.errorReason).to(beIdenticalTo(error))
                                done()
                            }
                        }

                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.failed))
                    }

                }

            }

            // RTN16
            context("Connection recovery") {

                // RTN16a
                it("connection state should recover explicitly with a recover key") {
                    let options = AblyTests.commonAppSetup()

                    let clientSend = ARTRealtime(options: options)
                    defer { clientSend.close() }
                    let channelSend = clientSend.channels.get("test")

                    let clientReceive = ARTRealtime(options: options)
                    defer { clientReceive.close() }
                    let channelReceive = clientReceive.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channelReceive.subscribe(attachCallback: { error in
                            expect(error).to(beNil())
                            channelSend.publish(nil, data: "message") { error in
                                expect(error).to(beNil())
                            }
                        }, callback: { message in
                            expect(message.data as? String).to(equal("message"))
                            done()
                        })
                    }

                    options.recover = clientReceive.connection.recoveryKey
                    clientReceive.onError(AblyTests.newErrorProtocolMessage())

                    waitUntil(timeout: testTimeout) { done in
                        channelSend.publish(nil, data: "queue a message") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    let clientRecover = ARTRealtime(options: options)
                    defer { clientRecover.close() }
                    let channelRecover = clientRecover.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channelRecover.subscribe { message in
                            expect(message.data as? String).to(equal("queue a message"))
                            done()
                        }
                    }
                }

                // RTN16b
                it("Connection#recoveryKey should be composed with the connection key and latest serial received") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        client.connection.once(.connected) { _ in
                            expect(client.connection.serial).to(equal(-1))
                            expect(client.connection.recoveryKey).to(equal("\(client.connection.key!):\(client.connection.serial)"))
                        }
                        channel.publish(nil, data: "message") { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                        channel.subscribe { message in
                            expect(message.data as? String).to(equal("message"))
                            expect(client.connection.serial).to(equal(0))
                            channel.unsubscribe()
                            partialDone()
                        }
                    }
                }

            }

            // RTN16
            context("Connection recovery") {

                // RTN16d
                it("when a connection is successfully recovered, Connection#id will be identical to the id of the connection that was recovered and Connection#key will always be updated to the ConnectionDetails#connectionKey provided in the first CONNECTED ProtocolMessage") {
                    let options = AblyTests.commonAppSetup()
                    let clientOriginal = ARTRealtime(options: options)
                    defer { clientOriginal.close() }

                    expect(clientOriginal.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    let expectedConnectionId = clientOriginal.connection.id

                    options.recover = clientOriginal.connection.recoveryKey
                    clientOriginal.onError(AblyTests.newErrorProtocolMessage())

                    let clientRecover = AblyTests.newRealtime(options)
                    defer { clientRecover.close() }

                    waitUntil(timeout: testTimeout) { done in
                        clientRecover.connection.once(.connected) { _ in
                            let transport = clientRecover.transport as! TestProxyTransport
                            let firstConnectionDetails = transport.protocolMessagesReceived.filter{ $0.action == .connected }.first!.connectionDetails
                            expect(firstConnectionDetails!.connectionKey).toNot(beNil())
                            expect(clientRecover.connection.id).to(equal(expectedConnectionId))
                            expect(clientRecover.connection.key).to(equal(firstConnectionDetails!.connectionKey))
                            done()
                        }
                    }
                }

            }

            // RTN16
            context("Connection recovery") {

                // RTN16c
                it("Connection#recoveryKey should become becomes null when a connection is explicitly CLOSED or CLOSED") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { _ in
                            client.connection.once(.closed) { _ in
                                expect(client.connection.recoveryKey).to(beNil())
                                expect(client.connection.key).to(beNil())
                                expect(client.connection.id).to(beNil())
                                done()
                            }
                            client.close()
                        }
                    }
                }

            }

            // RTN16
            context("Connection recovery") {

                // RTN16e
                it("should connect anyway if the recoverKey is no longer valid") {
                    let options = AblyTests.commonAppSetup()
                    options.recover = "99999!xxxxxx-xxxxxxxxx-xxxxxxxxx:-1"
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange!.reason!.message).to(contain("Unable to recover connection"))
                            expect(client.connection.errorReason).to(beIdenticalTo(stateChange!.reason))
                            done()
                        }
                    }
                }

            }

            // RTN17
            context("Host Fallback") {
                let expectedHostOrder = [4, 3, 0, 2, 1]
                let originalARTFallback_getRandomHostIndex = ARTFallback_getRandomHostIndex

                beforeEach {
                    ARTFallback_getRandomHostIndex = {
                        let hostIndexes = [1, 1, 0, 0, 0]
                        var i = 0
                        return { count in
                            let hostIndex = hostIndexes[i]
                            i += 1
                            return Int32(hostIndex)
                        }
                    }()
                }

                afterEach {
                    ARTFallback_getRandomHostIndex = originalARTFallback_getRandomHostIndex
                }

                // RTN17b
                it("failing connections with custom endpoint should result in an error immediately") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.environment = "test"
                    options.autoConnect = false
                    let client = AblyTests.newRealtime(options)
                    let channel = client.channels.get("test")

                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }

                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }

                    client.connect()
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            expect(error!.message).to(contain("TestProxyTransport error"))
                            done()
                        }
                    }

                    expect(urlConnections).to(haveCount(1))
                }

                // RTN17b
                it("applies when the default realtime.ably.io endpoint is being used") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    let channel = client.channels.get("test")

                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }

                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                        if urlConnections.count == 1 {
                            TestProxyTransport.network = nil
                        }
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }

                    client.connect()
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    expect(urlConnections).to(haveCount(2))
                    if urlConnections.count != 2 {
                        return
                    }
                    expect(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io")).to(beTrue())
                    expect(NSRegularExpression.match(urlConnections[1].absoluteString, pattern: "//[a-e].ably-realtime.com")).to(beTrue())
                }
                
                it("applies when an array of ClientOptions#fallbackHosts is provided") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    options.fallbackHosts = ["f.ably-realtime.com", "g.ably-realtime.com", "h.ably-realtime.com", "i.ably-realtime.com", "j.ably-realtime.com"]                    
                    let client = ARTRealtime(options: options)
                    let channel = client.channels.get("test")
                    
                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }
                    
                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                        if urlConnections.count == 1 {
                            TestProxyTransport.network = nil
                        }
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }
                    
                    client.connect()
                    defer { client.dispose(); client.close() }
                    
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }
                    
                    expect(urlConnections.count > 1 && urlConnections.count <= options.fallbackHosts!.count + 1).to(beTrue())
                    expect(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io")).to(beTrue())
                    for connection in urlConnections.dropFirst() {
                        expect(NSRegularExpression.match(connection.absoluteString, pattern: "//[f-j].ably-realtime.com")).to(beTrue())
                    }
                }

                // RTN17d
                context("should use an alternative host when") {
                    for caseTest: NetworkAnswer in [.hostUnreachable,
                                                    .requestTimeout(timeout: 0.1),
                                                    .hostInternalError(code: 501)] {
                        it("\(caseTest)") {
                            let options = ARTClientOptions(key: "xxxx:xxxx")
                            options.autoConnect = false
                            let client = ARTRealtime(options: options)
                            let channel = client.channels.get("test")

                            client.setTransport(TestProxyTransport.self)
                            TestProxyTransport.network = caseTest
                            defer { TestProxyTransport.network = nil }

                            var urlConnections = [NSURL]()
                            TestProxyTransport.networkConnectEvent = { transport, url in
                                if client.transport !== transport {
                                    return
                                }
                                urlConnections.append(url as NSURL)
                                if urlConnections.count == 1 {
                                    TestProxyTransport.network = nil
                                }
                            }
                            defer { TestProxyTransport.networkConnectEvent = nil }

                            client.connect()
                            defer { client.dispose(); client.close() }

                            waitUntil(timeout: testTimeout) { done in
                                channel.publish(nil, data: "message") { error in
                                    done()
                                }
                            }

                            expect(urlConnections).to(haveCount(2))
                            expect(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io")).to(beTrue())
                            expect(NSRegularExpression.match(urlConnections[1].absoluteString, pattern: "//[a-e].ably-realtime.com")).to(beTrue())
                        }
                    }
                }

                it("should move to disconnected when there's no internet") {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer {
                        client.dispose()
                        client.close()
                    }
                    client.setTransport(TestProxyTransport.self)

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    guard let wsTransport = client.transport as? ARTWebSocketTransport else {
                        fail("expected WS transport")
                        return
                    }

                    wsTransport.webSocket(wsTransport.websocket, didFailWithError:NSError(domain: "NSPOSIXErrorDomain", code: 57, userInfo: [NSLocalizedDescriptionKey: "Socket is not connected"]))

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.disconnected), timeout: testTimeout)
                }

                it("should not use an alternative host when the client receives a bad request") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    let channel = client.channels.get("test")

                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .host400BadRequest
                    defer { TestProxyTransport.network = nil }

                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }

                    client.connect()
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    expect(urlConnections).to(haveCount(1))
                    expect(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io")).to(beTrue())
                }

                // RTN17a
                it("every connection is first attempted to the primary host realtime.ably.io") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    let channel = client.channels.get("test")

                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }

                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                        TestProxyTransport.network = nil
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }

                    client.connect()
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    client.connect()

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    expect(urlConnections).to(haveCount(3))
                    expect(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io")).to(beTrue())
                    expect(NSRegularExpression.match(urlConnections[1].absoluteString, pattern: "//[a-e].ably-realtime.com")).to(beTrue())
                    expect(NSRegularExpression.match(urlConnections[2].absoluteString, pattern: "//realtime.ably.io")).to(beTrue())
                }

                // RTN17c
                it("should retry hosts in random order after checkin if an internet connection is available") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    let channel = client.channels.get("test")

                    let testHttpExecutor = TestProxyHTTPExecutor()
                    client.rest.httpExecutor = testHttpExecutor

                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }

                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }

                    client.connect()
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    expect(NSRegularExpression.match(testHttpExecutor.requests[0].url!.absoluteString, pattern: "//internet-up.ably-realtime.com/is-the-internet-up.txt")).to(beTrue())
                    expect(urlConnections).to(haveCount(6)) // default + 5 fallbacks

                    let extractHostname = { (url: NSURL) in
                        NSRegularExpression.extract(url.absoluteString, pattern: "[a-e].ably-realtime.com")
                    }
                    let resultFallbackHosts = urlConnections.flatMap(extractHostname)
                    let expectedFallbackHosts = Array(expectedHostOrder.map({ ARTDefault.fallbackHosts()[$0] }))

                    expect(resultFallbackHosts).to(equal(expectedFallbackHosts))
                }

                it("should retry custom fallback hosts in random order after checkin if an internet connection is available") {
                    let fbHosts = ["f.ably-realtime.com", "g.ably-realtime.com", "h.ably-realtime.com", "i.ably-realtime.com", "j.ably-realtime.com"]
                    
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    options.fallbackHosts = fbHosts
                    let client = ARTRealtime(options: options)
                    let channel = client.channels.get("test")
                    
                    let testHttpExecutor = TestProxyHTTPExecutor()
                    client.rest.httpExecutor = testHttpExecutor
                    
                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }
                    
                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }
                    
                    client.connect()
                    defer { client.dispose(); client.close() }
                    
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }

                    expect(NSRegularExpression.match(testHttpExecutor.requests[0].url!.absoluteString, pattern: "//internet-up.ably-realtime.com/is-the-internet-up.txt")).to(beTrue())
                    expect(urlConnections).to(haveCount(6)) // default + 5 provided fallbacks
                    
                    let extractHostname = { (url: NSURL) in
                        NSRegularExpression.extract(url.absoluteString, pattern: "[f-j].ably-realtime.com")
                    }
                    let resultFallbackHosts = urlConnections.flatMap(extractHostname)
                    let expectedFallbackHosts = Array(expectedHostOrder.map({ fbHosts[$0] }))
                    
                    expect(resultFallbackHosts).to(equal(expectedFallbackHosts))
                }

                it("won't use fallback hosts feature if an empty array is provided") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    options.fallbackHosts = []
                    let client = ARTRealtime(options: options)
                    let channel = client.channels.get("test")
                    
                    let testHttpExecutor = TestProxyHTTPExecutor()
                    client.rest.httpExecutor = testHttpExecutor
                    
                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }
                    
                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }
                    
                    client.connect()
                    defer { client.dispose(); client.close() }
                    
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            done()
                        }
                    }
                    
                    expect(NSRegularExpression.match(testHttpExecutor.requests[0].url!.absoluteString, pattern: "//internet-up.ably-realtime.com/is-the-internet-up.txt")).to(beTrue())
                    expect(urlConnections).to(haveCount(1))
                }

                // RTN17e
                it("client is connected to a fallback host endpoint should do HTTP requests to the same data centre") {
                    let options = ARTClientOptions(key: "xxxx:xxxx")
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)

                    let testHttpExecutor = TestProxyHTTPExecutor()
                    client.rest.httpExecutor = testHttpExecutor

                    client.setTransport(TestProxyTransport.self)
                    TestProxyTransport.network = .hostUnreachable
                    defer { TestProxyTransport.network = nil }

                    var urlConnections = [NSURL]()
                    TestProxyTransport.networkConnectEvent = { transport, url in
                        if client.transport !== transport {
                            return
                        }
                        urlConnections.append(url as NSURL)
                        if urlConnections.count == 2 {
                            TestProxyTransport.network = nil
                            (client.transport as! TestProxyTransport).simulateTransportSuccess()
                        }
                    }
                    defer { TestProxyTransport.networkConnectEvent = nil }

                    client.connect()
                    // Because we're faking the CONNECTED state, we can't client.close() or it
                    // will actually try to use the connection believing it's ready and throw an
                    // exception because it's really not.

                    expect(urlConnections).toEventually(haveCount(2), timeout: testTimeout)

                    expect(NSRegularExpression.match(urlConnections[1].absoluteString, pattern: "//[a-e].ably-realtime.com")).to(beTrue())

                    client.time { _ in }

                    let timeRequestUrl = testHttpExecutor.requests.last!.url!
                    expect(timeRequestUrl.host).to(equal(urlConnections[1].host))
                }

            }

            // RTN19
            it("attributes within ConnectionDetails should be used as defaults") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let realtime = AblyTests.newRealtime(options)
                defer { realtime.close() }

                waitUntil(timeout: testTimeout) { done in
                    realtime.connection.once(.connecting) { stateChange in
                        expect(stateChange!.reason).to(beNil())

                        let transport = realtime.transport as! TestProxyTransport
                        transport.beforeProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .connected {
                                protocolMessage.connectionDetails!.clientId = "john"
                                protocolMessage.connectionDetails!.connectionKey = "123"
                            }
                        }
                    }
                    realtime.connection.once(.connected) { stateChange in
                        expect(stateChange!.reason).to(beNil())

                        let transport = realtime.transport as! TestProxyTransport
                        let connectedProtocolMessage = transport.protocolMessagesReceived.filter{ $0.action == .connected }[0]

                        expect(realtime.auth.clientId).to(equal(connectedProtocolMessage.connectionDetails!.clientId))
                        expect(realtime.connection.key).to(equal(connectedProtocolMessage.connectionDetails!.connectionKey))
                        done()
                    }
                    realtime.connect()
                }
            }

            context("Transport disconnected side effects") {

                // RTN19a
                it("should resend any ProtocolMessage that is awaiting a ACK/NACK") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 0.1
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    let transport = client.transport as! TestProxyTransport

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { _ in done() }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            expect(error).to(beNil())
                            guard let newTransport = client.transport as? TestProxyTransport else {
                                fail("Transport is nil"); done(); return
                            }
                            expect(newTransport).toNot(beIdenticalTo(transport))
                            expect(transport.protocolMessagesSent.filter{ $0.action == .message }).to(haveCount(1))
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .connected }).to(haveCount(1))
                            expect(newTransport.protocolMessagesReceived.filter{ $0.action == .connected }).to(haveCount(1))
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .connected }).to(haveCount(1))
                            expect(newTransport.protocolMessagesSent.filter{ $0.action == .message }).to(haveCount(1))
                            done()
                        }
                        client.onDisconnected()
                    }
                }

                // RTN19b
                it("should resent the ATTACH message if there are any pending channels") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 0.1
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    let transport = client.transport as! TestProxyTransport

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        transport.ignoreSends = true
                        channel.attach() { error in
                            expect(error).to(beNil())
                            guard let newTransport = client.transport as? TestProxyTransport else {
                                fail("Transport is nil"); done(); return
                            }
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .connected }).to(haveCount(1))
                            expect(newTransport.protocolMessagesReceived.filter{ $0.action == .connected }).to(haveCount(1))
                            expect(transport.protocolMessagesSent.filter{ $0.action == .attach }).to(haveCount(0))
                            expect(transport.protocolMessagesSentIgnored.filter{ $0.action == .attach }).to(haveCount(1))
                            expect(newTransport.protocolMessagesSent.filter{ $0.action == .attach }).to(haveCount(1))
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.attaching))
                        transport.ignoreSends = false
                        client.onDisconnected()
                    }
                }

                // RTN19b
                it("should resent the DETACH message if there are any pending channels") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    let transport = client.transport as! TestProxyTransport

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { _ in done() }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        transport.ignoreSends = true
                        channel.detach() { error in
                            expect(error).to(beNil())
                            guard let newTransport = client.transport as? TestProxyTransport else {
                                fail("Transport is nil"); done(); return
                            }
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .connected }).to(haveCount(1))
                            expect(newTransport.protocolMessagesReceived.filter{ $0.action == .connected }).to(haveCount(1))
                            expect(transport.protocolMessagesSent.filter{ $0.action == .detach }).to(haveCount(0))
                            expect(transport.protocolMessagesSentIgnored.filter{ $0.action == .detach }).to(haveCount(1))
                            expect(newTransport.protocolMessagesSent.filter{ $0.action == .detach }).to(haveCount(1))
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.detaching))
                        transport.ignoreSends = false
                        client.onDisconnected()
                    }
                }

            }

            // RTN20
            context("Operating System events for network/internet connectivity changes") {

                // RTN20a
                context("should immediately change the state to DISCONNECTED if the operating system indicates that the underlying internet connection is no longer available") {
                    var client: ARTRealtime!

                    beforeEach {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        client = ARTRealtime(options: options)
                        client.setReachabilityClass(TestReachability.self)
                    }

                    afterEach {
                        client.dispose()
                        client.close()
                    }

                    it("when CONNECTING") {
                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                switch stateChange!.current {
                                case .connecting:
                                    expect(stateChange!.reason).to(beNil())
                                    guard let reachability = client.reachability as? TestReachability else {
                                        fail("expected test reachability")
                                        done(); return
                                    }
                                    expect(reachability.host).to(equal(client.options.realtimeHost))
                                    reachability.simulate(false)
                                case .disconnected:
                                    guard let reason = stateChange!.reason else {
                                        fail("expected error reason")
                                        done(); return
                                    }
                                    expect(reason.code).to(equal(-1003))
                                    done()
                                default:
                                    break
                                }
                            }
                            client.connect()
                        }
                    }

                    it("when CONNECTED") {
                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                switch stateChange!.current {
                                case .connected:
                                    expect(stateChange!.reason).to(beNil())
                                    guard let reachability = client.reachability as? TestReachability else {
                                        fail("expected test reachability")
                                        done(); return
                                    }
                                    expect(reachability.host).to(equal(client.options.realtimeHost))
                                    reachability.simulate(false)
                                case .disconnected:
                                    guard let reason = stateChange!.reason else {
                                        fail("expected error reason")
                                        done(); return
                                    }
                                    expect(reason.code).to(equal(-1003))
                                    done()
                                default:
                                    break
                                }
                            }
                            client.connect()
                        }
                    }
                }

                // RTN20b
                it("should immediately attempt to connect if the operating system indicates that the underlying internet connection is now available when DISCONNECTED or SUSPENDED") {
                    var client: ARTRealtime!
                    let options = AblyTests.commonAppSetup()
                    // Ensure it won't reconnect because of timeouts.
                    options.disconnectedRetryTimeout = testTimeout + 10
                    options.suspendedRetryTimeout = testTimeout + 10
                    options.autoConnect = false
                    client = ARTRealtime(options: options)
                    client.setReachabilityClass(TestReachability.self)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            switch stateChange!.current {
                            case .connecting:
                                if stateChange!.previous == .disconnected {
                                    client.onSuspended()
                                } else if stateChange!.previous == .suspended {
                                    done()
                                }
                            case .connected:
                                client.onDisconnected()
                            case .disconnected, .suspended:
                                guard let reachability = client.reachability as? TestReachability else {
                                    fail("expected test reachability")
                                    done(); return
                                }
                                expect(reachability.host).to(equal(client.options.realtimeHost))
                                reachability.simulate(true)
                            default:
                                break
                            }
                        }
                        client.connect()
                    }
                }

                // RTN22
                it("Ably can request that a connected client re-authenticates by sending the client an AUTH ProtocolMessage") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransport(TestProxyTransport.self)
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { error in
                            expect(error).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    guard let initialConnectionId = client.connection.id else {
                        fail("ConnectionId is nil"); return
                    }

                    guard let initialToken = client.auth.tokenDetails?.token else {
                        fail("Initial token is nil"); return
                    }

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.update) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            expect(initialToken).toNot(equal(client.auth.tokenDetails?.token))
                            done()
                        }

                        let authMessage = ARTProtocolMessage()
                        authMessage.action = .auth
                        client.transport?.receive(authMessage)
                    }

                    expect(client.connection.id).to(equal(initialConnectionId))
                    expect(client.transport).to(beIdenticalTo(transport))

                    let authMessages = transport.protocolMessagesSent.filter({ $0.action == .auth })
                    expect(authMessages).to(haveCount(1))

                    guard let authMessage = authMessages.first else {
                        fail("Missing AUTH protocol message"); return
                    }

                    expect(authMessage.auth).toNot(beNil())

                    guard let accessToken = authMessage.auth?.accessToken else {
                        fail("Missing accessToken from AUTH ProtocolMessage auth attribute"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        let expectedMessage = ARTMessage(name: "ios", data: "message1")

                        channel.subscribe() { message in
                            expect(message.name).to(equal(expectedMessage.name))
                            expect(message.data as? String).to(equal(expectedMessage.data as? String))
                            partialDone()
                        }

                        let rest = ARTRest(options: AblyTests.clientOptions(key: options.key!))
                        rest.channels.get("foo").publish([expectedMessage]) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }
                    
                    channel.off()
                }

                // RTN22a
                it("re-authenticate and resume the connection when the client is forcibly disconnected following a DISCONNECTED message containing an error code in the range 40140 <= code < 40150") {
                    let options = AblyTests.commonAppSetup()
                    options.token = getTestToken(key: options.key!, ttl: 5.0)
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    guard let initialConnectionId = client.connection.id else {
                        fail("ConnectionId is nil"); return
                    }

                    guard let initialToken = client.auth.tokenDetails?.token else {
                        fail("Initial token is nil"); return
                    }

                    channel.once(.detached) { _ in
                        fail("Should not detach channels")
                    }

                    var authorizeMethodCallCount = 0
                    let hook = client.auth.testSuite_injectIntoMethod(after: #selector(client.auth.authorize(_:options:callback:))) {
                        authorizeMethodCallCount += 1
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.disconnected) { stateChange in
                            guard let error = stateChange?.reason else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.code) == 40142
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            expect(initialToken).toNot(equal(client.auth.tokenDetails?.token))
                            done()
                        }
                    }

                    expect(client.connection.id).to(equal(initialConnectionId))
                    expect(authorizeMethodCallCount) == 1

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        let expectedMessage = ARTMessage(name: "ios", data: "message1")

                        channel.subscribe() { message in
                            expect(message.name).to(equal(expectedMessage.name))
                            expect(message.data as? String).to(equal(expectedMessage.data as? String))
                            partialDone()
                        }

                        let rest = ARTRest(options: AblyTests.clientOptions(key: options.key!))
                        rest.channels.get("foo").publish([expectedMessage]) { error in
                            expect(error).to(beNil())
                            partialDone()
                        }
                    }

                    channel.off()
                }

            }

            // RTN24
            it("the client may receive a CONNECTED ProtocolMessage from Ably at any point and should emit an UPDATE event") {
                let options = AblyTests.commonAppSetup()
                options.authCallback = { _, completion in
                    completion(getTestToken(key: options.key!, ttl: 35) as NSString, nil)
                }
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.connected) { stateChange in
                        expect(stateChange?.reason).to(beNil())
                        done()
                    }
                }

                expect(client.auth.clientId).to(beNil())

                client.options.authCallback = { _, completion in
                    completion(getTestToken(key: options.key!, clientId: "tester", ttl: 5) as NSString, nil)
                }

                client.connection.once(.connected) { stateChange in
                    fail("Should not emit a Connected state")
                }

                waitUntil(timeout: 40) { done in
                    client.connection.once(.update) { stateChange in
                        guard let stateChange = stateChange else {
                            fail("ConnectionStateChange is nil"); done(); return
                        }
                        expect(stateChange.reason).to(beNil())
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                        expect(stateChange.current).to(equal(ARTRealtimeConnectionState.connected))
                        expect(stateChange.current).to(equal(stateChange.previous))
                        done()
                    }
                }

                expect(client.auth.clientId).to(equal("tester"))
            }

            // RTN24
            it("should set the Connection reason attribute based on the Error member of the CONNECTED ProtocolMessage") {
                let options = AblyTests.commonAppSetup()
                options.useTokenAuth = true
                let client = AblyTests.newRealtime(options)
                defer { client.dispose(); client.close() }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.connected) { stateChange in
                        expect(stateChange?.reason).to(beNil())
                        done()
                    }
                }

                guard let transport = client.transport as? TestProxyTransport else {
                    fail("TestProxyTransport is not set"); return
                }
                guard let originalConnectedMessage = transport.protocolMessagesReceived.filter({ $0.action == .connected }).first else {
                    fail("First CONNECTED message not received"); return
                }

                client.connection.once(.connected) { stateChange in
                    fail("Should not emit a Connected state")
                }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.update) { stateChange in
                        guard let stateChange = stateChange else {
                            fail("ConnectionStateChange is nil"); done(); return
                        }
                        guard let error = stateChange.reason else {
                            fail("Reason error is nil"); done(); return
                        }
                        expect(error.code) == 1234
                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                        expect(stateChange.current).to(equal(ARTRealtimeConnectionState.connected))
                        expect(stateChange.current).to(equal(stateChange.previous))
                        done()
                    }

                    let connectedMessageWithError = originalConnectedMessage
                    connectedMessageWithError.error = ARTErrorInfo.create(withCode: 1234, message: "fabricated error")
                    client.transport?.receive(connectedMessageWithError)
                }

                expect(client.connection.errorReason).to(beNil())
            }

            // https://github.com/ably/ably-ios/issues/454
            it("should not move to FAILED if received DISCONNECT with an error") {
                let options = AblyTests.commonAppSetup()
                let client = ARTRealtime(options: options)
                defer {
                    client.dispose()
                    client.close()
                }

                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

                let protoMsg = ARTProtocolMessage()
                protoMsg.action = .disconnect
                protoMsg.error = ARTErrorInfo.create(withCode: 123, message: "test error")
                client.transport?.receive(protoMsg)

                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.disconnected))
                expect(client.connection.errorReason).to(equal(protoMsg.error))
            }

            context("with fixture messages") {
                let fixtures = JSON(data: NSData(contentsOfFile: pathForTestResource(testResourcesPath + "messages-encoding.json"))! as Data, options: .mutableContainers)

                func expectDataToMatch(_ message: ARTMessage, _ fixtureMessage: JSON) {
                    switch fixtureMessage["expectedType"].string! {
                    case "string":
                        expect(message.data as? NSString).to(equal(fixtureMessage["expectedValue"].string! as NSString?))
                    case "jsonObject":
                        if let data = message.data as? NSDictionary {
                            expect(JSON(data)).to(equal(fixtureMessage["expectedValue"]))
                        } else {
                            fail("expected NSDictionary")
                        }              
                    case "jsonArray":
                        if let data = message.data as? NSArray {
                            expect(JSON(data)).to(equal(fixtureMessage["expectedValue"]))
                        } else {
                            fail("expected NSArray")
                        }
                    case "binary":
                        expect(message.data as? NSData).to(equal(fixtureMessage["expectedHexValue"].string!.dataFromHexadecimalString()! as NSData?))
                    default:
                        fail("unhandled: \(fixtureMessage["expectedType"].string!)")
                    }
                }

                // https://github.com/ably/wiki/issues/22
                it("should encode and decode fixture messages as expected") {
                    let options = AblyTests.commonAppSetup()
                    let client = AblyTests.newRealtime(options)
                    defer { client.dispose(); client.close() }
                    let channel = client.channels.get("test")
                    channel.attach()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
                    if channel.state != .attached {
                        return
                    }

                    for (_, fixtureMessage) in fixtures["messages"] {
                        var receivedMessage: ARTMessage?

                        waitUntil(timeout: testTimeout) { done in
                            channel.subscribe { message in
                                channel.unsubscribe()
                                receivedMessage = message
                                done()
                            }

                            let request = NSMutableURLRequest(url: NSURL(string: "/channels/\(channel.name)/messages")! as URL)
                            request.httpMethod = "POST"
                            request.httpBody = try! fixtureMessage.rawData()
                            request.allHTTPHeaderFields = [
                                "Accept" : "application/json",
                                "Content-Type" : "application/json"
                            ]
                            client.rest.execute(request as URLRequest, withAuthOption: .on, completion: { _, _, err in
                                if let err = err {
                                    fail("\(err)")
                                }
                            })
                        }

                        guard let message = receivedMessage else {
                            continue
                        }

                        expectDataToMatch(message, fixtureMessage)

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([message]) { err in
                                if let err = err {
                                    fail("\(err)")
                                    done()
                                    return
                                }

                                let request = NSMutableURLRequest(url: NSURL(string: "/channels/\(channel.name)/messages?limit=1")! as URL)
                                request.httpMethod = "GET"
                                request.allHTTPHeaderFields = ["Accept" : "application/json"]
                                client.rest.execute(request as URLRequest, withAuthOption: .on, completion: { _, data, err in
                                    if let err = err {
                                        fail("\(err)")
                                        done()
                                        return
                                    }
                                    let persistedMessage = JSON(data: data!).array!.first!
                                    expect(persistedMessage["data"]).to(equal(fixtureMessage["data"]))
                                    expect(persistedMessage["encoding"]).to(equal(fixtureMessage["encoding"]))
                                    done()
                                })
                            }
                        }
                    }
                }

                let jsonOptions = AblyTests.commonAppSetup()
                jsonOptions.useBinaryProtocol = false
                let msgpackOptions = AblyTests.commonAppSetup()
                msgpackOptions.useBinaryProtocol = true

                it("should send messages through raw JSON POST and retrieve equal messages through MsgPack and JSON") {
                    let restPublishClient = ARTRest(options: jsonOptions)
                    let realtimeSubscribeClientMsgPack = AblyTests.newRealtime(msgpackOptions)
                    let realtimeSubscribeClientJSON = AblyTests.newRealtime(jsonOptions)
                    defer {
                        realtimeSubscribeClientMsgPack.close()
                        realtimeSubscribeClientJSON.close()
                    }

                    let realtimeSubscribeChannelMsgPack = realtimeSubscribeClientMsgPack.channels.get("test-subscribe")
                    let realtimeSubscribeChannelJSON = realtimeSubscribeClientJSON.channels.get(realtimeSubscribeChannelMsgPack.name)

                    waitUntil(timeout: testTimeout) { done in
                        let partlyDone = AblyTests.splitDone(2, done: done)
                        realtimeSubscribeChannelMsgPack.attach { _ in partlyDone() }
                        realtimeSubscribeChannelJSON.attach { _ in partlyDone() }
                    }

                    for (_, fixtureMessage) in fixtures["messages"] {
                        waitUntil(timeout: testTimeout) { done in
                            let partlyDone = AblyTests.splitDone(2, done: done)

                            realtimeSubscribeChannelMsgPack.subscribe { message in
                                realtimeSubscribeChannelMsgPack.unsubscribe()
                                expectDataToMatch(message, fixtureMessage)
                                partlyDone()
                            }

                            realtimeSubscribeChannelJSON.subscribe { message in
                                realtimeSubscribeChannelJSON.unsubscribe()
                                expectDataToMatch(message, fixtureMessage)
                                partlyDone()
                            }

                            let request = NSMutableURLRequest(url: NSURL(string: "/channels/\(realtimeSubscribeChannelMsgPack.name)/messages")! as URL)
                            request.httpMethod = "POST"
                            request.httpBody = try! fixtureMessage.rawData()
                            request.allHTTPHeaderFields = [
                                "Accept" : "application/json",
                                "Content-Type" : "application/json"
                            ]
                            restPublishClient.execute(request as URLRequest, withAuthOption: .on, completion: { _, _, err in
                                if let err = err {
                                    fail("\(err)")
                                }
                            })
                        }
                    }
                }

                it("should send messages through MsgPack and JSON and retrieve equal messages through raw JSON GET") {
                    let restPublishClientMsgPack = ARTRest(options: msgpackOptions)
                    let restPublishClientJSON = ARTRest(options: jsonOptions)
                    let restRetrieveClient = ARTRest(options: jsonOptions)

                    let restPublishChannelMsgPack = restPublishClientMsgPack.channels.get("test-publish")
                    let restPublishChannelJSON = restPublishClientJSON.channels.get(restPublishChannelMsgPack.name)

                    for (_, fixtureMessage) in fixtures["messages"] {
                        var data: AnyObject
                        if fixtureMessage["expectedType"] == "binary" {
                            data = fixtureMessage["expectedHexValue"].string!.dataFromHexadecimalString()! as AnyObject
                        } else {
                            data = fixtureMessage["expectedValue"].object as AnyObject
                        }

                        for restPublishChannel in [restPublishChannelMsgPack, restPublishChannelJSON] {
                            waitUntil(timeout: testTimeout) { done in
                                restPublishChannel.publish("event", data: data) { err in 
                                    if let err = err {
                                        fail("\(err)")
                                        done()
                                        return
                                    }
                                    done()
                                }
                            }

                            waitUntil(timeout: testTimeout) { done in
                                let request = NSMutableURLRequest(url: NSURL(string: "/channels/\(restPublishChannel.name)/messages?limit=1")! as URL)
                                request.httpMethod = "GET"
                                request.allHTTPHeaderFields = ["Accept" : "application/json"]
                                restRetrieveClient.execute(request as URLRequest, withAuthOption: .on, completion: { _, data, err in
                                    if let err = err {
                                        fail("\(err)")
                                        done()
                                        return
                                    }
                                    let persistedMessage = JSON(data: data!).array!.first!
                                    expect(persistedMessage["data"]).to(equal(persistedMessage["data"]))
                                    expect(persistedMessage["encoding"]).to(equal(fixtureMessage["encoding"]))
                                    done()
                                })
                            }
                        }
                    }
                }
            }

            it("should abort reconnection with new token if the server has requested it to authorise and after it the connection has been closed") {
                let options = AblyTests.commonAppSetup()
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }

                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.connected) { stateChange in
                        expect(stateChange?.reason).to(beNil())
                        done()
                    }
                }

                client.auth.options.authCallback = { tokenParams, completion in
                    getTestTokenDetails(ttl: 0.1) { tokenDetails, error in
                        expect(error).to(beNil())
                        guard let tokenDetails = tokenDetails else {
                            fail("TokenDetails is nil"); return
                        }
                        // Let the token expire
                        delay(0.1) {
                            completion(tokenDetails.token as ARTTokenDetailsCompatible?, nil)
                        }
                    }
                }

                let authMessage = ARTProtocolMessage()
                authMessage.action = .auth
                client.transport?.receive(authMessage)

                client.close()

                waitUntil(timeout: testTimeout) { done in
                    client.connection.once(.failed) { _ in
                        fail("Should not receive error 40142")
                    }
                    client.connection.once(.connected) { _ in
                        fail("Should not connect")
                    }
                    client.connection.once(.closed) { _ in
                        done()
                    }
                }
            }

        }
    }
}
