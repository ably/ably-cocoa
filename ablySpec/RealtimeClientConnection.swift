//
//  RealtimeClient.connection.swift
//  ably
//
//  Created by Ricardo Pereira on 03/11/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

import Quick
import Nimble

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
                        client.eventEmitter.on { state, errorInfo in
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
                        client.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Failed:
                                AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                if let transport = client.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                                    expect(query).to(haveParam("accessToken", withValue: client.auth().tokenDetails?.token ?? ""))
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
                ARTRealtime(options: options).eventEmitter.on { state, errorInfo in
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
                    client.eventEmitter.on { state, errorInfo in
                        switch state {
                        case .Initialized:
                            // Delay 5 seconds to check if it is connecting by itself
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                                waiting = false
                                client.connect()
                            }
                        case .Connected:
                            if waiting {
                                XCTFail("Expected to be disconnected")
                            }
                            done()
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

                    let client = ARTRealtime(options: options)
                    let connection = client.connection()
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Initialized:
                                events += [state]
                                connection.connect()
                            case .Connecting:
                                events += [state]
                            case .Connected:
                                events += [state]
                                client.onDisconnected()
                            case .Disconnected:
                                events += [state]
                                client.close()
                            case .Suspended:
                                events += [state]
                                client.onError(AblyTests.newErrorProtocolMessage())
                            case .Closing:
                                events += [state]
                            case .Closed:
                                events += [state]
                                client.onSuspended()
                            case .Failed:
                                events += [state]
                                expect(errorInfo).toNot(beNil(), description: "Error is nil")
                                done()
                            }
                        }
                    }

                    if events.count != 8 {
                        fail("Missing some states")
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
                    let connection = ARTRealtime(options: AblyTests.commonAppSetup()).connection()
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
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
                    let connection = ARTRealtime(options: AblyTests.commonAppSetup()).connection()
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
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
                    let connection = client.connection()
                    expect(connection.state.rawValue).to(equal(ARTRealtimeConnectionState.Initialized.rawValue), description: "Missing INITIALIZED state")

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
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
                    let connection = client.connection()

                    // TODO: ConnectionStateChange object

                    var errorInfo: ARTErrorInfo?
                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, reason in
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
                    let channel = client.channel(channelName)

                    channel.subscribeToStateChanges { state, status in
                        if state == .Attached {
                            TotalReach.shared++
                        }
                    }

                    channel.attach()
                }
                // All channels attached
                expect(TotalReach.shared).toEventually(equal(max), timeout: testTimeout, description: "Channels not attached")

                TotalReach.shared = 0
                for client in disposable {
                    let channel = client.channel(channelName)
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))

                    channel.subscribe { message, errorInfo in
                        expect(message.payload.payload as? String).to(equal("message_string"))
                        TotalReach.shared++
                    }

                    channel.publish("message_string", cb: nil)
                }

                // Sends 50 messages from different clients to the same channel
                // 50 messages for 50 clients = 50*50 total messages
                // echo is off, so we need to subtract one message per client
                expect(TotalReach.shared).toEventually(equal(max*max - max), timeout: testTimeout)

                expect(disposable.count).to(equal(max))
                expect(disposable.first?.channels().count).to(equal(1))
                expect(disposable.last?.channels().count).to(equal(1))
            }

            // RTN6
            it("should have an opened websocket connection and received a CONNECTED ProtocolMessage") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                client.setTransportClass(TestProxyTransport.self)
                client.connect()

                waitUntil(timeout: testTimeout) { done in
                    client.eventEmitter.on({ state, error in
                        expect(error).to(beNil())
                        if state == .Connected && error == nil {
                            done()
                        }
                    })
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

                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                options.clientId = "client_string"
                let client = ARTRealtime(options: options)
                client.setTransportClass(TestProxyTransport.self)

                // RTN7a
                context("should expect either an ACK or NACK to confirm") {

                    it("successful receipt and acceptance of message") {
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

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
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.eventEmitter.on { state, error in
                                if state == .Connected {
                                    let channel = client.channel("test")
                                    channel.subscribeToStateChanges { state, status in
                                        if state == .Attached {
                                            channel.presence().enterClient("client_string", data: nil, cb: { status in
                                                expect(status.state).to(equal(ARTState.Ok))
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
                        let options = AblyTests.clientOptions()
                        options.token = getTestToken(capability: "{ \"test\":[\"subscribe\"] }")
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
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        waitUntil(timeout: testTimeout) { done in
                            client.eventEmitter.on { state, error in
                                if state == .Connected {
                                    let channel = client.channel("test")
                                    channel.subscribeToStateChanges { state, status in
                                        if state == .Attached {
                                            channel.presence().enterClient("invalid", data: nil, cb: { status in
                                                expect(status.state).to(equal(ARTState.Error))
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
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        let channel = client.channel("channel")
                        channel.attach()

                        waitUntil(timeout: testTimeout) { done in
                            channel.publish("message", cb: { status in
                                expect(status.state).to(equal(ARTState.Ok))
                                done()
                            })
                        }

                        TotalMessages.expected = 5
                        for index in 1...TotalMessages.expected {
                            channel.publish("message\(index)", cb: { status in
                                if status.state == ARTState.Ok {
                                    TotalMessages.succeeded++
                                }
                            })
                        }
                        expect(TotalMessages.succeeded).toEventually(equal(TotalMessages.expected), timeout: testTimeout)

                        waitUntil(timeout: testTimeout) { done in
                            channel.presence().enterClient("invalid", data: nil, cb: { status in
                                expect(status.state).to(equal(ARTState.Error))
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
                pending("should trigger the failure callback for the remaining pending messages if") {

                    it("connection is closed") {
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        let channel = client.channel("channel")
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Ack, .Nack]

                        waitUntil(timeout: testTimeout) { done in
                            channel.subscribeToStateChanges { state, status in
                                if state == .Attached {
                                    channel.publish("message", cb: { status in
                                        expect(status.state).to(equal(ARTState.Error))
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
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        let channel = client.channel("channel")
                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Ack, .Nack]

                        waitUntil(timeout: testTimeout) { done in
                            channel.subscribeToStateChanges { state, status in
                                if state == .Attached {
                                    channel.publish("message", cb: { status in
                                        expect(status.state).to(equal(ARTState.Error))
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
                        let client = ARTRealtimeExtended(options: options)
                        client.setTransportClass(TestProxyTransport.self)
                        client.connect()
                        defer { client.close() }

                        let channel = client.channel("channel")

                        let transport = client.transport as! TestProxyTransport
                        transport.actionsIgnored += [.Ack, .Nack]

                        waitUntil(timeout: testTimeout + options.disconnectedRetryTimeout) { done in
                            channel.subscribeToStateChanges { state, status in
                                if state == .Attached {
                                    channel.publish("message", cb: { status in
                                        expect(status.state).to(equal(ARTState.Error))
                                        done()
                                    })
                                    // Wait until the message is pushed to Ably first
                                    delay(1.0) {
                                        client.simulateLostConnection()
                                        expect(client.connection().state).toEventually(equal(ARTRealtimeConnectionState.Connecting), timeout: options.disconnectedRetryTimeout)
                                    }
                                }
                            }
                            channel.attach()
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
                    let connection = client.connection()

                    expect(connection.id).to(beNil())

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
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

                    connection.close()
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
                            let currentConnection = disposable.last!.connection()
                            currentConnection.eventEmitter.on { state, errorInfo in
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
                    let connection = client.connection()

                    expect(connection.key).to(beNil())

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
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
                            let currentConnection = disposable.last!.connection()
                            currentConnection.eventEmitter.on { state, errorInfo in
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
                    defer { client.close() }
                    waitUntil(timeout: testTimeout) { done in
                        client.eventEmitter.on { state, errorInfo in
                            if state == .Connected {
                                expect(client.connection().serial).to(equal(-1))
                                done()
                            }
                        }
                    }
                }

                // RTN10b
                pending("should not update when a message is sent but increments by one when ACK is received") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    let channel = client.channel("test")

                    for index in 0...5 {
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish("message", cb: { status in
                                expect(status.state).to(equal(ARTState.Ok))
                                // Updated
                                expect(client.connection().serial).to(equal(Int64(index)))
                                done()
                            })
                            // Not updated
                            expect(client.connection().serial).to(equal(Int64(index - 1)))
                        }
                    }
                }

                // RTN10c
                pending("should have last known connection serial from restored connection") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    let channel = client.channel("test")

                    var lastSerial: Int64 = 0
                    for _ in 1...5 {
                        channel.publish("message", cb: { status in
                            expect(status.state).to(equal(ARTState.Ok))
                            lastSerial = client.connection().serial
                        })
                    }
                    expect(lastSerial).toEventually(equal(4), timeout: testTimeout)

                    options.recover = client.recoveryKey()

                    let recoveredClient = ARTRealtime(options: options)
                    defer { recoveredClient.close() }
                    let recoveredChannel = recoveredClient.channel("test")

                    waitUntil(timeout: testTimeout) { done in
                        recoveredChannel.publish("message", cb: { status in
                            expect(status.state).to(equal(ARTState.Ok))
                            expect(recoveredClient.connection().serial).to(equal(lastSerial + 1))
                            done()
                        })
                        expect(recoveredClient.connection().serial).to(equal(lastSerial))
                    }
                }

            }

            // RTN12
            context("close") {

                // RTN12a
                pending("should send a CLOSE action, change state to CLOSING and receive a CLOSED action") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()

                    let transport = client.transport as! TestProxyTransport
                    var states: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        client.eventEmitter.on { state, errorInfo in
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
                pending("should transition to CLOSED action when the close process timeouts") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    client.connect()

                    let transport = client.transport as! TestProxyTransport
                    transport.actionsIgnored += [.Closed]

                    var states: [ARTRealtimeConnectionState] = []
                    var start: NSDate?
                    var end: NSDate?

                    client.eventEmitter.on { state, errorInfo in
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

                    let transport = client.transport as! TestProxyTransport
                    var states: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: testTimeout) { done in
                        client.eventEmitter.on { state, errorInfo in
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

            }

            // RTN14a
            it("should enter FAILED state when API key is invalid") {
                let options = AblyTests.commonAppSetup()
                options.key = String(options.key!.characters.reverse())
                let client = ARTRealtime(options: options)
                defer { client.close() }

                waitUntil(timeout: testTimeout) { done in
                    client.eventEmitter.on { state, errorInfo in
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
            pending("connection request fails") {

                // NOTE: the connection doesn't retry to request a new token if any failure occurs

                it("should not emit error with a renewable token") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let tokenTtl = 1.0
                    options.token = getTestToken(key: options.key, ttl: tokenTtl)

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)
                    defer { client.close() }

                    // Let the token expire
                    waitUntil(timeout: testTimeout) { done in
                        delay(tokenTtl) {
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Connected:
                                expect(errorInfo).to(beNil())
                                // New token
                                expect(client.auth().tokenDetails!.token).toNot(equal(options.token))
                                done()
                            case .Failed, .Disconnected, .Suspended:
                                fail("Should not emit error (\(errorInfo))")
                                done()
                            default:
                                break
                            }
                        }
                        client.connect()
                    }

                    let transport = client.transport as! TestProxyTransport
                    let failures = transport.protocolMessagesReceived.filter({ $0.action == .Error })

                    if failures.count != 1 {
                        fail("Should have only one connection request fail")
                        return
                    }

                    expect(failures[0].error!.code).to(equal(40142)) //Token expired
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
                    defer { client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.eventEmitter.on { state, errorInfo in
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
                    }

                    let transport = client.transport as! TestProxyTransport
                    let failures = transport.protocolMessagesReceived.filter({ $0.action == .Error })

                    if failures.count != 1 {
                        fail("Should have only one connection request fail")
                        return
                    }

                    expect(failures[0].error!.code).to(equal(40142))
                }

            }

            // RTN18
            context("state change side effects") {

                // RTN18a
                it("when a connection enters the DISCONNECTED state, it will have no effect on the the channel states") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.close() }

                    let channel = client.channel("test")
                    channel.attach()

                    expect(channel.state).toEventually(equal(ARTRealtimeChannelState.Attached), timeout: testTimeout)

                    client.onDisconnected()

                    expect(client.connection().state).to(equal(ARTRealtimeConnectionState.Disconnected))
                    expect(channel.state).to(equal(ARTRealtimeChannelState.Attached))

                    waitUntil(timeout: testTimeout + options.disconnectedRetryTimeout) { done in
                        channel.publish("queuedMessage", cb: { status in
                            expect(status.state).to(equal(ARTState.Ok))
                            done()
                        })
                    }
                    expect(client.connection().state).to(equal(ARTRealtimeConnectionState.Connected))
                }

            }

        }
    }
}
