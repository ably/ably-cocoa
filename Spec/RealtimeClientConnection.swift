//
//  RealtimeClient.connection.swift
//  ably
//
//  Created by Ricardo Pereira on 03/11/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

import Quick
import Nimble

func countChannels(channels: ARTRealtimeChannels) -> Int {
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
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()

                    if let transport = client.transport as? TestProxyTransport, let url = transport.lastUrl {
                        expect(url.host).to(equal("realtime.ably.io"))
                    }
                    else {
                        XCTFail("MockTransport isn't working")
                    }
                    client.close()
                }

                it("should connect with query string params") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Failed:
                                AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                                    expect(query).to(haveParam("key", withValue: options.key ?? ""))
                                    expect(query).to(haveParam("echo", withValue: "true"))
                                    expect(query).to(haveParam("format", withValue: "json"))
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

                it("should connect with query string params including clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    options.autoConnect = false
                    options.echoMessages = false

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Failed:
                                AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                                    expect(query).to(haveParam("accessToken", withValue: client.auth.tokenDetails?.token ?? ""))
                                    expect(query).to(haveParam("echo", withValue: "false"))
                                    expect(query).to(haveParam("format", withValue: "json"))
                                    expect(query).to(haveParam("client_id", withValue: "client_string"))
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
            }

            // RTN3
            it("should connect automatically") {
                let options = AblyTests.commonAppSetup()
                var connected = false

                // Default
                expect(options.autoConnect).to(beTrue(), description: "autoConnect should be true by default")

                // The only way to control this functionality is with the options flag
                ARTRealtime(options: options).connection.on { stateChange in
                    let stateChange = stateChange!
                    let state = stateChange.current
                    let errorInfo = stateChange.reason
                    switch state {
                    case .Connected:
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
                var waiting = true

                waitUntil(timeout: testTimeout) { done in
                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .Connected:
                            if waiting {
                                XCTFail("Expected to be disconnected")
                            }
                            done()
                        default:
                            break
                        }
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                        waiting = false
                        client.connect()
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
                            case .Connecting:
                                if !alreadyDisconnected {
                                    events += [state]
                                }
                            case .Connected:
                                if alreadyClosed {
                                    client.onSuspended()
                                } else if alreadyDisconnected {
                                    client.close()
                                } else {
                                    events += [state]
                                    client.onDisconnected()
                                }
                            case .Disconnected:
                                events += [state]
                                alreadyDisconnected = true
                            case .Suspended:
                                events += [state]
                                client.onError(AblyTests.newErrorProtocolMessage())
                            case .Closing:
                                events += [state]
                            case .Closed:
                                events += [state]
                                alreadyClosed = true
                                client.connect()
                            case .Failed:
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

                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.Initialized.rawValue), description: "Should be INITIALIZED state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.Connecting.rawValue), description: "Should be CONNECTING state")
                    expect(events[2].rawValue).to(equal(ARTRealtimeConnectionState.Connected.rawValue), description: "Should be CONNECTED state")
                    expect(events[3].rawValue).to(equal(ARTRealtimeConnectionState.Disconnected.rawValue), description: "Should be DISCONNECTED state")
                    expect(events[4].rawValue).to(equal(ARTRealtimeConnectionState.Closing.rawValue), description: "Should be CLOSING state")
                    expect(events[5].rawValue).to(equal(ARTRealtimeConnectionState.Closed.rawValue), description: "Should be CLOSED state")
                    expect(events[6].rawValue).to(equal(ARTRealtimeConnectionState.Suspended.rawValue), description: "Should be SUSPENDED state")
                    expect(events[7].rawValue).to(equal(ARTRealtimeConnectionState.Failed.rawValue), description: "Should be FAILED state")

                    client.close()
                }

                // RTN4b
                it("should emit states on a new connection") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    let connection = client.connection
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Connecting:
                                events += [state]
                            case .Connected:
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

                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.Connecting.rawValue), description: "Should be CONNECTING state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.Connected.rawValue), description: "Should be CONNECTED state")

                    connection.close()
                }

                // RTN4c
                it("should emit states when connection is closed") {
                    let connection = ARTRealtime(options: AblyTests.commonAppSetup()).connection
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Connected:
                                connection.close()
                            case .Closing:
                                events += [state]
                            case .Closed:
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

                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.Closing.rawValue), description: "Should be CLOSING state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.Closed.rawValue), description: "Should be CLOSED state")

                    connection.close()
                }

                // RTN4d
                it("should have the current state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    let connection = client.connection
                    expect(connection.state.rawValue).to(equal(ARTRealtimeConnectionState.Initialized.rawValue), description: "Missing INITIALIZED state")

                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Connecting:
                                expect(connection.state.rawValue).to(equal(ARTRealtimeConnectionState.Connecting.rawValue), description: "Missing CONNECTING state")
                            case .Connected:
                                expect(connection.state.rawValue).to(equal(ARTRealtimeConnectionState.Connected.rawValue), description: "Missing CONNECTED state")
                                done()
                            default:
                                break
                            }
                        }
                        client.connect()
                    }

                    connection.close()
                }

                // RTN4f
                it("should have the reason which contains an ErrorInfo") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    let connection = client.connection

                    // TODO: ConnectionStateChange object

                    var errorInfo: ARTErrorInfo?
                    waitUntil(timeout: testTimeout) { done in
                        connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let reason = stateChange.reason
                            switch state {
                            case .Connected:
                                client.onError(AblyTests.newErrorProtocolMessage())
                            case .Failed:
                                errorInfo = reason
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(errorInfo).toNot(beNil())

                    connection.close()
                }
            }

            class TotalReach {
                // Easy way to create an atomic var
                static var shared = 0
                // This prevents others from using the default '()' initializer
                private init() {}
            }

            // RTN5
            it("basic operations should work simultaneously") {
                let options = AblyTests.commonAppSetup()
                options.echoMessages = false
                var disposable = [ARTRealtime]()
                let max = 50
                let channelName = "chat"

                TotalReach.shared = 0
                for _ in 1...max {
                    let client = ARTRealtime(options: options)
                    disposable.append(client)
                    let channel = client.channels.get(channelName)

                    channel.on { errorInfo in
                        if channel.state == .Attached {
                            TotalReach.shared += 1
                        }
                    }

                    channel.attach()
                }
                // All channels attached
                expect(TotalReach.shared).toEventually(equal(max), timeout: testTimeout, description: "Channels not attached")

                TotalReach.shared = 0
                for client in disposable {
                    let channel = client.channels.get(channelName)
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))

                    channel.subscribe { message in
                        expect(message.data as? String).to(equal("message_string"))
                        TotalReach.shared += 1
                    }

                    channel.publish(nil, data: "message_string", callback: nil)
                }

                // Sends 50 messages from different clients to the same channel
                // 50 messages for 50 clients = 50*50 total messages
                // echo is off, so we need to subtract one message per client
                expect(TotalReach.shared).toEventually(equal(max*max - max), timeout: testTimeout)

                expect(disposable.count).to(equal(max))

                expect(countChannels(disposable.first!.channels)).to(equal(1))
                expect(countChannels(disposable.last!.channels)).to(equal(1))
            }

            // RTN6
            it("should have an opened websocket connection and received a CONNECTED ProtocolMessage") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                client.setTransportClass(TestProxyTransport.self)
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
                        if state == .Connected && error == nil {
                            done()
                        }
                    }
                }

                if let webSocketTransport = client.transport as? ARTWebSocketTransport {
                    expect(webSocketTransport.isConnected).to(beTrue())
                }
                else {
                    XCTFail("WebSocket is not the default transport")
                }

                if let transport = client.transport as? TestProxyTransport {
                    // CONNECTED ProtocolMessage
                    expect(transport.protocolMessagesReceived.map{ $0.action }).to(contain(ARTProtocolMessageAction.Connected))
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
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            publishFirstTestMessage(client, completion: { error in
                                expect(error).to(beNil())
                                done()
                            })
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .Message }).last else {
                            XCTFail("No MESSAGE action was sent"); return
                        }

                        guard let receivedAck = transport.protocolMessagesReceived.filter({ $0.action == .Ack }).last else {
                            XCTFail("No ACK action was received"); return
                        }

                        expect(publishedMessage.msgSerial).to(equal(receivedAck.msgSerial))
                    }

                    it("successful receipt and acceptance of presence") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .Connected {
                                    let channel = client.channels.get("test")
                                    channel.on { errorInfo in
                                        if channel.state == .Attached {
                                            channel.presence.enterClient("client_string", data: nil, callback: { errorInfo in
                                                expect(errorInfo).to(beNil())
                                                done()
                                            })
                                        }
                                    }
                                    channel.attach()
                                }
                            }
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .Presence }).last else {
                            XCTFail("No PRESENCE action was sent"); return
                        }

                        guard let receivedAck = transport.protocolMessagesReceived.filter({ $0.action == .Ack }).last else {
                            XCTFail("No ACK action was received"); return
                        }

                        expect(publishedMessage.msgSerial).to(equal(receivedAck.msgSerial))
                    }

                    it("message failure") {
                        let options = AblyTests.commonAppSetup()
                        options.token = getTestToken(key: options.key, capability: "{ \"\(ARTChannels_getChannelNamePrefix!())-test\":[\"subscribe\"] }")
                        options.autoConnect = false
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            publishFirstTestMessage(client, completion: { error in
                                expect(error).toNot(beNil())
                                done()
                            })
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .Message }).last else {
                            XCTFail("No MESSAGE action was sent"); return
                        }

                        guard let receivedNack = transport.protocolMessagesReceived.filter({ $0.action == .Nack }).last else {
                            XCTFail("No NACK action was received"); return
                        }

                        expect(publishedMessage.msgSerial).to(equal(receivedNack.msgSerial))
                    }

                    it("presence failure") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let error = stateChange.reason
                                if state == .Connected {
                                    let channel = client.channels.get("test")
                                    channel.on { errorInfo in
                                        if channel.state == .Attached {
                                            channel.presence.enterClient("invalid", data: nil, callback: { errorInfo in
                                                expect(errorInfo).toNot(beNil())
                                                done()
                                            })
                                        }
                                    }
                                    channel.attach()
                                }
                            }
                        }

                        let transport = client.transport as! TestProxyTransport

                        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .Presence }).last else {
                            XCTFail("No PRESENCE action was sent"); return
                        }

                        guard let receivedNack = transport.protocolMessagesReceived.filter({ $0.action == .Nack }).last else {
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
                        private init() {}
                    }

                    it("should contain unique serially incrementing msgSerial along with the count") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

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
                        let acks = transport.protocolMessagesReceived.filter({ $0.action == .Ack })
                        let nacks = transport.protocolMessagesReceived.filter({ $0.action == .Nack })

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
                }

                // RTN7c
                context("should trigger the failure callback for the remaining pending messages if") {

                    it("connection is closed") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        let channel = client.channels.get("channel")
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Ack, .Nack]

                        waitUntil(timeout: testTimeout) { done in
                            channel.on { errorInfo in
                                if channel.state == .Attached {
                                    channel.publish(nil, data: "message", callback: { errorInfo in
                                        expect(errorInfo).toNot(beNil())
                                        done()
                                    })
                                    // Wait until the message is pushed to Ably first
                                    delay(1.0) {
                                        transport.simulateIncomingNormalClose()
                                    }
                                }
                            }
                            channel.attach()
                        }
                    }

                    it("connection state enters FAILED") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.clientId = "client_string"
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        let channel = client.channels.get("channel")
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Ack, .Nack]

                        waitUntil(timeout: testTimeout) { done in
                            channel.on { errorInfo in
                                if channel.state == .Attached {
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
                            channel.attach()
                        }
                    }

                    it("lost connection state") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.disconnectedRetryTimeout = 0.1
                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        let channel = client.channels.get("channel")

                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Ack, .Nack]

                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                        var gotPublishedCallback = false
                        channel.publish(nil, data: "message", callback: { errorInfo in
                            expect(errorInfo).toNot(beNil())
                            gotPublishedCallback = true
                        })

                        let oldConnectionId = client.connection.id!
                        // Wait until the message is pushed to Ably first
                        waitUntil(timeout: testTimeout) { done in
                            delay(1.0) { done() }
                        }

                        client.simulateLostConnectionAndState()
                        expect(gotPublishedCallback).to(beFalse())
                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                        expect(client.connection.id).toNot(equal(oldConnectionId))
                        expect(gotPublishedCallback).to(beTrue())
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
                            if state == .Connected {
                                expect(connection.id).toNot(beNil())
                                done()
                            }
                            else if state == .Connecting {
                                expect(connection.id).to(beNil())
                            }
                        }
                    }
                }

                // RTN8b
                it("should have unique IDs") {
                    let options = AblyTests.commonAppSetup()
                    var disposable = [ARTRealtime]()
                    var ids = [String]()
                    let max = 25

                    waitUntil(timeout: testTimeout) { done in
                        for _ in 1...max {
                            disposable.append(ARTRealtime(options: options))
                            let currentConnection = disposable.last!.connection
                            currentConnection.on { stateChange in
                                let stateChange = stateChange!
                                let state = stateChange.current
                                let errorInfo = stateChange.reason
                                if state == .Connected {
                                    guard let connectionId = currentConnection.id else {
                                        fail("connectionId is nil on CONNECTED")
                                        done()
                                        return
                                    }
                                    expect(ids).toNot(contain(connectionId))
                                    ids.append(connectionId)

                                    currentConnection.close()

                                    if ids.count == max {
                                        done()
                                    }
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
                            if state == .Connected {
                                expect(connection.id).toNot(beNil())
                                done()
                            }
                            else if state == .Connecting {
                                expect(connection.key).to(beNil())
                            }
                        }
                    }
                }

                // RTN9b
                it("should have unique connection keys") {
                    let options = AblyTests.commonAppSetup()
                    var disposable = [ARTRealtime]()
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
                                if state == .Connected {
                                    guard let connectionKey = currentConnection.key else {
                                        fail("connectionKey is nil on CONNECTED")
                                        done()
                                        return
                                    }
                                    expect(keys).toNot(contain(connectionKey))
                                    keys.append(connectionKey)

                                    currentConnection.close()

                                    if keys.count == max {
                                        done()
                                    }
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
                            if state == .Connected {
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
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                    expect(client.connection.serial).to(equal(-1))

                    for index in 0...3 {
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: "message", callback: { errorInfo in
                                expect(errorInfo).to(beNil())
                                // Updated
                                expect(client.connection.serial).to(equal(Int64(index)))
                                done()
                            })
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

                    var lastSerial: Int64 = 0
                    for _ in 1...5 {
                        channel.publish(nil, data: "message", callback: { errorInfo in
                            expect(errorInfo).to(beNil())
                            lastSerial = client.connection.serial
                        })
                    }
                    expect(lastSerial).toEventually(equal(4), timeout: testTimeout)

                    options.recover = client.connection.recoveryKey

                    let recoveredClient = ARTRealtime(options: options)
                    defer { recoveredClient.close() }
                    expect(recoveredClient.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        expect(recoveredClient.connection.serial).to(equal(lastSerial))
                        recoveredClient.channels.get("test").publish(nil, data: "message", callback: { errorInfo in
                            expect(errorInfo).to(beNil())
                            expect(recoveredClient.connection.serial).to(equal(lastSerial + 1))
                            done()
                        })
                    }
                }

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
                    expect(lastStateChange!.current).toEventually(equal(ARTRealtimeConnectionState.Closing), timeout: testTimeout)
                }

                // RTN12a
                it("if CONNECTED, should send a CLOSE action, change state to CLOSING and receive a CLOSED action") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
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
                            case .Connected:
                                client.close()
                            case .Closing:
                                expect(transport.protocolMessagesSent.filter({ $0.action == .Close })).to(haveCount(1))
                                states += [state]
                            case.Closed:
                                expect(transport.protocolMessagesReceived.filter({ $0.action == .Closed })).to(haveCount(1))
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
                    expect(states[0]).to(equal(ARTRealtimeConnectionState.Closing))
                    expect(states[1]).to(equal(ARTRealtimeConnectionState.Closed))
                }

                // RTN12b
                it("should transition to CLOSED action when the close process timeouts") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()
                    defer {
                        client.dispose()
                        client.close()
                    }

                    let transport = client.transport as! TestProxyTransport
                    transport.actionsIgnored += [.Closed]

                    var states: [ARTRealtimeConnectionState] = []
                    var start: NSDate?
                    var end: NSDate?

                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .Connected:
                            client.close()
                        case .Closing:
                            start = NSDate()
                            states += [state]
                        case .Closed:
                            end = NSDate()
                            states += [state]
                        case .Disconnected:
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

                    expect(states[0]).to(equal(ARTRealtimeConnectionState.Closing))
                    expect(states[1]).to(equal(ARTRealtimeConnectionState.Closed))
                }

                // RTN12c
                it("transitions to the CLOSING state and then to the CLOSED state if the transport is abruptly closed") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
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
                            case .Connected:
                                states += [state]
                                client.close()
                            case .Closing:
                                states += [state]
                                transport.simulateIncomingAbruptlyClose()
                            case .Closed:
                                states += [state]
                                done()
                            case .Disconnected, .Suspended, .Failed:
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

                    expect(states[0]).to(equal(ARTRealtimeConnectionState.Connected))
                    expect(states[1]).to(equal(ARTRealtimeConnectionState.Closing))
                    expect(states[2]).to(equal(ARTRealtimeConnectionState.Closed))
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

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    client.onDisconnected()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Disconnected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        client.connection.once { stateChange in
                            expect(stateChange!.current).to(equal(ARTRealtimeConnectionState.Closed))
                            partialDone()
                        }

                        client.close()

                        delay(options.disconnectedRetryTimeout + 0.5) {
                            // Make sure the retry doesn't happen.
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closed))
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

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    client.onSuspended()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Suspended), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        client.connection.once { stateChange in
                            expect(stateChange!.current).to(equal(ARTRealtimeConnectionState.Closed))
                            partialDone()
                        }

                        client.close()

                        delay(options.suspendedRetryTimeout + 0.5) {
                            // Make sure the retry doesn't happen.
                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closed))
                            partialDone()
                        }
                    }
                }
            }

            // RTN13b
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

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Initialized))
                    expect { client.ping { _ in } }.to(raiseException())

                    client.connect()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                    client.onSuspended()

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Suspended))
                    expect { client.ping { _ in } }.to(raiseException())

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                    client.close()

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closing))
                    expect { client.ping { _ in } }.to(raiseException())

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Closed), timeout: testTimeout)
                    expect { client.ping { _ in } }.to(raiseException())

                    client.onError(AblyTests.newErrorProtocolMessage())

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Failed))
                    expect { client.ping { _ in } }.to(raiseException())
                }
            }

            // RTN13
            context("Ping") {

                // RTN13a
                it("should send a ProtocolMessage with action HEARTBEAT and expects a HEARTBEAT message in response") {
                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.ping() { error in
                            expect(error).to(beNil())
                            let transport = client.transport as! TestProxyTransport
                            expect(transport.protocolMessagesSent.filter{ $0.action == .Heartbeat }).to(haveCount(1))
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .Heartbeat }).to(haveCount(1))
                            done()
                        }
                    }
                }

            }

            // RTN13
            context("Ping") {

                // RTN13c
                pending("should fail if a HEARTBEAT ProtocolMessage is not received within the default realtime request timeout") {
                    let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                    defer { client.close() }
                    // TODO
                    //ARTDefault.connectionStateTtl()
                    waitUntil(timeout: testTimeout) { done in
                        let start = NSDate()
                        client.ping() { error in
                            let end = NSDate()
                            expect(error.message).to(contain("timed out"))
                            expect(end.timeIntervalSinceDate(start)).to(beCloseTo(ARTDefault.connectionStateTtl()))
                            done()
                        }
                    }
                }

            }

            // RTN14a
            it("should enter FAILED state when API key is invalid") {
                let options = AblyTests.commonAppSetup()
                options.key = String(options.key!.characters.reverse())
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
                        case .Failed:
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
                        callback(getTestTokenDetails(key: options.key, capability: tokenParams.capability, ttl: tokenParams.ttl), nil)
                    }
                    let tokenTtl = 1.0
                    options.token = getTestToken(key: options.key, ttl: tokenTtl)

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    defer {
                        client.dispose()
                        client.close()
                    }

                    // Let the token expire
                    waitUntil(timeout: testTimeout) { done in
                        delay(tokenTtl) {
                            done()
                        }
                    }

                    var transport: TestProxyTransport!

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Connected:
                                expect(errorInfo).to(beNil())
                                // New token
                                expect(client.auth.tokenDetails!.token).toNot(equal(options.token))
                                done()
                            case .Failed, .Disconnected, .Suspended:
                                fail("Should not emit error (\(errorInfo))")
                                done()
                            default:
                                break
                            }
                        }
                        client.connect()
                        transport = client.transport as! TestProxyTransport
                    }

                    let failures = transport.protocolMessagesReceived.filter({ $0.action == .Error })

                    if failures.count != 1 {
                        fail("Should have only one connection request fail")
                        return
                    }

                    expect(failures[0].error!.code).to(equal(40142)) //Token expired
                }

                it("should transition to Failed when the token renewal fails") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let tokenTtl = 1.0
                    let tokenDetails = getTestTokenDetails(key: options.key, capability: nil, ttl: tokenTtl)!
                    options.token = tokenDetails.token
                    options.authCallback = { tokenParams, callback in
                        callback(tokenDetails, nil) // Return the same expired token again.
                    }

                    // Let the token expire
                    waitUntil(timeout: testTimeout) { done in
                        delay(tokenTtl) {
                            done()
                        }
                    }

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
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
                            case .Connected:
                                fail("Should not be connected")
                                done()
                            case .Failed, .Disconnected, .Suspended:
                                guard let errorInfo = errorInfo else {
                                    fail("ErrorInfo is nil"); done(); return
                                }
                                expect(errorInfo.code).to(equal(40142)) //Token expired
                                done()
                            default:
                                break
                            }
                        }
                        client.connect()
                        transport = client.transport as! TestProxyTransport
                    }

                    let failures = transport.protocolMessagesReceived.filter({ $0.action == .Error })

                    if failures.count != 2 {
                        fail("Should have two connection request fail")
                        return
                    }

                    expect(failures[0].error!.code).to(equal(40142))
                    expect(failures[1].error!.code).to(equal(40142))
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
                    client.setTransportClass(TestProxyTransport.self)
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
                            case .Connected:
                                fail("Should not be connected")
                                done()
                            case .Failed, .Disconnected, .Suspended:
                                guard let errorInfo = errorInfo else {
                                    fail("ErrorInfo is nil"); done(); return
                                }
                                expect(errorInfo.code).to(equal(40142)) //Token expired
                                done()
                            default:
                                break
                            }
                        }
                        client.connect()
                        transport = client.transport as! TestProxyTransport
                    }

                    let failures = transport.protocolMessagesReceived.filter({ $0.action == .Error })

                    if failures.count != 1 {
                        fail("Should have only one connection request fail")
                        return
                    }

                    expect(failures[0].error!.code).to(equal(40142))
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

                    expect(channel1.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    let firstConnection: (id: String, key: String) = (client1.connection.id!, client1.connection.key!)

                    // Connection state cannot be resumed
                    client1.simulateLostConnectionAndState()

                    channel2.publish(nil, data: "message") { errorInfo in
                        expect(errorInfo).to(beNil())
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client1.connection.once(.Connecting) { _ in
                            expect(client1.resuming).to(beTrue())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client1.connection.once(.Connected) { _ in
                            expect(client1.resuming).to(beFalse())
                            expect(client1.connection.id).toNot(equal(firstConnection.id))
                            expect(client1.connection.key).toNot(equal(firstConnection.key))
                            done()
                        }
                    }
                    
                    expect(states).to(equal([.Connecting, .Connected, .Disconnected, .Connecting, .Connected]))
                }

                // RTN15b
                context("reconnects to the websocket endpoint with additional querystring params") {

                    // RTN15b1, RTN15b2
                    it("resume is the private connection key and connection_serial is the most recent ProtocolMessage#connectionSerial received") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 0.1
                        let client = AblyTests.newRealtime(options)
                        defer { client.close() }

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                        let expectedConnectionKey = client.connection.key!
                        let expectedConnectionSerial = client.connection.serial
                        client.onDisconnected()

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Connected) { _ in
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
                    pending("CONNECTED ProtocolMessage with the same connectionId as the current client, and no error") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                        let expectedConnectionId = client.connection.id
                        client.onDisconnected()

                        channel.publish(nil, data: "queued message")
                        expect(client.queuedMessages).toEventually(haveCount(1), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Connected) { stateChange in
                                let transport = client.transport as! TestProxyTransport
                                let connectedPM = transport.protocolMessagesReceived.filter{ $0.action == .Connected }[0]
                                expect(connectedPM.connectionId).to(equal(expectedConnectionId))
                                expect(stateChange!.reason).to(beNil())
                                done()
                            }
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))
                        expect(client.queuedMessages).toEventually(haveCount(0), timeout: testTimeout)
                    }

                    // RTN15c2
                    pending("CONNECTED ProtocolMessage with the same connectionId as the current client and an non-fatal error") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                        let expectedConnectionId = client.connection.id
                        client.onDisconnected()

                        channel.publish(nil, data: "queued message")
                        expect(client.queuedMessages).toEventually(haveCount(1), timeout: testTimeout)

                        client.connection.once(.Connecting) { _ in
                            let transport = client.transport as! TestProxyTransport
                            transport.beforeProcessingReceivedMessage = { protocolMessage in
                                if protocolMessage.action == .Connected {
                                    protocolMessage.error = ARTErrorInfo.createWithCode(0, message: "Injected error")
                                }
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Connected) { stateChange in
                                expect(stateChange!.reason!.message).to(equal("Injected error"))
                                expect(client.connection.errorReason).to(beIdenticalTo(stateChange!.reason))
                                let transport = client.transport as! TestProxyTransport
                                let connectedPM = transport.protocolMessagesReceived.filter{ $0.action == .Connected }[0]
                                expect(connectedPM.connectionId).to(equal(expectedConnectionId))
                                expect(client.connection.id).to(equal(expectedConnectionId))
                                done()
                            }
                        }

                        channel.once(.Attaching) { _ in
                            let transport = client.transport as! TestProxyTransport
                            transport.beforeProcessingReceivedMessage = { protocolMessage in
                                if protocolMessage.action == .Attached {
                                    protocolMessage.error = ARTErrorInfo.createWithCode(0, message: "Channel injected error")
                                }
                            }
                        }

                        channel.once(.Attached) { error in
                            expect(error!.message).to(equal("Channel injected error"))
                            expect(channel.errorReason).to(beIdenticalTo(error))
                        }

                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))
                        expect(client.queuedMessages).toEventually(haveCount(0), timeout: testTimeout)
                    }

                    // RTN15c3
                    pending("CONNECTED ProtocolMessage with a new connectionId and an error") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                        let expectedConnectionId = client.connection.id
                        client.simulateLostConnectionAndState()

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Connected) { stateChange in
                                expect(stateChange!.reason!.code).to(equal(80008))
                                expect(stateChange!.reason!.message).to(contain("Unable to recover connection"))
                                expect(client.connection.errorReason).to(beIdenticalTo(stateChange!.reason))
                                let transport = client.transport as! TestProxyTransport
                                let connectedPM = transport.protocolMessagesReceived.filter{ $0.action == .Connected }[0]
                                expect(connectedPM.connectionId).toNot(equal(expectedConnectionId))
                                expect(client.connection.id).to(equal(connectedPM.connectionId))
                                done()
                            }
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detached))
                        expect(channel.errorReason!.code).to(equal(80008))
                        expect(channel.errorReason!.message).to(contain("Unable to recover connection"))
                        expect(client.msgSerial).to(equal(0))
                    }

                    // RTN15c4
                    pending("ERROR ProtocolMessage indicating a fatal error in the connection") {
                        let options = AblyTests.commonAppSetup()
                        options.disconnectedRetryTimeout = 1.0
                        let client = AblyTests.newRealtime(options)
                        defer { client.close() }
                        let channel = client.channels.get("test")

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                        client.onDisconnected()

                        let protocolError = AblyTests.newErrorProtocolMessage()
                        client.connection.once(.Connecting) { _ in
                            // Resuming
                            let transport = client.transport as! TestProxyTransport
                            transport.actionsIgnored += [.Connected]
                            client.onError(protocolError)
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Failed) { stateChange in
                                expect(stateChange!.reason).to(beIdenticalTo(protocolError.error))
                                expect(client.connection.errorReason).to(beIdenticalTo(protocolError.error))
                                done()
                            }
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Failed))
                        expect(channel.errorReason).to(beIdenticalTo(protocolError.error))
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
                        channel1.subscribeWithAttachCallback({ errorInfo in
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
                        client1.connection.once(.Connecting) { _ in
                            expect(receivedMessages).to(beEmpty())
                            done()
                        }
                    }

                    expect(client1.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                    expect(receivedMessages).toEventually(equal(expectedMessages), timeout: testTimeout)
                }

                // RTN15e
                context("when a connection is resumed") {

                    it("the connection#key may change and will be provided in the first CONNECTED ProtocolMessage#connectionDetails") {
                        let options = AblyTests.commonAppSetup()
                        options.autoConnect = false
                        options.disconnectedRetryTimeout = 1.0

                        let client = ARTRealtime(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }
                        let channel = client.channels.get("test")

                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                        client.onDisconnected()

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Connecting) { _ in
                                client.connection.setKey("key_to_be_replaced")
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.connection.once(.Connected) { _ in
                                let transport = client.transport as! TestProxyTransport
                                let firstConnectionDetails = transport.protocolMessagesReceived.filter{ $0.action == .Connected }[0].connectionDetails
                                expect(firstConnectionDetails!.connectionKey).toNot(beNil())
                                expect(client.connection.key).to(equal(firstConnectionDetails!.connectionKey))
                                done()
                            }
                        }
                    }

                }

                // RTN15g
                it("when the connection resume has failed, all channels should be detached with an error reason") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 1.0

                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    client.simulateLostConnectionAndState()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)
                    expect(channel.errorReason!.message).to(contain("Unable to recover connection"))
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
                        channelReceive.subscribeWithAttachCallback({ error in
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
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { _ in
                            expect(client.connection.serial).to(equal(-1))
                            expect(client.connection.recoveryKey).to(equal("\(client.connection.key!):\(client.connection.serial)"))
                        }
                        channel.publish(nil, data: "message") { error in
                            expect(error).to(beNil())
                            expect(client.connection.serial).to(equal(0))
                            done()
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

                    expect(clientOriginal.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    let expectedConnectionId = clientOriginal.connection.id

                    options.recover = clientOriginal.connection.recoveryKey
                    clientOriginal.onError(AblyTests.newErrorProtocolMessage())

                    let clientRecover = AblyTests.newRealtime(options)
                    defer { clientRecover.close() }

                    waitUntil(timeout: testTimeout) { done in
                        clientRecover.connection.once(.Connected) { _ in
                            let transport = clientRecover.transport as! TestProxyTransport
                            let firstConnectionDetails = transport.protocolMessagesReceived.filter{ $0.action == .Connected }.first!.connectionDetails
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
                    defer { client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { _ in
                            client.connection.once(.Closed) { _ in
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
                    defer { client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange!.reason!.message).to(contain("Unable to recover connection"))
                            expect(client.connection.errorReason).to(beIdenticalTo(stateChange!.reason))
                            done()
                        }
                    }
                }

            }

            // RTN18
            context("state change side effects") {

                // RTN18a
                it("when a connection enters the DISCONNECTED state, it will have no effect on the the channel states") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer {
                        client.dispose()
                        client.close()
                    }

                    let channel = client.channels.get("test")
                    channel.attach()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    client.onDisconnected()

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Disconnected))
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))

                    waitUntil(timeout: testTimeout + options.disconnectedRetryTimeout) { done in
                        channel.publish(nil, data: "queuedMessage", callback: { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        })
                    }
                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                }

                // RTN18b
                context("all channels will move to DETACHED state") {

                    it("when a connection enters SUSPENDED state") {
                        let options = AblyTests.commonAppSetup()
                        options.suspendedRetryTimeout = 0.1
                        let client = ARTRealtime(options: options)
                        defer {
                            client.dispose()
                            client.close()
                        }

                        let channel = client.channels.get("test")
                        channel.attach()

                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                        client.simulateSuspended()

                        expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Suspended))
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            // Reject publishing of messages
                            channel.publish(nil, data: "message", callback: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                expect(errorInfo!.code).to(equal(90001))
                                done()
                            })
                        }

                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connecting), timeout: options.suspendedRetryTimeout + 1.0)
                        channel.attach()
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            // Accept publishing of messages
                            channel.publish(nil, data: "message", callback: { errorInfo in
                                expect(errorInfo).to(beNil())
                                done()
                            })
                        }
                    }
                    
                    it("when a connection enters CLOSED state") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRealtime(options: options)
                        defer {
                            client.dispose()
                            client.close()
                        }
                        let channel = client.channels.get("test")
                        channel.attach()
                        
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                        
                        client.close()
                        
                        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Closed), timeout: testTimeout)
                        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Detached), timeout: testTimeout)
                        
                        waitUntil(timeout: testTimeout) { done in
                            // Reject publishing of messages
                            channel.publish(nil, data: "message", callback: { errorInfo in
                                expect(errorInfo).toNot(beNil())
                                expect(errorInfo!.code).to(equal(90001))
                                done()
                            })
                        }
                    }
                    
                }
                
                // RTN18c
                it("when a connection enters FAILED state, all channels will move to FAILED state") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer {
                        client.dispose()
                        client.close()
                    }
                    let channel = client.channels.get("test")
                    channel.attach()
                    
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)
                    
                    client.onError(AblyTests.newErrorProtocolMessage())
                    
                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Failed))
                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Failed), timeout: testTimeout)
                    
                    waitUntil(timeout: testTimeout) { done in
                        // Reject publishing of messages
                        channel.publish(nil, data: "message", callback: { errorInfo in
                            expect(errorInfo).toNot(beNil())
                            expect(errorInfo!.code).to(equal(90001))
                            done()
                        })
                    }
                }
                
            }

            // RTN19
            it("attributes within ConnectionDetails should be used as defaults") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let realtime = AblyTests.newRealtime(options)
                defer { realtime.close() }

                waitUntil(timeout: testTimeout) { done in
                    realtime.connection.once(.Connecting) { stateChange in
                        expect(stateChange!.reason).to(beNil())

                        let transport = realtime.transport as! TestProxyTransport
                        transport.beforeProcessingReceivedMessage = { protocolMessage in
                            if protocolMessage.action == .Connected {
                                protocolMessage.connectionDetails!.clientId = "john"
                                protocolMessage.connectionDetails!.connectionKey = "123"
                            }
                        }
                    }
                    realtime.connection.once(.Connected) { stateChange in
                        expect(stateChange!.reason).to(beNil())

                        let transport = realtime.transport as! TestProxyTransport
                        let connectedProtocolMessage = transport.protocolMessagesReceived.filter{ $0.action == .Connected }[0]

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
                    options.logLevel = .Debug
                    options.disconnectedRetryTimeout = 0.1
                    let client = AblyTests.newRealtime(options)
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    let transport = client.transport as! TestProxyTransport

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { _ in done() }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        transport.ignoreSends = true
                        channel.publish(nil, data: "message") { error in
                            expect(error).to(beNil())
                            let newTransport = client.transport as! TestProxyTransport
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .Connected }).to(haveCount(1))
                            expect(newTransport.protocolMessagesReceived.filter{ $0.action == .Connected }).to(haveCount(1))
                            expect(transport.protocolMessagesSent.filter{ $0.action == .Message }).to(haveCount(0))
                            expect(transport.protocolMessagesSentIgnored.filter{ $0.action == .Message }).to(haveCount(1))
                            expect(newTransport.protocolMessagesSent.filter{ $0.action == .Message }).to(haveCount(1))
                            done()
                        }
                        transport.ignoreSends = false
                        client.onDisconnected()
                    }
                }

                // RTN19b
                it("should resent the ATTACH message if there are any pending channels") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 0.1
                    let client = AblyTests.newRealtime(options)
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    let transport = client.transport as! TestProxyTransport

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        transport.ignoreSends = true
                        channel.attach() { error in
                            expect(error).to(beNil())
                            let newTransport = client.transport as! TestProxyTransport
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .Connected }).to(haveCount(1))
                            expect(newTransport.protocolMessagesReceived.filter{ $0.action == .Connected }).to(haveCount(1))
                            expect(transport.protocolMessagesSent.filter{ $0.action == .Attach }).to(haveCount(0))
                            expect(transport.protocolMessagesSentIgnored.filter{ $0.action == .Attach }).to(haveCount(1))
                            expect(newTransport.protocolMessagesSent.filter{ $0.action == .Attach }).to(haveCount(1))
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Attaching))
                        transport.ignoreSends = false
                        client.onDisconnected()
                    }
                }

                // RTN19b
                it("should resent the DETACH message if there are any pending channels") {
                    let options = AblyTests.commonAppSetup()
                    options.disconnectedRetryTimeout = 0.1
                    let client = AblyTests.newRealtime(options)
                    defer { client.close() }
                    let channel = client.channels.get("test")
                    let transport = client.transport as! TestProxyTransport

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach() { _ in done() }
                    }

                    waitUntil(timeout: testTimeout * 1000) { done in
                        transport.ignoreSends = true
                        channel.detach() { error in
                            expect(error).to(beNil())
                            let newTransport = client.transport as! TestProxyTransport
                            expect(transport.protocolMessagesReceived.filter{ $0.action == .Connected }).to(haveCount(1))
                            expect(newTransport.protocolMessagesReceived.filter{ $0.action == .Connected }).to(haveCount(1))
                            expect(transport.protocolMessagesSent.filter{ $0.action == .Detach }).to(haveCount(0))
                            expect(transport.protocolMessagesSentIgnored.filter{ $0.action == .Detach }).to(haveCount(1))
                            expect(newTransport.protocolMessagesSent.filter{ $0.action == .Detach }).to(haveCount(1))
                            done()
                        }
                        expect(channel.state).to(equal(ARTRealtimeChannelState.Detaching))
                        transport.ignoreSends = false
                        client.onDisconnected()
                    }
                }

            }

        }
    }
}
