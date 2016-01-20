//
//  RealtimeClient.connection.swift
//  ably
//
//  Created by Ricardo Pereira on 03/11/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

import Quick
import Nimble

@testable import ably
@testable import ably.Private

/// A Nimble matcher that succeeds when a param exists.
public func haveParam(key: String, withValue expectedValue: String) -> NonNilMatcherFunc<String> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "param <\(key)=\(expectedValue)> exists"
        guard let actualValue = try actualExpression.evaluate() else { return false }
        let queryItems = actualValue.componentsSeparatedByString("&")
        for item in queryItems {
            let param = item.componentsSeparatedByString("=")
            if let currentKey = param.first, let currentValue = param.last where currentKey == key && currentValue == expectedValue {
                return true
            }
        }
        return false
    }
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
                                client.close()
                            case .Disconnected:
                                events += [state]
                                // Forced
                                client.transition(.Failed, withErrorInfo: ARTErrorInfo())
                            case .Suspended:
                                events += [state]
                                // Forced
                                client.transition(.Disconnected)
                            case .Closing:
                                events += [state]
                            case .Closed:
                                events += [state]
                                // Forced
                                client.transition(.Suspended)
                            case .Failed:
                                events += [state]
                                expect(errorInfo).toNot(beNil(), description: "Error is nil")
                                done()
                            }
                        }
                    }

                    expect(events).to(haveCount(8), description: "Missing some states")

                    if events.count != 8 {
                        return
                    }

                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.Initialized.rawValue), description: "Should be INITIALIZED state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.Connecting.rawValue), description: "Should be CONNECTING state")
                    expect(events[2].rawValue).to(equal(ARTRealtimeConnectionState.Connected.rawValue), description: "Should be CONNECTED state")
                    expect(events[3].rawValue).to(equal(ARTRealtimeConnectionState.Closing.rawValue), description: "Should be CLOSING state")
                    expect(events[4].rawValue).to(equal(ARTRealtimeConnectionState.Closed.rawValue), description: "Should be CLOSED state")
                    expect(events[5].rawValue).to(equal(ARTRealtimeConnectionState.Suspended.rawValue), description: "Should be SUSPENDED state")
                    expect(events[6].rawValue).to(equal(ARTRealtimeConnectionState.Disconnected.rawValue), description: "Should be DISCONNECTED state")
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
                    let connection = ARTRealtime(options: options).connection()
                    expect(connection.state.rawValue).to(equal(0), description: "Missing INITIALIZED state")

                    connection.close()
                }

                // RTN4e
                it("should have the current state on the event change") {
                    let connection = ARTRealtime(options: AblyTests.commonAppSetup()).connection()
                    var lastState = ARTRealtimeConnectionState.Initialized

                    // TODO: ConnectionStateChange object

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Connected:
                                lastState = state
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(lastState.rawValue).to(equal(2), description: "Missing state argument")

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
                                // Forced
                                client.transition(.Failed, withErrorInfo: ARTErrorInfo())
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

                // RTN7a
                context("should expect either an ACK or NACK to confirm") {

                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.clientId = "client_string"
                    let client = ARTRealtime(options: options)
                    client.setTransportClass(TestProxyTransport.self)

                    it("successful receipt and acceptance of message") {
                        client.connect()
                        defer {
                            client.dispose()
                            client.close()
                        }

                        waitUntil(timeout: testTimeout) { done in
                            publishTestMessage(client, completion: { error in
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
                            publishTestMessage(client, completion: { error in
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

            }

            // RTN8
            context("connection#id") {

                // RTN8a
                it("should be null until connected") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    let connection = client.connection()

                    expect(connection.id).to(beEmpty())

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            if state == .Connected && errorInfo == nil {
                                expect(connection.id).toNot(beEmpty())
                                done()
                            }
                            else if state == .Connecting {
                                expect(connection.id).to(beEmpty())
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
                            let currentConnection = disposable.last?.connection()
                            currentConnection?.eventEmitter.on { state, errorInfo in
                                if state == .Connected {
                                    expect(ids).toNot(contain(currentConnection?.id))
                                    ids.append(currentConnection?.id ?? "")

                                    currentConnection?.close()
                                    
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

                    expect(connection.key).to(beEmpty())

                    waitUntil(timeout: testTimeout) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            if state == .Connected && errorInfo == nil {
                                expect(connection.key).toNot(beEmpty())
                                done()
                            }
                            else if state == .Connecting {
                                expect(connection.key).to(beEmpty())
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
                            let currentConnection = disposable.last?.connection()
                            currentConnection?.eventEmitter.on { state, errorInfo in
                                if state == .Connected {
                                    expect(keys).toNot(contain(currentConnection?.key))
                                    keys.append(currentConnection?.key ?? "")

                                    currentConnection?.close()

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
        }
    }
}
